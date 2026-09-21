class_name PlayerController
extends Node2D

## Controlador de movimento de Snake fiel à física e colisão MSX2 (Etapa 5).
## Coordenadas em subpixels com avanço discreto de 2.0 pixels/tick e 2 pontos de colisão por direção.

enum Direction {
	UP = 1,
	DOWN = 2,
	LEFT = 3,
	RIGHT = 4,
}

const SPEED_NORMAL: float = 2.0
const ANIM_TICKS_PER_FRAME: int = 6

# Pontos exatos de amostragem de colisão da ROM (Shape 0 / BoxColliderDat)
const COLLIDER_OFFSETS = {
	Direction.UP: [Vector2i(-6, -5), Vector2i(5, -5)],
	Direction.DOWN: [Vector2i(-6, 4), Vector2i(5, 4)],
	Direction.LEFT: [Vector2i(-8, -4), Vector2i(-8, 3)],
	Direction.RIGHT: [Vector2i(7, -4), Vector2i(7, 3)],
}

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

func set_rank_life(new_max_life: int, full_heal: bool = true) -> void:
	max_life = new_max_life
	if full_heal or life > max_life:
		life = max_life
	queue_redraw()

func _ready() -> void:
	z_index = 10

func set_collision_grid(grid: Array) -> void:
	collision_grid = grid

func set_grid_position(px: float, py: float) -> void:
	position = Vector2(px, py)
	queue_redraw()

func punch() -> bool:
	if punch_timer <= 0 and life > 0:
		punch_timer = 8
		is_punching = true
		is_moving = false
		queue_redraw()
		return true
	return false

## Disparo com arma de fogo equipada (logic/weapon/handgun.asm:39-65)
## Origem do tiro: PlayerX, PlayerY - 14 (deslocamento vertical exato da ROM)
func fire_weapon(weapon_sys: WeaponSystem) -> Bullet:
	if weapon_sys == null or not weapon_sys.can_fire() or life <= 0:
		return null

	if not weapon_sys.consume_ammo():
		return null

	var b: Bullet = Bullet.new()
	b.position = Vector2(position.x, position.y - 14.0)
	b.direction = current_direction
	b.speed = 6.0
	b.ticks_remaining = 16
	b.damage = 2
	b.is_enemy = false
	return b

func apply_damage(amount: int) -> bool:
	if infinite_life:
		life = max_life
		return false
	if invulnerable_timer <= 0 and life > 0:
		life = maxi(0, life - amount)
		invulnerable_timer = 32
		queue_redraw()
		return true
	return false

func step_tick(input_dir: Vector2i) -> bool:
	if invulnerable_timer > 0:
		invulnerable_timer -= 1

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
	if collision_grid.is_empty():
		return false

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
	# Efeito de piscar durante o período de invulnerabilidade (32 ticks)
	if invulnerable_timer > 0 and (invulnerable_timer % 4) < 2:
		return

	# Representação visual de Snake (16x16 pixels centralizado)
	var body_rect := Rect2(-8, -12, 16, 16)
	
	# Uniforme militar (verde oliva autêntico MSX)
	var uniform_color := Color("486838")
	var shadow_color := Color("283818")
	var skin_color := Color("d89870")
	var bandana_color := Color("c83030")

	draw_rect(body_rect, uniform_color)
	draw_rect(Rect2(-8, -12, 16, 2), shadow_color)

	# Faixa da bandana
	draw_rect(Rect2(-7, -10, 14, 2), bandana_color)
	
	# Rosto / Pele visível
	draw_rect(Rect2(-5, -8, 10, 4), skin_color)

	# Indicador de direção dos olhos / visão
	var eye_offset := Vector2.ZERO
	match current_direction:
		Direction.UP:
			draw_rect(Rect2(-6, -11, 12, 4), shadow_color) # Costas da cabeça
		Direction.DOWN:
			draw_rect(Rect2(-4, -7, 2, 2), Color.BLACK)
			draw_rect(Rect2(2, -7, 2, 2), Color.BLACK)
		Direction.LEFT:
			draw_rect(Rect2(-6, -7, 2, 2), Color.BLACK)
		Direction.RIGHT:
			draw_rect(Rect2(4, -7, 2, 2), Color.BLACK)

	# Pés com animação de passos
	var leg_left := Rect2(-6, 2, 4, 3)
	var leg_right := Rect2(2, 2, 4, 3)
	if is_moving:
		if frame_num == 1:
			leg_left.position.y += 1
			leg_right.position.y -= 1
		elif frame_num == 2:
			leg_left.position.y -= 1
			leg_right.position.y += 1
	draw_rect(leg_left, shadow_color)
	draw_rect(leg_right, shadow_color)

	# Animação do soco (braço/punho estendido na direção do ataque)
	if is_punching:
		var fist_rect := Rect2(0, 0, 4, 4)
		match current_direction:
			Direction.UP:
				fist_rect = Rect2(-2, -16, 4, 5)
			Direction.DOWN:
				fist_rect = Rect2(-2, 4, 4, 5)
			Direction.LEFT:
				fist_rect = Rect2(-13, -6, 5, 4)
			Direction.RIGHT:
				fist_rect = Rect2(8, -6, 5, 4)
		draw_rect(fist_rect, skin_color)
		draw_rect(Rect2(fist_rect.position, Vector2(fist_rect.size.x, 1)), shadow_color)

	# Debug: desenhar os 2 pontos de colisão ativos de BoxColliderDat
	if show_debug_colliders:
		var offsets: Array = COLLIDER_OFFSETS.get(current_direction, [])
		for offset: Vector2i in offsets:
			draw_circle(Vector2(offset.x, offset.y), 1.5, Color.RED)
