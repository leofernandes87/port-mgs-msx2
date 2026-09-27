class_name EnemyGuard
extends Node2D

## Soldado inimigo fiel à física, rotas de patrulha, linha de visão e combate MSX2 RC750 (Etapas 7 e 8).
## Lógica revertida de logic/actors/chkdiscover.asm, data/paths.asm, logic/actors/guardalert.asm e logic/punchenemy.asm.

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

# Sistema de Combate e Dano MSX2 RC750 (Etapa 8)
var punches_received: int = 0 # Guarda morre após 3 socos (Banks0123.asm:12819)
var stunned_timer: int = 0    # 64 ticks (0x40) de atordoamento ao levar soco (Banks0123.asm:12822)
var is_dead: bool = false
var touch_damage: int = 2     # ActorTouchDamage para ID_GUARD_SLOW e MEDIUM = 2 (data/shapes.asm:36)

var guard_type: GuardType = GuardType.MEDIUM
var actor_type_id: int = 5
var speed: float = 1.0
var state: GuardState = GuardState.PATROL
var current_direction: PlayerController.Direction = PlayerController.Direction.RIGHT
var is_shooter: bool = false
var shoot_cooldown: int = 0

var waypoints: Array[Vector2] = []
var current_waypoint_idx: int = 0
var waypoint_reverse: bool = false

var is_alert: bool = false
var alert_timer: float = 0.0
var show_debug_vision: bool = false

var is_lorry_guard: bool = false
var lorry_timer: int = 0
var wait_ticks: int = 0

var anim_tick: int = 0
var anim_frame: int = 0

func _ready() -> void:
	z_index = 8
	match guard_type:
		GuardType.SLOW:
			speed = 0.4
		GuardType.MEDIUM:
			speed = 0.7
		GuardType.FAST:
			speed = 1.0

	if actor_type_id in [10, 11]:
		# Soldados de alerta da ROM (ID_GUARD_ALERT e ID_GUARD_REDALERT)
		speed = 1.0
		state = GuardState.ALERT
		is_alert = true
		if actor_type_id == 11:
			is_shooter = true

	if actor_type_id in [13, 57]:
		is_shooter = true

	if actor_type_id == 19:
		# GuardLorry: começa escondido dentro do caminhão por alguns segundos (MSX behaviour)
		is_lorry_guard = true
		lorry_timer = 150 # 2.5 segundos a 60 fps
		visible = false

func set_patrol_path(points: Array[Vector2]) -> void:
	waypoints = points
	current_waypoint_idx = 0
	waypoint_reverse = false
	if not waypoints.is_empty():
		_update_direction_to_target(waypoints[0])

## Verifica se o inimigo foi atingido por um soco de Snake (logic/punchenemy.asm:29-87)
## Utiliza as distâncias e raios exatos das tabelas PunchUpDat, PunchDownDat, PunchLeftDat, PunchRightDat
func check_punched(player_pos: Vector2, player_dir: PlayerController.Direction) -> bool:
	if is_dead:
		return false

	var offset_y: float = 0.0
	var offset_x: float = 0.0
	var radius_y: float = 12.0
	var radius_x: float = 12.0

	match player_dir:
		PlayerController.Direction.UP:
			offset_y = 12.0
		PlayerController.Direction.DOWN:
			offset_y = -12.0
		PlayerController.Direction.LEFT:
			offset_x = 12.0
		PlayerController.Direction.RIGHT:
			offset_x = -12.0

	var diff_y: float = absf(position.y + offset_y - player_pos.y)
	var diff_x: float = absf(position.x + offset_x - player_pos.x)

	return diff_y < radius_y and diff_x < radius_x

func receive_punch() -> void:
	if is_dead or stunned_timer > 0:
		return
	punches_received += 1
	stunned_timer = 64
	state = GuardState.ALERT
	is_alert = true
	if punches_received >= 3:
		is_dead = true
		print("GUARD_KILLED: Guarda derrotado por socos na posição %s!" % position)
	else:
		print("GUARD_HIT: Guarda atingido (%d/3) - atordoado por 64 ticks!" % punches_received)
	queue_redraw()

