class_name ShotGunnerBullet
extends Node2D

## Projétil de Escopeta do Shoot Gunner — ID_SGUNNER_SHOT = 0x2B (43)
## Fonte: logic/actors/shotgunner.asm:188-235 e data/actorspriteattr.asm:434-437
## (ShotGunShot1 a ShotGunShot4)
##
## Características autênticas MSX2:
## - Velocidade escalar de ~2.0 px/tick (fiel a CalShootSpeed na ROM)
## - Efeito de Spray de Chumbinho ("Buckshot Spread"):
##   * Frame 1 (wait 0-6): Flash de saída do cano (losango/cruz branca)
##   * Frame 2 (wait 7-13): Pequeno aglomerado compacto de chumbo (r <= 6 px)
##   * Frame 3 (wait 14-20): Abertura do cone de dispersão (r <= 11 px)
##   * Frame 4 (wait 21+): Nuvem ampla de partículas brancas de chumbo (r <= 18 px)
## - Colide com tiles sólidos da grade e com Snake
## - Dano ao jogador: 8 (ActorTouchDamage[42] na ROM)
## - Alcance delimitado: se dissipa no ar após 52 ticks (~0.85s)

const SPEED: float = 2.0
const SPEED_PX_PER_SEC: float = 120.0 # 2.0 * 60 = 120 px/s
const PLAYER_DAMAGE: int = 8
const MAX_LIFETIME_TICKS: int = 52

const FRAME2_THRESHOLD: int = 7
const FRAME3_THRESHOLD: int = 14
const FRAME4_THRESHOLD: int = 21

const SHAPE_RADII: Array[float] = [4.0, 7.0, 12.0, 18.0]

## Offsets fixos determinísticos de partículas de chumbo (evita jitter visual)
const SPRAY_F2: Array[Vector2] = [
	Vector2(-5.0, 1.0), Vector2(0.0, 4.0), Vector2(3.0, -3.0), Vector2(4.0, -2.0),
	Vector2(0.0, -5.0), Vector2(5.0, 2.0), Vector2(-1.0, -1.0), Vector2(-1.0, 4.0),
	Vector2(2.0, -1.0), Vector2(0.0, -2.0), Vector2(3.0, 4.0), Vector2(-3.0, -1.0)
]

const SPRAY_F3: Array[Vector2] = [
	Vector2(2.0, -5.0), Vector2(-2.0, -6.0), Vector2(-2.0, 0.0), Vector2(-8.0, 5.0),
	Vector2(1.0, -4.0), Vector2(-1.0, 10.0), Vector2(-6.0, 6.0), Vector2(-4.0, 8.0),
	Vector2(5.0, 5.0), Vector2(2.0, 4.0), Vector2(-3.0, -1.0), Vector2(8.0, -2.0),
	Vector2(-7.0, 4.0), Vector2(9.0, -1.0), Vector2(4.0, 8.0), Vector2(-6.0, -3.0),
	Vector2(1.0, 0.0), Vector2(2.0, -2.0), Vector2(5.0, -2.0), Vector2(4.0, -3.0),
	Vector2(1.0, -7.0), Vector2(0.0, 1.0), Vector2(3.0, 2.0), Vector2(2.0, 2.0)
]

const SPRAY_F4: Array[Vector2] = [
	Vector2(14.0, -7.0), Vector2(10.0, -12.0), Vector2(-10.0, 4.0), Vector2(-4.0, 15.0),
	Vector2(-6.0, -6.0), Vector2(-4.0, 10.0), Vector2(-4.0, 8.0), Vector2(1.0, -9.0),
	Vector2(-9.0, 0.0), Vector2(-3.0, 6.0), Vector2(-4.0, 3.0), Vector2(4.0, 3.0),
	Vector2(-5.0, -15.0), Vector2(8.0, 13.0), Vector2(12.0, 5.0), Vector2(14.0, 1.0),
	Vector2(9.0, -3.0), Vector2(7.0, -3.0), Vector2(9.0, -1.0), Vector2(8.0, -6.0),
	Vector2(-5.0, -2.0), Vector2(-15.0, -1.0), Vector2(8.0, -13.0), Vector2(-1.0, -12.0),
	Vector2(15.0, -5.0), Vector2(-8.0, 1.0), Vector2(10.0, 4.0), Vector2(-7.0, -14.0),
	Vector2(-7.0, -12.0), Vector2(-4.0, 6.0), Vector2(-3.0, 4.0), Vector2(-11.0, -6.0),
	Vector2(8.0, -1.0), Vector2(-8.0, 7.0), Vector2(13.0, -7.0), Vector2(1.0, -2.0),
	Vector2(-5.0, -13.0), Vector2(-6.0, -2.0), Vector2(3.0, 10.0), Vector2(-3.0, 7.0),
	Vector2(1.0, -7.0), Vector2(5.0, 14.0), Vector2(6.0, 10.0), Vector2(15.0, -2.0),
	Vector2(1.0, -10.0), Vector2(7.0, 9.0), Vector2(-5.0, -10.0), Vector2(-3.0, -10.0),
	Vector2(11.0, -13.0), Vector2(-11.0, -7.0), Vector2(-10.0, -2.0), Vector2(-9.0, -2.0),
	Vector2(1.0, 4.0), Vector2(0.0, 1.0), Vector2(-6.0, 9.0), Vector2(7.0, -1.0),
	Vector2(-4.0, -5.0), Vector2(11.0, 1.0), Vector2(2.0, 1.0), Vector2(-3.0, 0.0),
	Vector2(0.0, -4.0), Vector2(11.0, 2.0), Vector2(8.0, -2.0), Vector2(5.0, 5.0)
]

