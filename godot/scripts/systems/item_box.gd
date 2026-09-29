class_name ItemBox
extends Node2D

## Caixa de item coletável do Metal Gear MSX2 RC750 (Etapa 9).
## Posições e identidades autênticas revertidas de data/itemsinrooms.asm.

static var collected_boxes: Dictionary = {}

var item_id: String = ""
var room_id: int = 0
var box_unique_id: String = ""
var collected: bool = false

func _ready() -> void:
	z_index = 5
	box_unique_id = "%d_%s_%d_%d" % [room_id, item_id, int(position.x), int(position.y)]
	if collected_boxes.has(box_unique_id):
		collected = true

func step_tick(player_pos: Vector2, inventory: InventoryManager, weapon_system: WeaponSystem = null, capture_system: CaptureSystem = null) -> bool:
	if collected:
		return false

	# Detecção canônica da ROM (ChkTakeItem em logic/items.asm:60-98)
	# Raio horizontal C = 20px (0x14) e vertical Radius Y = 16-20px a partir do centro da caixa.
	# Permite que Snake colete itens posicionados sobre mesas, escrivaninhas ou armários
	# apenas encostando na face do obstáculo sólido com sua caixa de colisão.
	var dx: float = absf(position.x - player_pos.x)
	var dy: float = absf(position.y - player_pos.y)
	if dx <= 20.0 and dy <= 20.0:
		if item_id in [WeaponSystem.WEAPON_HANDGUN, WeaponSystem.WEAPON_SMG, WeaponSystem.WEAPON_GRENADE_LAUNCHER]:
			if weapon_system != null:
				# Fiel ao MSX: Armas de fogo comuns vêm descarregadas (0 balas, ItemTakeAmount).
				weapon_system.add_weapon(item_id, 0)
				collected = true
				collected_boxes[box_unique_id] = true
				queue_redraw()
				return true
		elif item_id == WeaponSystem.WEAPON_MISSILE:
			if weapon_system != null:
				weapon_system.add_weapon(WeaponSystem.WEAPON_MISSILE, 5)
				collected = true
				collected_boxes[box_unique_id] = true
				queue_redraw()
				return true
		elif item_id in [WeaponSystem.WEAPON_PLASTIC_BOMB, "PLASTIC_BOMB"]:
			if weapon_system != null:
				weapon_system.add_weapon(WeaponSystem.WEAPON_PLASTIC_BOMB, 5)
				collected = true
				collected_boxes[box_unique_id] = true
				queue_redraw()
				return true
		elif item_id in [WeaponSystem.WEAPON_LAND_MINE, "LAND_MINE", "MINES"]:
			if weapon_system != null:
				weapon_system.add_weapon(WeaponSystem.WEAPON_LAND_MINE, 5)
				collected = true
				collected_boxes[box_unique_id] = true
				queue_redraw()
				return true
		elif item_id == InventoryManager.ITEM_AMMO_CRATE:
			if weapon_system != null:
				weapon_system.add_ammo_crate(20, 20, 6)
				collected = true
				collected_boxes[box_unique_id] = true
				queue_redraw()
				return true
		elif item_id == InventoryManager.ITEM_SILENCER:
			inventory.collect_item(item_id)
			if weapon_system != null:
				weapon_system.set_silencer(true)
			collected = true
			collected_boxes[box_unique_id] = true
			queue_redraw()
			return true
		elif item_id == InventoryManager.ITEM_BAG or item_id == "BAG":
			if capture_system != null:
				capture_system.restore_equipment(inventory, weapon_system)
			collected = true
			collected_boxes[box_unique_id] = true
			queue_redraw()
			return true
		elif inventory != null and inventory.collect_item(item_id):
			collected = true
			collected_boxes[box_unique_id] = true
			queue_redraw()
			return true

	return false

