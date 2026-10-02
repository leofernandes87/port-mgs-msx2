class_name CaptureSystem
extends RefCounted

## Sistema de Captura na Sala 8, Encarceramento na Cela 211, Parede Oca e Restituição (Etapa 21).
## Fundamentado na engenharia reversa da ROM MSX2 RC750:
## - logic/common.asm:26-47 (Gatilho de captura na Sala 8, PlayerX entre 0xC0 e 0xD0)
## - logic/capturescene.asm:87-118 (Confisco de equipamentos e spawn na cela 0x80, 0x50)
## - logic/doors/opendoor.asm:285-319 (Resistência decrementada durante o soco)
## - logic/doors/erasedoor.asm:25,365-367,399-414 (Restauração do fundo da parede)
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

# Banks0123.asm:11797-11799; opendoor.asm:300-319 decrements each
# qualifying game iteration, not once per button press.
const WALL_LIFE: int = 0x28
const WALL_TICK_SEC: float = 1.0 / 60.0 # Existing player punch clock (8 ticks).
var wall_tick_accumulator: float = 0.0

# Estado global da mecânica
var is_captured: bool = false
var capture_occurred: bool = false
var equip_bag_taken: bool = false
var wall_hit_counter: int = 0
var wall_broken: bool = false
# Separate PrisonWall2Life for Door 12: opendoor.asm:307-316.
var south_wall_hit_counter: int = 0
var south_wall_broken: bool = false
var south_wall_tick_accumulator: float = 0.0

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
	wall_tick_accumulator = 0.0

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

## One original ChkPrisonWalls invocation; right side uses render type 15.
## DoorOpenEnterDat: data/doors.asm:28-29,724-728; half-open bounds.
func check_wall_punch(player_pos: Vector2, direction: int, punching: bool, render_type: int = 14) -> bool:
	var south: bool = render_type in [12, 13]
	if (south_wall_broken if south else wall_broken) or not punching:
		return false
	var expected_dir: int = PlayerController.Direction.LEFT if render_type == 14 else PlayerController.Direction.RIGHT
	var area := Rect2(32, 64, 26, 16) if render_type == 14 else Rect2(198, 64, 26, 16)
	if south:
		expected_dir = PlayerController.Direction.DOWN if render_type == 13 else PlayerController.Direction.UP
		area = Rect2(104, 142, 16, 18) if render_type == 13 else Rect2(104, 160, 16, 8)
	if direction != expected_dir or not area.has_point(player_pos):
		return false
	if south:
		south_wall_hit_counter += 1
		south_wall_broken = south_wall_hit_counter == WALL_LIFE
		return true
	wall_hit_counter += 1
	if wall_hit_counter == WALL_LIFE:
		wall_broken = true
		wall_broken_signal.emit()
	else:
		wall_damaged.emit(wall_hit_counter, WALL_LIFE - wall_hit_counter)
	return true

## Consume only the active part of the punch, using the player's existing clock.
## Called before player.step_tick so the initial PunchCnt=8 also contributes.
func step_wall_punch(player_pos: Vector2, direction: int, remaining_sec: float, delta: float, render_type: int = 14) -> void:
	var south: bool = render_type in [12, 13]
	var accumulator: float = south_wall_tick_accumulator if south else wall_tick_accumulator
	if remaining_sec <= 0.0:
		accumulator = 0.0
	else:
		accumulator += minf(delta, remaining_sec)
		while accumulator + 0.000001 >= WALL_TICK_SEC:
			accumulator -= WALL_TICK_SEC
			check_wall_punch(player_pos, direction, true, render_type)
	if south:
		south_wall_tick_accumulator = accumulator
	else:
		wall_tick_accumulator = accumulator

func is_wall_broken(door_id: int) -> bool:
	return south_wall_broken if door_id == 12 else wall_broken

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
	south_wall_hit_counter = 0
	south_wall_broken = false
	south_wall_tick_accumulator = 0.0
	wall_tick_accumulator = 0.0
	backup_items.clear()
	backup_rations_count = 0
	backup_selected_item_index = -1
	backup_owned_weapons.clear()
	backup_selected_weapon = ""
	backup_ammo.clear()
	backup_has_silencer = false
