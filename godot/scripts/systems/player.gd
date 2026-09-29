class_name PlayerController
extends Node2D

# ==============================================================================
# SCRIPT DO JOGADOR (SOLID SNAKE)
# Este arquivo é responsável por tudo que acontece com o personagem principal.
# 
# O QUE VOCÊ PODE ALTERAR AQUI:
# - Física de movimentação (tamanho dos passos, bloqueios).
# - Desenho do Sprite (se ele usa a arte original do MSX ou a arte HD importada).
# - Ajustes de posição da sombra e da escala (procure a função _draw()).
#
# IMPORTANTE: A colisão aqui não usa nós Area2D. Ela é feita matematicamente 
# consultando o `collision_grid` (uma tabela invisível de 1 e 0 que representa as paredes).
# ==============================================================================

## Controlador de movimento de Snake fiel à física e colisão MSX2 (Etapa 5).
## Coordenadas em subpixels com avanço discreto de 2.0 pixels/tick e 2 pontos de colisão por direção.

enum Direction {
	UP = 1,
	DOWN = 2,
	LEFT = 3,
	RIGHT = 4,
}

const SPEED_NORMAL: float = 1.0
const ANIM_TICKS_PER_FRAME: int = 12

# Pontos exatos de amostragem de colisão da ROM (Shape 0 / BoxColliderDat)
const COLLIDER_OFFSETS = {
	Direction.UP: [Vector2i(-6, -5), Vector2i(5, -5)],
	Direction.DOWN: [Vector2i(-6, 4), Vector2i(5, 4)],
	Direction.LEFT: [Vector2i(-8, -4), Vector2i(-8, 3)],
	Direction.RIGHT: [Vector2i(7, -4), Vector2i(7, 3)],
}

signal player_died

var current_direction: Direction = Direction.DOWN
var is_moving: bool = false
var anim_wait_cnt: int = 0
var frame_num: int = 0  # 0: Parado, 1: Passo 1, 2: Passo 2

var collision_grid: Array = []  # 768 inteiros (32x24 tiles, 1=bloqueio, 0=livre)
var show_debug_colliders: bool = false

# Sistema de Vida e Combate MSX2 RC750 (Etapa 8)
var life: int = 24       # Rank 1: 24 pontos de vida (Banks0123.asm:9672)
var max_life: int = 24
var invulnerable_timer: int = 0 # 32 ticks de atraso de dano (logic/touchenemy.asm:155)

var punch_timer: int = 0 # 8 ticks de duração do soco (Banks0123.asm:8949)
var is_punching: bool = false
var infinite_life: bool = false # Modo de teste (God Mode)

# Sistema de Armas e Animação de Disparo
var equipped_weapon: String = ""
var shoot_timer: int = 0 # 6 ticks de clarão (muzzle flash) e recuo do disparo

# Mecânica da Caixa de Papelão
var is_in_box: bool = false

# Estado de Morte e Bloqueio de Controles (Game Over punitivo clássico)
var is_dead: bool = false
var can_control: bool = true

func set_rank_life(new_max_life: int, full_heal: bool = true) -> void:
	max_life = new_max_life
	if full_heal or life > max_life:
		life = max_life
	queue_redraw()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	can_control = false
	is_moving = false
	is_punching = false
	punch_timer = 0
	anim_wait_cnt = 0
	frame_num = 0
	queue_redraw()
	player_died.emit()
	print("PLAYER_DEATH: Snake foi eliminado! Game Over iniciado.")

func revive() -> void:
	is_dead = false
	can_control = true
	life = max_life
	invulnerable_timer = 0
	punch_timer = 0
	is_punching = false
	is_moving = false
	anim_wait_cnt = 0
	frame_num = 0
	current_direction = Direction.UP
	queue_redraw()
	print("PLAYER_REVIVE: Snake revivido e controles liberados (Vida: %d/%d)" % [life, max_life])

static var _msx_texture: Texture2D = null
static var _checked_texture: bool = false

static func load_msx_texture() -> void:
	if _checked_texture:
		return
	_checked_texture = true
	var path := "res://assets/protected/sprites/snake_msx.png"
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			_msx_texture = ImageTexture.create_from_image(img)
			print("PLAYER: Spritesheet autêntico MSX2 carregado com sucesso! (64x320 px)")

