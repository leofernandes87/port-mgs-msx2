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
var shoot_flash_timer: int = 0 # Clarão de disparo na ponta do fuzil

var waypoints: Array[Vector2] = []
var current_waypoint_idx: int = 0
var waypoint_reverse: bool = false

var is_alert: bool = false
var alert_timer: float = 0.0
var show_debug_vision: bool = false

# GuardAlert (ID 10, 11 - logic/actors/guardalert.asm)
enum AlertSubstate {
	CHASE = 0,          # GuardWalk (Status 0): persegue Snake
	WAIT_SHOT = 1,      # GuardWaitShot (Status 1): mira em Snake e aguarda disparo
	AVOID_OBSTACLE = 2, # GuardAvoidObstacle (Status 2): desvia de obstáculos do cenário
	WALK_AWAY = 3       # GuardWalkAwayShot (Status 3): recua/afasta-se para escaramuça
}
var alert_substate: AlertSubstate = AlertSubstate.CHASE
var alert_counter: int = 24
var walk_away_dir: PlayerController.Direction = PlayerController.Direction.DOWN

var is_lorry_guard: bool = false
var lorry_timer: int = 0
var is_exiting_lorry: bool = false
var is_entering_lorry: bool = false
var lorry_anim_pixels: float = 0.0
var lorry_id: int = 0
var wait_ticks: int = 0

var anim_tick: int = 0
var anim_frame: int = 0

# GuardElevator (ID 14 - logic/actors/guardelevator.asm)
var is_elevator_guard: bool = false
enum ElevatorGuardState {
	ENTERING = 0,
	IDLE = 1,
	LEAVING = 2
}
var elev_guard_state: ElevatorGuardState = ElevatorGuardState.IDLE
var elev_guard_target_x: float = 80.0
var elev_guard_idle_timer: int = 256
var elev_guard_look_timer: int = 30
var is_relieve_speaker: bool = false

# GuardDog (ID_DOG = 25 - logic/actors/dog.asm)
const DOG_SPEED: float = 1.3
var is_dog: bool = false
enum DogState {
	SLEEP = 0,
	LISTEN = 1,
	CHASE = 2
}
var dog_state: DogState = DogState.SLEEP
var dog_wait_timer: int = 40
var dog_listen_timer: int = 0
var dog_bark_timer: int = 0
var dog_anim_tick: int = 0

signal chow_time_called
signal dog_barked(dog_pos: Vector2)

# SleepyGuard (Rooms 26, 85, 138 - logic/actors/guard.asm:187-260, Banks0123.asm:6815-6844)
var is_sleepy_guard: bool = false
enum SleepyState {
	AWAKE = 0,
	SLEEPING = 1
}
var sleepy_state: SleepyState = SleepyState.AWAKE
var awake_timer: int = 64
var sleep_timer: int = 256
var snore_anim_tick: int = 0

signal sleepy_dialog_called(dialog_text: String)

# Sprites autênticos do MSX2 extraídos de SprGuard e SprDog (RC750)
static var _guard_texture: Texture2D = null
static var _dog_texture: Texture2D = null
static var _checked_textures: bool = false

static func load_enemy_textures() -> void:
	if _checked_textures:
		return
	_checked_textures = true
	var guard_path := "res://assets/protected/sprites/guard_msx.png"
	var abs_guard := ProjectSettings.globalize_path(guard_path)
	if FileAccess.file_exists(abs_guard):
		var img_g := Image.load_from_file(abs_guard)
		if img_g != null and not img_g.is_empty():
			_guard_texture = ImageTexture.create_from_image(img_g)
			print("ENEMY: Spritesheet autêntico MSX2 de Guarda carregado com sucesso! (64x128 px)")

	var dog_path := "res://assets/protected/sprites/dog_msx.png"
	var abs_dog := ProjectSettings.globalize_path(dog_path)
	if FileAccess.file_exists(abs_dog):
		var img_d := Image.load_from_file(abs_dog)
		if img_d != null and not img_d.is_empty():
			_dog_texture = ImageTexture.create_from_image(img_d)
			print("ENEMY: Spritesheet autêntico MSX2 de Cão carregado com sucesso! (128x96 px)")

func _get_guard_sprite_rect() -> Rect2:
	var row: int = 0
	match current_direction:
		PlayerController.Direction.DOWN:
			row = 0
		PlayerController.Direction.UP:
			row = 1
		PlayerController.Direction.RIGHT:
			row = 2
		PlayerController.Direction.LEFT:
			row = 3

	var col: int = 0
	if is_sleepy_guard and sleepy_state == SleepyState.SLEEPING:
		row = 0 # Down
		col = 0 # Stand
	elif wait_ticks > 0 or stunned_timer > 0:
		col = 0 # Stand
	else:
		col = 1 if anim_frame == 0 else 2

	return Rect2(col * 16.0, row * 32.0, 16.0, 32.0)

func _get_dog_sprite_rect() -> Rect2:
	if dog_state == DogState.SLEEP:
		return Rect2(0.0, 2.0 * 32.0, 32.0, 32.0)
	if dog_state == DogState.LISTEN:
		return Rect2(1.0 * 32.0, 2.0 * 32.0, 32.0, 32.0)

	var col: int = 0
	var row: int = 0
	var f: int = anim_frame % 2
	match current_direction:
		PlayerController.Direction.DOWN:
			row = 0
			col = f
		PlayerController.Direction.UP:
			row = 0
			col = 2 + f
		PlayerController.Direction.LEFT:
			row = 1
			col = f
		PlayerController.Direction.RIGHT:
			row = 1
			col = 2 + f

	return Rect2(col * 32.0, row * 32.0, 32.0, 32.0)

func _ready() -> void:
	load_enemy_textures()
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
		lorry_timer = 128 + (randi() % 128) # 2.1 a 4.25 segundos a 60 fps (r | 128)
		visible = false

	if actor_type_id == 14:
		# GuardElevator (ID 14): sentinela da porta do elevador (velocidade guardMedium = 0.7)
		is_elevator_guard = true
		guard_type = GuardType.MEDIUM
		speed = 0.7
		if elev_guard_state == ElevatorGuardState.IDLE:
			current_direction = PlayerController.Direction.DOWN
			if is_zero_approx(elev_guard_target_x):
				elev_guard_target_x = position.x
			elev_guard_idle_timer = 256
			elev_guard_look_timer = 30 + (randi() % 16)

	if actor_type_id in [25, 27]:
		init_dog()

func init_dog() -> void:
	is_dog = true
	actor_type_id = 25
	guard_type = GuardType.FAST
	speed = DOG_SPEED
	touch_damage = 2
	dog_state = DogState.SLEEP
	dog_wait_timer = 32 + (randi() % 4) * 8 # 32..56 ticks (dog.asm:11-17)
	dog_listen_timer = 0
	dog_bark_timer = 0
	dog_anim_tick = 0
	punches_received = 0
	is_dead = false

func init_sleepy_guard(force_awake_timer: int = -1) -> void:
	is_sleepy_guard = true
	sleepy_state = SleepyState.AWAKE
	if force_awake_timer >= 0:
		awake_timer = force_awake_timer
	else:
		# Banks0123.asm:6832-6837: r & 1 == 0 -> 5 ticks; else -> 64 ticks (0x40)
		awake_timer = 5 if (randi() % 2 == 0) else 64
	sleep_timer = 256
	snore_anim_tick = 0

func wake_up_to_chase() -> void:
	if is_dead or not is_dog:
		return
	if dog_state != DogState.CHASE:
		dog_state = DogState.CHASE
		speed = DOG_SPEED
		dog_bark_timer = 12
		dog_barked.emit(position)
		queue_redraw()