# ---------------------------------------------------------------------------
# Estado
# ---------------------------------------------------------------------------

var velocity: Vector2 = Vector2.ZERO
var wait_tick: int = 0
var anim_frame: int = 1
var current_radius: float = SHAPE_RADII[0]
var is_active: bool = true

var collision_grid: Array = []

signal hit_player(damage: int)
signal bullet_destroyed

var _bullet_texture: Texture2D = null

func _ready() -> void:
	z_index = 12
	if ResourceLoader.exists("res://assets/protected/sprites/shotgun_shot_msx.png"):
		_bullet_texture = load("res://assets/protected/sprites/shotgun_shot_msx.png")

func setup(origin: Vector2, target: Vector2, grid: Array) -> void:
	position = origin
	collision_grid = grid
	var direction: Vector2 = (target - origin).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	velocity = direction * SPEED
	wait_tick = 0
	anim_frame = 1
	current_radius = SHAPE_RADII[0]
	is_active = true

func step_tick(player_pos: Vector2, grid: Array, delta: float = 1.0 / 60.0) -> void:
	if not is_active:
		return
	collision_grid = grid
	wait_tick += 1

	# Alcance máximo de dispersão: dissipa no ar
	if wait_tick > MAX_LIFETIME_TICKS:
		_destroy()
		return

	# Atualiza frame de animação (4 fases de ShotGunShot1 a 4)
	if wait_tick < FRAME2_THRESHOLD:
		anim_frame = 1
		current_radius = SHAPE_RADII[0]
	elif wait_tick < FRAME3_THRESHOLD:
		anim_frame = 2
		current_radius = SHAPE_RADII[1]
	elif wait_tick < FRAME4_THRESHOLD:
		anim_frame = 3
		current_radius = SHAPE_RADII[2]
	else:
		anim_frame = 4
		current_radius = SHAPE_RADII[3]

	var velocity_px_per_sec: Vector2 = velocity * 60.0
	position += velocity_px_per_sec * delta

	# Colisão com tiles sólidos da sala
	if _check_tile_collision():
		_destroy()
		return

	# Limite da tela
	if position.x < 4.0 or position.x > 252.0 or position.y < 4.0 or position.y > 188.0:
		_destroy()
		return

	# Colisão com Snake (área de espalhamento da nuvem)
	var dist: float = position.distance_to(player_pos)
	if dist < current_radius + 6.0:
		emit_signal("hit_player", PLAYER_DAMAGE)
		_destroy()
		return

	queue_redraw()

func _check_tile_collision() -> bool:
	if collision_grid.is_empty():
		return false
	var tx: int = int(position.x) / 8
	var ty: int = int(position.y) / 8
	if tx < 0 or tx >= 32 or ty < 0 or ty >= 24:
		return true
	var idx: int = ty * 32 + tx
	if idx >= 0 and idx < collision_grid.size() and int(collision_grid[idx]) == 1:
		return true
	return false

func _destroy() -> void:
	if not is_active:
		return
	is_active = false
	visible = false
	queue_redraw()
	emit_signal("bullet_destroyed")
	if get_parent() != null:
		get_parent().remove_child(self)
	queue_free()

# ---------------------------------------------------------------------------
# Desenho procedural autêntico do Spray de Escopeta MSX2
# Pontos brancos de chumbo com expansão natural e núcleo denso
# ---------------------------------------------------------------------------

func _draw() -> void:
	if not is_active:
		return

	# 1. Renderização autêntica com spritesheet MSX2 (ShotGunShot1..ShotGunShot4)
	if _bullet_texture != null:
		var frame_idx: int = clampi(anim_frame - 1, 0, 3)
		var src_rect := Rect2(frame_idx * 32.0, 0.0, 32.0, 32.0)
		var dest_rect := Rect2(-16.0, -16.0, 32.0, 32.0)
		draw_texture_rect_region(_bullet_texture, dest_rect, src_rect)
		return

	# 2. Desenho procedural autêntico do Spray de Escopeta MSX2
	match anim_frame:
		1:
			# Flash de saída do cano: losango/cruz branca compacta
			draw_rect(Rect2(-1.0, -1.0, 3.0, 3.0), Color.WHITE)
			draw_line(Vector2(0.0, -3.0), Vector2(0.0, 3.0), Color.WHITE, 1.0)
			draw_line(Vector2(-3.0, 0.0), Vector2(3.0, 0.0), Color.WHITE, 1.0)
		2:
			# Início do cone: pequeno grupo de chumbo
			draw_rect(Rect2(-1.0, -1.0, 2.0, 2.0), Color.WHITE)
			for pt: Vector2 in SPRAY_F2:
				draw_rect(Rect2(pt.x, pt.y, 1.0, 1.0), Color(0.95, 0.95, 1.0))
		3:
			# Abertura média da nuvem de chumbo
			draw_rect(Rect2(-1.0, -1.0, 2.0, 2.0), Color.WHITE)
			for pt: Vector2 in SPRAY_F3:
				draw_rect(Rect2(pt.x, pt.y, 1.0, 1.0), Color(0.9, 0.95, 1.0))
		4:
			# Spray completo: nuvem de partículas idêntica à captura do MSX2
			# Núcleo mais denso
			draw_rect(Rect2(-1.0, -1.0, 3.0, 3.0), Color.WHITE)
			for pt: Vector2 in SPRAY_F4:
				# Variação sutil de brilho: mais brilhante no centro, pontinhos discretos na borda
				var d: float = pt.length()
				var alpha: float = clampf(1.0 - (d / 22.0) * 0.4, 0.6, 1.0)
				draw_rect(Rect2(pt.x, pt.y, 1.0, 1.0), Color(1.0, 1.0, 1.0, alpha))
