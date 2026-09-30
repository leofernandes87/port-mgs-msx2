class_name PlasticBomb
extends Node2D

## Entidade física do Explosivo Plástico C4 fiel ao Metal Gear MSX2 RC750.
## Lógica revertida de logic/weapon/plasticbomb.asm e data/shapes.asm.

signal bomb_exploded(bomb_pos: Vector2, radius: float, damage: int)
signal bomb_finished(bomb_node: Node2D)

const TIMER_ARMED_TICKS: int = 96    # 96 frames na ROM MSX (~1.6s)
const TIMER_EXPLOSION_TICKS: int = 15 # 0Fh na ROM MSX (~0.25s)
const TIMER_ARMED_SEC: float = 96.0 / 60.0        # 1.600s
const TIMER_EXPLOSION_SEC: float = 15.0 / 60.0    # 0.250s
const BLAST_RADIUS: float = 24.0     # Raio de detonação para quebra de paredes e dano
const DAMAGE: int = 10               # Dano letal a guardas e cães

var timer_sec: float = TIMER_ARMED_SEC
var timer: int:
	get:
		return int(ceil(timer_sec * 60.0 - 0.0001))
	set(v):
		timer_sec = float(v) / 60.0

var explosion_timer_sec: float = TIMER_EXPLOSION_SEC
var explosion_timer: int:
	get:
		return int(ceil(explosion_timer_sec * 60.0 - 0.0001))
	set(v):
		explosion_timer_sec = float(v) / 60.0

var is_exploding: bool = false
var tick_count: int = 0

# Offsets canônicos dependendo da direção de Snake (logic/weapon/plasticbomb.asm:80-84)
# UP: Y - 16; DOWN: Y + 8; LEFT: X - 12; RIGHT: X + 12
static func get_spawn_offset(dir: PlayerController.Direction) -> Vector2:
	match dir:
		PlayerController.Direction.UP:
			return Vector2(0.0, -16.0)
		PlayerController.Direction.DOWN:
			return Vector2(0.0, 8.0)
		PlayerController.Direction.LEFT:
			return Vector2(-12.0, 0.0)
		PlayerController.Direction.RIGHT:
			return Vector2(12.0, 0.0)
	return Vector2.ZERO

func setup(snake_pos: Vector2, dir: PlayerController.Direction) -> void:
	position = snake_pos + get_spawn_offset(dir)
	z_index = 8
	timer_sec = TIMER_ARMED_SEC
	explosion_timer_sec = TIMER_EXPLOSION_SEC
	is_exploding = false
	tick_count = 0

func step_tick(delta: float = 1.0 / 60.0) -> void:
	tick_count += 1
	if not is_exploding:
		timer_sec = maxf(0.0, timer_sec - delta)
		queue_redraw()
		if timer_sec <= 0.0001:
			timer_sec = 0.0
			explode()
	else:
		explosion_timer_sec = maxf(0.0, explosion_timer_sec - delta)
		queue_redraw()
		if explosion_timer_sec <= 0.0001:
			explosion_timer_sec = 0.0
			bomb_finished.emit(self)
			queue_free()

func explode() -> void:
	if is_exploding:
		return
	is_exploding = true
	print("PLASTIC_BOMB_EXPLODED: Detonação em %s! (Raio: %.1f px)" % [position, BLAST_RADIUS])
	bomb_exploded.emit(position, BLAST_RADIUS, DAMAGE)
	queue_redraw()

func _draw() -> void:
	if not is_exploding:
		# Miniatura do bloco militar de C4 (verde oliva escuro com detonador e fio)
		draw_rect(Rect2(-4, -3, 8, 6), Color("283828"))
		draw_rect(Rect2(-3, -2, 6, 4), Color("3d4f3d"))
		draw_rect(Rect2(-2, -4, 4, 2), Color("1a1a1a")) # Detonador
		# LED piscante do detonador (pisca a cada 6 ticks)
		var led_on: bool = (timer % 8) < 4
		var led_color: Color = Color("ff2020") if led_on else Color("601010")
		draw_rect(Rect2(-1, -4, 2, 2), led_color)
	else:
		# Efeito visual autêntico de explosão MSX2
		var progress: float = 1.0 - (float(explosion_timer) / float(TIMER_EXPLOSION_TICKS))
		var cur_radius: float = lerpf(8.0, BLAST_RADIUS, progress)

		# Clarão central branco e anéis concêntricos amarelo/laranja
		draw_circle(Vector2.ZERO, cur_radius, Color(1.0, 0.45, 0.1, 0.85))
		draw_circle(Vector2.ZERO, cur_radius * 0.7, Color(1.0, 0.85, 0.2, 0.95))
		draw_circle(Vector2.ZERO, cur_radius * 0.35, Color(1.0, 1.0, 1.0, 1.0))

		# Fagulhas e estilhaços pontuais
		for i: int in range(6):
			var angle: float = (float(i) / 6.0) * TAU + progress * 2.0
			var spark_dist: float = cur_radius * 1.15
			var spark_pos := Vector2(cos(angle), sin(angle)) * spark_dist
			draw_rect(Rect2(spark_pos - Vector2(1, 1), Vector2(3, 3)), Color(1.0, 0.9, 0.3, 0.9))