func set_patrol_path(points: Array[Vector2]) -> void:
	waypoints = points
	waypoint_reverse = false
	if is_lorry_guard:
		current_direction = PlayerController.Direction.DOWN
		current_waypoint_idx = 1 if waypoints.size() > 1 else 0
	else:
		current_waypoint_idx = 0
		if not waypoints.is_empty():
			_update_direction_to_target(waypoints[0])

## Verifica se o inimigo foi atingido por um soco de Snake (logic/punchenemy.asm:29-87)
## Utiliza as distâncias e raios exatos das tabelas PunchUpDat, PunchDownDat, PunchLeftDat, PunchRightDat
func check_punched(player_pos: Vector2, player_dir: PlayerController.Direction) -> bool:
	if is_dead:
		return false

	var dx: float = position.x - player_pos.x
	var dy: float = position.y - player_pos.y

	match player_dir:
		PlayerController.Direction.UP:
			return dy >= -24.0 and dy <= 4.0 and absf(dx) <= 12.0
		PlayerController.Direction.DOWN:
			return dy >= -4.0 and dy <= 24.0 and absf(dx) <= 12.0
		PlayerController.Direction.LEFT:
			return dx >= -24.0 and dx <= 4.0 and absf(dy) <= 12.0
		PlayerController.Direction.RIGHT:
			return dx >= -4.0 and dx <= 24.0 and absf(dy) <= 12.0

	return false

func receive_punch() -> void:
	if is_dead or stunned_timer > 0:
		return
	punches_received += 1
	stunned_timer = 32 if is_dog else 64
	if is_dog:
		dog_state = DogState.CHASE
		speed = DOG_SPEED
		if punches_received >= 2:
			is_dead = true
			print("DOG_KILLED: Cão derrotado por socos na posição %s!" % position)
		else:
			print("DOG_HIT: Cão atingido (%d/2) - atordoado por 32 ticks!" % punches_received)
		queue_redraw()
		return

	if is_sleepy_guard:
		sleepy_state = SleepyState.AWAKE

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
	if is_dog:
		print("DOG_KILLED_BY_BULLET: Cão eliminado por disparo na posição %s!" % position)
	else:
		print("GUARD_KILLED_BY_BULLET: Guarda eliminado por disparo na posição %s!" % position)
	queue_redraw()
	return true

## Disparo inimigo para atiradores (ID 13, 57) ou guardas em alerta (logic/actors/shooter.asm e guardalert.asm)
func try_shoot(player_pos: Vector2) -> Bullet:
	if is_dead or stunned_timer > 0 or not visible or is_dog:
		return null

	if shoot_cooldown > 0:
		shoot_cooldown -= 1
		return null

	# Dispara se for atirador nativo ou se estiver em modo de alerta perseguindo
	if is_shooter or (state == GuardState.ALERT and is_alert):
		shoot_cooldown = 48 # Cadência de ~48 ticks (aprox. 0.8s)
		shoot_flash_timer = 6
		queue_redraw()
		var b: Bullet = Bullet.new()
		match current_direction:
			PlayerController.Direction.UP:
				b.position = Vector2(position.x, position.y - 26.0)
			PlayerController.Direction.DOWN:
				b.position = Vector2(position.x + 2.0, position.y + 4.0)
			PlayerController.Direction.LEFT:
				b.position = Vector2(position.x - 9.0, position.y - 15.0)
			PlayerController.Direction.RIGHT:
				b.position = Vector2(position.x + 9.0, position.y - 15.0)
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

	if shoot_flash_timer > 0:
		shoot_flash_timer -= 1
		queue_redraw()

	if is_dog:
		if is_punching and check_punched(player_pos, player_dir):
			receive_punch()
			return
		if stunned_timer > 0:
			stunned_timer -= 1
			queue_redraw()
			return
		_step_dog(collision_grid, player_pos, player)
		return

	if is_lorry_guard and lorry_timer > 0:
		lorry_timer -= 1
		if lorry_timer <= 0:
			visible = true
			is_exiting_lorry = true
			lorry_anim_pixels = 16.0
			current_direction = PlayerController.Direction.DOWN
		return

	if is_exiting_lorry:
		position.y += speed
		lorry_anim_pixels -= speed
		if lorry_anim_pixels <= 0.0:
			is_exiting_lorry = false
			if waypoints.size() > 0:
				position.y = waypoints[0].y
			current_waypoint_idx = 1 if waypoints.size() > 1 else 0
			if not waypoints.is_empty():
				_update_direction_to_target(waypoints[current_waypoint_idx])
		queue_redraw()
		return

	if is_entering_lorry:
		position.y -= speed
		lorry_anim_pixels -= speed
		if lorry_anim_pixels <= 0.0:
			is_entering_lorry = false
			visible = false
			lorry_timer = 128 + (randi() % 128)
			current_waypoint_idx = 1 if waypoints.size() > 1 else 0
		queue_redraw()
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

	# 2.5. Processamento canônico de guarda sonolento (logic/actors/guard.asm:187-260)
	if is_sleepy_guard and state == GuardState.PATROL:
		match sleepy_state:
			SleepyState.AWAKE:
				awake_timer -= 1
				if awake_timer <= 0:
					sleepy_state = SleepyState.SLEEPING
					sleep_timer = 256 # guard.asm:205
					current_direction = PlayerController.Direction.DOWN
					sleepy_dialog_called.emit("I'm sleepy...")
					queue_redraw()
			SleepyState.SLEEPING:
				snore_anim_tick += 1
				# Checa toque físico com Snake (ListenShotsChkTouch em chkdiscover.asm:502-535)
				var touch_dist: float = position.distance_to(player_pos)
				if touch_dist <= 12.0:
					sleepy_state = SleepyState.AWAKE
					trigger_alert()
					transform_to_alert_guard()
					if player != null:
						player.apply_damage(touch_damage)
					queue_redraw()
					return

				# Decrementa o tempo de sono (256 ticks per guard.asm:205)
				sleep_timer -= 1
				if sleep_timer <= 0:
					sleepy_state = SleepyState.AWAKE
					awake_timer = 192 # 0C0h ticks canônicos per guard.asm:233
					sleepy_dialog_called.emit("Overslept!")
					if not waypoints.is_empty():
						_update_direction_to_target(waypoints[current_waypoint_idx])

				queue_redraw()
				return # Enquanto dorme, não se desloca e linha de visão fica suprimida

	# 3. Movimentação (Perseguição em ALERTA, Sentinela do Elevador ou Patrulha de Waypoints)
	if state == GuardState.ALERT:
		_chase_player(player_pos, collision_grid)
	elif is_elevator_guard:
		_process_elevator_guard()
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

