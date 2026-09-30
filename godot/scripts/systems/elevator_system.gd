# elevator_system.gd
# Implementação fiel da lógica de elevadores do Metal Gear MSX2 RC750.
# Baseado nas rotinas e estruturas da ROM:
# - data/elevatorrooms.asm (idxElevatorRoom, ElevatorRoom1..11)
# - logic/elevatorroom.asm (ElevatorRoomLogic, MoveElevator, SetElevatorSpr)
# - logic/nextroom.asm (SetDoorOrElev, SetElevatorPosY, ChkDoorDestination)
# - Banks0123.asm (ElevatorCtrl, ControlPlayerH, ChkCtrlElevator, ChkLimitXElevator)

class_name ElevatorSystem
extends RefCounted

# Constantes canônicas de coordenadas da ROM
const ELEVATOR_CABIN_X: float = 112.0      # ElevatorX na ROM (0x70)
const PLAYER_ENTRY_X: float = 216.0        # PlayerXdec inicial (0xD8)
const CABIN_TRIGGER_X: float = 120.0       # PlayerX <= 0x78 está dentro da cabine
const SHAFT_MIN_X: float = 104.0           # Limite esquerdo da cabine (ChkLimitXElevator)
const SHAFT_MAX_X: float = 224.0           # Limite direito para acionar saída (ChkLimitXElevator2)
const ELEVATOR_SPEED: float = 1.0          # 1 px/tick (dec (hl) / inc (hl) em MoveElevator)
const ELEVATOR_SPEED_PX_PER_SEC: float = 60.0 # 1 px/tick * 60 = 60 px/s (Banks0123.asm:8540-8556)
const EXIT_UP_Y: float = 24.0               # cp 24 em MoveElevator (0x18)
const EXIT_DOWN_Y: float = 208.0            # cp 208 em ElevatorDown (0xD0)
const ENTRY_UP_Y: float = 208.0             # 0xD0 em SetNextRoomElev (entrando por baixo ao subir)
const ENTRY_DOWN_Y: float = 24.0            # 0x18 em SetNextRoomElev (entrando por cima ao descer)

# Conexões verticais canônicas de shafts multi-telas da ROM (data/roomsconnections.asm:152-162)
const ELEVATOR_CONNECTIONS: Dictionary = {
	241: {"up": 242, "down": -1},
	242: {"up": -1, "down": 241},
	243: {"up": 244, "down": -1},
	244: {"up": -1, "down": 243},
	245: {"up": 246, "down": -1},
	246: {"up": -1, "down": 245},
	247: {"up": -1, "down": 248},
	248: {"up": 247, "down": 249},
	249: {"up": 248, "down": 250},
	250: {"up": 249, "down": -1},
}

static func get_connected_elevator_room(room_id: int, direction_y: int) -> int:
	var conns: Dictionary = ELEVATOR_CONNECTIONS.get(room_id, {})
	if conns.is_empty():
		return -1
	if direction_y < 0:
		return int(conns.get("up", -1))
	elif direction_y > 0:
		return int(conns.get("down", -1))
	return -1

# Mapeamento completo dos 11 elevadores da ROM (data/elevatorrooms.asm)
# Salas 240 a 250 (0xF0 a 0xFA)
const ELEVATOR_DATA: Dictionary = {
	240: {
		"top_limit": 56.0,      # 0x38
		"bottom_limit": 184.0,  # 0xB8
		"floors": [
			{"room_id": 31, "player_y": 56.0, "elevator_y": 52.0},   # Telhado
			{"room_id": 3,  "player_y": 184.0, "elevator_y": 180.0}   # Prédio 1 - Térreo
		]
	},
	241: {
		"top_limit": 40.0,      # 0x28
		"bottom_limit": 184.0,  # 0xB8
		"floors": [
			{"room_id": 27, "player_y": 56.0, "elevator_y": 52.0},    # Andar Superior (Telhado P2)
			{"room_id": 15, "player_y": 120.0, "elevator_y": 116.0},  # Andar Médio (P2)
			{"room_id": 63, "player_y": 184.0, "elevator_y": 180.0}   # Andar Inferior (P2 Térreo)
		]
	},
	242: {
		"top_limit": 120.0,     # 0x78
		"bottom_limit": 200.0,  # 0xC8
		"floors": [
			{"room_id": 53, "player_y": 120.0, "elevator_y": 116.0},
			{"room_id": 39, "player_y": 184.0, "elevator_y": 180.0}
		]
	},
	243: {
		"top_limit": 40.0,      # 0x28
		"bottom_limit": 184.0,  # 0xB8
		"floors": [
			{"room_id": 81, "player_y": 56.0, "elevator_y": 52.0},
			{"room_id": 72, "player_y": 120.0, "elevator_y": 116.0},
			{"room_id": 95, "player_y": 184.0, "elevator_y": 180.0}
		]
	},
	244: {
		"top_limit": 184.0,     # 0xB8
		"bottom_limit": 200.0,  # 0xC8
		"floors": [
			{"room_id": 88, "player_y": 184.0, "elevator_y": 180.0}
		]
	},
	245: {
		"top_limit": 40.0,      # 0x28
		"bottom_limit": 184.0,  # 0xB8
		"floors": [
			{"room_id": 205, "player_y": 56.0, "elevator_y": 52.0},
			{"room_id": 206, "player_y": 120.0, "elevator_y": 116.0},
			{"room_id": 207, "player_y": 184.0, "elevator_y": 180.0}
		]
	},
	246: {
		"top_limit": 184.0,     # 0xB8
		"bottom_limit": 200.0,  # 0xC8
		"floors": [
			{"room_id": 154, "player_y": 184.0, "elevator_y": 180.0}
		]
	},
	247: {
		"top_limit": 56.0,      # 0x38
		"bottom_limit": 200.0,  # 0xC8
		"floors": [
			{"room_id": 109, "player_y": 56.0, "elevator_y": 52.0}
		]
	},
	250: {
		"top_limit": 40.0,      # 0x28
		"bottom_limit": 184.0,  # 0xB8
		"floors": [
			{"room_id": 115, "player_y": 184.0, "elevator_y": 180.0}
		]
	}
}

