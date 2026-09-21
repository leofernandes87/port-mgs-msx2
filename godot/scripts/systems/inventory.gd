class_name InventoryManager
extends RefCounted

## Gerenciador de inventário e equipamentos fiel à lógica de itens do MSX2 RC750 (Etapa 9).
## Lógica revertida de data/itemsinrooms.asm e logic/menuequipment.asm.

const ITEM_CARD1: String = "CARD1"
const ITEM_CARD2: String = "CARD2"
const ITEM_CARD3: String = "CARD3"
const ITEM_CARD4: String = "CARD4"
const ITEM_CARD5: String = "CARD5"
const ITEM_CARD6: String = "CARD6"
const ITEM_CARD7: String = "CARD7"
const ITEM_CARD8: String = "CARD8"
const ITEM_RATION: String = "RATION"
const ITEM_BINOCULARS: String = "BINOCULARS"
const ITEM_SILENCER: String = "SILENCER"       # ID 8 na ROM (SUPRESSOR)
const ITEM_GOGGLES: String = "GOGGLES"         # ID 12 na ROM (GOGGLES / Óculos Infravermelhos)
const ITEM_GAS_MASK: String = "GAS_MASK"       # ID 13 na ROM (GAS_MASK)
const ITEM_BOX: String = "BOX"                 # ID 21 na ROM (CARDBOARD_BOX / Caixa de Papelão)
const ITEM_AMMO_CRATE: String = "AMMO_CRATE"   # ID 35 na ROM (AMMO_CRATE)
const ITEM_CIGARETTES: String = "CIGARETTES"   # Equipamento inicial do Snake (Banks0123.asm:11775)
const ITEM_BAG: String = "BAG"                 # ID 34 na ROM (BAG / Saco de equipamentos)

var items: Array[String] = []
var selected_index: int = -1
var rations_count: int = 0
var max_rations: int = 3 # Limite dinâmico de rações baseado no Rank (maxammo.asm:20-35)

func update_rank_capacities(rank: int) -> void:
	match rank:
		1: max_rations = 3
		2: max_rations = 6
		3: max_rations = 9
		4: max_rations = 12
		_: max_rations = 3

	if rations_count > max_rations:
		rations_count = max_rations

func has_item(item_id: String) -> bool:
	if item_id == ITEM_RATION:
		return rations_count > 0
	return items.has(item_id)

func get_selected_item() -> String:
	if selected_index >= 0 and selected_index < items.size():
		return items[selected_index]
	return ""

## Retorna o nível mais alto de cartão obtido (1 a 8), ou 0 se nenhum (logic/setalert.asm:25-36)
func get_card_level() -> int:
	for lvl in range(8, 0, -1):
		if has_item("CARD%d" % lvl):
			return lvl
	return 0

func collect_item(item_id: String) -> bool:
	if item_id == ITEM_RATION:
		if rations_count < max_rations:
			rations_count += 1
			if not items.has(ITEM_RATION):
				items.append(ITEM_RATION)
			if selected_index == -1:
				selected_index = items.find(ITEM_RATION)
			print("ITEM_COLLECTED: Ração coletada (%d/%d)" % [rations_count, max_rations])
			return true
		return false

	if not items.has(item_id):
		items.append(item_id)
		if selected_index == -1:
			selected_index = 0
		print("ITEM_COLLECTED: %s adquirido e adicionado ao inventário!" % item_id)
		return true

	return false

func cycle_item() -> void:
	if items.is_empty():
		selected_index = -1
		return
	selected_index = (selected_index + 1) % items.size()
	print("ITEM_SELECTED: %s" % get_selected_item())

func select_item(item_id: String) -> bool:
	var idx: int = items.find(item_id)
	if idx != -1:
		selected_index = idx
		return true
	return false

func clear_selection() -> void:
	selected_index = -1

func use_selected_item(player: PlayerController) -> bool:
	var current: String = get_selected_item()
	if current == ITEM_RATION and rations_count > 0 and player != null:
		# Consome a ração e restaura a energia para o valor máximo (logic/menuequipment.asm:228)
		player.life = player.max_life
		rations_count -= 1
		print("ITEM_USED: Ração consumida! Vida restaurada para %d. Restam: %d" % [player.life, rations_count])
		if rations_count <= 0:
			items.erase(ITEM_RATION)
			if selected_index >= items.size():
				selected_index = items.size() - 1
		player.queue_redraw()
		return true
	return false

func get_status_text() -> String:
	var cur: String = get_selected_item()
	if cur.is_empty():
		return "[NENHUM]"
	if cur == ITEM_RATION:
		return "[RAÇÃO x%d]" % rations_count
	return "[%s]" % cur

func reset() -> void:
	items.clear()
	selected_index = -1
	rations_count = 0
	max_rations = 3
	print("INVENTORY_RESET: Inventário limpo e cartões removidos.")