## Perseguição e escaramuça autêntica do soldado em alerta (logic/actors/guardalert.asm:91-200)
func _chase_player(target_pos: Vector2, collision_grid: Array) -> void:
	var diff: Vector2 = target_pos - position
	var dist: float = diff.length()

	match alert_substate:
		AlertSubstate.CHASE:
			# GuardWalk (Status 0): persegue o jogador ao longo do eixo dominante
			var dir_to_player: PlayerController.Direction
			var step_vec := Vector2.ZERO
			if absf(diff.x) >= absf(diff.y):
				var step_x: float = signf(diff.x) * minf(speed, absf(diff.x))
				step_vec.x = step_x
				dir_to_player = PlayerController.Direction.RIGHT if step_x > 0 else PlayerController.Direction.LEFT
			else:
				var step_y: float = signf(diff.y) * minf(speed, absf(diff.y))
				step_vec.y = step_y
				dir_to_player = PlayerController.Direction.DOWN if step_y > 0 else PlayerController.Direction.UP

			current_direction = dir_to_player

			# Avançar se não colidir com paredes do cenário
			var next_pos: Vector2 = position + step_vec
			if not _is_colliding_grid(next_pos, collision_grid):
				position = next_pos
			else:
				# Tentar desvio pelo eixo alternativo (GuardAvoidObstacle - Status 2)
				var alt_vec := Vector2.ZERO
				if step_vec.x != 0.0 and absf(diff.y) > 0.5:
					alt_vec.y = signf(diff.y) * minf(speed, absf(diff.y))
				elif step_vec.y != 0.0 and absf(diff.x) > 0.5:
					alt_vec.x = signf(diff.x) * minf(speed, absf(diff.x))
				if alt_vec != Vector2.ZERO and not _is_colliding_grid(position + alt_vec, collision_grid):
					position += alt_vec
					if alt_vec.x != 0.0:
						current_direction = PlayerController.Direction.RIGHT if alt_vec.x > 0 else PlayerController.Direction.LEFT
					else:
						current_direction = PlayerController.Direction.DOWN if alt_vec.y > 0 else PlayerController.Direction.UP

			# Decrementar temporizador da marcha
			alert_counter -= 1
			if alert_counter <= 0:
				# ChkNearPlayer (guardalert.asm:124, 464 - limite 36 px):
				# Quando próximo a Snake, o soldado NÃO fica imóvel colado: recua para escaramuça!
				if dist <= 36.0:
					_start_walk_away(target_pos, collision_grid)
				else:
					alert_counter = 20 + (randi() % 16)
					# Sorteio canônico para decidir entre atirar ou continuar marchando (guardalert.asm:148-154)
					if (randi() % 4) == 0:
						_start_wait_shot(target_pos)

		AlertSubstate.WALK_AWAY:
			# GuardWalkAwayShot (Status 3): afasta-se de Snake para manobrar ao redor
			var away_vec: Vector2 = _get_dir_vector(walk_away_dir) * speed
			var next_away: Vector2 = position + away_vec
			if not _is_colliding_grid(next_away, collision_grid):
				position = next_away
				current_direction = walk_away_dir
			else:
				# Parede encontrada ao recuar: tenta eixo ortogonal de desvio
				var alt_away_dir := _get_perpendicular_away_dir(target_pos)
				var alt_away_vec: Vector2 = _get_dir_vector(alt_away_dir) * speed
				if not _is_colliding_grid(position + alt_away_vec, collision_grid):
					position += alt_away_vec
					walk_away_dir = alt_away_dir
					current_direction = alt_away_dir
				else:
					_start_wait_shot(target_pos)
					return

			alert_counter -= 1
			if alert_counter <= 0:
				if dist <= 20.0:
					_start_walk_away(target_pos, collision_grid)
				else:
					# Atingiu distância segura/tática: para, mira e atira! (guardalert.asm:315-316)
					_start_wait_shot(target_pos)

		AlertSubstate.WAIT_SHOT:
			# GuardWaitShot (Status 1): soldado para brevemente, mira em Snake e dispara
			_update_direction_to_target(target_pos)
			alert_counter -= 1
			if alert_counter <= 0:
				# Fim da pausa de tiro: retoma perseguição
				alert_substate = AlertSubstate.CHASE
				alert_counter = 24 + (randi() % 16)

	anim_tick += 1
	if anim_tick >= 12:
		anim_tick = 0
		anim_frame = 1 if anim_frame == 0 else 0

func _start_walk_away(target_pos: Vector2, _collision_grid: Array) -> void:
	alert_substate = AlertSubstate.WALK_AWAY
	alert_counter = 18 + (randi() % 14)
	# Direção oposta canônica (GetOppositePlayer em helperdirections.asm:52)
	var diff: Vector2 = target_pos - position
	if absf(diff.x) >= absf(diff.y):
		walk_away_dir = PlayerController.Direction.LEFT if diff.x > 0 else PlayerController.Direction.RIGHT
	else:
		walk_away_dir = PlayerController.Direction.UP if diff.y > 0 else PlayerController.Direction.DOWN
	current_direction = walk_away_dir

func _get_perpendicular_away_dir(target_pos: Vector2) -> PlayerController.Direction:
	var diff: Vector2 = target_pos - position
	if walk_away_dir in [PlayerController.Direction.LEFT, PlayerController.Direction.RIGHT]:
		return PlayerController.Direction.UP if diff.y >= 0 else PlayerController.Direction.DOWN
	else:
		return PlayerController.Direction.LEFT if diff.x >= 0 else PlayerController.Direction.RIGHT

func _start_wait_shot(target_pos: Vector2) -> void:
	alert_substate = AlertSubstate.WAIT_SHOT
	alert_counter = 16 # Pausa de tiro de ~16 ticks (0.26s)
	shoot_cooldown = 0 # Pronto para disparar
	_update_direction_to_target(target_pos)

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
		if is_lorry_guard and current_waypoint_idx == 0:
			# Chegou de volta à traseira do caminhão (carroceria) após a volta completa!
			# Entra na carroceria caminhando na direção Norte (UP)
			is_entering_lorry = true
			lorry_anim_pixels = 16.0
			current_direction = PlayerController.Direction.UP
			return
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

	if is_lorry_guard:
		# O MSX tem uma regra especial: ele NUNCA pausa no PRIMEIRO ponto (logo após sair do caminhão).
		if current_waypoint_idx == 1:
			wait_ticks = 0

		# Ciclo contínuo de rota: 1 -> 2 -> 3 -> 4 -> 0
		current_waypoint_idx = (current_waypoint_idx + 1) % waypoints.size()
		return

	# Se rota tem apenas 2 pontos, vai e volta (estilo vai-e-vem)
	if waypoints.size() == 2:
		current_waypoint_idx = 1 if current_waypoint_idx == 0 else 0
	else:
		# Ciclo contínuo de rota
		current_waypoint_idx = (current_waypoint_idx + 1) % waypoints.size()

	if wait_ticks == 0 and not waypoints.is_empty():
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

## Processa a máquina de estados do sentinela do elevador (MSX: logic/actors/guardelevator.asm)
func _process_elevator_guard() -> void:
	match elev_guard_state:
		ElevatorGuardState.IDLE:
			# Fica parado guardando a porta do elevador e alternando a visão para os lados
			if elev_guard_idle_timer > 0:
				elev_guard_idle_timer -= 1
				elev_guard_look_timer -= 1
				if elev_guard_look_timer <= 0:
					elev_guard_look_timer = 30 + (randi() % 16)
					# MSX Z80 (guardelevator.asm:305): alterna entre DOWN, LEFT e RIGHT (nunca UP)
					var dirs: Array[PlayerController.Direction] = [
						PlayerController.Direction.DOWN,
						PlayerController.Direction.LEFT,
						PlayerController.Direction.RIGHT
					]
					current_direction = dirs[randi() % dirs.size()]
					queue_redraw()
				return

			# Idle timer esgotou: hora do revezamento ("Chow time!!")
			elev_guard_state = ElevatorGuardState.LEAVING
			current_direction = PlayerController.Direction.RIGHT
			if is_relieve_speaker:
				chow_time_called.emit()
			queue_redraw()

		ElevatorGuardState.LEAVING:
			# Caminha para o lado direito em direção à outra sala
			current_direction = PlayerController.Direction.RIGHT
			position.x += speed
			anim_tick += 1
			if anim_tick >= 8:
				anim_tick = 0
				anim_frame = 1 if anim_frame == 0 else 0
			if position.x >= 272.0: # Totalmente fora da viewport visível (256 + 16px)
				visible = false
				is_dead = true
				queue_free()

		ElevatorGuardState.ENTERING:
			# Guarda de revezamento voltando da outra sala caminhando para a esquerda
			current_direction = PlayerController.Direction.LEFT
			if position.x > elev_guard_target_x:
				position.x -= speed
				anim_tick += 1
				if anim_tick >= 8:
					anim_tick = 0
					anim_frame = 1 if anim_frame == 0 else 0
			else:
				position.x = elev_guard_target_x
				current_direction = PlayerController.Direction.DOWN
				elev_guard_state = ElevatorGuardState.IDLE
				elev_guard_idle_timer = 256
				elev_guard_look_timer = 30 + (randi() % 16)
				queue_redraw()


