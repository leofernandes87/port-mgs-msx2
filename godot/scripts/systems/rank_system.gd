class_name RankSystem
extends RefCounted

## Sistema de Patente Militar (Class / Rank ★1 a ★4) e Registro de Reféns do Metal Gear MSX2.
## Lógica revertida de Banks0123.asm:9574-9679 e logic/maxammo.asm.

signal rank_changed(new_rank: int)
signal prisoner_rescued(room_id: int, prisoner_name: String, message: String)
signal prisoner_killed(room_id: int, is_vital: bool)

const MIN_RANK: int = 1
const MAX_RANK: int = 4
const RESCUED_PER_RANK: int = 4

var current_rank: int = 1
var rescued_count: int = 0 # Contador para o próximo rank (0 a 4)
var total_rescued: int = 0
var rescued_rooms: Dictionary = {} # room_id -> bool

func get_max_life() -> int:
	match current_rank:
		1: return 24
		2: return 32
		3: return 40
		4: return 48
		_: return 24

func get_max_ammo(weapon_id: String) -> int:
	match weapon_id:
		"HANDGUN", "SMG":
			match current_rank:
				1: return 50
				2: return 100
				3: return 200
				4: return 300
				_: return 50
		"GRENADE_LAUNCHER":
			match current_rank:
				1: return 15
				2: return 30
				3: return 60
				4: return 90
				_: return 15
		_:
			return 50

func get_max_rations() -> int:
	match current_rank:
		1: return 3
		2: return 6
		3: return 9
		4: return 12
		_: return 3

func get_rank_stars() -> String:
	return "★".repeat(current_rank) + "☆".repeat(MAX_RANK - current_rank)

func is_room_rescued(room_id: int) -> bool:
	return rescued_rooms.get(room_id, false)

## Registra o resgate de um refém. Retorna true se Snake subiu de patente.
func register_rescue(room_id: int, prisoner_name: String = "PRISONER", message: String = "") -> bool:
	if rescued_rooms.get(room_id, false):
		return false

	rescued_rooms[room_id] = true
	total_rescued += 1
	rescued_count += 1
	prisoner_rescued.emit(room_id, prisoner_name, message)
	print("PRISONER_RESCUED: %s resgatado na sala %d! (Progresso: %d/%d)" % [
		prisoner_name, room_id, rescued_count, RESCUED_PER_RANK
	])

	if rescued_count >= RESCUED_PER_RANK:
		rescued_count = 0
		if current_rank < MAX_RANK:
			current_rank += 1
			rank_changed.emit(current_rank)
			print("RANK_UP: Parabéns! Snake promovido para Rank ★%d (%s)!" % [current_rank, get_rank_stars()])
			return true

	return false

## Rebaixa Snake de patente (DowngradeRank em Banks0123.asm:9581-9625) ao matar refém.
func downgrade_rank() -> bool:
	rescued_count = 0
	if current_rank > MIN_RANK:
		current_rank -= 1
		rank_changed.emit(current_rank)
		print("RANK_DOWN: Snake foi rebaixado para Rank ★%d (%s)!" % [current_rank, get_rank_stars()])
		return true
	return false

## Registra morte de refém atingido por tiro ou soco.
func register_kill(room_id: int, is_vital: bool = false) -> bool:
	prisoner_killed.emit(room_id, is_vital)
	return downgrade_rank()

func reset() -> void:
	current_rank = MIN_RANK
	rescued_count = 0
	total_rescued = 0
	rescued_rooms.clear()
	rank_changed.emit(current_rank)
	print("RANK_RESET: Patente reiniciada para Rank ★1 (%s)." % get_rank_stars())


