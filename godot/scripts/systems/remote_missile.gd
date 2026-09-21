class_name RemoteMissile
extends Node2D

## Entidade de Míssil Teleguiado por Controle Remoto (Etapa 20 — WEAPON_MISSILE).
## Lógica revertida de logic/weapon/missile.asm, logic/weaponuse.asm e logic/damagetoenemy.asm.

signal missile_exploded(pos: Vector2)
signal missile_destroyed

enum MissileState {
	FLIGHT = 0,
	EXPLODING = 1,
	FINISHED = 2
}

const SPEED: float = 4.0               # 4 px/tick constante (MissileIniSpeed no offset 0x48DE)
const EXPLOSION_DURATION: int = 15      # 0x0F ticks (MedExplosionLogic em plasticbomb.asm:150)
const DAMAGE: int = 5                  # 5 HP (MissileDamage em weapondamage.asm:58)

# Limites de tela do MSX2 (weaponuse.asm:365-375)
const MIN_X: float = 9.0
const MAX_X: float = 248.0
const MIN_Y: float = 0.0
const MAX_Y: float = 184.0

var speed: float = SPEED
var state: int = MissileState.FLIGHT
var current_direction: int = PlayerController.Direction.UP
var velocity: Vector2 = Vector2(0, -SPEED)
var explosion_timer: int = EXPLOSION_DURATION
var smoke_trail: Array[Vector2] = []
var damage: int = DAMAGE

func _init() -> void:
	z_index = 10

func setup(start_pos: Vector2, initial_dir: int) -> void:
	# No MSX2 (missile.asm:37-47), spawn ocorre ligeiramente acima de Snake: Y - 16
	position = start_pos + Vector2(0, -12.0)
	current_direction = initial_dir
	_update_velocity_from_direction()
	state = MissileState.FLIGHT
	explosion_timer = EXPLOSION_DURATION
	smoke_trail.clear()
	queue_redraw()

func _update_velocity_from_direction() -> void:
	match current_direction:
		PlayerController.Direction.UP:
			velocity = Vector2(0, -SPEED)
		PlayerController.Direction.DOWN:
			velocity = Vector2(0, SPEED)
		PlayerController.Direction.LEFT:
			velocity = Vector2(-SPEED, 0)
		PlayerController.Direction.RIGHT:
			velocity = Vector2(SPEED, 0)

## Manobra direcional em voo acionada pelos inputs do jogador (missile.asm:112-133)
func steer(input_dir: Vector2i) -> void:
	if state != MissileState.FLIGHT:
		return

	var new_dir: int = current_direction
	if input_dir.y < 0:
		new_dir = PlayerController.Direction.UP
	elif input_dir.y > 0:
		new_dir = PlayerController.Direction.DOWN
	elif input_dir.x < 0:
		new_dir = PlayerController.Direction.LEFT
	elif input_dir.x > 0:
		new_dir = PlayerController.Direction.RIGHT

	if new_dir != current_direction:
		current_direction = new_dir
		_update_velocity_from_direction()
		queue_redraw()

## Atualização de física e colisões por tick
func step_tick(runtime_collision: Array, room_bounds: Rect2 = Rect2(MIN_X, MIN_Y, MAX_X - MIN_X, MAX_Y - MIN_Y)) -> bool:
	if state == MissileState.FINISHED:
		return false

	if state == MissileState.EXPLODING:
		explosion_timer -= 1
		queue_redraw()
		if explosion_timer <= 0:
			state = MissileState.FINISHED
			missile_destroyed.emit()
			return false
		return true

	# Em voo (FLIGHT)
	smoke_trail.append(position)
	if smoke_trail.size() > 6:
		smoke_trail.pop_front()

	position += velocity

	# 1. Checar limites de tela (ChkShotBoundaries em weaponuse.asm:365)
	if position.x < MIN_X or position.x > MAX_X or position.y < MIN_Y or position.y > MAX_Y:
		explode()
		return true

	# 2. Checar colisão com paredes sólidas da grade 32x24 (ChkShotCollision)
	if not runtime_collision.is_empty():
		var tile_x: int = int(position.x) / 8
		var tile_y: int = int(position.y) / 8
		if tile_x >= 0 and tile_x < 32 and tile_y >= 0 and tile_y < 24:
			var idx: int = tile_y * 32 + tile_x
			if idx >= 0 and idx < runtime_collision.size() and int(runtime_collision[idx]) == 1:
				explode()
				return true

	queue_redraw()
	return true