## Verifica linha de visão com tolerâncias e bloqueio por obstáculos fiéis à ROM (chkdiscover.asm)
func check_line_of_sight(player_pos: Vector2, collision_grid: Array) -> bool:
	if is_dead or not visible:
		return false
	if is_sleepy_guard and sleepy_state == SleepyState.SLEEPING:
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
	if is_dog:
		wake_up_to_chase()
		return
	if is_sleepy_guard:
		sleepy_state = SleepyState.AWAKE
	is_alert = true
	state = GuardState.ALERT
	speed = 1.5 # SetWalkSpeedFast
	alert_timer = 60.0
	queue_redraw()

## Restaura soldado ao estado de patrulha pacífica
func reset_to_patrol() -> void:
	if is_dead:
		return
	if is_dog:
		dog_state = DogState.SLEEP
		dog_wait_timer = 32 + (randi() % 4) * 8
		queue_redraw()
		return
	is_alert = false
	state = GuardState.PATROL
	if is_sleepy_guard:
		sleepy_state = SleepyState.AWAKE
		awake_timer = 192 # reinicia ciclo acordado canônico (0C0h)
	match guard_type:
		GuardType.SLOW:
			speed = 0.5
		GuardType.MEDIUM:
			speed = 1.0
		GuardType.FAST:
			speed = 1.5
	queue_redraw()

