class_name GasHazardSystem
extends RefCounted

## Gerenciador de perigo ambiental de gás tóxico e proteção por máscara de gás (Etapa 19).
## Lógica revertida de logic/damagegas.asm (ChkGasRooms, ChkGasMask, GasRooms no offset 0x4C79).

signal gas_damage_taken(damage: int, remaining_life: int)
signal gas_protection_status_changed(is_protected: bool)

# Tabela canônica de 9 salas de gás do MSX2 RC750 (damagegas.asm:53)
const CANONICAL_GAS_ROOMS: Array[int] = [29, 94, 96, 97, 98, 100, 101, 112, 114]
const DAMAGE_INTERVAL_TICKS: int = 16 # 0x10 ticks (damagegas.asm:34)
const DAMAGE_PER_INTERVAL: int = 2    # 2 HP (damagegas.asm:45)

var gas_rooms: Array[int] = []
var _last_protection_state: bool = false

func _init() -> void:
	load_gas_hazard_data()

## Restaura estado interno do sistema de gás
func reset() -> void:
	_last_protection_state = false

## Carrega especificação neutra exportada de data/extracted/gas_hazard.json com fallback canônico
func load_gas_hazard_data(custom_path: String = "") -> void:
	gas_rooms.clear()
	var path: String = custom_path
	if path.is_empty():
		for p: String in ["res://../data/extracted/gas_hazard.json", "res://data/gas_hazard.json"]:
			if FileAccess.file_exists(p):
				path = p
				break

	if not path.is_empty() and FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var json_obj = JSON.parse_string(file.get_as_text())
			file.close()
			if json_obj is Dictionary and json_obj.has("gas_rooms"):
				for r in json_obj["gas_rooms"]:
					gas_rooms.append(int(r))
				return

	# Fallback canônico
	gas_rooms = CANONICAL_GAS_ROOMS.duplicate()

## Verifica se a sala informada contém gás tóxico
func is_gas_room(room_id: int) -> bool:
	return gas_rooms.has(room_id)

## Verifica se o jogador está equipado com a máscara de gás
func is_player_protected(inventory: InventoryManager) -> bool:
	if inventory == null:
		return false
	return inventory.get_selected_item() == InventoryManager.ITEM_GAS_MASK

## Atualização de lógica de gás por tick de física
func tick(room_id: int, player: PlayerController, inventory: InventoryManager) -> Dictionary:
	if not is_gas_room(room_id) or player == null or player.is_dead:
		return {"in_gas": false, "protected": false, "damaged": false}

	var protected: bool = is_player_protected(inventory)

	if protected != _last_protection_state:
		_last_protection_state = protected
		gas_protection_status_changed.emit(protected)

	if protected:
		return {"in_gas": true, "protected": true, "damaged": false}

	# Jogador em sala com gás sem máscara equipada
	var damaged: bool = false
	if player.invulnerable_timer <= 0:
		damaged = player.apply_damage(DAMAGE_PER_INTERVAL)
		if damaged:
			# O temporizador de dano de gás na ROM dura 16 ticks (0x10)
			player.invulnerable_timer = DAMAGE_INTERVAL_TICKS
			gas_damage_taken.emit(DAMAGE_PER_INTERVAL, player.life)
			print("GAS_DAMAGE: Snake sofreu %d de dano por gás na sala %d! Vida restante: %d" % [
				DAMAGE_PER_INTERVAL, room_id, player.life
			])

	return {"in_gas": true, "protected": false, "damaged": damaged}