func _draw() -> void:
	if collected:
		return

	# Caixa militar clássica de suprimentos do Metal Gear (12x12 pixels)
	var box_rect := Rect2(-6, -6, 12, 12)
	var box_color := Color("889098") # Cinza metálico claro
	var border_color := Color("283038") # Borda escura
	var strap_color := Color("404850") # Cinta escura central

	draw_rect(box_rect, box_color)
	draw_rect(box_rect, border_color, false, 1.0)
	
	# Cinta horizontal
	draw_rect(Rect2(-6, -1, 12, 2), strap_color)
	
	# Letra / Identificador sutil
	if item_id.begins_with("CARD"):
		# Desenho do cartão em miniatura
		draw_rect(Rect2(-2, -4, 4, 3), Color.WHITE)
		draw_rect(Rect2(-1, -3, 2, 1), Color.RED)
	elif item_id == InventoryManager.ITEM_RATION:
		# Cruz médica vermelha na ração
		draw_rect(Rect2(-3, -4, 6, 2), Color("d02020"))
		draw_rect(Rect2(-1, -6, 2, 6), Color("d02020"))
	elif item_id in [WeaponSystem.WEAPON_HANDGUN, WeaponSystem.WEAPON_SMG]:
		# Miniatura de arma de fogo
		draw_rect(Rect2(-3, -4, 6, 2), Color.DARK_GRAY)
		draw_rect(Rect2(-3, -2, 2, 3), Color.DARK_GRAY)
	elif item_id == InventoryManager.ITEM_AMMO_CRATE:
		# Miniatura de projétil / munição
		draw_rect(Rect2(-2, -5, 4, 3), Color("e0c030"))
		draw_rect(Rect2(-1, -2, 2, 3), Color("c08020"))
	elif item_id == InventoryManager.ITEM_SILENCER:
		# Miniatura do cilindro silenciador
		draw_rect(Rect2(-4, -4, 8, 3), Color("303840"))
		draw_rect(Rect2(2, -3, 2, 1), Color.LIGHT_GRAY)
	elif item_id == WeaponSystem.WEAPON_MISSILE:
		# Miniatura de míssil teleguiado (corpo vermelho, ogiva branca e aletas escuras)
		draw_rect(Rect2(-2, -5, 4, 7), Color("e03020"))
		draw_rect(Rect2(-1, -6, 2, 2), Color.WHITE)
		draw_rect(Rect2(-4, 0, 8, 2), Color("303840"))
	elif item_id == InventoryManager.ITEM_BOX or item_id == "BOX":
		# Miniatura da caixa de papelão (marrom com vinco e fita)
		draw_rect(Rect2(-4, -5, 8, 8), Color("b88858"))
		draw_rect(Rect2(-4, -5, 8, 2), Color("885e38"))
		draw_rect(Rect2(-1, -5, 2, 8), Color("d0d0d0"))
	elif item_id == InventoryManager.ITEM_PLASTIC_BOMB or item_id == "PLASTIC_BOMB":
		# Bloco de explosivo plástico C4 militar (verde oliva escuro com detonador vermelho)
		draw_rect(Rect2(-4, -4, 8, 7), Color("384838"))
		draw_rect(Rect2(-2, -5, 4, 2), Color("d83030"))
		draw_rect(Rect2(-3, -2, 6, 3), Color("283228"))
	elif item_id == InventoryManager.ITEM_BAG or item_id == "BAG":
		# Bolsa militar de equipamentos (saco cinza/azulado amarrado no topo)
		draw_rect(Rect2(-5, -4, 10, 9), Color("404858"))
		draw_rect(Rect2(-4, -6, 8, 3), Color("586878"))
		draw_rect(Rect2(-2, -7, 4, 2), Color("c8a030"))
	elif item_id == InventoryManager.ITEM_UNIFORM or item_id == "UNIFORM":
		# Farda inimiga (túnica militar verde com colarinho e cinto)
		draw_rect(Rect2(-4, -5, 8, 9), Color("385038"))
		draw_rect(Rect2(-3, -6, 6, 2), Color("486048"))
		draw_rect(Rect2(-4, -1, 8, 2), Color("202020"))
	elif item_id == InventoryManager.ITEM_BODY_ARMOR or item_id == "BODY_ARMOR":
		# Colete balístico (colete azul marinho escuro com reforços Kevlar)
		draw_rect(Rect2(-4, -5, 8, 8), Color("202838"))
		draw_rect(Rect2(-3, -6, 6, 2), Color("303848"))
		draw_rect(Rect2(-3, -3, 6, 2), Color("404858"))
	elif item_id == InventoryManager.ITEM_MINE_DETECTOR or item_id == "MINE_DETECTOR":
		# Detector de minas (dispositivo retangular cinza/amarelo com antena)
		draw_rect(Rect2(-3, -3, 6, 7), Color("505050"))
		draw_rect(Rect2(-2, -2, 4, 3), Color("d0b030"))
		draw_line(Vector2(2, -3), Vector2(4, -7), Color("c0c0c0"), 1.0)
	else:
		# Ícone de suprimento
		draw_rect(Rect2(-2, -4, 4, 2), Color.YELLOW)