func _draw() -> void:
	if is_dog:
		_draw_dog()
		return

	# 1. Soldado derrotado (no MSX2 original o ator é dispensado sem deixar corpo no chão)
	if is_dead:
		return

	# 2. Renderização autêntica com spritesheet MSX2 (se o asset extraído estiver presente)
	if _guard_texture != null:
		var src_rect := _get_guard_sprite_rect()
		var dest_rect := Rect2(-8.0, -26.0, 16.0, 32.0)
		draw_texture_rect_region(_guard_texture, dest_rect, src_rect)

		# Clarão de disparo (muzzle flash) na ponta do fuzil
		if shoot_flash_timer > 0:
			var flash_pos := Vector2.ZERO
			match current_direction:
				PlayerController.Direction.UP:
					flash_pos = Vector2(0.0, -26.0)
				PlayerController.Direction.DOWN:
					flash_pos = Vector2(2.0, 4.0)
				PlayerController.Direction.LEFT:
					flash_pos = Vector2(-9.0, -15.0)
				PlayerController.Direction.RIGHT:
					flash_pos = Vector2(9.0, -15.0)
			# Clarão de disparo discreto em pixel-art estilo MSX2
			draw_rect(Rect2(flash_pos.x - 1, flash_pos.y - 1, 2, 2), Color.WHITE)
			draw_rect(Rect2(flash_pos.x - 2, flash_pos.y, 1, 1), Color("ffff77"))
			draw_rect(Rect2(flash_pos.x + 1, flash_pos.y, 1, 1), Color("ffff77"))
			draw_rect(Rect2(flash_pos.x, flash_pos.y - 2, 1, 1), Color("ffff77"))
			draw_rect(Rect2(flash_pos.x, flash_pos.y + 1, 1, 1), Color("ffff77"))

		_draw_guard_overlays()
		return

	# 3. Procedural Fallback (se a textura não estiver carregada)
	var c_helmet := Color("1c2432")       # Capacete de combate de aço
	var c_helmet_light := Color("2c384c") # Cúpula superior do capacete
	var c_helmet_rim := Color("101620")   # Borda e aba do capacete
	var c_skin := Color("d89870")         # Pele humana
	var c_skin_shadow := Color("a86c48")  # Sombra sob a aba do capacete
	var c_suit := Color("384860")         # Farda militar azul-acinzentada
	var c_suit_shadow := Color("243040")  # Dobras e sombras da farda
	var c_vest := Color("202a3a")         # Colete tático balístico
	var c_vest_light := Color("303e54")   # Ombreiras e acabamentos
	var c_belt := Color("141820")         # Cinto de guarnição e coldre
	var c_buckle := Color("788490")       # Fivela metálica
	var c_boot := Color("10141c")         # Coturnos de combate pretos
	var c_glove := Color("141820")        # Luvas táticas
	var c_rifle := Color("12161e")        # Fuzil de assalto / metralhadora
	var c_barrel := Color("2c3444")       # Cano metálico da arma

	# Altura total: 32 pixels (Y de -26 até +6)
	# Largura total: 16 pixels (X de -8 até +8)

	# --- CAPACETE E CABEÇA (Y: -26 a -15) ---
	# Cúpula do capacete
	draw_rect(Rect2(-5, -26, 10, 4), c_helmet_light)
	draw_rect(Rect2(-6, -24, 12, 5), c_helmet)
	# Borda / aba do capacete
	draw_rect(Rect2(-7, -21, 14, 2), c_helmet_rim)

	# Rosto / Pele (Y: -19 a -14)
	draw_rect(Rect2(-5, -19, 10, 5), c_skin)
	draw_rect(Rect2(-5, -19, 10, 1), c_skin_shadow) # Sombra da aba

	# Detalhes direcionais da cabeça e expressão
	match current_direction:
		PlayerController.Direction.DOWN:
			if is_sleepy_guard and sleepy_state == SleepyState.SLEEPING:
				# Olhos fechados dormindo (fendas horizontais)
				draw_rect(Rect2(-4, -17, 3, 1), Color("243040"))
				draw_rect(Rect2(1, -17, 3, 1), Color("243040"))
				# Nariz e boca relaxados
				draw_rect(Rect2(-1, -15, 2, 1), c_skin_shadow)
			else:
				# Olhos vigilantes da guarda
				draw_rect(Rect2(-4, -18, 2, 2), Color.BLACK)
				draw_rect(Rect2(2, -18, 2, 2), Color.BLACK)
				draw_rect(Rect2(-4, -18, 1, 1), Color.WHITE)
				draw_rect(Rect2(2, -18, 1, 1), Color.WHITE)
				draw_rect(Rect2(-1, -16, 2, 2), c_skin_shadow)

		PlayerController.Direction.UP:
			# Traseira do capacete cobrindo a nuca
			draw_rect(Rect2(-5, -20, 10, 6), c_helmet)
			draw_rect(Rect2(-6, -18, 12, 3), c_helmet_rim)

		PlayerController.Direction.LEFT:
			# Perfil virado para a esquerda
			draw_rect(Rect2(-7, -20, 3, 3), c_helmet_rim) # Aba proeminente à esquerda
			draw_rect(Rect2(-6, -18, 2, 3), c_skin)        # Nariz
			draw_rect(Rect2(-4, -18, 2, 2), Color.BLACK)   # Olho esquerdo
			draw_rect(Rect2(-4, -18, 1, 1), Color.WHITE)
			draw_rect(Rect2(1, -21, 5, 7), c_helmet)      # Traseira do capacete

		PlayerController.Direction.RIGHT:
			# Perfil virado para a direita
			draw_rect(Rect2(4, -20, 3, 3), c_helmet_rim)  # Aba proeminente à direita
			draw_rect(Rect2(4, -18, 2, 3), c_skin)         # Nariz
			draw_rect(Rect2(2, -18, 2, 2), Color.BLACK)    # Olho direito
			draw_rect(Rect2(3, -18, 1, 1), Color.WHITE)
			draw_rect(Rect2(-6, -21, 5, 7), c_helmet)     # Traseira do capacete

	# --- PESCOÇO E GOLA MILITAR (Y: -14 a -12) ---
	draw_rect(Rect2(-4, -14, 8, 2), c_suit_shadow)

	# --- TRONCO, FARDA E COLETE (Y: -13 a -3) ---
	# Túnica da farda base
	draw_rect(Rect2(-7, -13, 14, 10), c_suit)
	# Colete balístico de Outer Heaven
	draw_rect(Rect2(-6, -13, 12, 9), c_vest)
	# Ombreiras reforçadas
	draw_rect(Rect2(-7, -13, 2, 4), c_vest_light)
	draw_rect(Rect2(5, -13, 2, 4), c_vest_light)

	# --- ARMA / FUZIL E BRAÇOS CONFORME A DIREÇÃO ---
	var arm_l_y := -12
	var arm_r_y := -12
	if anim_frame == 1:
		arm_l_y = -10
		arm_r_y = -14
	else:
		arm_l_y = -14
		arm_r_y = -10

	match current_direction:
		PlayerController.Direction.DOWN:
			# Braços segurando o fuzil na diagonal à frente
			draw_rect(Rect2(-8, arm_l_y, 2, 7), c_suit)
			draw_rect(Rect2(-8, arm_l_y + 6, 2, 3), c_glove)
			draw_rect(Rect2(6, arm_r_y, 2, 7), c_suit)
			draw_rect(Rect2(6, arm_r_y + 6, 2, 3), c_glove)
			# Fuzil de assalto apontando para baixo
			draw_rect(Rect2(1, -9, 3, 10), c_rifle)
			draw_rect(Rect2(2, 1, 2, 5), c_barrel) # Cano descendo até o cinto
			draw_rect(Rect2(4, -6, 2, 4), c_rifle)  # Carregador curvo
			if shoot_flash_timer > 0:
				draw_rect(Rect2(2, 6, 2, 2), Color.WHITE)
				draw_rect(Rect2(1, 7, 1, 1), Color("ffff77"))
				draw_rect(Rect2(4, 7, 1, 1), Color("ffff77"))
				draw_rect(Rect2(2, 5, 1, 1), Color("ffff77"))
				draw_rect(Rect2(2, 8, 1, 1), Color("ffff77"))

		PlayerController.Direction.UP:
			# Costas do soldado: alça do fuzil cruzando o peito
			draw_rect(Rect2(-8, arm_l_y, 2, 7), c_suit)
			draw_rect(Rect2(6, arm_r_y, 2, 7), c_suit)
			draw_line(Vector2(-4, -13), Vector2(4, -4), c_belt, 1.5)
			# Cano do fuzil sobressaindo acima do ombro direito
			draw_rect(Rect2(4, -18, 2, 6), c_barrel)
			if shoot_flash_timer > 0:
				draw_rect(Rect2(4, -20, 2, 2), Color.WHITE)
				draw_rect(Rect2(3, -19, 1, 1), Color("ffff77"))
				draw_rect(Rect2(6, -19, 1, 1), Color("ffff77"))
				draw_rect(Rect2(4, -21, 1, 1), Color("ffff77"))
				draw_rect(Rect2(4, -18, 1, 1), Color("ffff77"))

		PlayerController.Direction.LEFT:
			# Fuzil de assalto empunhado apontando à esquerda
			draw_rect(Rect2(-2, arm_l_y, 4, 8), c_suit)
			draw_rect(Rect2(-2, arm_l_y + 6, 4, 3), c_glove)
			# Coronha sob o braço e cano estendido à esquerda
			draw_rect(Rect2(-8, -8, 8, 3), c_rifle)
			draw_rect(Rect2(-14, -7, 6, 2), c_barrel) # Cano do fuzil à frente
			draw_rect(Rect2(-6, -5, 2, 3), c_rifle)   # Carregador
			if shoot_flash_timer > 0:
				draw_rect(Rect2(-16, -7, 2, 2), Color.WHITE)
				draw_rect(Rect2(-17, -6, 1, 1), Color("ffff77"))
				draw_rect(Rect2(-14, -6, 1, 1), Color("ffff77"))
				draw_rect(Rect2(-15, -8, 1, 1), Color("ffff77"))
				draw_rect(Rect2(-15, -5, 1, 1), Color("ffff77"))

		PlayerController.Direction.RIGHT:
			# Fuzil de assalto empunhado apontando à direita
			draw_rect(Rect2(-2, arm_r_y, 4, 8), c_suit)
			draw_rect(Rect2(-2, arm_r_y + 6, 4, 3), c_glove)
			# Coronha sob o braço e cano estendido à direita
			draw_rect(Rect2(0, -8, 8, 3), c_rifle)
			draw_rect(Rect2(8, -7, 6, 2), c_barrel)   # Cano do fuzil à frente
			draw_rect(Rect2(4, -5, 2, 3), c_rifle)    # Carregador
			if shoot_flash_timer > 0:
				draw_rect(Rect2(14, -7, 2, 2), Color.WHITE)
				draw_rect(Rect2(13, -6, 1, 1), Color("ffff77"))
				draw_rect(Rect2(16, -6, 1, 1), Color("ffff77"))
				draw_rect(Rect2(15, -8, 1, 1), Color("ffff77"))
				draw_rect(Rect2(15, -5, 1, 1), Color("ffff77"))

	# --- CINTO E EQUIPAMENTOS (Y: -4 a 0) ---
	draw_rect(Rect2(-6, -4, 12, 3), c_belt)
	draw_rect(Rect2(-1, -4, 2, 3), c_buckle)
	draw_rect(Rect2(-6, -4, 2, 3), c_vest_light) # Pouch esquerdo
	draw_rect(Rect2(4, -4, 2, 3), c_vest_light)  # Cantil direito

	# --- PERNAS E COTURNOS (Y: 0 a +6) ---
	var leg_l_rect := Rect2(-5, 0, 4, 4)
	var leg_r_rect := Rect2(1, 0, 4, 4)
	var boot_l_rect := Rect2(-5, 4, 4, 2)
	var boot_r_rect := Rect2(1, 4, 4, 2)

	if anim_frame == 1:
		leg_l_rect.position.y += 1
		boot_l_rect.position.y += 1
		leg_r_rect.position.y -= 1
		boot_r_rect.position.y -= 1
	else:
		leg_l_rect.position.y -= 1
		boot_l_rect.position.y -= 1
		leg_r_rect.position.y += 1
		boot_r_rect.position.y += 1

	if current_direction == PlayerController.Direction.LEFT:
		draw_rect(Rect2(-4, 0, 6, 4), c_suit)
		draw_rect(Rect2(-5, 4, 6, 2), c_boot)
		if anim_frame == 1:
			draw_rect(Rect2(-6, 4, 4, 2), c_boot)
			draw_rect(Rect2(0, 2, 4, 2), Color("080c12"))
	elif current_direction == PlayerController.Direction.RIGHT:
		draw_rect(Rect2(-2, 0, 6, 4), c_suit)
		draw_rect(Rect2(-1, 4, 6, 2), c_boot)
		if anim_frame == 1:
			draw_rect(Rect2(2, 4, 4, 2), c_boot)
			draw_rect(Rect2(-4, 2, 4, 2), Color("080c12"))
	else:
		draw_rect(leg_l_rect, c_suit)
		draw_rect(leg_r_rect, c_suit)
		draw_rect(boot_l_rect, c_boot)
		draw_rect(boot_r_rect, c_boot)
		draw_line(Vector2(boot_l_rect.position.x, boot_l_rect.end.y), Vector2(boot_l_rect.end.x, boot_l_rect.end.y), Color("06080c"), 1.0)
		draw_line(Vector2(boot_r_rect.position.x, boot_r_rect.end.y), Vector2(boot_r_rect.end.x, boot_r_rect.end.y), Color("06080c"), 1.0)

	_draw_guard_overlays()

