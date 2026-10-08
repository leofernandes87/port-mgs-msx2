class_name GameHUD
extends Control

# ==============================================================================
# COMPONENTE DE HUD AUTÊNTICO DO METAL GEAR MSX2 (RC750, 1987)
#
# Renderiza a barra de status inferior de 256x20 pixels em Y=192..211 com:
# - L.I.F.E (Barra de energia vermelha dinâmica de até 48 px, logic/hud.asm:162-205)
# - CLASS (Patente militar com 1 a 4 estrelas ★, logic/hud.asm:214-244)
# - CALL (Sinal piscante de chamada do transceptor de 24x16 px, logic/hud.asm:25-56)
# - WEAPON (Caixa de arma de 58x18 px com sprites e munição, Banks0123.asm:2092-2141)
# - ITEM (Caixa de item de 27x18 px com sprites e número de cartão, Banks0123.asm:2270-2312)
# ==============================================================================

# Coordenadas e Dimensões Canônicas da ROM MSX2 (Offset Y = -192 para coordenadas locais)
const HUD_WIDTH: float = 256.0
const HUD_HEIGHT: float = 20.0
const HUD_Y: float = 192.0

const POS_LIFE_TEXT: Vector2 = Vector2(16, 1)        # X=16, Y=193
const RECT_LIFE_BOX: Rect2 = Rect2(49, 1, 50, 8)     # X=49, Y=193, 50x8 px
const POS_LIFE_BAR: Vector2 = Vector2(50, 2)         # X=50, Y=194, 48x6 px
const MAX_BAR_WIDTH: float = 48.0                    # 0x30 = 48 px no MSX2

const POS_CLASS_TEXT: Vector2 = Vector2(8, 9)        # X=8, Y=201
const POS_CLASS_STARS: Vector2 = Vector2(52, 9)      # X=52, Y=201

const RECT_CALL_SIGN: Rect2 = Rect2(120, 1, 24, 16)  # X=120, Y=193, 24x16 px

const RECT_WEAPON_BOX: Rect2 = Rect2(159, 1, 58, 18) # X=159, Y=193, 58x18 px
const POS_WEAPON_SPRITE: Vector2 = Vector2(160, 2)   # X=160, Y=194, 32x16 px
const POS_WEAPON_AMMO: Vector2 = Vector2(192, 8)     # X=192, Y=200

const RECT_ITEM_BOX: Rect2 = Rect2(222, 1, 27, 18)   # X=222, Y=193, 27x18 px
const POS_ITEM_SPRITE: Vector2 = Vector2(228, 2)     # X=228, Y=194, 16x16 px (centralizado)
const POS_ITEM_CARD_NUM: Vector2 = Vector2(240, 8)   # X=240, Y=200

# Cores VDP V9938 do MSX2 Screen 5
const COLOR_BLACK: Color = Color(0.0, 0.0, 0.0, 1.0)
const COLOR_WHITE: Color = Color(0.85, 0.85, 0.85, 1.0)    # Cor 14 (Cinza claro / Branco MSX)
const COLOR_LIFE_RED: Color = Color(1.0, 0.14, 0.14, 1.0) # Cor 8 (Vermelho vivo MSX)
const COLOR_LIFE_BG: Color = Color(0.0, 0.0, 0.0, 1.0)
const COLOR_CALL_GREEN: Color = Color(0.71, 1.0, 0.71, 1.0) # Cor 3 (Verde claro)
const COLOR_STAR_YELLOW: Color = Color(1.0, 0.86, 0.14, 1.0) # Amarelo ouro (logic/loadfont.asm:28 - Load yellow star tile)

# Mapeamento de Armas na Textura hud_weapons.png (8 armas de 32x16 px)
const WEAPON_TEX_INDICES: Dictionary = {
	"HANDGUN": 0,
	"SMG": 1,
	"GRENADE_LAUNCHER": 2,
	"ROCKET_LAUNCHER": 3,
	"PLASTIC_BOMB": 4,
	"LAND_MINE": 5,
	"MISSILE": 6,
	"SILENCER": 7,
}