static func is_elevator_room(room_id: int) -> bool:
	return room_id >= 240 and room_id <= 250

static func get_elevator_config(room_id: int) -> Dictionary:
	return ELEVATOR_DATA.get(room_id, {})

## Determina a posição inicial de Snake e da cabine ao entrar no elevador vindo de um andar (GetElevatorPosY)
static func get_entry_state(elevator_room_id: int, previous_room_id: int) -> Dictionary:
	var config: Dictionary = get_elevator_config(elevator_room_id)
	if config.is_empty():
		return {
			"player_pos": Vector2(PLAYER_ENTRY_X, 184.0),
			"player_dir": PlayerController.Direction.LEFT,
			"elevator_y": 180.0
		}

	var floors: Array = config.get("floors", [])
	for f_var: Variant in floors:
		if f_var is Dictionary:
			var f: Dictionary = f_var as Dictionary
			if int(f.get("room_id", -1)) == previous_room_id:
				return {
					"player_pos": Vector2(PLAYER_ENTRY_X, float(f.get("player_y", 184.0))),
					"player_dir": PlayerController.Direction.LEFT,
					"elevator_y": float(f.get("elevator_y", 180.0))
				}

	# Se a sala anterior não estiver na tabela, usa o andar padrão (inferior)
	if not floors.is_empty():
		var last_floor: Dictionary = floors[floors.size() - 1] as Dictionary
		return {
			"player_pos": Vector2(PLAYER_ENTRY_X, float(last_floor.get("player_y", 184.0))),
			"player_dir": PlayerController.Direction.LEFT,
			"elevator_y": float(last_floor.get("elevator_y", 180.0))
		}

	return {
		"player_pos": Vector2(PLAYER_ENTRY_X, 184.0),
		"player_dir": PlayerController.Direction.LEFT,
		"elevator_y": 180.0
	}

## Localiza o próximo andar na direção desejada (-1 = UP, +1 = DOWN)
static func get_next_target_floor(
	elevator_room_id: int,
	current_elevator_y: float,
	direction: int
) -> Dictionary:
	var config: Dictionary = get_elevator_config(elevator_room_id)
	if config.is_empty() or direction == 0:
		return {"has_target": false}

	var floors: Array = config.get("floors", [])
	var candidate: Dictionary = {}

	if direction < 0:
		# Subindo: procura o andar com elevator_y menor que o atual, mas mais próximo dele
		var max_lesser_y: float = -9999.0
		for f_var: Variant in floors:
			if f_var is Dictionary:
				var f: Dictionary = f_var as Dictionary
				var ey: float = float(f.get("elevator_y", 0.0))
				if ey < current_elevator_y - 2.0:
					if ey > max_lesser_y:
						max_lesser_y = ey
						candidate = f
		if not candidate.is_empty():
			return {
				"has_target": true,
				"target_elev_y": float(candidate.get("elevator_y", 0.0)),
				"target_player_y": float(candidate.get("player_y", 0.0)),
				"room_id": int(candidate.get("room_id", -1)),
				"is_screen_transition": false
			}
		# Se não há mais andares acima nesta sala, verifica se o shaft continua subindo para outra tela (ex: 241 -> 242)
		var next_up: int = get_connected_elevator_room(elevator_room_id, -1)
		if next_up != -1:
			return {
				"has_target": true,
				"target_elev_y": EXIT_UP_Y,
				"target_player_y": EXIT_UP_Y + 4.0,
				"room_id": -1,
				"is_screen_transition": true,
				"next_room_id": next_up
			}
	elif direction > 0:
		# Descendo: procura o andar com elevator_y maior que o atual, mas mais próximo dele
		var min_greater_y: float = 9999.0
		for f_var: Variant in floors:
			if f_var is Dictionary:
				var f: Dictionary = f_var as Dictionary
				var ey: float = float(f.get("elevator_y", 0.0))
				if ey > current_elevator_y + 2.0:
					if ey < min_greater_y:
						min_greater_y = ey
						candidate = f
		if not candidate.is_empty():
			return {
				"has_target": true,
				"target_elev_y": float(candidate.get("elevator_y", 0.0)),
				"target_player_y": float(candidate.get("player_y", 0.0)),
				"room_id": int(candidate.get("room_id", -1)),
				"is_screen_transition": false
			}
		# Se não há mais andares abaixo nesta sala, verifica se o shaft continua descendo para outra tela (ex: 242 -> 241)
		var next_down: int = get_connected_elevator_room(elevator_room_id, 1)
		if next_down != -1:
			return {
				"has_target": true,
				"target_elev_y": EXIT_DOWN_Y,
				"target_player_y": EXIT_DOWN_Y + 4.0,
				"room_id": -1,
				"is_screen_transition": true,
				"next_room_id": next_down
			}

	return {"has_target": false}

