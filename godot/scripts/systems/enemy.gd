class_name EnemyGuard
extends Node2D

## Soldado inimigo fiel à física, rotas de patrulha e linha de visão da ROM do MSX2 RC750 (Etapa 7).
## Lógica revertida de logic/actors/chkdiscover.asm e data/paths.asm.

enum GuardType {
	SLOW = 4,   # ID_GUARD_SLOW (0.5 px/tick ou 1.0 px a cada 2 ticks)
	MEDIUM = 5, # ID_GUARD_MEDIUM (1.0 px/tick)
	FAST = 6,   # ID_GUARD_FAST (1.5 px/tick)
}

enum GuardState {
	PATROL = 0,
	ALERT = 1,
}

# Tolerâncias exatas de visão da ROM (ChkViewVertical e ChkViewHorizontal em chkdiscover.asm:447-491)
const VIEW_HALF_WIDTH_V: float = 8.0  # |PlayerX - EnemyX| < 8 para UP / DOWN
const VIEW_HALF_HEIGHT_H: float = 6.0 # |PlayerY - EnemyY| < 6 para LEFT / RIGHT
const MAX_VIEW_DISTANCE: float = 160.0 # Alcance máximo do feixe visual (20 tiles)

var guard_type: GuardType = GuardType.MEDIUM
var speed: float = 1.0
var state: GuardState = GuardState.PATROL
var current_direction: PlayerController.Direction = PlayerController.Direction.RIGHT

var waypoints: Array[Vector2] = []
var current_waypoint_idx: int = 0
var waypoint_reverse: bool = false

var is_alert: bool = false
var alert_timer: float = 0.0
var show_debug_vision: bool = false

var anim_tick: int = 0
var anim_frame: int = 0

func _ready() -> void:
	z_index = 8
	match guard_type:
		GuardType.SLOW:
			speed = 0.5
		GuardType.MEDIUM:
			speed = 1.0
		GuardType.FAST:
			speed = 1.5

func set_patrol_path(points: Array[Vector2]) -> void:
	waypoints = points
	current_waypoint_idx = 0
	waypoint_reverse = false
	if not waypoints.is_empty():
		_update_direction_to_target(waypoints[0])

func step_tick(collision_grid: Array, player_pos: Vector2) -> void:
	if is_alert:
		alert_timer = maxf(0.0, alert_timer - 1.0)

	# 1. Movimentação ao longo da rota de patrulha
	if not waypoints.is_empty() and state == GuardState.PATROL:
		_follow_patrol_path()

	# 2. Amostragem da linha de visão até Snake
	var sees_player: bool = check_line_of_sight(player_pos, collision_grid)
	if sees_player and not is_alert:
		trigger_alert()

	queue_redraw()

func _follow_patrol_path() -> void:
	var target: Vector2 = waypoints[current_waypoint_idx]
	var diff: Vector2 = target - position

	# Determinar eixo prioritário de avanço
	if absf(diff.x) > 0.5:
		var step_x: float = signf(diff.x) * minf(speed, absf(diff.x))
		position.x += step_x
		current_direction = PlayerController.Direction.RIGHT if step_x > 0 else PlayerController.Direction.LEFT
	elif absf(diff.y) > 0.5:
		var step_y: float = signf(diff.y) * minf(speed, absf(diff.y))
		position.y += step_y
		current_direction = PlayerController.Direction.DOWN if step_y > 0 else PlayerController.Direction.UP
	else:
		# Atingiu o waypoint atual: avançar para o próximo
		position = target
		_advance_waypoint()

	anim_tick += 1
	if anim_tick >= 8:
		anim_tick = 0
		anim_frame = 1 if anim_frame == 0 else 0

func _advance_waypoint() -> void:
	if waypoints.size() <= 1:
		return

	# Se rota tem apenas 2 pontos, vai e volta (estilo vai-e-vem)
	if waypoints.size() == 2:
		current_waypoint_idx = 1 if current_waypoint_idx == 0 else 0
	else:
		# Ciclo contínuo de rota
		current_waypoint_idx = (current_waypoint_idx + 1) % waypoints.size()

	_update_direction_to_target(waypoints[current_waypoint_idx])

func _update_direction_to_target(target: Vector2) -> void:
	var diff: Vector2 = target - position
	if absf(diff.x) >= absf(diff.y):
		if diff.x > 0:
			current_direction = PlayerController.Direction.RIGHT
		elif diff.x < 0:
			current_direction = PlayerController.Direction.LEFT
	else:
		if diff.y > 0:
			current_direction = PlayerController.Direction.DOWN
		elif diff.y < 0:
			current_direction = PlayerController.Direction.UP

## Verifica linha de visão com tolerâncias e bloqueio por obstáculos fiéis à ROM (chkdiscover.asm)
func check_line_of_sight(player_pos: Vector2, collision_grid: Array) -> bool:
	var diff: Vector2 = player_pos - position

	match current_direction:
		PlayerController.Direction.UP:
			if diff.y >= 0.0 or absf(diff.y) > MAX_VIEW_DISTANCE:
				return false
			if absf(diff.x) > VIEW_HALF_WIDTH_V:
				return false
			return _is_path_clear_of_obstacles(position, player_pos, collision_grid)

		PlayerController.Direction.DOWN:
			if diff.y <= 0.0 or diff.y > MAX_VIEW_DISTANCE:
				return false
			if absf(diff.x) > VIEW_HALF_WIDTH_V:
				return false
			return _is_path_clear_of_obstacles(position, player_pos, collision_grid)

		PlayerController.Direction.LEFT:
			if diff.x >= 0.0 or absf(diff.x) > MAX_VIEW_DISTANCE:
				return false
			if absf(diff.y) > VIEW_HALF_HEIGHT_H:
				return false
			return _is_path_clear_of_obstacles(position, player_pos, collision_grid)

		PlayerController.Direction.RIGHT:
			if diff.x <= 0.0 or diff.x > MAX_VIEW_DISTANCE:
				return false
			if absf(diff.y) > VIEW_HALF_HEIGHT_H:
				return false
			return _is_path_clear_of_obstacles(position, player_pos, collision_grid)

	return false

