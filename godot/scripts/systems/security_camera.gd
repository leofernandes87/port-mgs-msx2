class_name SecurityCamera
extends Node2D

## Câmera de Vigilância autêntica do Metal Gear MSX2 RC750 (ID_CAMERA = 6).
## Lógica revertida de:
## - logic/actors/camera.asm (InitCamera, CamameraMove, CamAlertAnim, RoomCamTypes, CameraDrawOffsets)
## - logic/actors/chkdiscover.asm (ChkSeePlayer, ChkLookUp/Down/Left/Right, ChkViewObstacles)
## - Banks0123.asm:6409 (InitCamera) e Enums.asm:175 (ID_CAMERA = 6)

enum Direction {
	UP = 0,
	DOWN = 1,
	LEFT = 2,
	RIGHT = 3
}

## Mapeamento canônico da ROM (RoomCamTypes / CamDirs em camera.asm:93-121)
## 0=Up, 1=Down, 2=Left, 3=Right
const ROOM_CAM_DIRS: Dictionary = {
	14: [Direction.RIGHT, Direction.LEFT, Direction.LEFT],  # CamDirs7: 3, 2, 2
	21: [Direction.DOWN],                                  # CamDirs6: 1
	27: [Direction.UP, Direction.RIGHT],                   # CamDirs4: 0, 3
	28: [Direction.RIGHT],                                 # CamDirs5: 3
	31: [Direction.RIGHT, Direction.UP],                   # CamDirs3: 3, 0
	36: [Direction.DOWN, Direction.DOWN],                  # CamDirs2: 1, 1
	110: [Direction.DOWN, Direction.DOWN],                 # CamDirs2: 1, 1
	111: [Direction.DOWN, Direction.DOWN],                 # CamDirs1: 1, 1
	115: [Direction.DOWN, Direction.DOWN],                 # CamDirs1: 1, 1
	118: [Direction.DOWN, Direction.DOWN],                 # CamDirs1: 1, 1
	149: [Direction.DOWN, Direction.DOWN],                 # CamDirs1: 1, 1
}

## CameraDrawOffsets (camera.asm:234-238)
## Offset em pixels para a posição focal da lente/sensor
const CAMERA_DRAW_OFFSETS: Dictionary = {
	Direction.UP: Vector2(0.0, -12.0),
	Direction.DOWN: Vector2(0.0, 43.0),
	Direction.LEFT: Vector2(-17.0, 0.0),
	Direction.RIGHT: Vector2(16.0, 0.0),
}

signal player_detected(camera: SecurityCamera)

var room_id: int = 0
# Velocidade canônica de 0.5 px/frame (logic/actors/camera.asm:145-186) -> 0.5 * 60 = 30 px/s
const SPEED_PX_PER_SEC: float = 30.0
const WAIT_DURATION_SEC: float = 60.0 / 60.0 # 1.000s de pausa (SetCamRndWait em camera.asm:241-248)
const ALERT_DURATION_SEC: float = 32.0 / 60.0 # 0.5333s de alarme (Wait = 20h em camera.asm:174)

var camera_index: int = 0
var facing_direction: int = Direction.DOWN
var patrol_waypoints: Array[Vector2] = []
var waypoint_target_idx: int = 0
var speed: float = 0.5
var is_moving: bool = true

var wait_timer_sec: float = 0.0
var wait_timer: int:
	get:
		return int(ceil(wait_timer_sec * 60.0 - 0.0001))
	set(v):
		wait_timer_sec = float(v) / 60.0

var alert_flashing: bool = false
var alert_timer_sec: float = 0.0
var alert_timer: int:
	get:
		return int(ceil(alert_timer_sec * 60.0 - 0.0001))
	set(v):
		alert_timer_sec = float(v) / 60.0

var has_seen_player: bool = false
var show_debug_vision: bool = false

func setup(p_room_id: int, p_camera_index: int, p_waypoints: Array[Vector2], p_initial_pos: Vector2) -> void:
	room_id = p_room_id
	camera_index = p_camera_index
	position = p_initial_pos

	var dirs: Array = ROOM_CAM_DIRS.get(room_id, [])
	if camera_index >= 0 and camera_index < dirs.size():
		facing_direction = int(dirs[camera_index])
	else:
		facing_direction = Direction.DOWN

	patrol_waypoints = p_waypoints
	if patrol_waypoints.size() >= 2:
		# Define o próximo waypoint
		var d0: float = position.distance_squared_to(patrol_waypoints[0])
		var d1: float = position.distance_squared_to(patrol_waypoints[1])
		waypoint_target_idx = 1 if d0 < d1 else 0
	else:
		is_moving = false

	queue_redraw()

