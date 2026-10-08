class_name ItemBox
extends Node2D

## Caixa de item coletável do Metal Gear MSX2 RC750 (Etapa 9).
## Posições e identidades autênticas revertidas de data/itemsinrooms.asm.
## Renderização gráfica fiel de armas e itens no chão das salas conforme
## a rotina DrawRoomItems em logic/drawitemsinroom.asm:1-75.

static var collected_boxes: Dictionary = {}

# Mapeamento canônico de Armas na VRAM (WeaponGfxXY em data/weapongfxxy.asm:5-12)
# Células de 32x16 na textura hud_weapons.png (8 armas)
const WEAPON_TEX_INDICES: Dictionary = {
	"HANDGUN": 0,
	"SMG": 1,
	"SUB_MACHINE_GUN": 1,
	"GRENADE_LAUNCHER": 2,
	"ROCKET_LAUNCHER": 3,
	"PLASTIC_BOMB": 4,
	"LAND_MINE": 5,
	"MINES": 5,
	"MISSILE": 6,
	"REMOTE_MISSILE": 6,
	"SILENCER": 7,
	"SUPRESSOR": 7,
}

# Mapeamento canônico de Itens na VRAM (ItemGfxXY em data/itemgfxxy.asm:4-30)
# Células de 16x16 na textura hud_items.png (27 itens)
const ITEM_TEX_INDICES: Dictionary = {
	"ARMOR": 0, "BODY_ARMOR": 0,
	"SUIT": 1, "BOMB_BLAST_SUIT": 1, "BOMB_SUIT": 1,
	"LIGHT": 2, "FLASHLIGHT": 2,
	"GOGGLES": 3, "INFRARED_GOGGLES": 3,
	"GAS_MASK": 4,
	"CIGARETTES": 5,
	"MINE_DETECTOR": 6,
	"ANTENNA": 7,
	"BINOCULARS": 8,
	"OXYGEN_TANK": 9, "OXYGEN": 9,
	"COMPASS": 10,
	"PARACHUTE": 11,
	"ANTIDOTE": 12,
	"CARD1": 13, "CARD2": 14, "CARD3": 15, "CARD4": 16,
	"CARD5": 17, "CARD6": 18, "CARD7": 19, "CARD8": 20,
	"RATION": 21,
	"TRANSCEIVER": 22,
	"UNIFORM": 23, "ENEMY_UNIFORM": 23,
	"BOX": 24, "CARDBOARD_BOX": 24,
	"BAG": 25, "ITEM_BAG": 25,
	"AMMO_CRATE": 26, "AMMO": 26,
}

# Texturas autênticas extraídas da ROM MSX2
static var tex_weapons: Texture2D = null
static var tex_items: Texture2D = null
static var textures_loaded: bool = false

var item_id: String = ""
var room_id: int = 0
var box_unique_id: String = ""
var collected: bool = false

static func _ensure_textures() -> void:
	if textures_loaded:
		return
	textures_loaded = true
	if ResourceLoader.exists("res://assets/protected/sprites/hud/hud_weapons.png"):
		tex_weapons = load("res://assets/protected/sprites/hud/hud_weapons.png")
	if ResourceLoader.exists("res://assets/protected/sprites/hud/hud_items.png"):
		tex_items = load("res://assets/protected/sprites/hud/hud_items.png")

func _ready() -> void:
	z_index = 5
	box_unique_id = "%d_%s_%d_%d" % [room_id, item_id, int(position.x), int(position.y)]
	if collected_boxes.has(box_unique_id):
		collected = true
	_ensure_textures()

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
		if item_id in [WeaponSystem.WEAPON_HANDGUN, WeaponSystem.WEAPON_SMG, WeaponSystem.WEAPON_GRENADE_LAUNCHER, "SUB_MACHINE_GUN"]:
			if weapon_system != null:
				# Fiel ao MSX: Armas de fogo comuns vêm descarregadas (0 balas, ItemTakeAmount em data/itemtakeamount.asm).
				var wid: String = item_id
				if wid == "SUB_MACHINE_GUN":
					wid = WeaponSystem.WEAPON_SMG
				weapon_system.add_weapon(wid, 0)
				collected = true
				collected_boxes[box_unique_id] = true
				queue_redraw()
				return true
		elif item_id == "ROCKET_LAUNCHER":
			if weapon_system != null:
				weapon_system.add_weapon(item_id, 0)
			collected = true
			collected_boxes[box_unique_id] = true
			queue_redraw()
			return true
		elif item_id in [WeaponSystem.WEAPON_MISSILE, "REMOTE_MISSILE"]:
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
		elif item_id in [InventoryManager.ITEM_AMMO_CRATE, "AMMO"]:
			if weapon_system != null:
				weapon_system.add_ammo_crate(20, 20, 6)
				collected = true
				collected_boxes[box_unique_id] = true
				queue_redraw()
				return true
		elif item_id in [InventoryManager.ITEM_SILENCER, "SUPRESSOR"]:
			inventory.collect_item(item_id)
			if weapon_system != null:
				weapon_system.set_silencer(true)
			collected = true
			collected_boxes[box_unique_id] = true
			queue_redraw()
			return true
		elif item_id in [InventoryManager.ITEM_BAG, "BAG"]:
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

	_ensure_textures()

	# 1. Renderização de armas autênticas (logic/drawitemsinroom.asm:17-68 e data/weapongfxxy.asm:5-12)
	if WEAPON_TEX_INDICES.has(item_id):
		var w_idx: int = int(WEAPON_TEX_INDICES[item_id])
		if tex_weapons != null:
			# hud_weapons.png contém 8 armas em células de 32x16.
			# Armas 0..3 (Handgun, SMG, Grenade, Rocket) medem 32x16 px.
			# Armas 4..7 (Plastic Bomb, Mine, Missile, Silencer) medem 16x16 px e estão centralizadas na célula de 32px (offset X=8).
			# Desenhar centrado em Rect2(-16, -8, 32, 16) coloca o centro exato da colisão em (0, 0).
			var src_rect := Rect2(float(w_idx * 32), 0.0, 32.0, 16.0)
			draw_texture_rect_region(tex_weapons, Rect2(-16, -8, 32, 16), src_rect)
			return
		else:
			_draw_procedural_fallback()
			return

	# 2. Renderização de itens / equipamentos autênticos (logic/drawitemsinroom.asm:21-68 e data/itemgfxxy.asm:4-30)
	if ITEM_TEX_INDICES.has(item_id):
		var i_idx: int = int(ITEM_TEX_INDICES[item_id])
		if tex_items != null:
			# hud_items.png contém 27 itens de 16x16 px.
			# Desenha o sprite autêntico centrado em Rect2(-8, -8, 16, 16).
			var src_rect := Rect2(float(i_idx * 16), 0.0, 16.0, 16.0)
			draw_texture_rect_region(tex_items, Rect2(-8, -8, 16, 16), src_rect)
			return
		else:
			_draw_procedural_fallback()
			return

	# Fallback para itens não mapeados
	_draw_procedural_fallback()