## Amostragem de tiles de 8x8 pixels entre guarda e Snake (ChkViewObstacles em chkdiscover.asm:212)
func _is_path_clear_of_obstacles(start_pos: Vector2, end_pos: Vector2, collision_grid: Array) -> bool:
	if collision_grid.is_empty():
		return true

	var dist: float = start_pos.distance_to(end_pos)
	var steps: int = int(dist / 8.0)
	var step_vec: Vector2 = (end_pos - start_pos).normalized() * 8.0

	var sample: Vector2 = start_pos
	for s: int in range(steps):
		sample += step_vec
		var tx: int = int(sample.x) / 8
		var ty: int = int(sample.y) / 8
		if tx >= 0 and tx < 32 and ty >= 0 and ty < 24:
			var idx: int = ty * 32 + tx
			if idx < collision_grid.size() and int(collision_grid[idx]) == 1:
				return false # Bloqueado por obstáculo sólido (caixa/parede)

	return true

func trigger_alert() -> void:
	is_alert = true
	alert_timer = 60.0 # 60 ticks de alerta
	state = GuardState.ALERT
	print("GUARD_ALERT: Soldado detectou Snake na posição %s!" % position)

func _draw() -> void:
	# Corpo do soldado inimigo (16x16)
	var body_rect := Rect2(-8, -12, 16, 16)
	var suit_color := Color("485068")   # Azul acinzentado do exército de Outer Heaven
	var helmet_color := Color("283040") # Capacete escuro
	var skin_color := Color("d89870")   # Rosto visível
	var shadow_color := Color("182028")

	draw_rect(body_rect, suit_color)
	draw_rect(Rect2(-8, -12, 16, 4), helmet_color) # Capacete
	draw_rect(Rect2(-5, -7, 10, 3), skin_color)    # Rosto

	# Visão / Arma na direção do guarda
	match current_direction:
		PlayerController.Direction.UP:
			draw_rect(Rect2(-6, -12, 12, 5), helmet_color) # Costas do capacete
		PlayerController.Direction.DOWN:
			draw_rect(Rect2(-4, -6, 2, 2), Color.BLACK)
			draw_rect(Rect2(2, -6, 2, 2), Color.BLACK)
			draw_rect(Rect2(2, -2, 3, 6), shadow_color) # Rifle voltado para baixo
		PlayerController.Direction.LEFT:
			draw_rect(Rect2(-6, -6, 2, 2), Color.BLACK)
			draw_rect(Rect2(-12, -2, 6, 3), shadow_color) # Rifle à esquerda
		PlayerController.Direction.RIGHT:
			draw_rect(Rect2(4, -6, 2, 2), Color.BLACK)
			draw_rect(Rect2(6, -2, 6, 3), shadow_color) # Rifle à direita

	# Pés animados
	var leg_l := Rect2(-6, 2, 4, 3)
	var leg_r := Rect2(2, 2, 4, 3)
	if anim_frame == 1:
		leg_l.position.y += 1
		leg_r.position.y -= 1
	draw_rect(leg_l, shadow_color)
	draw_rect(leg_r, shadow_color)

	# Ponto de Exclamação (!) clássico do Metal Gear quando em alerta
	if is_alert:
		# Balão vermelho
		draw_circle(Vector2(0, -22), 6.0, Color("c82020"))
		# Linha superior da exclamação
		draw_rect(Rect2(-1, -26, 2, 5), Color.WHITE)
		# Ponto inferior da exclamação
		draw_rect(Rect2(-1, -19, 2, 2), Color.WHITE)

	# Visualização de depuração do cone de visão
	if show_debug_vision:
		var beam_color := Color(1.0, 1.0, 0.2, 0.25) if not is_alert else Color(1.0, 0.2, 0.2, 0.35)
		match current_direction:
			PlayerController.Direction.UP:
				draw_rect(Rect2(-VIEW_HALF_WIDTH_V, -MAX_VIEW_DISTANCE, VIEW_HALF_WIDTH_V * 2.0, MAX_VIEW_DISTANCE), beam_color)
			PlayerController.Direction.DOWN:
				draw_rect(Rect2(-VIEW_HALF_WIDTH_V, 0.0, VIEW_HALF_WIDTH_V * 2.0, MAX_VIEW_DISTANCE), beam_color)
			PlayerController.Direction.LEFT:
				draw_rect(Rect2(-MAX_VIEW_DISTANCE, -VIEW_HALF_HEIGHT_H, MAX_VIEW_DISTANCE, VIEW_HALF_HEIGHT_H * 2.0), beam_color)
			PlayerController.Direction.RIGHT:
				draw_rect(Rect2(0.0, -VIEW_HALF_HEIGHT_H, MAX_VIEW_DISTANCE, VIEW_HALF_HEIGHT_H * 2.0), beam_color)
