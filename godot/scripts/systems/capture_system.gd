class_name CaptureSystem
extends RefCounted

## Sistema de Captura na Sala 8, Encarceramento na Cela 211, Parede Oca e Restituição (Etapa 21).
## Fundamentado na engenharia reversa da ROM MSX2 RC750:
## - logic/common.asm:26-47 (Gatilho de captura na Sala 8, PlayerX entre 0xC0 e 0xD0)
## - logic/capturescene.asm:87-118 (Confisco de equipamentos e spawn na cela 0x80, 0x50)
## - logic/doors/opendoor.asm:300-320 (Detecção de 4 socos na parede oca)
## - logic/doors/erasedoor.asm:380-384 (Quebra da parede e liberação de passagem)
## - logic/items.asm:120-124, 295-325 e data/itemsinrooms.asm:155 (Item BAG e restituição)

signal captured
signal wall_damaged(hits: int, hits_remaining: int)
signal wall_broken_signal
signal equipment_restored

const ROOM_CAPTURE: int = 8
const CAPTURE_MIN_X: float = 192.0  # 0xC0
const CAPTURE_MAX_X: float = 208.0  # 0xD0

const ROOM_PRISON: int = 211
const ROOM_ADJACENT: int = 212
const SPAWN_PRISON: Vector2 = Vector2(128.0, 80.0)  # 0x80, 0x50

const HITS_REQUIRED: int = 4

# Coordenadas dos tiles que compõem a parede quebrável (colunas 0-5, linhas 8-11 até a borda esquerda)
const WALL_TILES: Array = [
	Vector2i(0, 8), Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8),
	Vector2i(0, 9), Vector2i(1, 9), Vector2i(2, 9), Vector2i(3, 9), Vector2i(4, 9), Vector2i(5, 9),
	Vector2i(0, 10), Vector2i(1, 10), Vector2i(2, 10), Vector2i(3, 10), Vector2i(4, 10), Vector2i(5, 10),
	Vector2i(0, 11), Vector2i(1, 11), Vector2i(2, 11), Vector2i(3, 11), Vector2i(4, 11), Vector2i(5, 11)
]

# Coordenadas dos tiles correspondentes na borda direita da Sala 212 (colunas 26-31, linhas 8-11)
const ADJACENT_WALL_TILES: Array = [
	Vector2i(26, 8), Vector2i(27, 8), Vector2i(28, 8), Vector2i(29, 8), Vector2i(30, 8), Vector2i(31, 8),
	Vector2i(26, 9), Vector2i(27, 9), Vector2i(28, 9), Vector2i(29, 9), Vector2i(30, 9), Vector2i(31, 9),
	Vector2i(26, 10), Vector2i(27, 10), Vector2i(28, 10), Vector2i(29, 10), Vector2i(30, 10), Vector2i(31, 10),
	Vector2i(26, 11), Vector2i(27, 11), Vector2i(28, 11), Vector2i(29, 11), Vector2i(30, 11), Vector2i(31, 11)
]

# Estado global da mecânica
var is_captured: bool = false
var capture_occurred: bool = false
var equip_bag_taken: bool = false
var wall_hit_counter: int = 0
var wall_broken: bool = false
var wall_punch_active: bool = false

# Vetores de backup do inventário e arsenal
var backup_items: Array[String] = []
var backup_rations_count: int = 0
var backup_selected_item_index: int = -1

var backup_owned_weapons: Array[String] = []
var backup_selected_weapon: String = ""
var backup_ammo: Dictionary = {}
var backup_has_silencer: bool = false

## Verifica se Snake entrou na zona de emboscada da Sala 8
func check_capture_trigger(room_id: int, pos: Vector2) -> bool:
	if capture_occurred or equip_bag_taken:
		return false
	if room_id != ROOM_CAPTURE:
		return false
	return pos.x >= CAPTURE_MIN_X and pos.x <= CAPTURE_MAX_X

## Executa o evento de captura: salva o inventário e armas em backup e limpa o ativo
func execute_capture(inventory: InventoryManager, weapon_system: WeaponSystem) -> void:
	is_captured = true
	capture_occurred = true
	wall_hit_counter = 0
	wall_broken = false
	wall_punch_active = false

	# Backup do inventário
	backup_items.clear()
	backup_rations_count = 0
	backup_selected_item_index = -1
	if inventory != null:
		backup_items = inventory.items.duplicate()
		backup_rations_count = inventory.rations_count
		backup_selected_item_index = inventory.selected_index
		inventory.items.clear()
		inventory.rations_count = 0
		inventory.selected_index = -1

	# Backup do sistema de armas
	backup_owned_weapons.clear()
	backup_ammo.clear()
	backup_selected_weapon = ""
	backup_has_silencer = false
	if weapon_system != null:
		backup_owned_weapons = weapon_system.owned_weapons.duplicate()
		backup_selected_weapon = weapon_system.selected_weapon
		backup_ammo = weapon_system.ammo.duplicate()
		backup_has_silencer = weapon_system.has_silencer

		weapon_system.owned_weapons.clear()
		weapon_system.selected_weapon = WeaponSystem.WEAPON_NONE
		for k in weapon_system.ammo.keys():
			weapon_system.ammo[k] = 0
		weapon_system.has_silencer = false

	captured.emit()
	print("CAPTURE_EVENT: Solid Snake foi emboscado e capturado na Sala 8! Equipamentos confiscados.")