## Verifica colisão entre projétil e o bounding box do guarda (logic/damagetoenemy.asm:108-132)
func check_bullet_hit(bullet_pos: Vector2) -> bool:
	if is_dead:
		return false
	var diff_x: float = absf(position.x - bullet_pos.x)
	var diff_y: float = absf(position.y - bullet_pos.y)
	return diff_x <= 8.0 and diff_y <= 10.0

## Aplica dano balístico (data/weapondamage.asm:18 / logic/damagetoenemy.asm:216)
## No MSX2, dano de bala a soldados é 2, resultando em eliminação com 1 único tiro
func take_bullet_hit(bullet_damage: int = 2) -> bool:
	if is_dead:
		return false
	is_dead = true
	print("GUARD_KILLED_BY_BULLET: Guarda eliminado por disparo na posição %s!" % position)
	queue_redraw()
	return true

## Disparo inimigo para atiradores (ID 13, 57) ou guardas em alerta (logic/actors/shooter.asm e guardalert.asm)
func try_shoot(player_pos: Vector2) -> Bullet:
	if is_dead or stunned_timer > 0:
		return null

	if shoot_cooldown > 0:
		shoot_cooldown -= 1
		return null

	# Dispara se for atirador nativo ou se estiver em modo de alerta perseguindo
	if is_shooter or (state == GuardState.ALERT and is_alert):
		shoot_cooldown = 48 # Cadência de ~48 ticks (aprox. 0.8s)
		var b: Bullet = Bullet.new()
		b.position = Vector2(position.x, position.y - 6.0)
		b.direction = current_direction
		b.speed = 2.0
		b.ticks_remaining = 48
		b.damage = 2
		b.is_enemy = true
		return b

	return null

func step_tick(collision_grid: Array, player_pos: Vector2, is_punching: bool = false, player_dir: PlayerController.Direction = PlayerController.Direction.DOWN, player: PlayerController = null) -> void:
	if is_dead:
		queue_redraw()
		return

	if is_lorry_guard and lorry_timer > 0:
		lorry_timer -= 1
		if lorry_timer <= 0:
			visible = true
		return

	# 1. Se Snake estiver socando, verificar se acerta este guarda
	if is_punching:
		if check_punched(player_pos, player_dir):
			receive_punch()
			return

	# 2. Se o guarda estiver atordoado, decrementa o contador e não age
	if stunned_timer > 0:
		stunned_timer -= 1
		queue_redraw()
		return

	if is_alert:
		alert_timer = maxf(0.0, alert_timer - 1.0)

	# 3. Movimentação (Perseguição em ALERTA ou Patrulha de Waypoints)
	if state == GuardState.ALERT:
		_chase_player(player_pos, collision_grid)
	elif not waypoints.is_empty() and state == GuardState.PATROL:
		_follow_patrol_path(collision_grid)

	# 4. Amostragem da linha de visão até Snake
	var sees_player: bool = check_line_of_sight(player_pos, collision_grid)
	
	# Mecânica da Caixa de Papelão (Stealth)
	# Se Snake está na caixa e PARADO, os guardas não conseguem vê-lo!
	if player != null and player.is_in_box and not player.is_moving:
		sees_player = false

	if sees_player and not is_alert:
		trigger_alert()

	# 5. Dano por contato físico com Snake (logic/touchenemy.asm:137 / data/shapes.asm:36)
	var touch_dist: float = position.distance_to(player_pos)
	if touch_dist <= 12.0 and player != null:
		player.apply_damage(touch_damage)

	queue_redraw()