func tick(player_pos: Vector2, collision_grid: Array, is_box_idle: bool = false, in_alert_mode: bool = false, delta_time: float = 1.0 / 60.0) -> void:
	# No MSX2, durante o modo de alerta as câmeras param de se mover (camera.asm:146-148)
	if in_alert_mode and not alert_flashing:
		is_moving = false
		queue_redraw()
		return

	# Animação de alarme (piscar vermelho por 32 frames / ~0.533s)
	if alert_flashing:
		alert_timer_sec = maxf(0.0, alert_timer_sec - delta_time)
		queue_redraw()
		if alert_timer_sec <= 0.0001:
			alert_timer_sec = 0.0
			alert_flashing = false
		return

	# Checagem de visão contra Snake
	if not has_seen_player and check_vision(player_pos, collision_grid, is_box_idle):
		has_seen_player = true
		is_moving = false
		alert_flashing = true
		alert_timer_sec = ALERT_DURATION_SEC
		player_detected.emit(self)
		queue_redraw()
		return

	# Movimento de patrulha ao longo do trilho/waypoints
	if not is_moving:
		wait_timer_sec = maxf(0.0, wait_timer_sec - delta_time)
		if wait_timer_sec <= 0.0001:
			wait_timer_sec = 0.0
			is_moving = true
		return

	if patrol_waypoints.size() >= 2:
		var target: Vector2 = patrol_waypoints[waypoint_target_idx]
		var diff: Vector2 = target - position
		var dist: float = diff.length()
		var step_dist: float = (speed * 60.0) * delta_time

		if dist <= step_dist:
			position = target
			is_moving = false
			wait_timer_sec = WAIT_DURATION_SEC # Pausa no final do trilho antes de retornar (1.0s a 60 FPS)
			waypoint_target_idx = (waypoint_target_idx + 1) % patrol_waypoints.size()
		else:
			position += diff.normalized() * step_dist

	queue_redraw()

func check_vision(player_pos: Vector2, collision_grid: Array, is_box_idle: bool) -> bool:
	if is_box_idle:
		# Snake na caixa de papelão imóvel não é detectado (chkdiscover.asm:30-48)
		return false

	var focus_offset: Vector2 = CAMERA_DRAW_OFFSETS.get(facing_direction, Vector2.ZERO)
	var focus_pt: Vector2 = position + focus_offset

	# Tolerância perpendicular autêntica da ROM: 8 pixels (ChkViewVertical/Horizontal)
	var in_view_range: bool = false
	var ray_dir: Vector2 = Vector2.ZERO

	match facing_direction:
		Direction.UP:
			if player_pos.y < focus_pt.y and absf(player_pos.x - focus_pt.x) <= 8.0:
				in_view_range = true
				ray_dir = Vector2.UP
		Direction.DOWN:
			if player_pos.y > focus_pt.y and absf(player_pos.x - focus_pt.x) <= 8.0:
				in_view_range = true
				ray_dir = Vector2.DOWN
		Direction.LEFT:
			if player_pos.x < focus_pt.x and absf(player_pos.y - focus_pt.y) <= 8.0:
				in_view_range = true
				ray_dir = Vector2.LEFT
		Direction.RIGHT:
			if player_pos.x > focus_pt.x and absf(player_pos.y - focus_pt.y) <= 8.0:
				in_view_range = true
				ray_dir = Vector2.RIGHT

	if not in_view_range:
		return false

	# Teste de oclusão por obstáculos sólidos da grade de colisão (ChkViewObstacles)
	if not collision_grid.is_empty():
		var total_dist: float = (player_pos - focus_pt).length()
		var step_size: float = 8.0
		var steps: int = int(total_dist / step_size)

		for i in range(1, steps):
			var sample_pt: Vector2 = focus_pt + ray_dir * (float(i) * step_size)
			var tile_x: int = int(sample_pt.x / 8.0)
			var tile_y: int = int(sample_pt.y / 8.0)

			if tile_x >= 0 and tile_x < 32 and tile_y >= 0 and tile_y < 24:
				var idx: int = tile_y * 32 + tile_x
				if idx < collision_grid.size() and int(collision_grid[idx]) != 0:
					# Obstáculo sólido bloqueia a visão da câmera!
					return false

	return true

func _draw() -> void:
	# Suporte metálico de fixação na parede/trilho
	draw_rect(Rect2(-6, -6, 12, 12), Color("283038"))
	draw_rect(Rect2(-5, -5, 10, 10), Color("404850"))

	# Corpo da cúpula/câmera
	draw_circle(Vector2.ZERO, 5.0, Color("506068"))
	draw_circle(Vector2.ZERO, 3.5, Color("303840"))

	# Lente apontando na direção ativa
	var lens_vec: Vector2 = Vector2.ZERO
	match facing_direction:
		Direction.UP: lens_vec = Vector2(0, -5)
		Direction.DOWN: lens_vec = Vector2(0, 5)
		Direction.LEFT: lens_vec = Vector2(-5, 0)
		Direction.RIGHT: lens_vec = Vector2(5, 0)

	draw_circle(lens_vec, 2.0, Color("102030"))

	# LED indicador de vigilância / alarme
	var led_color: Color = Color("20e040") # Verde vigilância
	if alert_flashing:
		# Pisca vermelho a cada 4 ticks (camera.asm:206-210)
		var is_red: bool = ((alert_timer / 4) % 2) == 1
		led_color = Color("ff2020") if is_red else Color("404850")
	elif has_seen_player:
		led_color = Color("ff2020")

	draw_circle(Vector2(0, 0), 1.5, led_color)

	# Linha de visão de debug se ativada
	if show_debug_vision:
		var focus_offset: Vector2 = CAMERA_DRAW_OFFSETS.get(facing_direction, Vector2.ZERO)
		var line_color: Color = Color(1.0, 0.2, 0.2, 0.6) if has_seen_player else Color(0.2, 0.8, 1.0, 0.4)
		draw_line(Vector2.ZERO, focus_offset, line_color, 1.0)
		draw_circle(focus_offset, 3.0, line_color)
