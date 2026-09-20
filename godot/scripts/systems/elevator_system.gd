# elevator_system.gd
# Implementação fiel da lógica de elevadores do Metal Gear MSX2 RC750.
# Baseado nas rotinas e estruturas da ROM:
# - data/elevatorrooms.asm (idxElevatorRoom, ElevatorRoom1..11)
# - logic/elevatorroom.asm (ElevatorRoomLogic, MoveElevator, SetElevatorSpr)
# - logic/nextroom.asm (SetDoorOrElev, SetElevatorPosY, ChkDoorDestination)
# - Banks0123.asm (ChkCtrlElevator, ChkLimitXElevator, GetElevatorRoomDat)

class_name ElevatorSystem
extends RefCounted

# Constantes canônicas de coordenadas da ROM
const ELEVATOR_CABIN_X: float = 112.0      # ElevatorX na ROM (0x70)
const PLAYER_ENTRY_X: float = 216.0        # PlayerXdec inicial (0xD8)
const CABIN_TRIGGER_X: float = 120.0       # PlayerX <= 0x78 está dentro da cabine
const SHAFT_MIN_X: float = 104.0           # Limite esquerdo da cabine (ChkLimitXElevator)
const SHAFT_MAX_X: float = 224.0           # Limite direito para acionar saída (ChkLimitXElevator2)
const ELEVATOR_SPEED: float = 1.0          # 1 px/tick (dec (hl) / inc (hl) em MoveElevator)

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
			{"room_id": 27, "player_y": 56.0, "elevator_y": 52.0},
			{"room_id": 15, "player_y": 120.0, "elevator_y": 116.0},
			{"room_id": 63, "player_y": 184.0, "elevator_y": 180.0}
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

## Determina a posição inicial de Snake e da cabine ao entrar no elevador vindo de um andar
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

	# Se a sala anterior não estiver na tabela, usa o andar padrão (primeiro ou inferior)
	if not floors.is_empty():
		var first_floor: Dictionary = floors[floors.size() - 1] as Dictionary
		return {
			"player_pos": Vector2(PLAYER_ENTRY_X, float(first_floor.get("player_y", 184.0))),
			"player_dir": PlayerController.Direction.LEFT,
			"elevator_y": float(first_floor.get("elevator_y", 180.0))
		}

	return {
		"player_pos": Vector2(PLAYER_ENTRY_X, 184.0),
		"player_dir": PlayerController.Direction.LEFT,
		"elevator_y": 180.0
	}

## Executa a movimentação da cabine e de Snake quando dentro da cabine (1 px/tick)
static func step_movement(
	elevator_room_id: int,
	player_pos: Vector2,
	elevator_y: float,
	input_y: int
) -> Dictionary:
	var result := {
		"player_pos": player_pos,
		"elevator_y": elevator_y,
		"is_moving": false,
		"floor_reached": false,
		"current_floor_room_id": -1
	}

	# Snake só controla o elevador se estiver dentro da cabine (PlayerX <= 120)
	if player_pos.x > CABIN_TRIGGER_X or input_y == 0:
		return result

	var config: Dictionary = get_elevator_config(elevator_room_id)
	if config.is_empty():
		return result

	var top_limit: float = float(config.get("top_limit", 40.0))
	var bottom_limit: float = float(config.get("bottom_limit", 184.0))

	var new_elev_y: float = elevator_y
	var new_player_y: float = player_pos.y

	if input_y < 0:
		# Subir
		if elevator_y > top_limit - 4.0:
			new_elev_y -= ELEVATOR_SPEED
			new_player_y -= ELEVATOR_SPEED
			result["is_moving"] = true
	elif input_y > 0:
		# Descer
		if elevator_y < bottom_limit - 4.0:
			new_elev_y += ELEVATOR_SPEED
			new_player_y += ELEVATOR_SPEED
			result["is_moving"] = true

	result["elevator_y"] = new_elev_y
	result["player_pos"] = Vector2(player_pos.x, new_player_y)

	# Verificar se coincide com algum andar registrado
	var floors: Array = config.get("floors", [])
	for f_var: Variant in floors:
		if f_var is Dictionary:
			var f: Dictionary = f_var as Dictionary
			var target_elev_y: float = float(f.get("elevator_y", 0.0))
			if absf(new_elev_y - target_elev_y) < 1.0:
				result["floor_reached"] = true
				result["current_floor_room_id"] = int(f.get("room_id", -1))
				break

	return result

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

	# Acha o andar mais próximo do elevador atual (dentro de tolerância de 4px)
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