## Perseguição do soldado em alerta em direção ao Snake (logic/actors/guardalert.asm:42 GetDirToPlayer)
func _chase_player(target_pos: Vector2, collision_grid: Array) -> void:
	var diff: Vector2 = target_pos - position
	if diff.length() <= 4.0:
		return

	var step_vec := Vector2.ZERO
	if absf(diff.x) >= absf(diff.y):
		var step_x: float = signf(diff.x) * minf(speed, absf(diff.x))
		step_vec.x = step_x
		current_direction = PlayerController.Direction.RIGHT if step_x > 0 else PlayerController.Direction.LEFT
	else:
		var step_y: float = signf(diff.y) * minf(speed, absf(diff.y))
		step_vec.y = step_y
		current_direction = PlayerController.Direction.DOWN if step_y > 0 else PlayerController.Direction.UP

	var next_pos: Vector2 = position + step_vec
	if not _is_colliding_grid(next_pos, collision_grid):
		position = next_pos
	else:
		# Tentar contorno pelo eixo alternativo
		if step_vec.x != 0.0 and absf(diff.y) > 0.5:
			var alt_y: float = signf(diff.y) * minf(speed, absf(diff.y))
			if not _is_colliding_grid(position + Vector2(0.0, alt_y), collision_grid):
				position.y += alt_y
				current_direction = PlayerController.Direction.DOWN if alt_y > 0 else PlayerController.Direction.UP
		elif step_vec.y != 0.0 and absf(diff.x) > 0.5:
			var alt_x: float = signf(diff.x) * minf(speed, absf(diff.x))
			if not _is_colliding_grid(position + Vector2(alt_x, 0.0), collision_grid):
				position.x += alt_x
				current_direction = PlayerController.Direction.RIGHT if alt_x > 0 else PlayerController.Direction.LEFT

	anim_tick += 1
	if anim_tick >= 12:
		anim_tick = 0
		anim_frame = 1 if anim_frame == 0 else 0

func _is_colliding_grid(test_pos: Vector2, collision_grid: Array) -> bool:
	if collision_grid.is_empty():
		return false
	# Amostragem de bounding box (10x10 px ao redor da posição central)
	var half_w: float = 5.0
	var half_h: float = 5.0
	var check_points: Array[Vector2] = [
		test_pos + Vector2(-half_w, -half_h),
		test_pos + Vector2(half_w, -half_h),
		test_pos + Vector2(-half_w, half_h),
		test_pos + Vector2(half_w, half_h)
	]
	for pt: Vector2 in check_points:
		var tx: int = int(pt.x) / 8
		var ty: int = int(pt.y) / 8
		if tx < 0 or tx >= 32 or ty < 0 or ty >= 24:
			return true
		var idx: int = ty * 32 + tx
		if idx >= 0 and idx < collision_grid.size() and int(collision_grid[idx]) == 1:
			return true
	return false

func _follow_patrol_path(collision_grid: Array = []) -> void:
	if waypoints.is_empty():
		return

	if wait_ticks > 0:
		wait_ticks -= 1
		return

	var target: Vector2 = waypoints[current_waypoint_idx]
	var diff: Vector2 = target - position

	# Determinar eixo prioritário de avanço
	if absf(diff.x) > 0.5:
		var step_x: float = signf(diff.x) * minf(speed, absf(diff.x))
		var new_pos := Vector2(position.x + step_x, position.y)
		if not _is_colliding_grid(new_pos, collision_grid):
			position.x += step_x
		else:
			_advance_waypoint()
		current_direction = PlayerController.Direction.RIGHT if step_x > 0 else PlayerController.Direction.LEFT
	elif absf(diff.y) > 0.5:
		var step_y: float = signf(diff.y) * minf(speed, absf(diff.y))
		var new_pos := Vector2(position.x, position.y + step_y)
		if not _is_colliding_grid(new_pos, collision_grid):
			position.y += step_y
		else:
			_advance_waypoint()
		current_direction = PlayerController.Direction.DOWN if step_y > 0 else PlayerController.Direction.UP
	else:
		# Atingiu o waypoint atual: avançar para o próximo
		position = target
		_advance_waypoint()

	anim_tick += 1
	if anim_tick >= 16:
		anim_tick = 0
		anim_frame = 1 if anim_frame == 0 else 0