func _get_msx_sprite_rect() -> Rect2:
	if is_dead:
		return Rect2(16.0, 9 * 32.0, 16.0, 32.0) # Dead 1
	if is_in_box:
		return Rect2(0.0, 9 * 32.0, 16.0, 32.0) # Box
	if is_punching:
		match current_direction:
			Direction.DOWN:
				return Rect2(0.0 * 16.0, 8 * 32.0, 16.0, 32.0)
			Direction.UP:
				return Rect2(1.0 * 16.0, 8 * 32.0, 16.0, 32.0)
			Direction.RIGHT:
				return Rect2(2.0 * 16.0, 8 * 32.0, 16.0, 32.0)
			Direction.LEFT:
				return Rect2(3.0 * 16.0, 8 * 32.0, 16.0, 32.0)

	var is_armed: bool = (equipped_weapon in [WeaponSystem.WEAPON_HANDGUN, WeaponSystem.WEAPON_SMG, WeaponSystem.WEAPON_GRENADE_LAUNCHER, WeaponSystem.WEAPON_MISSILE])
	var base_row: int = 4 if is_armed else 0
	match current_direction:
		Direction.DOWN:
			base_row += 0
		Direction.UP:
			base_row += 1
		Direction.RIGHT:
			base_row += 2
		Direction.LEFT:
			base_row += 3

	var col: int = clampi(frame_num, 0, 2)
	return Rect2(col * 16.0, base_row * 32.0, 16.0, 32.0)

func _ready() -> void:
	z_index = 10
	load_msx_texture()

func set_collision_grid(grid: Array) -> void:
	collision_grid = grid

func set_grid_position(px: float, py: float) -> void:
	position = Vector2(px, py)
	queue_redraw()

func punch() -> bool:
	if is_dead or not can_control or life <= 0:
		return false
	if punch_timer <= 0:
		punch_timer = 8
		is_punching = true
		is_moving = false
		queue_redraw()
		return true
	return false

## Disparo com arma de fogo equipada (logic/weapon/handgun.asm:39-65)
## O projétil emerge com precisão do cano da arma na direção em que Snake está mirando
func fire_weapon(weapon_sys: WeaponSystem) -> Bullet:
	if is_dead or not can_control or life <= 0 or weapon_sys == null or not weapon_sys.can_fire():
		return null

	if not weapon_sys.consume_ammo():
		return null

	shoot_timer = 6 # Clarão do disparo (muzzle flash) e recuo por 6 ticks
	equipped_weapon = weapon_sys.selected_weapon
	queue_redraw()

	var b: Bullet = Bullet.new()
	match current_direction:
		Direction.UP:
			b.position = Vector2(position.x + 3.0, position.y - 24.0)
		Direction.DOWN:
			b.position = Vector2(position.x + 3.0, position.y + 6.0)
		Direction.LEFT:
			b.position = Vector2(position.x - 9.0, position.y - 12.0)
		Direction.RIGHT:
			b.position = Vector2(position.x + 9.0, position.y - 12.0)
	b.direction = current_direction
	b.speed = 3.0
	b.ticks_remaining = 32
	b.damage = 2
	b.is_enemy = false
	return b

func apply_damage(amount: int) -> bool:
	if is_dead:
		return false
	if infinite_life:
		life = max_life
		return false
	if invulnerable_timer <= 0 and life > 0:
		life = maxi(0, life - amount)
		invulnerable_timer = 32
		queue_redraw()
		if life <= 0:
			die()
		return true
	return false

