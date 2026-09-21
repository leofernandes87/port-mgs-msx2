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

func step_tick(player_pos: Vector2, inventory: InventoryManager, weapon_system: WeaponSystem = null) -> bool:
	if collected:
		return false

	# Detecção canônica da ROM (ChkTakeItem em logic/items.asm:60-98)
	# Raio horizontal C = 20px (0x14) e vertical Radius Y = 16-20px a partir do centro da caixa.
	# Permite que Snake colete itens posicionados sobre mesas, escrivaninhas ou armários
	# apenas encostando na face do obstáculo sólido com sua caixa de colisão.
	var dx: float = absf(position.x - player_pos.x)
	var dy: float = absf(position.y - player_pos.y)
	if dx <= 20.0 and dy <= 20.0:
		if item_id in [WeaponSystem.WEAPON_HANDGUN, WeaponSystem.WEAPON_SMG, WeaponSystem.WEAPON_GRENADE_LAUNCHER, WeaponSystem.WEAPON_MISSILE]:
			if weapon_system != null:
				var init_ammo: int = 5 if item_id == WeaponSystem.WEAPON_MISSILE else 20
				weapon_system.add_weapon(item_id, init_ammo)
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
	else:
		# Ícone de suprimento
		draw_rect(Rect2(-2, -4, 4, 2), Color.YELLOW)