func _draw_guard_overlays() -> void:
	# --- INDICADOR DE ATORDOAMENTO (estrelas girando sobre o capacete) ---
	if stunned_timer > 0:
		var st_phase: int = (stunned_timer / 8) % 4
		var offsets := [Vector2(-6, -30), Vector2(0, -32), Vector2(6, -30), Vector2(0, -28)]
		for i: int in range(3):
			var pt: Vector2 = offsets[(st_phase + i) % 4]
			draw_circle(pt, 1.5, Color.YELLOW)

	# --- SÍMBOLO ANIMADO DE RONCO ZZZ FLUTUANTE (snoringsymbol.asm) ---
	if is_sleepy_guard and sleepy_state == SleepyState.SLEEPING and not is_alert and stunned_timer <= 0:
		_draw_snoring_symbol()

	# --- PONTO DE EXCLAMAÇÃO (!) CLÁSSICO DO METAL GEAR ---
	if is_alert and stunned_timer <= 0:
		# Balão vermelho elevado acima do capacete
		draw_circle(Vector2(0, -34), 6.0, Color("c82020"))
		# Linha superior da exclamação
		draw_rect(Rect2(-1, -38, 2, 5), Color.WHITE)
		# Ponto inferior da exclamação
		draw_rect(Rect2(-1, -31, 2, 2), Color.WHITE)

	# --- VISUALIZAÇÃO DE DEPURAÇÃO DO CONE DE VISÃO ---
	if show_debug_vision and stunned_timer <= 0 and not (is_sleepy_guard and sleepy_state == SleepyState.SLEEPING):
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

func _draw_snoring_symbol() -> void:
	var phase: float = float(snore_anim_tick % 48) / 48.0
	var float_y: float = -phase * 4.0
	# 3 letras Z flutuantes com tamanhos crescentes acima do capacete (snoringsymbol.asm)
	_draw_z_char(Vector2(2.0, -28.0 + float_y), 1.0, Color("e0e8f0"))
	_draw_z_char(Vector2(6.0, -33.0 + float_y), 1.25, Color("f8d840"))
	_draw_z_char(Vector2(10.0, -38.0 + float_y), 1.5, Color("40d8f8"))

func _draw_z_char(pos: Vector2, s: float, col: Color) -> void:
	# Barra superior
	draw_rect(Rect2(pos.x, pos.y, 4.0 * s, 1.0 * s), col)
	# Diagonal
	draw_rect(Rect2(pos.x + 2.0 * s, pos.y + 1.0 * s, 1.0 * s, 1.0 * s), col)
	draw_rect(Rect2(pos.x + 1.0 * s, pos.y + 2.0 * s, 1.0 * s, 1.0 * s), col)
	# Barra inferior
	draw_rect(Rect2(pos.x, pos.y + 3.0 * s, 4.0 * s, 1.0 * s), col)

## Lógica canônica do cão de guarda MSX2 RC750 (logic/actors/dog.asm:29-201)
func _step_dog(collision_grid: Array, player_pos: Vector2, player: PlayerController = null) -> void:
	# 1. Proximidade com Snake acorda o cão imediatamente se estiver dormindo ou ouvindo (<= 48 px)
	var dist_to_player: float = position.distance_to(player_pos)
	if dog_state != DogState.CHASE and dist_to_player <= 48.0:
		wake_up_to_chase()

	# 2. Máquina de estados canônica do cão (dog.asm:29-36)
	match dog_state:
		DogState.SLEEP:
			dog_wait_timer -= 1
			if dog_wait_timer <= 0:
				dog_state = DogState.LISTEN
				# Random number 20-32 ticks de escuta (dog.asm:49-53)
				dog_listen_timer = (5 + (randi() % 4)) * 4
				dog_wait_timer = dog_listen_timer * 2 # 40-64 ticks de espera
			dog_anim_tick += 1
			queue_redraw()
			return

		DogState.LISTEN:
			dog_listen_timer -= 1
			if dog_listen_timer <= 0:
				# 50% de chance de acordar e 50% de voltar a dormir (dog.asm:74-81)
				if randf() > 0.5:
					dog_state = DogState.CHASE
					speed = DOG_SPEED
					_reorient_dog_to_player(player_pos, collision_grid)
					dog_wait_timer = (5 + (randi() % 4)) * 4
				else:
					dog_state = DogState.SLEEP
					if dog_wait_timer <= 0:
						dog_wait_timer = 32 + (randi() % 4) * 8
			dog_anim_tick += 1
			queue_redraw()
			return

		DogState.CHASE:
			if dog_bark_timer > 0:
				dog_bark_timer -= 1

			# Dano por mordida / toque canônico: 2 HP (shapes.asm:37)
			if dist_to_player <= 12.0 and player != null:
				player.apply_damage(touch_damage)

			# Movimentação canônica a 1.3 px/tick (dog.asm:193-201)
			var dir_vec: Vector2 = _get_dir_vector(current_direction)
			var step_vec: Vector2 = dir_vec * speed
			var next_pos: Vector2 = position + step_vec

			# Verifica colisão na direção atual
			if not _is_colliding_grid(next_pos, collision_grid):
				position = next_pos
				dog_wait_timer -= 1
				if dog_wait_timer <= 0:
					# Ao expirar o tempo de corrida na mesma direção: late e reorienta (dog.asm:123-146)
					dog_bark_timer = 16
					dog_barked.emit(position)
					_reorient_dog_to_player(player_pos, collision_grid)
					dog_wait_timer = (5 + (randi() % 4)) * 4
			else:
				# Bloqueado por obstáculo: late, reorienta rumo para o eixo secundário (dog.asm:127-147)
				dog_bark_timer = 12
				dog_barked.emit(position)
				_reorient_dog_to_player(player_pos, collision_grid)
				dog_wait_timer = (5 + (randi() % 4)) * 4
				# Tenta dar o passo na nova direção desobstruída
				var new_step: Vector2 = _get_dir_vector(current_direction) * speed
				if not _is_colliding_grid(position + new_step, collision_grid):
					position += new_step

			dog_anim_tick += 1
			# Alterna quadro de animação da passada a cada 4 iterações (dog.asm:163 bit 2, ANIM_CNT)
			anim_frame = (dog_anim_tick / 4) % 2
			queue_redraw()

func _get_dir_vector(dir: PlayerController.Direction) -> Vector2:
	match dir:
		PlayerController.Direction.UP:
			return Vector2(0.0, -1.0)
		PlayerController.Direction.DOWN:
			return Vector2(0.0, 1.0)
		PlayerController.Direction.LEFT:
			return Vector2(-1.0, 0.0)
		PlayerController.Direction.RIGHT:
			return Vector2(1.0, 0.0)
	return Vector2.ZERO

