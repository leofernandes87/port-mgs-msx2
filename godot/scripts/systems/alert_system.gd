class_name AlertSystem
extends RefCounted

## Máquina de Estados de Alerta Global, Evasão e Reforços Militares fiel ao MSX2 RC750 (Etapa 17).
## Lógica revertida de:
## - logic/setalert.asm (SetAlertMode, SetAlertModeRespawn, NumRespawnGuards = CardLevel + 3)
## - Banks0123.asm:6550-6720 (ChkRespawnEnemy, ChkAlarmEnd, StopAlert, TransformAlertGuard)
## - data/respawninfo.asm (tabela RespawnInfo offset 0xC445 do Banco 6)

enum AlertState {
	NORMAL = 0,
	ALERT = 1,
	EVASION = 2,
}

signal state_changed(old_state: AlertState, new_state: AlertState)
signal reinforcement_requested(enemy_id: int, spawn_pos: Vector2)
signal alert_cleared()

const RESPAWN_INTERVAL: int = 24 # ~20 a 35 ticks na ROM (Banks0123.asm:6576)
const EVASION_COUNTDOWN_TICKS: int = 99 # Temporizador regressivo de busca

var current_state: AlertState = AlertState.NORMAL
var is_red_alert: bool = false
var current_room_id: int = 0
var room_alert_origin: int = 0

var num_respawn_guards: int = 0
var respawn_timer: int = 0
var evasion_timer: int = 0
var spawn_point_index: int = 0
var max_active_reinforcements: int = 3

# Cache da tabela RespawnInfo (room_id -> {enemy_id, spawn_points})
var respawn_table: Dictionary = {}

func _init() -> void:
	load_respawn_table()

## Carrega a tabela RespawnInfo neutra exportada de data/extracted/respawn_info.json
func load_respawn_table(custom_path: String = "") -> void:
	respawn_table.clear()
	var path: String = custom_path
	if path.is_empty():
		# Tenta caminhos do projeto Godot
		for p in ["res://../data/extracted/respawn_info.json", "res://data/respawn_info.json"]:
			if FileAccess.file_exists(p):
				path = p
				break

	if not path.is_empty() and FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var text := file.get_as_text()
			file.close()
			var json_obj = JSON.parse_string(text)
			if json_obj is Dictionary and json_obj.has("rooms"):
				for r in json_obj["rooms"]:
					var rid: int = int(r.get("room_id", 0))
					var eid: int = int(r.get("enemy_id", 0))
					var pts: Array[Vector2] = []
					for pt in r.get("spawn_points", []):
						pts.append(Vector2(float(pt.get("x", 0)), float(pt.get("y", 0))))
					respawn_table[rid] = {
						"enemy_id": eid,
						"spawn_points": pts,
					}
				return

	# Fallback sintético canônico para salas críticas de teste caso o JSON não esteja montado
	_init_fallback_table()

func _init_fallback_table() -> void:
	# Salas 0 a 4 conferidas diretamente da ROM no offset 0xC445
	respawn_table[0] = { "enemy_id": 10, "spawn_points": [Vector2(144.0, 16.0), Vector2(240.0, 160.0)] }
	respawn_table[1] = { "enemy_id": 10, "spawn_points": [Vector2(64.0, 16.0), Vector2(240.0, 144.0)] }
	respawn_table[2] = { "enemy_id": 10, "spawn_points": [Vector2(192.0, 80.0), Vector2(16.0, 160.0)] }
	respawn_table[3] = { "enemy_id": 11, "spawn_points": [Vector2(48.0, 240.0), Vector2(160.0, 240.0)] }
	respawn_table[4] = { "enemy_id": 10, "spawn_points": [Vector2(144.0, 16.0), Vector2(160.0, 240.0)] }

## Consulta as informações de respawn para a sala especificada
func get_respawn_info(room_id: int) -> Dictionary:
	if respawn_table.has(room_id):
		return respawn_table[room_id]
	return {
		"enemy_id": 10,
		"spawn_points": [Vector2(128.0, 16.0), Vector2(240.0, 96.0)],
	}

## Aciona o modo de alerta (SetAlertMode em logic/setalert.asm:14-40)
func trigger_alert(is_red: bool = false, card_level: int = 1, room_id: int = 0) -> void:
	current_room_id = room_id
	room_alert_origin = room_id

	if current_state == AlertState.ALERT:
		if is_red:
			is_red_alert = true
		return

	var old_state: AlertState = current_state
	current_state = AlertState.ALERT
	is_red_alert = is_red

	# NumRespawnGuards = CardLevel + 3 (setalert.asm:35-39)
	num_respawn_guards = maxi(3, card_level + 3)
	respawn_timer = 20 # Delay inicial antes do primeiro respawn
	evasion_timer = EVASION_COUNTDOWN_TICKS
	spawn_point_index = 0

	state_changed.emit(old_state, current_state)
	print("ALERT_SYSTEM: ALERTA acionado na sala %d! RedAlert: %s, Reforços: %d" % [
		room_id, is_red_alert, num_respawn_guards
	])