func step_tick(input_dir: Vector2i) -> bool:
	if is_dead or not can_control:
		is_moving = false
		return false

	if invulnerable_timer > 0:
		invulnerable_timer -= 1

	if shoot_timer > 0:
		shoot_timer -= 1
		queue_redraw()

	if punch_timer > 0:
		punch_timer -= 1
		is_punching = (punch_timer > 0)
		is_moving = false
		queue_redraw()
		return false
	is_punching = false
	if input_dir == Vector2i.ZERO:
		is_moving = false
		anim_wait_cnt = 0
		frame_num = 0
		queue_redraw()
		return false

	var new_dir: Direction
	if input_dir.y < 0:
		new_dir = Direction.UP
	elif input_dir.y > 0:
		new_dir = Direction.DOWN
	elif input_dir.x < 0:
		new_dir = Direction.LEFT
	else:
		new_dir = Direction.RIGHT

	current_direction = new_dir

	var speed_vector := Vector2.ZERO
	match current_direction:
		Direction.UP:
			speed_vector = Vector2(0.0, -SPEED_NORMAL)
		Direction.DOWN:
			speed_vector = Vector2(0.0, SPEED_NORMAL)
		Direction.LEFT:
			speed_vector = Vector2(-SPEED_NORMAL, 0.0)
		Direction.RIGHT:
			speed_vector = Vector2(SPEED_NORMAL, 0.0)

	var next_pos := position + speed_vector

	if is_colliding_at(next_pos, current_direction):
		is_moving = false
		queue_redraw()
		return false

	position = next_pos
	is_moving = true

	anim_wait_cnt += 1
	if anim_wait_cnt >= ANIM_TICKS_PER_FRAME:
		anim_wait_cnt = 0
		frame_num += 1
		if frame_num >= 3:
			frame_num = 1

	queue_redraw()
	return true

func is_colliding_at(target_pos: Vector2, dir: Direction) -> bool:
	if not collision_grid.is_empty():
		var offsets: Array = COLLIDER_OFFSETS.get(dir, [])
		for offset: Vector2i in offsets:
			var sample_x: float = target_pos.x + float(offset.x)
			var sample_y: float = target_pos.y + float(offset.y)

			if sample_x < 0.0 or sample_x >= 256.0 or sample_y < 0.0 or sample_y >= 192.0:
				return true

			var tile_x: int = int(sample_x) / 8
			var tile_y: int = int(sample_y) / 8

			if tile_x < 0 or tile_x >= 32 or tile_y < 0 or tile_y >= 24:
				return true

			var tile_index: int = tile_y * 32 + tile_x
			if tile_index < collision_grid.size() and int(collision_grid[tile_index]) == 1:
				return true

	return false