func _advance_waypoint() -> void:
	if waypoints.size() <= 1:
		return

	# Lógica Canônica MSX (Banks0123.asm:7120 - ChkWaitPathPoint e guard.asm - GuardPatrolTurn)
	# 1. 50% de chance de NÃO parar e continuar patrulhando imediatamente.
	if guard_type in [GuardType.SLOW, GuardType.MEDIUM] and randf() <= 0.5:
		# 2. Se decidir parar, ele aguarda um pouco (16 frames de espera na direção do movimento)
		# 3. Depois, ele vira a cabeça em 90 graus (eixo perpendicular)
		# 4. Aguarda mais 16 frames olhando e depois volta a andar.
		wait_ticks = 32 # 0.5s de parada total
		
		# Pega eixo atual e vira perpendicular
		var rand_perpendicular := randf() > 0.5
		match current_direction:
			PlayerController.Direction.LEFT, PlayerController.Direction.RIGHT:
				current_direction = PlayerController.Direction.DOWN if rand_perpendicular else PlayerController.Direction.UP
			PlayerController.Direction.UP, PlayerController.Direction.DOWN:
				current_direction = PlayerController.Direction.LEFT if rand_perpendicular else PlayerController.Direction.RIGHT

	# Se rota tem apenas 2 pontos, vai e volta (estilo vai-e-vem)
	if waypoints.size() == 2:
		current_waypoint_idx = 1 if current_waypoint_idx == 0 else 0
	else:
		# Ciclo contínuo de rota
		current_waypoint_idx = (current_waypoint_idx + 1) % waypoints.size()

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
	if is_dead:
		return false

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
	if is_dead:
		return
	is_alert = true
	alert_timer = 60.0 # 60 ticks de alerta
	state = GuardState.ALERT
	print("GUARD_ALERT: Soldado detectou Snake na posição %s!" % position)

## Transforma guarda regular em soldado de alerta (TransformAlertGuard em Banks0123.asm:6726)
func transform_to_alert_guard() -> void:
	if is_dead:
		return
	is_alert = true
	state = GuardState.ALERT
	speed = 1.5 # SetWalkSpeedFast
	alert_timer = 60.0
	queue_redraw()

## Restaura soldado ao estado de patrulha pacífica
func reset_to_patrol() -> void:
	if is_dead:
		return
	is_alert = false
	state = GuardState.PATROL
	match guard_type:
		GuardType.SLOW:
			speed = 0.5
		GuardType.MEDIUM:
			speed = 1.0
		GuardType.FAST:
			speed = 1.5
	queue_redraw()

func _draw() -> void:
	# Se derrotado, desenha silhueta caída no chão
	if is_dead:
		var dead_rect := Rect2(-8, -4, 16, 8)
		draw_rect(dead_rect, Color("202830"))
		draw_rect(Rect2(-6, -3, 12, 6), Color("384050"))
		return

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

	# Indicador de atordoamento (estrelas/pontos girando sobre a cabeça)
	if stunned_timer > 0:
		var st_phase: int = (stunned_timer / 8) % 4
		var offsets := [Vector2(-6, -16), Vector2(0, -18), Vector2(6, -16), Vector2(0, -14)]
		for i: int in range(3):
			var pt: Vector2 = offsets[(st_phase + i) % 4]
			draw_circle(pt, 1.5, Color.YELLOW)

	# Ponto de Exclamação (!) clássico do Metal Gear quando em alerta
	if is_alert and stunned_timer <= 0:
		# Balão vermelho
		draw_circle(Vector2(0, -22), 6.0, Color("c82020"))
		# Linha superior da exclamação
		draw_rect(Rect2(-1, -26, 2, 5), Color.WHITE)
		# Ponto inferior da exclamação
		draw_rect(Rect2(-1, -19, 2, 2), Color.WHITE)

	# Visualização de depuração do cone de visão
	if show_debug_vision and stunned_timer <= 0:
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