# Mapeamento de Itens na Textura hud_items.png (27 itens de 16x16 px)
const ITEM_TEX_INDICES: Dictionary = {
	"ARMOR": 0, "BODY_ARMOR": 0,
	"SUIT": 1, "BOMB_BLAST_SUIT": 1,
	"LIGHT": 2, "FLASHLIGHT": 2,
	"GOGGLES": 3,
	"GAS_MASK": 4,
	"CIGARETTES": 5,
	"MINE_DETECTOR": 6,
	"ANTENNA": 7,
	"BINOCULARS": 8,
	"OXYGEN_TANK": 9,
	"COMPASS": 10,
	"PARACHUTE": 11,
	"ANTIDOTE": 12,
	"CARD1": 13, "CARD2": 14, "CARD3": 15, "CARD4": 16,
	"CARD5": 17, "CARD6": 18, "CARD7": 19, "CARD8": 20,
	"RATION": 21,
	"TRANSCEIVER": 22,
	"UNIFORM": 23,
	"BOX": 24, "CARDBOARD_BOX": 24,
	"BAG": 25, "ITEM_BAG": 25,
	"AMMO_CRATE": 26,
}

# Texturas Originais Autênticas
var tex_weapons: Texture2D = null
var tex_items: Texture2D = null
var tex_call: Texture2D = null
var tex_msx_font: Texture2D = null

# Estado Interno do HUD
var current_life: int = 24
var max_life: int = 24
var current_rank: int = 1
var selected_weapon: String = ""
var ammo_count: int = 0
var selected_item: String = ""
var card_number: int = 0
var has_incoming_call: bool = false

# Controle de Piscar do Sinal CALL (logic/hud.asm:40 - bit 3 do tick counter = 8 frames on / 8 frames off)
var call_timer_sec: float = 0.0
var call_tick_counter: int:
	get:
		return int(roundf(call_timer_sec * 60.0))
	set(v):
		call_timer_sec = float(v) / 60.0
var call_sign_visible: bool = false

# Referências fracas aos sistemas
var _player: PlayerController = null
var _rank_system: RankSystem = null
var _weapon_system: WeaponSystem = null
var _inventory: InventoryManager = null
var _radio_system: RadioSystem = null

func _init() -> void:
	custom_minimum_size = Vector2(HUD_WIDTH, HUD_HEIGHT)
	position = Vector2(0, HUD_Y)
	size = Vector2(HUD_WIDTH, HUD_HEIGHT)
	_load_textures()

func _ready() -> void:
	if tex_weapons == null:
		_load_textures()

func _load_textures() -> void:
	if ResourceLoader.exists("res://assets/protected/sprites/hud/hud_weapons.png"):
		tex_weapons = load("res://assets/protected/sprites/hud/hud_weapons.png")
	if ResourceLoader.exists("res://assets/protected/sprites/hud/hud_items.png"):
		tex_items = load("res://assets/protected/sprites/hud/hud_items.png")
	if ResourceLoader.exists("res://assets/protected/sprites/hud/hud_call.png"):
		tex_call = load("res://assets/protected/sprites/hud/hud_call.png")
	if ResourceLoader.exists("res://assets/protected/sprites/transceiver/msx_font.png"):
		tex_msx_font = load("res://assets/protected/sprites/transceiver/msx_font.png")

## Vincula os sistemas de gameplay para atualização reativa
func bind_systems(player_ctrl: PlayerController, rank_sys: RankSystem, weapon_sys: WeaponSystem, inv_mgr: InventoryManager, rad_sys: RadioSystem) -> void:
	_player = player_ctrl
	_rank_system = rank_sys
	_weapon_system = weapon_sys
	_inventory = inv_mgr
	_radio_system = rad_sys

	if _rank_system:
		if not _rank_system.rank_changed.is_connected(_on_rank_changed):
			_rank_system.rank_changed.connect(_on_rank_changed)
		current_rank = _rank_system.current_rank
		max_life = _rank_system.get_max_life()

	if _player:
		current_life = _player.life
		max_life = _player.max_life

	update_hud_state()

func _on_rank_changed(new_rank: int) -> void:
	current_rank = new_rank
	if _rank_system:
		max_life = _rank_system.get_max_life()
	queue_redraw()

func _process(delta: float) -> void:
	call_timer_sec += delta
	# Alternância canônica Z80: bit 3 de TickCounter (período de 16 ticks: 8 on, 8 off)
	var prev_blink := call_sign_visible
	call_sign_visible = ((call_tick_counter >> 3) & 1) == 0

	var needs_redraw: bool = (has_incoming_call and prev_blink != call_sign_visible)
	if update_hud_state() or needs_redraw:
		queue_redraw()