## Determina o primeiro andar de parada ao entrar em uma nova sala de elevador em trânsito
static func get_entry_moving_target(elevator_room_id: int, move_dir_y: int) -> Dictionary:
	var config: Dictionary = get_elevator_config(elevator_room_id)
	var floors: Array = config.get("floors", [])
	if move_dir_y < 0:
		# Entrou por baixo (Y=208), subindo:
		# Primeiro andar que encontra é o andar com o MAIOR elevator_y na nova sala
		var target_floor: Dictionary = {}
		var max_y: float = -9999.0
		for f_var: Variant in floors:
			if f_var is Dictionary:
				var f: Dictionary = f_var as Dictionary
				var ey: float = float(f.get("elevator_y", 0.0))
				if ey > max_y:
					max_y = ey
					target_floor = f
		if not target_floor.is_empty():
			return {
				"has_target": true,
				"target_elev_y": float(target_floor.get("elevator_y", 24.0)),
				"target_player_y": float(target_floor.get("player_y", 28.0)),
				"room_id": int(target_floor.get("room_id", -1))
			}
		else:
			# Sala sem andares (e.g. poço contínuo 248) -> continua subindo para sair pelo topo
			return {
				"has_target": true,
				"target_elev_y": EXIT_UP_Y,
				"target_player_y": EXIT_UP_Y + 4.0,
				"room_id": -1
			}
	elif move_dir_y > 0:
		# Entrou por cima (Y=24), descendo:
		# Primeiro andar que encontra é o andar com o MENOR elevator_y na nova sala
		var target_floor: Dictionary = {}
		var min_y: float = 9999.0
		for f_var: Variant in floors:
			if f_var is Dictionary:
				var f: Dictionary = f_var as Dictionary
				var ey: float = float(f.get("elevator_y", 0.0))
				if ey < min_y:
					min_y = ey
					target_floor = f
		if not target_floor.is_empty():
			return {
				"has_target": true,
				"target_elev_y": float(target_floor.get("elevator_y", 208.0)),
				"target_player_y": float(target_floor.get("player_y", 212.0)),
				"room_id": int(target_floor.get("room_id", -1))
			}
		else:
			# Sala sem andares (e.g. poço contínuo 249) -> continua descendo para sair pelo fundo
			return {
				"has_target": true,
				"target_elev_y": EXIT_DOWN_Y,
				"target_player_y": EXIT_DOWN_Y + 4.0,
				"room_id": -1
			}
	return {"has_target": false}

## Verifica se Snake está saindo do elevador pelo corredor direito (X >= 224)
static func check_exit(
	elevator_room_id: int,
	player_pos: Vector2,
	elevator_y: float
) -> Dictionary:
	var result := {
		"should_exit": false,
		"destination_room_id": -1,
		"entry_position": Vector2(108.0, 36.0),
		"destination_direction": PlayerController.Direction.DOWN
	}

	if player_pos.x < SHAFT_MAX_X:
		return result

	var config: Dictionary = get_elevator_config(elevator_room_id)
	if config.is_empty():
		return result

	# Acha o andar alinhado com o elevador atual (dentro de tolerância de 8px)
	var floors: Array = config.get("floors", [])
	var best_floor: Dictionary = {}
	var min_dist: float = 9999.0

	for f_var: Variant in floors:
		if f_var is Dictionary:
			var f: Dictionary = f_var as Dictionary
			var f_elev_y: float = float(f.get("elevator_y", 0.0))
			var dist: float = absf(elevator_y - f_elev_y)
			if dist < min_dist and dist <= 8.0:
				min_dist = dist
				best_floor = f

	if not best_floor.is_empty():
		result["should_exit"] = true
		result["destination_room_id"] = int(best_floor.get("room_id", -1))
		# Ao entrar na sala do andar, Snake sai na porta do elevador (norte), descendo para o sul
		result["entry_position"] = Vector2(108.0, 36.0)
		result["destination_direction"] = PlayerController.Direction.DOWN

	return result
