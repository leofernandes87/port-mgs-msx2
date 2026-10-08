class_name BinocularSystem
extends RefCounted

## Sistema de binóculo / telescópio autêntico do Metal Gear MSX2 RC750.
## Lógica revertida de logic/menuequipment.asm:295-350 e Banks0123.asm:12250-12604 (BinocularLogic).

enum State {
	INACTIVE = 0,
	IDLE = 1,      ## No quarto de origem, aguardando direção (setas / WASD)
	LOOKING = 2,   ## Observando sala adjacente com temporizador ativo
}

const PREVIEW_DURATION_TICKS: int = 128 ## 80h na ROM MSX (Banks0123.asm:12481) ~2.1s a 60fps
const PREVIEW_DURATION_SEC: float = 128.0 / 60.0

var is_active: bool = false
var state: State = State.INACTIVE
var home_room_id: int = -1
var preview_room_id: int = -1
var looking_direction: int = -1
var preview_timer_sec: float = 0.0
var preview_timer: int:
	get:
		return int(ceil(preview_timer_sec * 60.0 - 0.0001))
	set(v):
		preview_timer_sec = float(v) / 60.0

## Salas isoladas da ROM onde o binóculo é inoperante (Banks0123.asm:1030-1048 e menuequipment.asm:300)
static func is_room_isolated(room_id: int) -> bool:
	return RoomManager.is_room_isolated(room_id)

func can_use_in_room(room_id: int) -> bool:
	return not is_room_isolated(room_id)

func activate(current_room_id: int) -> bool:
	if not can_use_in_room(current_room_id):
		return false
	is_active = true
	state = State.IDLE
	home_room_id = current_room_id
	preview_room_id = current_room_id
	looking_direction = -1
	preview_timer_sec = 0.0
	print("BINOCULARS_ACTIVATED: Modo binóculo ativo na sala %d" % current_room_id)
	return true

func deactivate() -> void:
	is_active = false
	state = State.INACTIVE
	home_room_id = -1
	preview_room_id = -1
	looking_direction = -1
	preview_timer_sec = 0.0
	print("BINOCULARS_DEACTIVATED: Modo binóculo desativado")

func look_direction(dir: PlayerController.Direction) -> int:
	if not is_active or state != State.IDLE:
		return -1
	var target_room: int = RoomManager.get_next_room(home_room_id, dir)
	if target_room == RoomManager.NO_ROOM:
		return -1
	looking_direction = int(dir)
	preview_room_id = target_room
	preview_timer_sec = PREVIEW_DURATION_SEC
	state = State.LOOKING
	print("BINOCULARS_LOOK: Observando sala adjacente %d na direção %d (Duração: %d ticks)" % [
		target_room, looking_direction, preview_timer
	])
	return target_room

func step_tick(delta: float = 1.0 / 60.0) -> Dictionary:
	var result := {
		"is_active": is_active,
		"state": state,
		"returned_home": false,
		"preview_room_id": preview_room_id,
		"looking_direction": looking_direction,
		"remaining_ticks": preview_timer,
	}
	if not is_active:
		return result
	if state == State.LOOKING:
		preview_timer_sec = maxf(0.0, preview_timer_sec - delta)
		if preview_timer_sec <= 0.0001:
			preview_timer_sec = 0.0
			state = State.IDLE
			preview_room_id = home_room_id
			looking_direction = -1
			result["state"] = state
			result["returned_home"] = true
			result["preview_room_id"] = home_room_id
			result["looking_direction"] = -1
			result["remaining_ticks"] = 0
			print("BINOCULARS_RETURN: Fim do temporizador, retornando à sala de origem %d" % home_room_id)
		else:
			result["remaining_ticks"] = preview_timer
	return result