## Transita imediatamente para estado de explosão
func explode() -> void:
	if state != MissileState.FLIGHT:
		return
	state = MissileState.EXPLODING
	explosion_timer = EXPLOSION_DURATION
	velocity = Vector2.ZERO
	missile_exploded.emit(position)
	print("MISSILE_EXPLODE: Míssil detonou em %s!" % position)
	queue_redraw()

func check_actor_hit(target_pos: Vector2, hit_radius: float = 16.0) -> bool:
	if state == MissileState.FINISHED:
		return false
	if state == MissileState.EXPLODING and explosion_timer != EXPLOSION_DURATION:
		return false
	return position.distance_to(target_pos) <= hit_radius

func _draw() -> void:
	if state == MissileState.FLIGHT:
		# Desenhar fumaça da trilha do propulsor
		for i: int in range(smoke_trail.size()):
			var smoke_pos: Vector2 = to_local(smoke_trail[i])
			var alpha: float = float(i + 1) / float(smoke_trail.size()) * 0.4
			draw_circle(smoke_pos, 2.5, Color(0.7, 0.75, 0.7, alpha))

		# Desenhar corpo do míssil orientado
		var col_body := Color(0.9, 0.9, 0.95)
		var col_tip := Color(0.95, 0.2, 0.2)
		var col_fin := Color(0.2, 0.2, 0.25)
		var col_flame := Color(1.0, 0.7, 0.1, 0.8)

		match current_direction:
			PlayerController.Direction.UP:
				draw_rect(Rect2(-2, -6, 4, 10), col_body)
				draw_polygon([Vector2(-2, -6), Vector2(0, -10), Vector2(2, -6)], [col_tip, col_tip, col_tip])
				draw_rect(Rect2(-4, 2, 2, 3), col_fin)
				draw_rect(Rect2(2, 2, 2, 3), col_fin)
				draw_circle(Vector2(0, 5), 2.0, col_flame)
			PlayerController.Direction.DOWN:
				draw_rect(Rect2(-2, -4, 4, 10), col_body)
				draw_polygon([Vector2(-2, 6), Vector2(0, 10), Vector2(2, 6)], [col_tip, col_tip, col_tip])
				draw_rect(Rect2(-4, -5, 2, 3), col_fin)
				draw_rect(Rect2(2, -5, 2, 3), col_fin)
				draw_circle(Vector2(0, -5), 2.0, col_flame)
			PlayerController.Direction.LEFT:
				draw_rect(Rect2(-6, -2, 10, 4), col_body)
				draw_polygon([Vector2(-6, -2), Vector2(-10, 0), Vector2(-6, 2)], [col_tip, col_tip, col_tip])
				draw_rect(Rect2(2, -4, 3, 2), col_fin)
				draw_rect(Rect2(2, 2, 3, 2), col_fin)
				draw_circle(Vector2(5, 0), 2.0, col_flame)
			PlayerController.Direction.RIGHT:
				draw_rect(Rect2(-4, -2, 10, 4), col_body)
				draw_polygon([Vector2(6, -2), Vector2(10, 0), Vector2(6, 2)], [col_tip, col_tip, col_tip])
				draw_rect(Rect2(-5, -4, 3, 2), col_fin)
				draw_rect(Rect2(-5, 2, 3, 2), col_fin)
				draw_circle(Vector2(-5, 0), 2.0, col_flame)

	elif state == MissileState.EXPLODING:
		# Animação autêntica MSX de explosão média (3 fases: MedExplosionLogic)
		if explosion_timer > 10:
			# Fase 1: Flash central brilhante amarelo/branco
			draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.9, 0.3, 0.9))
			draw_circle(Vector2.ZERO, 3.0, Color(1.0, 1.0, 0.9))
		elif explosion_timer > 5:
			# Fase 2: Expansão laranja com faíscas
			draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.45, 0.1, 0.8))
			draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.85, 0.2))
			draw_line(Vector2(-12, -4), Vector2(-8, -2), Color(1.0, 0.9, 0.2), 1.5)
			draw_line(Vector2(10, 5), Vector2(14, 8), Color(1.0, 0.9, 0.2), 1.5)
			draw_line(Vector2(-5, 10), Vector2(-8, 13), Color(1.0, 0.9, 0.2), 1.5)
		else:
			# Fase 3: Dissipação escura avermelhada
			draw_circle(Vector2.ZERO, 15.0, Color(0.8, 0.2, 0.1, 0.45))
			draw_circle(Vector2.ZERO, 8.0, Color(0.9, 0.4, 0.1, 0.55))
