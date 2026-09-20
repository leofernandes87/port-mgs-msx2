extends Control
## Cena de teste jogável de Snake com movimentação e colisão fiéis ao MSX2 (Etapa 5).

var snapshot: RoomSnapshot = RoomSnapshot.new()
var player: PlayerController
var room_manager: RoomManager = RoomManager.new()
var enemies: Array[EnemyGuard] = []
var room_texture: ImageTexture
var show_collision: bool = false
var show_enemy_vision: bool = false
var zoom: float = 3.0
var canvas_origin: Vector2 = Vector2.ZERO

var status_label: Label
var collision_btn: CheckButton
var colliders_btn: CheckButton
var vision_btn: CheckButton

# Posição inicial padrão (Sala 1: centro do corredor livre da entrada)
const DEFAULT_SPAWN_X: float = 128.0
const DEFAULT_SPAWN_Y: float = 104.0

func _ready() -> void:
	# Montar interface
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	# Linha 1: Título e Status de Vida/Alerta
	var header_bar := HBoxContainer.new()
	column.add_child(header_bar)

	var title := Label.new()
	title.text = "Metal Gear MSX2 · Sandbox"
	header_bar.add_child(title)

	status_label = Label.new()
	status_label.text = "Carregando..."
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_bar.add_child(status_label)

	# Linha 2: Controles e Atalhos (HFlowContainer evita qualquer corte na direita)
	var controls_bar := HFlowContainer.new()
	controls_bar.add_theme_constant_override("h_separation", 10)
	controls_bar.add_theme_constant_override("v_separation", 4)
	column.add_child(controls_bar)

	collision_btn = CheckButton.new()
	collision_btn.text = "Colisão (C)"
	collision_btn.focus_mode = Control.FOCUS_NONE
	collision_btn.toggled.connect(func(v: bool) -> void: 
		show_collision = v
		if room_display:
			room_display.queue_redraw()
	)
	controls_bar.add_child(collision_btn)

	colliders_btn = CheckButton.new()
	colliders_btn.text = "Pontos Snake (V)"
	colliders_btn.focus_mode = Control.FOCUS_NONE
	colliders_btn.toggled.connect(func(v: bool) -> void: 
		if player:
			player.show_debug_colliders = v
			player.queue_redraw()
	)
	controls_bar.add_child(colliders_btn)

	vision_btn = CheckButton.new()
	vision_btn.text = "Visão Inimigos (B)"
	vision_btn.focus_mode = Control.FOCUS_NONE
	vision_btn.toggled.connect(func(v: bool) -> void:
		show_enemy_vision = v
		for enemy: EnemyGuard in enemies:
			enemy.show_debug_vision = v
			enemy.queue_redraw()
	)
	controls_bar.add_child(vision_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Reiniciar (R)"
	reset_btn.focus_mode = Control.FOCUS_NONE
	reset_btn.pressed.connect(reset_player)
	controls_bar.add_child(reset_btn)

	var help_label := Label.new()
	help_label.text = "· Mover: Setas/WASD · Soco: Espaço / Z / J"
	controls_bar.add_child(help_label)

	# Área central de jogo (Control que contém e centraliza o mundo do jogo)
	viewport_area = Control.new()
	viewport_area.custom_minimum_size = Vector2(256, 192)
	viewport_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_area.clip_contents = true
	viewport_area.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport_area.resized.connect(_on_viewport_resized)
	column.add_child(viewport_area)

	# Nó container 2D escalado (mundo nativo 256x192)
	game_world = Node2D.new()
	viewport_area.add_child(game_world)

	# Fundo da sala
	room_display = Node2D.new()
	room_display.draw.connect(_draw_room_and_collision)
	game_world.add_child(room_display)

	# Instanciar Player no mundo nativo 256x192
	player = preload("res://scenes/player.tscn").instantiate() as PlayerController
	game_world.add_child(player)

	# Carregar sala inicial (tenta caminho real exportado, ou fallback sintético)
	_load_initial_room()
	reset_player()
	call_deferred("_post_ready_layout")

var viewport_area: Control
var game_world: Node2D
var room_display: Node2D

func _post_ready_layout() -> void:
	if viewport_area:
		_update_world_transform(viewport_area.size)

func _on_viewport_resized() -> void:
	if viewport_area:
		_update_world_transform(viewport_area.size)

func _update_world_transform(area_size: Vector2) -> void:
	if not game_world or area_size.x <= 0.0 or area_size.y <= 0.0:
		return
	var zoom_x: float = floorf(area_size.x / 256.0)
	var zoom_y: float = floorf(area_size.y / 192.0)
	zoom = maxf(1.0, minf(zoom_x, zoom_y))
	canvas_origin = ((area_size - Vector2(256, 192) * zoom) / 2.0).floor()
	game_world.position = canvas_origin
	game_world.scale = Vector2(zoom, zoom)

func _draw_room_and_collision() -> void:
	if room_texture:
		room_display.draw_texture(room_texture, Vector2.ZERO)
	if show_collision and snapshot.loaded:
		for i: int in range(768):
			if int(snapshot.collision[i]) == 1:
				var cell := Vector2(i % 32, i / 32) * 8.0
				room_display.draw_rect(Rect2(cell, Vector2(8, 8)), Color(1.0, 0.2, 0.1, 0.35))
				room_display.draw_rect(Rect2(cell, Vector2(8, 8)), Color(1.0, 0.2, 0.1, 0.8), false, 1.0)

func _load_initial_room() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	for i: int in range(arguments.size() - 1):
		if arguments[i] == "--snapshot":
			if snapshot.load_path(arguments[i + 1]) == OK:
				_apply_snapshot()
				return
		elif arguments[i] == "--room":
			var req_id: int = arguments[i + 1].to_int()
			var snap := room_manager.load_room_snapshot(req_id)
			if snap != null:
				snapshot = snap
				_apply_snapshot()
				return

	# Tentar carregar Sala 1 do Prédio 1 (entrada com caixas)
	var initial_snap := room_manager.load_room_snapshot(1)
	if initial_snap != null:
		snapshot = initial_snap
		_apply_snapshot()
		return

	# Fallback sintético limpo caso nenhuma extração esteja presente
	_create_synthetic_fallback_room()

func _apply_snapshot() -> void:
	room_texture = ImageTexture.create_from_image(snapshot.make_image())
	if player:
		player.set_collision_grid(snapshot.collision)
	_spawn_room_enemies(snapshot.room_id)
	status_label.text = "Sala %03d · %s · Use Setas/WASD para mover Snake entre as salas" % [snapshot.room_id, snapshot.source]
	print("SANDBOX_ROOM_LOADED: %d (Inimigos: %d)" % [snapshot.room_id, enemies.size()])
	if room_display:
		room_display.queue_redraw()

func _spawn_room_enemies(room_id: int) -> void:
	for enemy: EnemyGuard in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()

	if not game_world:
		return

	var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
	if room_id == 1:
		# Sala 001 (fachada com caixas): 3 guardas autênticos da ROM (data/actorsinrooms.asm:6)
		# Guarda 0: MEDIUM (1.0 px/tick), spawn (64, 176), rota horizontal inferior
		var g0: EnemyGuard = enemy_scene.instantiate() as EnemyGuard
		g0.guard_type = EnemyGuard.GuardType.MEDIUM
		g0.position = Vector2(64.0, 176.0)
		g0.set_patrol_path([Vector2(200.0, 176.0), Vector2(56.0, 176.0)])
		g0.show_debug_vision = show_enemy_vision
		game_world.add_child(g0)
		enemies.append(g0)

		# Guarda 1: SLOW (0.5 px/tick), spawn (80, 80), rota de 8 pontos ao redor das caixas centrais
		var g1: EnemyGuard = enemy_scene.instantiate() as EnemyGuard
		g1.guard_type = EnemyGuard.GuardType.SLOW
		g1.position = Vector2(80.0, 80.0)
		g1.set_patrol_path([
			Vector2(56.0, 80.0), Vector2(56.0, 116.0), Vector2(200.0, 116.0), Vector2(200.0, 80.0),
			Vector2(168.0, 80.0), Vector2(168.0, 104.0), Vector2(88.0, 104.0), Vector2(88.0, 80.0)
		])
		g1.show_debug_vision = show_enemy_vision
		game_world.add_child(g1)
		enemies.append(g1)

		# Guarda 2: MEDIUM (1.0 px/tick), spawn (192, 24), rota horizontal superior
		var g2: EnemyGuard = enemy_scene.instantiate() as EnemyGuard
		g2.guard_type = EnemyGuard.GuardType.MEDIUM
		g2.position = Vector2(192.0, 24.0)
		g2.set_patrol_path([Vector2(56.0, 24.0), Vector2(200.0, 24.0)])
		g2.show_debug_vision = show_enemy_vision
		game_world.add_child(g2)
		enemies.append(g2)

	elif room_id == 2:
		# Sala 002 (corredor interno): 2 guardas autênticos da ROM (data/actorsinrooms.asm:14)
		var g0: EnemyGuard = enemy_scene.instantiate() as EnemyGuard
		g0.guard_type = EnemyGuard.GuardType.SLOW
		g0.position = Vector2(64.0, 48.0)
		g0.set_patrol_path([Vector2(72.0, 48.0), Vector2(136.0, 48.0), Vector2(168.0, 48.0)])
		g0.show_debug_vision = show_enemy_vision
		game_world.add_child(g0)
		enemies.append(g0)

		var g1: EnemyGuard = enemy_scene.instantiate() as EnemyGuard
		g1.guard_type = EnemyGuard.GuardType.MEDIUM
		g1.position = Vector2(168.0, 112.0)
		g1.set_patrol_path([Vector2(88.0, 112.0), Vector2(168.0, 112.0)])
		g1.show_debug_vision = show_enemy_vision
		game_world.add_child(g1)
		enemies.append(g1)

func _create_synthetic_fallback_room() -> void:
	var pixels: Array[int] = []
	pixels.resize(49152)
	pixels.fill(2) # Verde chão
	var collision: Array[int] = []
	collision.resize(768)
	collision.fill(0)
	# Paredes nas bordas
	for ty: int in range(24):
		for tx: int in range(32):
			if tx == 0 or tx == 31 or ty == 0 or ty == 23:
				collision[ty * 32 + tx] = 1
				for py: int in range(8):
					for px: int in range(8):
						pixels[(ty * 8 + py) * 256 + (tx * 8 + px)] = 1 # Parede
			# Bloco de obstáculo central
			if tx >= 12 and tx <= 19 and ty >= 8 and ty <= 12:
				collision[ty * 32 + tx] = 1
				for py: int in range(8):
					for px: int in range(8):
						pixels[(ty * 8 + py) * 256 + (tx * 8 + px)] = 1
	var palette: Array = []
	for i: int in range(18):
		palette.append([0, 0, 0])
	palette[1] = [120, 120, 120] # Cinza parede
	palette[2] = [40, 100, 40]   # Verde chão

	snapshot.decode({
		"format_version": "1.0.0", "room_id": 999, "width": 256, "height": 192,
		"pixels": pixels, "collision": collision, "palette_rgb": palette,
		"source": "synthetic_sandbox", "input_sha256": "0".repeat(64)
	})
	_apply_snapshot()

func reset_player() -> void:
	if player:
		# Posição inicial livre na sala
		player.set_grid_position(DEFAULT_SPAWN_X, DEFAULT_SPAWN_Y)
		player.current_direction = PlayerController.Direction.UP
		player.is_moving = false
		player.life = 24
		player.invulnerable_timer = 0
		player.punch_timer = 0
		player.queue_redraw()
	if snapshot:
		_spawn_room_enemies(snapshot.room_id)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			show_collision = not show_collision
			collision_btn.set_pressed_no_signal(show_collision)
			if room_display:
				room_display.queue_redraw()
		elif event.keycode == KEY_V:
			if player:
				player.show_debug_colliders = not player.show_debug_colliders
				colliders_btn.set_pressed_no_signal(player.show_debug_colliders)
				player.queue_redraw()
		elif event.keycode == KEY_B:
			show_enemy_vision = not show_enemy_vision
			vision_btn.set_pressed_no_signal(show_enemy_vision)
			for enemy: EnemyGuard in enemies:
				if is_instance_valid(enemy):
					enemy.show_debug_vision = show_enemy_vision
					enemy.queue_redraw()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_Z or event.keycode == KEY_J:
			if player:
				player.punch()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			reset_player()

func _physics_process(_delta: float) -> void:
	if not player:
		return

	# Leitura de entrada com prioridade de eixos autêntica MSX
	var input_dir := Vector2i.ZERO
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		input_dir = Vector2i(0, -1)
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		input_dir = Vector2i(0, 1)
	elif Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		input_dir = Vector2i(-1, 0)
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		input_dir = Vector2i(1, 0)

	var moved: bool = player.step_tick(input_dir)
	if moved:
		_check_and_handle_room_transition()

	# Atualizar soldados inimigos, perseguição e combate
	var any_alert: bool = false
	var defeated_count: int = 0
	for enemy: EnemyGuard in enemies:
		if is_instance_valid(enemy):
			enemy.step_tick(snapshot.collision, player.position, player.is_punching, player.current_direction, player)
			if enemy.is_alert and not enemy.is_dead:
				any_alert = true
			if enemy.is_dead:
				defeated_count += 1

	var blocks: int = maxi(0, player.life / 3)
	var empty_blocks: int = maxi(0, (player.max_life - player.life) / 3)
	var life_bar: String = "■".repeat(blocks) + "□".repeat(empty_blocks)

	if player.life <= 0:
		status_label.text = "SNAKE MORREU! [Pressione R para reiniciar]"
		status_label.modulate = Color(1.0, 0.1, 0.1)
	elif any_alert:
		status_label.text = "ALERTA! Soldados em perseguição! | VIDA: [%s] %02d/%02d (Derrotados: %d/%d)" % [
			life_bar, player.life, player.max_life, defeated_count, enemies.size()
		]
		status_label.modulate = Color(1.0, 0.3, 0.3)
	elif snapshot.loaded:
		status_label.text = "Sala %03d · %s | VIDA: [%s] %02d/%02d · Espaço: Soco" % [
			snapshot.room_id, snapshot.source, life_bar, player.life, player.max_life
		]
		status_label.modulate = Color(1.0, 1.0, 1.0)

func _check_and_handle_room_transition() -> void:
	if not player or not snapshot:
		return

	var exit_dir: int = RoomManager.check_room_exit(player.position)
	if exit_dir == 0:
		return

	var next_room_id: int = RoomManager.get_next_room(snapshot.room_id, exit_dir)
	if next_room_id != RoomManager.NO_ROOM:
		var entry_pos: Vector2 = RoomManager.get_entry_position(exit_dir, player.position)
		change_to_room(next_room_id, entry_pos)
	else:
		_clamp_to_room_bounds(exit_dir)

func _clamp_to_room_bounds(exit_dir: int) -> void:
	if not player:
		return
	match exit_dir:
		PlayerController.Direction.LEFT:
			player.position.x = RoomManager.EXIT_LEFT_X
		PlayerController.Direction.RIGHT:
			player.position.x = RoomManager.EXIT_RIGHT_X - 0.1
		PlayerController.Direction.UP:
			player.position.y = RoomManager.EXIT_UP_Y
		PlayerController.Direction.DOWN:
			player.position.y = RoomManager.EXIT_DOWN_Y - 0.1
	player.queue_redraw()

func change_to_room(new_room_id: int, entry_pos: Vector2) -> bool:
	var snap: RoomSnapshot = room_manager.load_room_snapshot(new_room_id)
	if snap == null:
		print("ROOM_TRANSITION_ABORTED: snapshot para sala %d não encontrado localmente" % new_room_id)
		return false

	snapshot = snap
	_apply_snapshot()
	if player:
		player.set_grid_position(entry_pos.x, entry_pos.y)
		player.queue_redraw()
	print("ROOM_TRANSITION_OK: transição para sala %d na posição %s" % [new_room_id, entry_pos])
	return true
