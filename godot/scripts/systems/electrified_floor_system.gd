class_name ElectrifiedFloorSystem
extends RefCounted

## Gerenciador do perigo ambiental de Pisos Eletrificados e Painéis de Força (Etapa 22).
## Lógica revertida de logic/damageelectric.asm (ChkElectricFloor, ChkElectricFloor2, ChkElectricFloor3),
## e logic/actors/powerswitch.asm.

const ROOM_SOLDIER: int = 16
const ROOM_SWITCH_1: int = 37
const ROOM_ROOF: int = 40
const ROOM_SWITCH_2: int = 110
const ROOM_BASEMENT: int = 116

const ELECTRIFIED_ROOMS: Array[int] = [ROOM_SOLDIER, ROOM_SWITCH_1, ROOM_ROOF, ROOM_SWITCH_2, ROOM_BASEMENT]

const DAMAGE_PER_SHOCK: int = 2     # DecrementLife_2 em logic/damageelectric.asm:62
const SHOCK_DELAY_TICKS: int = 8    # ld a, 8; ld (DamageDelayTimer), a em logic/damageelectric.asm:59-60
const SHOCK_DELAY_SEC: float = 8.0 / 60.0
const SFX_ID: int = 24              # 0x18 (SFX electric damage) em logic/damageelectric.asm:56

signal player_shocked(damage: int)
signal power_changed(room_id: int, is_on: bool)

var current_room_id: int = -1
var damage_delay_timer_sec: float = 0.0
var damage_delay_timer: int:
	get:
		return int(ceil(damage_delay_timer_sec * 60.0 - 0.0001))
	set(v):
		damage_delay_timer_sec = float(v) / 60.0
var room_panels_state: Dictionary = {}        # room_id (int) -> is_on (bool)
var hazard_coords_by_room: Dictionary = {}    # room_id (int) -> Dictionary[Vector2i, bool]
var hazard_tile_ids_by_room: Dictionary = {}  # room_id (int) -> Array[int]
var pulse_tick: int = 0

func _init() -> void:
	hazard_tile_ids_by_room = {
		ROOM_SOLDIER: [0x60, 0x61],
		ROOM_SWITCH_1: [0x60, 0x61],
		ROOM_ROOF: [0x45, 0x46],
		ROOM_SWITCH_2: [0x60, 0x61],
		ROOM_BASEMENT: [0x40, 0x41],
	}
	_load_extracted_data()
	reset_state()

func _load_extracted_data() -> void:
	var data: Dictionary = RomProvenance.load_canonical_json("electrified_floor.json")
	var rooms_list: Array = data.get("rooms", [])
	for r_entry: Variant in rooms_list:
		if not r_entry is Dictionary:
			continue
		var r_dict: Dictionary = r_entry as Dictionary
		var rid: int = int(r_dict.get("room_id", -1))
		var coords_arr: Array = r_dict.get("hazard_tile_coords", [])
		var set_dict: Dictionary = {}
		for c_pair: Variant in coords_arr:
			if c_pair is Array and c_pair.size() >= 2:
				var v := Vector2i(int(c_pair[0]), int(c_pair[1]))
				set_dict[v] = true
		hazard_coords_by_room[rid] = set_dict

func reset_state() -> void:
	damage_delay_timer_sec = 0.0
	pulse_tick = 0
	for rid: int in ELECTRIFIED_ROOMS:
		room_panels_state[rid] = true

func setup_room(room_id: int) -> void:
	current_room_id = room_id
	damage_delay_timer_sec = 0.0
	if not room_panels_state.has(room_id):
		room_panels_state[room_id] = true

func is_room_electrified(room_id: int) -> bool:
	return room_id in ELECTRIFIED_ROOMS

func is_power_on(room_id: int) -> bool:
	return room_panels_state.get(room_id, true)

func set_power(room_id: int, on: bool) -> void:
	room_panels_state[room_id] = on
	power_changed.emit(room_id, on)

func is_tile_electrified(room_id: int, tx: int, ty: int) -> bool:
	if not is_room_electrified(room_id):
		return false
	var room_coords: Dictionary = hazard_coords_by_room.get(room_id, {})
	var coord := Vector2i(tx, ty)
	return room_coords.has(coord)

## Injeta coordenadas de tiles de perigo manualmente (útil para testes sintéticos).
func set_custom_hazard_tiles(room_id: int, tiles: Array[Vector2i]) -> void:
	var set_dict: Dictionary = {}
	for t: Vector2i in tiles:
		set_dict[t] = true
	hazard_coords_by_room[room_id] = set_dict

## Verifica se o jogador sofre dano de choque no frame atual (GetTilePlayer em logic/collisions.asm:155).
## Retorna o valor de dano causado (2 ou 0).
func check_player_hazard(player_pos: Vector2, room_id: int, delta: float = 1.0 / 60.0) -> int:
	if not is_room_electrified(room_id):
		damage_delay_timer_sec = 0.0
		return 0
	if not is_power_on(room_id):
		damage_delay_timer_sec = 0.0
		return 0

	# GetTilePlayer: verifica pé esquerdo (pos.x - 4, pos.y) e pé direito (pos.x + 4, pos.y)
	var left_tx: int = int(floor((player_pos.x - 4.0) / 8.0))
	var left_ty: int = int(floor(player_pos.y / 8.0))
	var right_tx: int = int(floor((player_pos.x + 4.0) / 8.0))
	var right_ty: int = int(floor(player_pos.y / 8.0))

	var on_hazard: bool = is_tile_electrified(room_id, left_tx, left_ty) or is_tile_electrified(room_id, right_tx, right_ty)

	if on_hazard:
		if damage_delay_timer_sec > 0.0001:
			damage_delay_timer_sec = maxf(0.0, damage_delay_timer_sec - delta)
			return 0
		else:
			damage_delay_timer_sec = SHOCK_DELAY_SEC
			player_shocked.emit(DAMAGE_PER_SHOCK)
			return DAMAGE_PER_SHOCK
	else:
		if damage_delay_timer_sec > 0.0001:
			damage_delay_timer_sec = maxf(0.0, damage_delay_timer_sec - delta)
		return 0

func get_hazard_coords(room_id: int) -> Array[Vector2i]:
	var res: Array[Vector2i] = []
	var coords_dict: Dictionary = hazard_coords_by_room.get(room_id, {})
	for k: Variant in coords_dict.keys():
		res.append(k as Vector2i)
	return res