## Reorienta rumo do cão escolhendo eixo dominante e contornando colisões (dog.asm:88-98, 127-137)
func _reorient_dog_to_player(player_pos: Vector2, collision_grid: Array) -> void:
	var diff: Vector2 = player_pos - position
	var primary_dir: PlayerController.Direction
	var secondary_dir: PlayerController.Direction

	if absf(diff.x) >= absf(diff.y):
		primary_dir = PlayerController.Direction.RIGHT if diff.x >= 0.0 else PlayerController.Direction.LEFT
		secondary_dir = PlayerController.Direction.DOWN if diff.y >= 0.0 else PlayerController.Direction.UP
	else:
		primary_dir = PlayerController.Direction.DOWN if diff.y >= 0.0 else PlayerController.Direction.UP
		secondary_dir = PlayerController.Direction.RIGHT if diff.x >= 0.0 else PlayerController.Direction.LEFT

	# Testa se a direção primária está livre de colisão
	var step_pri: Vector2 = _get_dir_vector(primary_dir) * speed
	if not _is_colliding_grid(position + step_pri, collision_grid):
		current_direction = primary_dir
	else:
		# Testa se o eixo secundário está livre (dog.asm:95, 134)
		var step_sec: Vector2 = _get_dir_vector(secondary_dir) * speed
		if not _is_colliding_grid(position + step_sec, collision_grid):
			current_direction = secondary_dir
		else:
			current_direction = primary_dir