## Sincroniza dados com os sistemas vinculados. Retorna true se algo mudou.
func update_hud_state() -> bool:
	var changed: bool = false

	if _player:
		if current_life != _player.life:
			current_life = _player.life
			changed = true
		if max_life != _player.max_life:
			max_life = _player.max_life
			changed = true

	if _rank_system:
		if current_rank != _rank_system.current_rank:
			current_rank = _rank_system.current_rank
			changed = true

	if _weapon_system:
		var w_id: String = _weapon_system.selected_weapon
		var w_ammo: int = int(_weapon_system.ammo.get(w_id, 0))
		if selected_weapon != w_id or ammo_count != w_ammo:
			selected_weapon = w_id
			ammo_count = w_ammo
			changed = true

	if _inventory:
		var item_id: String = _inventory.get_selected_item()
		var card_num: int = 0
		if item_id.begins_with("CARD"):
			var suffix: String = item_id.substr(4)
			if suffix.is_valid_int():
				card_num = suffix.to_int()

		if selected_item != item_id or card_number != card_num:
			selected_item = item_id
			card_number = card_num
			changed = true

	if _radio_system:
		if has_incoming_call != _radio_system.has_incoming_call:
			has_incoming_call = _radio_system.has_incoming_call
			changed = true

	return changed

func _draw() -> void:
	# Fundo preto do HUD (256x20 px)
	draw_rect(Rect2(0, 0, HUD_WIDTH, HUD_HEIGHT), COLOR_BLACK, true)

	_draw_life()
	_draw_class()
	_draw_call()
	_draw_weapon()
	_draw_item()

# ------------------------------------------------------------------------------
# 1. RENDERIZAÇÃO DA BARRA DE VIDA (DrawLife em logic/hud.asm:162-205)
# ------------------------------------------------------------------------------
func _draw_life() -> void:
	# Texto "LIFE" em (16, 1) - data/hudstartendtexts.asm:45
	_draw_msx_string("LIFE", POS_LIFE_TEXT)

	# Borda branca da caixa da barra de energia: (49, 1) a (99, 9) - logic/hud.asm:166-170
	draw_rect(RECT_LIFE_BOX, COLOR_WHITE, false, 1.0)

	# Barra vermelha preenchida: (50, 2), largura de 1 pixel por ponto de vida (máx 48 px).
	# Regra canônica MSX2 (Banks0123.asm:8400-8402, 9660-9675 e logic/hud.asm:179-184):
	# A caixa do HUD tem largura fixa de 48 pixels úteis.
	# - Rank 1 (Class 0): MaxLife = 24 -> preenche exatamente metade da caixa (24 px de 48 px).
	# - Rank 2 (Class 1): MaxLife = 32 -> preenche 32 px.
	# - Rank 3 (Class 2): MaxLife = 40 -> preenche 40 px.
	# - Rank 4 (Class 3): MaxLife = 48 -> preenche a caixa completa (48 px).
	var fill_w: float = clampf(float(current_life), 0.0, MAX_BAR_WIDTH)
	if fill_w > 0.0:
		draw_rect(Rect2(POS_LIFE_BAR.x, POS_LIFE_BAR.y, fill_w, 6.0), COLOR_LIFE_RED, true)

# ------------------------------------------------------------------------------
# 2. RENDERIZAÇÃO DA PATENTE MILITAR (DrawClass em logic/hud.asm:214-244)
# ------------------------------------------------------------------------------
func _draw_class() -> void:
	# Texto "CLASS" em (8, 9) - data/hudstartendtexts.asm:55
	_draw_msx_string("CLASS", POS_CLASS_TEXT)

	# Estrelas ★ em amarelo autêntico (logic/loadfont.asm:28: "Load yellow star tile")
	var rank_clamped: int = clampi(current_rank, 1, 4)
	for i in range(rank_clamped):
		var star_pos := Vector2(POS_CLASS_STARS.x + float(i * 8), POS_CLASS_STARS.y)
		_draw_msx_char(ord("*"), star_pos, COLOR_STAR_YELLOW)

# ------------------------------------------------------------------------------
# 3. RENDERIZAÇÃO DO SINAL DE CHAMADA (DrawCallTimer em logic/hud.asm:25-56)
# ------------------------------------------------------------------------------
func _draw_call() -> void:
	if not has_incoming_call or not call_sign_visible:
		return

	if tex_call:
		draw_texture(tex_call, RECT_CALL_SIGN.position)
	else:
		# Fallback procedural autêntico em vermelho vivo sem moldura
		_draw_msx_string("CALL", RECT_CALL_SIGN.position + Vector2(0, 4), COLOR_LIFE_RED)