## Monitora se o soco de Snake atinge as coordenadas da parede oca da Sala 211
## Suporta chamada flexível: (pos, dir, is_punching, timer) ou compatibilidade com (pos, dir, timer)
func check_wall_punch(player_pos: Vector2, direction: int, is_punching_or_timer: Variant = true, legacy_timer: int = 8) -> bool:
	if wall_broken:
		return false

	var punching: bool = false
	var timer: int = 8
	if typeof(is_punching_or_timer) == TYPE_BOOL:
		punching = bool(is_punching_or_timer)
		timer = legacy_timer
	elif typeof(is_punching_or_timer) == TYPE_INT:
		timer = int(is_punching_or_timer)
		punching = (timer > 0)

	if not punching:
		wall_punch_active = false
		return false

	if wall_punch_active:
		return false

	# Snake deve estar de frente para a parede esquerda (Direction.LEFT = 3)
	if direction != PlayerController.Direction.LEFT:
		return false

	# Posição de Snake adjacente à parede oca interna da cela
	# Cobre confortavelmente a aproximação de Snake na parede esquerda
	if player_pos.x < 32.0 or player_pos.x > 76.0:
		return false
	if player_pos.y < 56.0 or player_pos.y > 96.0:
		return false

	wall_punch_active = true
	wall_hit_counter += 1
	if wall_hit_counter >= HITS_REQUIRED:
		wall_broken = true
		wall_broken_signal.emit()
		print("PRISON_WALL_BROKEN: Parede oca destruída após %d acertos! Caminho de fuga aberto." % wall_hit_counter)
	else:
		var remaining: int = HITS_REQUIRED - wall_hit_counter
		wall_damaged.emit(wall_hit_counter, remaining)
		print("PRISON_WALL_HIT: Parede oca atingida! Acerto %d de %d (restam %d)." % [wall_hit_counter, HITS_REQUIRED, remaining])

	return true

## Restitui todo o inventário e armas a partir do vetor de backup ao coletar a bolsa
func restore_equipment(inventory: InventoryManager, weapon_system: WeaponSystem) -> void:
	if not is_captured and backup_items.is_empty() and backup_owned_weapons.is_empty():
		# Se Snake coletar a bolsa sem ter passado pelo gatilho prévio de captura (ex: teste direto),
		# fornece os equipamentos canônicos correspondentes a este ponto da progressão MSX2:
		if inventory != null:
			if not inventory.has_item(InventoryManager.ITEM_CARD1):
				inventory.collect_item(InventoryManager.ITEM_CARD1)
			if not inventory.has_item(InventoryManager.ITEM_CARD2):
				inventory.collect_item(InventoryManager.ITEM_CARD2)
			if not inventory.has_item(InventoryManager.ITEM_CIGARETTES):
				inventory.collect_item(InventoryManager.ITEM_CIGARETTES)
			if not inventory.has_item(InventoryManager.ITEM_RATION):
				inventory.collect_item(InventoryManager.ITEM_RATION)
		if weapon_system != null:
			if not weapon_system.has_weapon(WeaponSystem.WEAPON_HANDGUN):
				weapon_system.add_weapon(WeaponSystem.WEAPON_HANDGUN, 30)
		is_captured = false
		equip_bag_taken = true
		equipment_restored.emit()
		print("EQUIPMENT_RESTORED: Bolsa de equipamentos recuperada (kit canônico padrão)! Inventário e armas restituídos.")
		return

	# Restaura itens
	if inventory != null:
		inventory.items = backup_items.duplicate()
		inventory.rations_count = backup_rations_count
		inventory.selected_index = backup_selected_item_index

	# Restaura armas
	if weapon_system != null:
		weapon_system.owned_weapons = backup_owned_weapons.duplicate()
		weapon_system.selected_weapon = backup_selected_weapon
		weapon_system.ammo = backup_ammo.duplicate()
		weapon_system.has_silencer = backup_has_silencer

	is_captured = false
	equip_bag_taken = true
	equipment_restored.emit()
	print("EQUIPMENT_RESTORED: Bolsa de equipamentos recuperada! Inventário e armas restituídos.")

## Reseta o estado (usado em Game Over / reinício da cena)
func reset_state() -> void:
	is_captured = false
	capture_occurred = false
	equip_bag_taken = false
	wall_hit_counter = 0
	wall_broken = false
	wall_punch_active = false
	backup_items.clear()
	backup_rations_count = 0
	backup_selected_item_index = -1
	backup_owned_weapons.clear()
	backup_selected_weapon = ""
	backup_ammo.clear()
	backup_has_silencer = false