func _draw() -> void:
	# 0. Renderização autêntica com spritesheet do MSX2 (se o asset extraído estiver presente)
	if _msx_texture != null:
		# Efeito de piscar durante o período de invulnerabilidade (32 ticks)
		if invulnerable_timer > 0 and (invulnerable_timer % 4) < 2:
			return

		var src_rect := _get_msx_sprite_rect()
		var dest_rect := Rect2(-8.0, -24.0, 16.0, 32.0)
		draw_texture_rect_region(_msx_texture, dest_rect, src_rect)

		# Clarão de disparo (muzzle flash) quando atirando com arma de fogo
		if shoot_timer > 0:
			var flash_pos := Vector2.ZERO
			match current_direction:
				Direction.UP:
					flash_pos = Vector2(3.0, -24.0)
				Direction.DOWN:
					flash_pos = Vector2(3.0, 6.0)
				Direction.LEFT:
					flash_pos = Vector2(-9.0, -12.0)
				Direction.RIGHT:
					flash_pos = Vector2(9.0, -12.0)
			# Clarão de disparo discreto em pixel-art estilo MSX2
			draw_rect(Rect2(flash_pos.x - 1, flash_pos.y - 1, 2, 2), Color.WHITE)
			draw_rect(Rect2(flash_pos.x - 2, flash_pos.y, 1, 1), Color("ffff77"))
			draw_rect(Rect2(flash_pos.x + 1, flash_pos.y, 1, 1), Color("ffff77"))
			draw_rect(Rect2(flash_pos.x, flash_pos.y - 2, 1, 1), Color("ffff77"))
			draw_rect(Rect2(flash_pos.x, flash_pos.y + 1, 1, 1), Color("ffff77"))
		return

	# Fallback gracioso: Desenho procedural autoral caso a textura não exista
	# 1. Snake abatido / caído no solo (Game Over)
	if is_dead:
		var col_shadow := Color("141814")
		var col_uniform := Color("2a3828")
		var col_skin := Color("d89870")
		var col_bandana := Color("c82020")
		var col_vest := Color("1e281c")
		# Corpo caído horizontalmente (28x8)
		draw_rect(Rect2(-14, -4, 28, 8), col_shadow)
		draw_rect(Rect2(-13, -3, 26, 6), col_uniform)
		draw_rect(Rect2(-7, -3, 10, 6), col_vest) # Colete
		draw_rect(Rect2(5, -4, 8, 7), col_skin)    # Cabeça no solo
		draw_rect(Rect2(5, -4, 8, 2), col_bandana) # Bandana caída
		draw_rect(Rect2(-14, 0, 4, 4), Color("0a0e0a")) # Botas
		return

	# 2. Efeito de piscar durante o período de invulnerabilidade (32 ticks)
	if invulnerable_timer > 0 and (invulnerable_timer % 4) < 2:
		return

	# 3. Caixa de Papelão (Cardboard Box) com proporções humanas autênticas
	if is_in_box:
		var box_rect := Rect2(-11, -16, 22, 22)
		var col_box := Color("b88858")
		var col_box_dark := Color("885e38")
		var col_tape := Color("d0d0d0")
		var col_shadow := Color("182418")

		# Sombra sob a caixa
		draw_rect(Rect2(-11, 6, 22, 2), col_shadow)
		# Corpo da caixa
		draw_rect(box_rect, col_box)
		# Borda e vinco superior
		draw_rect(Rect2(-11, -16, 22, 2), col_box_dark)
		draw_rect(Rect2(-11, -16, 2, 22), col_box_dark)
		draw_rect(Rect2(9, -16, 2, 22), col_box_dark)
		# Fita adesiva central
		draw_rect(Rect2(-2, -16, 4, 22), col_tape)
		# Logotipo estilizado da caixa
		draw_rect(Rect2(-8, -8, 4, 2), col_box_dark)
		draw_rect(Rect2(4, -8, 4, 2), col_box_dark)

		# Animação de passadas das pernas por baixo da caixa ao andar
		if is_moving:
			var boot_y := 6
			var l_offset := 0
			var r_offset := 0
			if frame_num == 1:
				l_offset = 2
				r_offset = -1
			elif frame_num == 2:
				l_offset = -1
				r_offset = 2
			draw_rect(Rect2(-6, boot_y + l_offset, 4, 3), Color("141814"))
			draw_rect(Rect2(2, boot_y + r_offset, 4, 3), Color("141814"))
		return

	# 4. Paleta Canônica de Solid Snake (MSX2 RC750)
	var c_hair := Color("1a1008")        # Cabelo castanho escuro / preto
	var c_hair_light := Color("2e1d10")  # Mechas / volume do cabelo
	var c_skin := Color("d89870")        # Pele de Snake
	var c_skin_shadow := Color("aa7050") # Sombra facial / barba por fazer
	var c_bandana := Color("c82020")     # Faixa vermelha icônica da bandana
	var c_bandana_dark := Color("8a1414")# Sombra da bandana
	var c_suit := Color("3c4c38")        # Macacão militar verde-oliva
	var c_vest := Color("243022")        # Colete tático balístico escuro
	var c_vest_light := Color("42543e")  # Destaque de ombreiras e arnês
	var c_belt := Color("181c16")        # Cinto de guarnição e coldre
	var c_buckle := Color("8a9680")      # Fivela metálica
	var c_boot := Color("141814")        # Botas de combate pretas
	var c_glove := Color("1c221a")       # Luvas táticas sem dedos
	var c_eye := Color("120a06")         # Olhos escuros

	# Altura total: 32 pixels (Y de -24 até +8)
	# Largura total: 16 pixels (X de -8 até +8)

	# --- CABEÇA E CABELO (Y: -24 a -15) ---
	# Cabelo (volume base)
	draw_rect(Rect2(-5, -24, 10, 4), c_hair)
	draw_rect(Rect2(-6, -22, 12, 5), c_hair)
	draw_rect(Rect2(-3, -24, 6, 2), c_hair_light)

	# Faixa da Bandana (Y: -22 a -19)
	draw_rect(Rect2(-6, -21, 12, 2), c_bandana)
	draw_rect(Rect2(-6, -20, 12, 1), c_bandana_dark)

	# Rosto / Pele (Y: -19 a -14)
	draw_rect(Rect2(-5, -19, 10, 5), c_skin)
	draw_rect(Rect2(-4, -14, 8, 1), c_skin_shadow) # Queixo / maxilar

	# Detalhes direcionais da cabeça e feições
	match current_direction:
		Direction.DOWN:
			# Olhos focados para frente
			draw_rect(Rect2(-4, -18, 2, 2), c_eye)
			draw_rect(Rect2(2, -18, 2, 2), c_eye)
			draw_rect(Rect2(-4, -18, 1, 1), Color.WHITE)
			draw_rect(Rect2(2, -18, 1, 1), Color.WHITE)
			# Nariz e barba
			draw_rect(Rect2(-1, -16, 2, 2), c_skin_shadow)
			# Franja frontal sobre a bandana
			draw_rect(Rect2(-2, -22, 2, 2), c_hair)
			draw_rect(Rect2(1, -22, 2, 2), c_hair)
			# Pontas da bandana caindo atrás dos ombros
			draw_rect(Rect2(-7, -19, 2, 4), c_bandana)
			draw_rect(Rect2(5, -19, 2, 3), c_bandana)

		Direction.UP:
			# Costas da cabeça: cabelo cobre o rosto
			draw_rect(Rect2(-5, -20, 10, 6), c_hair)
			draw_rect(Rect2(-4, -18, 8, 4), c_hair_light)
			# Nó da bandana no centro da nuca
			draw_rect(Rect2(-1, -21, 2, 3), c_bandana_dark)
			# Duas tiras de tecido da bandana balançando
			var band_sway: int = 1 if frame_num == 1 else (-1 if frame_num == 2 else 0)
			draw_line(Vector2(0, -19), Vector2(-2 + band_sway, -14), c_bandana, 1.5)
			draw_line(Vector2(1, -19), Vector2(3 + band_sway, -13), c_bandana, 1.5)

		Direction.LEFT:
			# Perfil esquerdo: rosto virado para a esquerda
			draw_rect(Rect2(-6, -18, 2, 4), c_skin) # Nariz projetado
			draw_rect(Rect2(-4, -18, 2, 2), c_eye)
			draw_rect(Rect2(-4, -18, 1, 1), Color.WHITE)
			# Cabelo na parte de trás da cabeça (direita)
			draw_rect(Rect2(-1, -21, 6, 7), c_hair)
			draw_rect(Rect2(0, -19, 4, 4), c_hair_light)
			# Tiras da bandana voando para trás (para a direita)
			var band_trail: int = 1 if frame_num == 2 else 0
			draw_line(Vector2(4, -20), Vector2(8, -19 + band_trail), c_bandana, 2.0)
			draw_line(Vector2(5, -19), Vector2(10, -17 + band_trail), c_bandana, 1.5)

		Direction.RIGHT:
			# Perfil direito: rosto virado para a direita
			draw_rect(Rect2(4, -18, 2, 4), c_skin) # Nariz projetado
			draw_rect(Rect2(2, -18, 2, 2), c_eye)
			draw_rect(Rect2(3, -18, 1, 1), Color.WHITE)
			# Cabelo na parte de trás da cabeça (esquerda)
			draw_rect(Rect2(-5, -21, 6, 7), c_hair)
			draw_rect(Rect2(-4, -19, 4, 4), c_hair_light)
			# Tiras da bandana voando para trás (para a esquerda)
			var band_trail: int = -1 if frame_num == 2 else 0
			draw_line(Vector2(-4, -20), Vector2(-8, -19 + band_trail), c_bandana, 2.0)
			draw_line(Vector2(-5, -19), Vector2(-10, -17 + band_trail), c_bandana, 1.5)

	# --- PESCOÇO E OMBROS (Y: -14 a -12) ---
	draw_rect(Rect2(-3, -14, 6, 2), c_skin_shadow)

	# --- TRONCO E COLETE TÁTICO (Y: -13 a -3) ---
	# Macacão tático base
	draw_rect(Rect2(-7, -13, 14, 10), c_suit)
	# Colete balístico de combate
	draw_rect(Rect2(-6, -13, 12, 9), c_vest)
	# Ombreiras e arnês tático
	draw_rect(Rect2(-7, -13, 2, 5), c_vest_light)
	draw_rect(Rect2(5, -13, 2, 5), c_vest_light)

	if current_direction == Direction.DOWN:
		# Zíper frontal do colete e bolsos peitorais
		draw_line(Vector2(0, -13), Vector2(0, -4), c_vest_light, 1.0)
		draw_rect(Rect2(-4, -11, 3, 3), c_belt)
		draw_rect(Rect2(1, -11, 3, 3), c_belt)
	elif current_direction == Direction.UP:
		# Tiras traseiras cruzadas do arnês
		draw_line(Vector2(-4, -13), Vector2(4, -5), c_vest_light, 1.0)
		draw_line(Vector2(4, -13), Vector2(-4, -5), c_vest_light, 1.0)

	# --- BRAÇOS, SOCO E ARMAS ---
	var c_gun := Color("16181e")
	var c_gun_metal := Color("2e3440")
	var has_firearm: bool = (equipped_weapon in [WeaponSystem.WEAPON_HANDGUN, WeaponSystem.WEAPON_SMG, WeaponSystem.WEAPON_GRENADE_LAUNCHER, WeaponSystem.WEAPON_MISSILE])

	if is_punching:
		# GOLPE MARCIAL / SOCO DINÂMICO
		match current_direction:
			Direction.UP:
				# Braço esquerdo em guarda perto do peito
				draw_rect(Rect2(-7, -13, 3, 5), c_suit)
				draw_rect(Rect2(-7, -9, 3, 3), c_glove)
				# Braço direito sobe golpeando para cima
				draw_rect(Rect2(3, -24, 3, 11), c_suit)
				draw_rect(Rect2(2, -28, 5, 5), c_glove)
				draw_rect(Rect2(3, -28, 3, 2), c_skin)
				# Linhas cinéticas de impacto
				draw_line(Vector2(2, -30), Vector2(0, -34), Color(1, 1, 1, 0.8), 1.0)
				draw_line(Vector2(6, -30), Vector2(8, -34), Color(1, 1, 1, 0.8), 1.0)
			Direction.DOWN:
				# Braço esquerdo em guarda
				draw_rect(Rect2(-8, -13, 3, 5), c_suit)
				draw_rect(Rect2(-8, -9, 3, 3), c_glove)
				# Braço direito golpeia para baixo
				draw_rect(Rect2(3, -10, 4, 10), c_suit)
				draw_rect(Rect2(2, 0, 5, 5), c_glove)
				draw_rect(Rect2(3, 3, 3, 2), c_skin)
				# Linhas cinéticas de impacto
				draw_line(Vector2(2, 6), Vector2(0, 10), Color(1, 1, 1, 0.8), 1.0)
				draw_line(Vector2(6, 6), Vector2(8, 10), Color(1, 1, 1, 0.8), 1.0)
			Direction.LEFT:
				# Braço direito recuado em guarda
				draw_rect(Rect2(3, -13, 3, 6), c_suit)
				draw_rect(Rect2(3, -8, 3, 3), c_glove)
				# Braço esquerdo golpeia reto à esquerda
				draw_rect(Rect2(-12, -12, 6, 4), c_suit)
				draw_rect(Rect2(-17, -13, 5, 5), c_glove)
				draw_rect(Rect2(-17, -12, 2, 3), c_skin)
				# Linhas cinéticas de impacto
				draw_line(Vector2(-19, -13), Vector2(-23, -15), Color(1, 1, 1, 0.8), 1.0)
				draw_line(Vector2(-19, -9), Vector2(-23, -7), Color(1, 1, 1, 0.8), 1.0)
			Direction.RIGHT:
				# Braço esquerdo recuado em guarda
				draw_rect(Rect2(-6, -13, 3, 6), c_suit)
				draw_rect(Rect2(-6, -8, 3, 3), c_glove)
				# Braço direito golpeia reto à direita
				draw_rect(Rect2(6, -12, 6, 4), c_suit)
				draw_rect(Rect2(12, -13, 5, 5), c_glove)
				draw_rect(Rect2(15, -12, 2, 3), c_skin)
				# Linhas cinéticas de impacto
				draw_line(Vector2(19, -13), Vector2(23, -15), Color(1, 1, 1, 0.8), 1.0)
				draw_line(Vector2(19, -9), Vector2(23, -7), Color(1, 1, 1, 0.8), 1.0)

	elif has_firearm or shoot_timer > 0:
		# POSTURA DE EMPUNHADURA DE ARMA (SNAKE WITH WEAPON) E CLARÃO DE DISPARO
		match current_direction:
			Direction.DOWN:
				# Empunhadura à frente do quadril apontando para baixo
				draw_rect(Rect2(2, -12, 3, 8), c_suit)
				draw_rect(Rect2(2, -4, 3, 4), c_glove)
				draw_rect(Rect2(-4, -10, 3, 6), c_suit)
				draw_rect(Rect2(-2, -6, 3, 3), c_glove)
				draw_rect(Rect2(2, -5, 3, 7), c_gun)
				draw_rect(Rect2(2, 2, 2, 4), c_gun_metal)
				if shoot_timer > 0:
					# Clarão do disparo na ponta do cano
					draw_rect(Rect2(2, 6, 2, 2), Color.WHITE)
					draw_rect(Rect2(1, 7, 1, 1), Color("ffff77"))
					draw_rect(Rect2(4, 7, 1, 1), Color("ffff77"))
					draw_rect(Rect2(2, 5, 1, 1), Color("ffff77"))
					draw_rect(Rect2(2, 8, 1, 1), Color("ffff77"))

			Direction.UP:
				# Pistola erguida apontando para cima além do ombro
				draw_rect(Rect2(3, -21, 3, 9), c_suit)
				draw_rect(Rect2(3, -22, 3, 3), c_glove)
				draw_rect(Rect2(3, -26, 2, 5), c_gun_metal)
				draw_rect(Rect2(-7, -13, 2, 7), c_suit)
				draw_rect(Rect2(-7, -7, 2, 3), c_glove)
				if shoot_timer > 0:
					draw_rect(Rect2(3, -28, 2, 2), Color.WHITE)
					draw_rect(Rect2(2, -27, 1, 1), Color("ffff77"))
					draw_rect(Rect2(5, -27, 1, 1), Color("ffff77"))
					draw_rect(Rect2(3, -29, 1, 1), Color("ffff77"))
					draw_rect(Rect2(3, -26, 1, 1), Color("ffff77"))

			Direction.LEFT:
				# Postura tática isósceles apontando à esquerda
				draw_rect(Rect2(-7, -12, 6, 4), c_suit)
				draw_rect(Rect2(-10, -12, 4, 4), c_glove)
				draw_rect(Rect2(-14, -11, 5, 3), c_gun)
				draw_rect(Rect2(-16, -11, 2, 2), c_gun_metal)
				if shoot_timer > 0:
					draw_rect(Rect2(-19, -11, 2, 2), Color.WHITE)
					draw_rect(Rect2(-20, -10, 1, 1), Color("ffff77"))
					draw_rect(Rect2(-17, -10, 1, 1), Color("ffff77"))
					draw_rect(Rect2(-18, -12, 1, 1), Color("ffff77"))
					draw_rect(Rect2(-18, -9, 1, 1), Color("ffff77"))

			Direction.RIGHT:
				# Postura tática isósceles apontando à direita
				draw_rect(Rect2(1, -12, 6, 4), c_suit)
				draw_rect(Rect2(6, -12, 4, 4), c_glove)
				draw_rect(Rect2(9, -11, 5, 3), c_gun)
				draw_rect(Rect2(14, -11, 2, 2), c_gun_metal)
				if shoot_timer > 0:
					draw_rect(Rect2(17, -11, 2, 2), Color.WHITE)
					draw_rect(Rect2(16, -10, 1, 1), Color("ffff77"))
					draw_rect(Rect2(19, -10, 1, 1), Color("ffff77"))
					draw_rect(Rect2(18, -12, 1, 1), Color("ffff77"))
					draw_rect(Rect2(18, -9, 1, 1), Color("ffff77"))

	else:
		# BRAÇOS EM MOVIMENTO NATURAL / MARCHA
		var arm_l_y := -12
		var arm_r_y := -12
		if is_moving:
			if frame_num == 1:
				arm_l_y = -10
				arm_r_y = -14
			elif frame_num == 2:
				arm_l_y = -14
				arm_r_y = -10

		match current_direction:
			Direction.DOWN, Direction.UP:
				draw_rect(Rect2(-8, arm_l_y, 2, 7), c_suit)
				draw_rect(Rect2(-8, arm_l_y + 6, 2, 3), c_glove)
				draw_rect(Rect2(6, arm_r_y, 2, 7), c_suit)
				draw_rect(Rect2(6, arm_r_y + 6, 2, 3), c_glove)
			Direction.LEFT:
				draw_rect(Rect2(-2, arm_l_y, 3, 8), c_suit)
				draw_rect(Rect2(-2, arm_l_y + 6, 3, 3), c_glove)
			Direction.RIGHT:
				draw_rect(Rect2(-1, arm_r_y, 3, 8), c_suit)
				draw_rect(Rect2(-1, arm_r_y + 6, 3, 3), c_glove)

	# --- CINTO E GUILHOTINA TÁTICA (Y: -4 a 0) ---
	draw_rect(Rect2(-6, -4, 12, 3), c_belt)
	draw_rect(Rect2(-1, -4, 2, 3), c_buckle) # Fivela
	draw_rect(Rect2(-6, -4, 2, 3), c_vest_light) # Pouch esquerdo
	draw_rect(Rect2(4, -4, 2, 3), c_vest_light)  # Pouch direito

	# --- PERNAS E BOTAS (Y: 0 a +8) ---
	var leg_l_rect := Rect2(-5, 0, 4, 5)
	var leg_r_rect := Rect2(1, 0, 4, 5)
	var boot_l_rect := Rect2(-6, 5, 4, 3)
	var boot_r_rect := Rect2(1, 5, 4, 3)

	if is_moving:
		if frame_num == 1:
			leg_l_rect.position.y += 1
			boot_l_rect.position.y += 1
			leg_r_rect.position.y -= 1
			boot_r_rect.position.y -= 1
		elif frame_num == 2:
			leg_l_rect.position.y -= 1
			boot_l_rect.position.y -= 1
			leg_r_rect.position.y += 1
			boot_r_rect.position.y += 1

	if current_direction == Direction.LEFT:
		draw_rect(Rect2(-4, 0, 6, 5), c_suit)
		draw_rect(Rect2(-5, 5, 6, 3), c_boot)
		if is_moving and frame_num == 1:
			draw_rect(Rect2(-6, 5, 4, 3), c_boot)
			draw_rect(Rect2(0, 3, 4, 3), Color("0a0e0a"))
	elif current_direction == Direction.RIGHT:
		draw_rect(Rect2(-2, 0, 6, 5), c_suit)
		draw_rect(Rect2(-1, 5, 6, 3), c_boot)
		if is_moving and frame_num == 1:
			draw_rect(Rect2(2, 5, 4, 3), c_boot)
			draw_rect(Rect2(-4, 3, 4, 3), Color("0a0e0a"))
	else:
		draw_rect(leg_l_rect, c_suit)
		draw_rect(leg_r_rect, c_suit)
		draw_rect(Rect2(leg_l_rect.position.x, 2, 4, 2), c_vest)
		draw_rect(Rect2(leg_r_rect.position.x, 2, 4, 2), c_vest)
		draw_rect(boot_l_rect, c_boot)
		draw_rect(boot_r_rect, c_boot)
		draw_line(Vector2(boot_l_rect.position.x, boot_l_rect.end.y), Vector2(boot_l_rect.end.x, boot_l_rect.end.y), Color("080a08"), 1.0)
		draw_line(Vector2(boot_r_rect.position.x, boot_r_rect.end.y), Vector2(boot_r_rect.end.x, boot_r_rect.end.y), Color("080a08"), 1.0)

	# Debug: desenhar os 2 pontos de colisão ativos de BoxColliderDat
	if show_debug_colliders:
		var offsets: Array = COLLIDER_OFFSETS.get(current_direction, [])
		for offset: Vector2i in offsets:
			draw_circle(Vector2(offset.x, offset.y), 1.5, Color.RED)