## Desenho canônico do cão de guarda com base nas cores e poses da ROM MSX2 (actorspriteattr.asm:40, SprDog)
func _draw_dog() -> void:
	var col_body := Color("5a3418")        # Marrom chocolate do pelo
	var col_body_light := Color("7a4824")  # Brilho / pelagem superior
	var col_belly := Color("b87840")       # Caramelo / focinho e patas
	var col_dark := Color("2d1608")        # Contorno / orelhas / garras
	var col_nose := Color("120a05")        # Nariz e olhos escuros
	var col_white := Color("ffffff")       # Brilho nos olhos / Zzz
	var col_red := Color("c82020")         # Língua / alerta latido

	# 1. Cão Derrotado (no MSX2 original o ator é dispensado sem deixar corpo no chão)
	if is_dead:
		return

	# 2. Renderização autêntica com spritesheet MSX2 (se o asset extraído estiver presente)
	if _dog_texture != null:
		var src_rect := _get_dog_sprite_rect()
		var dest_rect := Rect2(-16.0, -16.0, 32.0, 32.0)
		draw_texture_rect_region(_dog_texture, dest_rect, src_rect)

		# Balão "Zzz" flutuante animado
		if dog_state == DogState.SLEEP:
			var z_phase: float = fmod(float(dog_anim_tick), 36.0)
			var z1_pos := Vector2(6.0 + sin(z_phase * 0.15) * 2.0, -6.0 - (z_phase * 0.25))
			_draw_z_symbol(z1_pos, 4.0, Color(0.85, 0.9, 1.0, 0.9))
			if dog_anim_tick % 36 > 16:
				var z2_phase: float = fmod(float(dog_anim_tick + 18), 36.0)
				var z2_pos := Vector2(9.0 + sin(z2_phase * 0.15) * 2.0, -6.0 - (z2_phase * 0.25))
				_draw_z_symbol(z2_pos, 3.0, Color(0.7, 0.85, 1.0, 0.7))

		# Balão de Latido ("AU!" / Sfx_DogBark)
		if dog_bark_timer > 0:
			draw_rect(Rect2(-12, -22, 24, 10), Color.BLACK)
			draw_rect(Rect2(-11, -21, 22, 8), Color.WHITE)
			draw_polygon(PackedVector2Array([Vector2(-2, -12), Vector2(2, -12), Vector2(0, -9)]), PackedColorArray([Color.BLACK]))
			draw_polygon(PackedVector2Array([Vector2(-1, -12), Vector2(1, -12), Vector2(0, -10)]), PackedColorArray([Color.WHITE]))
			draw_string(ThemeDB.fallback_font, Vector2(-9, -15), "AU!", HORIZONTAL_ALIGNMENT_CENTER, 18.0, 7, col_red)

		# Indicador de Atordoamento
		if stunned_timer > 0:
			var st_phase: int = (stunned_timer / 8) % 4
			var offsets := [Vector2(-6, -16), Vector2(0, -18), Vector2(6, -16), Vector2(0, -14)]
			for i: int in range(3):
				var pt: Vector2 = offsets[(st_phase + i) % 4]
				draw_circle(pt, 1.5, Color.YELLOW)
		return

	# 3. Procedural Fallback (Dormindo - DogSleep - Status 0)
	if dog_state == DogState.SLEEP:
		draw_rect(Rect2(-7, -4, 14, 8), col_body)
		draw_rect(Rect2(-6, -5, 12, 1), col_body_light)
		draw_rect(Rect2(-5, 3, 10, 2), col_belly)
		draw_rect(Rect2(3, -3, 6, 6), col_body)
		draw_rect(Rect2(7, -1, 4, 4), col_belly)
		draw_rect(Rect2(10, 0, 2, 2), col_nose)
		draw_line(Vector2(6, -1), Vector2(8, -1), col_dark, 1.0)
		draw_polygon(PackedVector2Array([Vector2(3, -5), Vector2(6, -5), Vector2(4, -2)]), PackedColorArray([col_dark]))
		draw_rect(Rect2(-5, 4, 4, 2), col_belly)
		draw_rect(Rect2(2, 4, 4, 2), col_belly)
		draw_line(Vector2(-7, -1), Vector2(-11, -3), col_dark, 1.5)
		draw_line(Vector2(-11, -3), Vector2(-9, -5), col_body, 1.5)

		# Balão "Zzz" flutuante animado
		var z_phase: float = fmod(float(dog_anim_tick), 36.0)
		var z1_pos := Vector2(6.0 + sin(z_phase * 0.15) * 2.0, -6.0 - (z_phase * 0.25))
		_draw_z_symbol(z1_pos, 4.0, Color(0.85, 0.9, 1.0, 0.9))
		if dog_anim_tick % 36 > 16:
			var z2_phase: float = fmod(float(dog_anim_tick + 18), 36.0)
			var z2_pos := Vector2(9.0 + sin(z2_phase * 0.15) * 2.0, -6.0 - (z2_phase * 0.25))
			_draw_z_symbol(z2_pos, 3.0, Color(0.7, 0.85, 1.0, 0.7))
		return

	# 3. Ouvindo / Alerta (DogListen - Status 1)
	if dog_state == DogState.LISTEN:
		draw_rect(Rect2(-8, -2, 13, 7), col_body)
		draw_rect(Rect2(-7, 3, 11, 2), col_belly)
		draw_rect(Rect2(2, -7, 6, 7), col_body)
		draw_rect(Rect2(3, -4, 4, 5), col_belly)
		draw_rect(Rect2(3, -11, 6, 6), col_body)
		draw_rect(Rect2(7, -9, 4, 4), col_belly)
		draw_rect(Rect2(10, -9, 2, 2), col_nose)
		draw_rect(Rect2(5, -10, 2, 2), col_white)
		draw_rect(Rect2(6, -10, 1, 1), col_nose)
		draw_polygon(PackedVector2Array([Vector2(3, -11), Vector2(4, -15), Vector2(6, -11)]), PackedColorArray([col_dark]))
		draw_polygon(PackedVector2Array([Vector2(6, -11), Vector2(7, -15), Vector2(8, -11)]), PackedColorArray([col_body_light]))
		draw_rect(Rect2(3, 4, 5, 2), col_belly)
		draw_rect(Rect2(-7, 4, 4, 2), col_dark)
		draw_line(Vector2(-8, -1), Vector2(-12, -5), col_body, 1.5)
		draw_circle(Vector2(6, -18), 1.5, Color("ffea40"))
		return

	# 4. Perseguição (DogMove / CHASE - Status 2)
	match current_direction:
		PlayerController.Direction.LEFT:
			draw_rect(Rect2(-4, -4, 11, 7), col_body)
			draw_rect(Rect2(-3, 1, 9, 2), col_belly)
			draw_rect(Rect2(-8, -7, 6, 6), col_body)
			draw_rect(Rect2(-12, -5, 4, 4), col_belly)
			draw_rect(Rect2(-13, -5, 2, 2), col_nose)
			draw_rect(Rect2(-7, -7, 2, 2), col_white)
			draw_rect(Rect2(-8, -7, 1, 1), col_nose)
			draw_polygon(PackedVector2Array([Vector2(-4, -7), Vector2(-1, -10), Vector2(-1, -6)]), PackedColorArray([col_dark]))
			draw_line(Vector2(7, -3), Vector2(12, -7), col_body, 1.5)
			if anim_frame == 0:
				draw_line(Vector2(-5, 2), Vector2(-10, 6), col_belly, 2.0)
				draw_line(Vector2(-3, 2), Vector2(-1, 6), col_dark, 2.0)
				draw_line(Vector2(3, 2), Vector2(1, 6), col_dark, 2.0)
				draw_line(Vector2(5, 2), Vector2(10, 6), col_belly, 2.0)
			else:
				draw_line(Vector2(-4, 2), Vector2(-3, 7), col_belly, 2.0)
				draw_line(Vector2(-2, 2), Vector2(-1, 7), col_dark, 2.0)
				draw_line(Vector2(2, 2), Vector2(0, 7), col_dark, 2.0)
				draw_line(Vector2(4, 2), Vector2(2, 7), col_belly, 2.0)

		PlayerController.Direction.RIGHT:
			draw_rect(Rect2(-7, -4, 11, 7), col_body)
			draw_rect(Rect2(-6, 1, 9, 2), col_belly)
			draw_rect(Rect2(2, -7, 6, 6), col_body)
			draw_rect(Rect2(8, -5, 4, 4), col_belly)
			draw_rect(Rect2(11, -5, 2, 2), col_nose)
			draw_rect(Rect2(5, -7, 2, 2), col_white)
			draw_rect(Rect2(7, -7, 1, 1), col_nose)
			draw_polygon(PackedVector2Array([Vector2(4, -7), Vector2(1, -10), Vector2(1, -6)]), PackedColorArray([col_dark]))
			draw_line(Vector2(-7, -3), Vector2(-12, -7), col_body, 1.5)
			if anim_frame == 0:
				draw_line(Vector2(5, 2), Vector2(10, 6), col_belly, 2.0)
				draw_line(Vector2(3, 2), Vector2(1, 6), col_dark, 2.0)
				draw_line(Vector2(-3, 2), Vector2(-1, 6), col_dark, 2.0)
				draw_line(Vector2(-5, 2), Vector2(-10, 6), col_belly, 2.0)
			else:
				draw_line(Vector2(4, 2), Vector2(3, 7), col_belly, 2.0)
				draw_line(Vector2(2, 2), Vector2(1, 7), col_dark, 2.0)
				draw_line(Vector2(-2, 2), Vector2(0, 7), col_dark, 2.0)
				draw_line(Vector2(-4, 2), Vector2(-2, 7), col_belly, 2.0)

		PlayerController.Direction.UP:
			draw_rect(Rect2(-5, -4, 10, 10), col_body)
			draw_rect(Rect2(-2, -3, 4, 8), col_body_light)
			draw_rect(Rect2(-4, -8, 8, 5), col_body)
			draw_polygon(PackedVector2Array([Vector2(-4, -8), Vector2(-5, -12), Vector2(-2, -8)]), PackedColorArray([col_dark]))
			draw_polygon(PackedVector2Array([Vector2(2, -8), Vector2(5, -12), Vector2(4, -8)]), PackedColorArray([col_dark]))
			draw_line(Vector2(0, 6), Vector2(0, 11), col_dark, 1.5)
			if anim_frame == 0:
				draw_rect(Rect2(-7, -7, 3, 4), col_belly)
				draw_rect(Rect2(4, -4, 3, 4), col_dark)
				draw_rect(Rect2(-7, 4, 3, 4), col_dark)
				draw_rect(Rect2(4, 1, 3, 4), col_belly)
			else:
				draw_rect(Rect2(-7, -4, 3, 4), col_dark)
				draw_rect(Rect2(4, -7, 3, 4), col_belly)
				draw_rect(Rect2(-7, 1, 3, 4), col_belly)
				draw_rect(Rect2(4, 4, 3, 4), col_dark)

		PlayerController.Direction.DOWN:
			draw_rect(Rect2(-5, -6, 10, 9), col_body)
			draw_rect(Rect2(-3, -2, 6, 5), col_belly)
			draw_rect(Rect2(-5, -3, 10, 6), col_body)
			draw_rect(Rect2(-3, 1, 6, 4), col_belly)
			draw_rect(Rect2(-2, 3, 4, 2), col_nose)
			draw_rect(Rect2(-4, -1, 2, 2), col_white)
			draw_rect(Rect2(-3, -1, 1, 1), col_nose)
			draw_rect(Rect2(2, -1, 2, 2), col_white)
			draw_rect(Rect2(2, -1, 1, 1), col_nose)
			draw_polygon(PackedVector2Array([Vector2(-5, -3), Vector2(-8, 0), Vector2(-5, 1)]), PackedColorArray([col_dark]))
			draw_polygon(PackedVector2Array([Vector2(5, -3), Vector2(8, 0), Vector2(5, 1)]), PackedColorArray([col_dark]))
			if anim_frame == 0:
				draw_rect(Rect2(-6, 4, 3, 4), col_belly)
				draw_rect(Rect2(3, 2, 3, 3), col_dark)
			else:
				draw_rect(Rect2(-6, 2, 3, 3), col_dark)
				draw_rect(Rect2(3, 4, 3, 4), col_belly)

	# 5. Balão de Latido ("AU!" / Sfx_DogBark)
	if dog_bark_timer > 0:
		draw_rect(Rect2(-12, -22, 24, 10), Color.BLACK)
		draw_rect(Rect2(-11, -21, 22, 8), Color.WHITE)
		draw_polygon(PackedVector2Array([Vector2(-2, -12), Vector2(2, -12), Vector2(0, -9)]), PackedColorArray([Color.BLACK]))
		draw_polygon(PackedVector2Array([Vector2(-1, -12), Vector2(1, -12), Vector2(0, -10)]), PackedColorArray([Color.WHITE]))
		draw_string(ThemeDB.fallback_font, Vector2(-9, -15), "AU!", HORIZONTAL_ALIGNMENT_CENTER, 18.0, 7, col_red)

	# 6. Indicador de Atordoamento
	if stunned_timer > 0:
		var st_phase: int = (stunned_timer / 8) % 4
		var offsets := [Vector2(-6, -16), Vector2(0, -18), Vector2(6, -16), Vector2(0, -14)]
		for i: int in range(3):
			var pt: Vector2 = offsets[(st_phase + i) % 4]
			draw_circle(pt, 1.5, Color.YELLOW)

func _draw_z_symbol(pos: Vector2, size: float, col: Color) -> void:
	draw_line(pos, pos + Vector2(size, 0.0), col, 1.0)
	draw_line(pos + Vector2(size, 0.0), pos + Vector2(0.0, size), col, 1.0)
	draw_line(pos + Vector2(0.0, size), pos + Vector2(size, size), col, 1.0)