# ------------------------------------------------------------------------------
# 4. RENDERIZAÇÃO DA ARMA SELECIONADA (DrawWeaponHUD em Banks0123.asm:2092-2141)
# ------------------------------------------------------------------------------
func _draw_weapon() -> void:
	# Borda branca da caixa da arma: (159, 1), 58x18 px
	draw_rect(RECT_WEAPON_BOX, COLOR_WHITE, false, 1.0)

	if selected_weapon == "" or not WEAPON_TEX_INDICES.has(selected_weapon):
		return

	var w_idx: int = WEAPON_TEX_INDICES[selected_weapon]

	# Desenha sprite autêntico da arma
	if tex_weapons:
		var src_rect := Rect2(float(w_idx * 32), 0.0, 32.0, 16.0)
		draw_texture_rect_region(tex_weapons, Rect2(POS_WEAPON_SPRITE, Vector2(32, 16)), src_rect)
	else:
		# Fallback procedural
		var label_w: String = selected_weapon.substr(0, 3)
		_draw_msx_string(label_w, POS_WEAPON_SPRITE + Vector2(2, 4))

	# Desenha contagem de munição (RenderAmmoHUD / Render3Numbers em Banks0123.asm:2139)
	# Apenas desenha munição se a arma utilizar munição (silenciador não utiliza)
	if selected_weapon != "SILENCER":
		var ammo_str := "%3d" % ammo_count
		_draw_msx_string(ammo_str, POS_WEAPON_AMMO)

# ------------------------------------------------------------------------------
# 5. RENDERIZAÇÃO DO ITEM SELECIONADO (DrawItemHUD em Banks0123.asm:2270-2312)
# ------------------------------------------------------------------------------
func _draw_item() -> void:
	# Borda branca da caixa do item: (222, 1), 27x18 px
	draw_rect(RECT_ITEM_BOX, COLOR_WHITE, false, 1.0)

	if selected_item == "" or not ITEM_TEX_INDICES.has(selected_item):
		return

	var i_idx: int = ITEM_TEX_INDICES[selected_item]

	# Desenha sprite autêntico do item (16x16 px em X=228, Y=2)
	if tex_items:
		var src_rect := Rect2(float(i_idx * 16), 0.0, 16.0, 16.0)
		draw_texture_rect_region(tex_items, Rect2(POS_ITEM_SPRITE, Vector2(16, 16)), src_rect)
	else:
		# Fallback procedural
		var label_i: String = selected_item.substr(0, 2)
		_draw_msx_string(label_i, POS_ITEM_SPRITE + Vector2(1, 4))

	# Se for um cartão de acesso (CARD1..CARD8), desenha o algarismo em X=240, Y=8
	if card_number > 0:
		var card_char: int = ord("0") + clampi(card_number, 1, 8)
		_draw_msx_char(card_char, POS_ITEM_CARD_NUM)

# ------------------------------------------------------------------------------
# ROTINAS DE RENDERIZAÇÃO DA FONTE BITMAP MSX2
# ------------------------------------------------------------------------------
func _draw_msx_string(text: String, pos: Vector2, color: Color = COLOR_WHITE) -> void:
	var cur_x: float = pos.x
	for i in range(text.length()):
		var ch_code: int = text.unicode_at(i)
		_draw_msx_char(ch_code, Vector2(cur_x, pos.y), color)
		cur_x += 8.0

func _draw_msx_char(ascii_code: int, pos: Vector2, color: Color = COLOR_WHITE) -> void:
	if ascii_code == 32: # Espaço em branco
		return

	if tex_msx_font:
		var code: int = clampi(ascii_code, 0, 127)
		var col: int = code % 16
		var row: int = code / 16
		var src_rect := Rect2(float(col * 8), float(row * 8), 8.0, 8.0)
		var dest_rect := Rect2(pos, Vector2(8.0, 8.0))
		draw_texture_rect_region(tex_msx_font, dest_rect, src_rect, color)
	else:
		# Fallback com fonte padrão simples
		var ch: String = String.chr(ascii_code)
		draw_string(ThemeDB.fallback_font, pos + Vector2(0, 7), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