## Cancela totalmente o alerta e retorna ao estado NORMAL (StopAlert em Banks0123.asm:6698)
func stop_alert() -> void:
	if current_state == AlertState.NORMAL:
		return

	var old_state: AlertState = current_state
	current_state = AlertState.NORMAL
	is_red_alert = false
	num_respawn_guards = 0
	respawn_timer = 0
	evasion_timer = 0

	state_changed.emit(old_state, current_state)
	alert_cleared.emit()
	print("ALERT_SYSTEM: Alerta encerrado. Estado NORMAL restaurado.")

## Reseta incondicionalmente o sistema de alerta para o modo furtivo/NORMAL
func reset() -> void:
	var old_state: AlertState = current_state
	current_state = AlertState.NORMAL
	is_red_alert = false
	current_room_id = 0
	room_alert_origin = 0
	num_respawn_guards = 0
	respawn_timer = 0
	evasion_timer = 0
	spawn_point_index = 0
	if old_state != AlertState.NORMAL:
		state_changed.emit(old_state, current_state)
	alert_cleared.emit()
	print("ALERT_RESET: Sistema de alerta resetado para modo furtivo/NORMAL.")


## Atualização de lógica a cada tick de física
func tick(has_vision_on_snake: bool, current_active_guards: int, room_id: int) -> void:
	current_room_id = room_id

	match current_state:
		AlertState.ALERT:
			if has_vision_on_snake:
				# Inimigos mantêm visada direta sobre Snake
				evasion_timer = EVASION_COUNTDOWN_TICKS

				# Ciclo de Respawn de Reforços (Banks0123.asm:6559-6628)
				if num_respawn_guards > 0:
					respawn_timer -= 1
					if respawn_timer <= 0:
						respawn_timer = RESPAWN_INTERVAL
						if current_active_guards < max_active_reinforcements:
							var info: Dictionary = get_respawn_info(room_id)
							var eid: int = int(info.get("enemy_id", 10))
							var pts: Array = info.get("spawn_points", [])
							if eid > 0 and not pts.is_empty():
								var spawn_pos: Vector2 = pts[spawn_point_index % pts.size()]
								spawn_point_index += 1
								num_respawn_guards -= 1
								reinforcement_requested.emit(eid, spawn_pos)
								print("ALERT_REINFORCEMENT: Soldado %d convocado em %s (Restantes: %d)" % [
									eid, spawn_pos, num_respawn_guards
								])
			else:
				# Snake quebrou a linha de visão (atrás de paredes, caixa de papelão, etc.)
				# Transição imediata para EVASÃO
				var old_state: AlertState = current_state
				current_state = AlertState.EVASION
				evasion_timer = EVASION_COUNTDOWN_TICKS
				state_changed.emit(old_state, current_state)
				print("ALERT_SYSTEM: Snake fora de vista! Transição para EVASÃO (Contador: %d)" % evasion_timer)

		AlertState.EVASION:
			if has_vision_on_snake:
				# Snake foi reavistado durante a busca de evasão!
				var old_state: AlertState = current_state
				current_state = AlertState.ALERT
				evasion_timer = EVASION_COUNTDOWN_TICKS
				state_changed.emit(old_state, current_state)
				print("ALERT_SYSTEM: Snake reavistado! Retorno ao modo de ALERTA!")
			else:
				# Contagem regressiva de evasão
				evasion_timer -= 1
				if evasion_timer <= 0:
					print("ALERT_SYSTEM: Temporizador de evasão esgotado com sucesso!")
					stop_alert()

		AlertState.NORMAL:
			pass

## Transição entre salas (ChkAlarmEnd em Banks0123.asm:6644-6670)
func on_room_transition(new_room_id: int) -> void:
	current_room_id = new_room_id

	# Entrar em um elevador cancela imediatamente o alerta (Banks0123.asm:6646 cp 0F0h; jr nc, StopAlert)
	if new_room_id >= 240:
		stop_alert()
		return

	# Se Snake mudar de sala após todos os reforços terem sido convocados, o alerta encerra (Banks0123.asm:6669)
	if current_state != AlertState.NORMAL:
		if num_respawn_guards <= 0 and new_room_id != room_alert_origin:
			stop_alert()