func _draw_procedural_fallback() -> void:
	# Caixa militar clássica de suprimentos do Metal Gear (12x12 pixels)
	var box_rect := Rect2(-6, -6, 12, 12)
	var box_color := Color("889098") # Cinza metálico claro
	var border_color := Color("283038") # Borda escura
	var strap_color := Color("404850") # Cinta escura central

	draw_rect(box_rect, box_color)
	draw_rect(box_rect, border_color, false, 1.0)
	draw_rect(Rect2(-6, -1, 12, 2), strap_color)

	if item_id.begins_with("CARD"):
		draw_rect(Rect2(-2, -4, 4, 3), Color.WHITE)
		draw_rect(Rect2(-1, -3, 2, 1), Color.RED)
	elif item_id == InventoryManager.ITEM_RATION:
		draw_rect(Rect2(-3, -4, 6, 2), Color("d02020"))
		draw_rect(Rect2(-1, -6, 2, 6), Color("d02020"))
	elif item_id in [WeaponSystem.WEAPON_HANDGUN, WeaponSystem.WEAPON_SMG]:
		draw_rect(Rect2(-3, -4, 6, 2), Color.DARK_GRAY)
		draw_rect(Rect2(-3, -2, 2, 3), Color.DARK_GRAY)
	elif item_id == InventoryManager.ITEM_AMMO_CRATE:
		draw_rect(Rect2(-2, -5, 4, 3), Color("e0c030"))
		draw_rect(Rect2(-1, -2, 2, 3), Color("c08020"))
	elif item_id == InventoryManager.ITEM_SILENCER:
		draw_rect(Rect2(-4, -4, 8, 3), Color("303840"))
		draw_rect(Rect2(2, -3, 2, 1), Color.LIGHT_GRAY)
	elif item_id == WeaponSystem.WEAPON_MISSILE:
		draw_rect(Rect2(-2, -5, 4, 7), Color("e03020"))
		draw_rect(Rect2(-1, -6, 2, 2), Color.WHITE)
		draw_rect(Rect2(-4, 0, 8, 2), Color("303840"))
	elif item_id == InventoryManager.ITEM_BOX or item_id == "BOX":
		draw_rect(Rect2(-4, -5, 8, 8), Color("b88858"))
		draw_rect(Rect2(-4, -5, 8, 2), Color("885e38"))
		draw_rect(Rect2(-1, -5, 2, 8), Color("d0d0d0"))
	elif item_id == InventoryManager.ITEM_PLASTIC_BOMB or item_id == "PLASTIC_BOMB":
		draw_rect(Rect2(-4, -4, 8, 7), Color("384838"))
		draw_rect(Rect2(-2, -5, 4, 2), Color("d83030"))
		draw_rect(Rect2(-3, -2, 6, 3), Color("283228"))
	elif item_id == InventoryManager.ITEM_BAG or item_id == "BAG":
		draw_rect(Rect2(-5, -4, 10, 9), Color("404858"))
		draw_rect(Rect2(-4, -6, 8, 3), Color("586878"))
		draw_rect(Rect2(-2, -7, 4, 2), Color("c8a030"))
	elif item_id == InventoryManager.ITEM_UNIFORM or item_id == "UNIFORM":
		draw_rect(Rect2(-4, -5, 8, 9), Color("385038"))
		draw_rect(Rect2(-3, -6, 6, 2), Color("486048"))
		draw_rect(Rect2(-4, -1, 8, 2), Color("202020"))
	elif item_id == InventoryManager.ITEM_BODY_ARMOR or item_id == "BODY_ARMOR":
		draw_rect(Rect2(-4, -5, 8, 8), Color("202838"))
		draw_rect(Rect2(-3, -6, 6, 2), Color("303848"))
		draw_rect(Rect2(-3, -3, 6, 2), Color("404858"))
	elif item_id == InventoryManager.ITEM_MINE_DETECTOR or item_id == "MINE_DETECTOR":
		draw_rect(Rect2(-3, -3, 6, 7), Color("505050"))
		draw_rect(Rect2(-2, -2, 4, 3), Color("d0b030"))
		draw_line(Vector2(2, -3), Vector2(4, -7), Color("c0c0c0"), 1.0)
	else:
		draw_rect(Rect2(-2, -4, 4, 2), Color.YELLOW)

