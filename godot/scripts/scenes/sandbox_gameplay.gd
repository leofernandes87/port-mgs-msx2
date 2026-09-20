extends Control
## Cena de teste jogável de Snake com movimentação e colisão fiéis ao MSX2 (Etapa 5).

var snapshot: RoomSnapshot = RoomSnapshot.new()
var player: PlayerController
var room_manager: RoomManager = RoomManager.new()
var enemies: Array[EnemyGuard] = []
var inventory: InventoryManager = InventoryManager.new()
var weapon_system: WeaponSystem = WeaponSystem.new()
var radio_system: RadioSystem = RadioSystem.new()
var radio_dialog: RadioDialog
var bullets: Array[Bullet] = []
var silencer_dropped_room_150: bool = false
var item_boxes: Array[ItemBox] = []
var room_doors: Array[RoomDoor] = []
var room_texture: ImageTexture
var show_collision: bool = false
var show_enemy_vision: bool = false
var zoom: float = 3.0
var canvas_origin: Vector2 = Vector2.ZERO

# 55 salas onde tiros sem silenciador NÃO alertam a guarnição (RoomShotSecure em logic/checkweaponalert.asm:37-40)
const ROOMS_SHOT_SECURE: Array[int] = [
	5, 6, 9, 10, 20, 29, 37, 50, 64, 65, 66, 67, 68, 71, 83, 102,
	103, 110, 119, 120, 150, 193, 208, 209, 54, 55, 56, 57, 58, 59, 60, 61,
	62, 63, 93, 94, 95, 96, 97, 98, 99, 100, 101, 111, 112, 113, 114, 115,
	116, 118, 123, 124, 125, 220, 221
]

var previous_room_id: int = -1
var is_in_elevator: bool = false
var elevator_cabin: ElevatorCabin
var elevator_y: float = 180.0
var elevator_target_y: float = 180.0
var elevator_state: int = ELEVATOR_STATE_IDLE
const ELEVATOR_STATE_IDLE: int = 0
const ELEVATOR_STATE_MOVING: int = 1

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
	help_label.text = "· Mover: Setas/WASD · Atirar: Espaço/F · Soco: M/Z/J · Arma: Q · Kit Teste: G · Item: E · Ração: U"
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

	# Cabine visual do elevador
	elevator_cabin = ElevatorCabin.new()
	elevator_cabin.visible = false
	game_world.add_child(elevator_cabin)

	# Instanciar Player no mundo nativo 256x192
	player = preload("res://scenes/player.tscn").instantiate() as PlayerController
	game_world.add_child(player)

	# Carregar sala inicial (tenta caminho real exportado, ou fallback sintético)
	_load_initial_room()
	reset_player()

	# Sistema de Rádio Transceptor (Etapa 15)
	radio_dialog = RadioDialog.new()
	add_child(radio_dialog)
	radio_dialog.radio_closed.connect(_on_radio_closed)
	if snapshot and snapshot.loaded:
		radio_system.check_incoming_call(snapshot.room_id)

	call_deferred("_post_ready_layout")

func _on_radio_closed() -> void:
	if player:
		player.queue_redraw()

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
	_spawn_room_items(snapshot.room_id)
	_spawn_room_doors(snapshot.room_id)
	print("SANDBOX_ROOM_LOADED: %d (Inimigos: %d, Itens: %d, Portas: %d)" % [
		snapshot.room_id, enemies.size(), item_boxes.size(), room_doors.size()
	])
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
	var room_data: Dictionary = room_manager.load_room_actors(room_id)
	var actors_data: Array = room_data.get("actors", [])

	if not actors_data.is_empty():
		# Tipos de atores que são combatentes/vigias/animais no MSX2 (Banks0123.asm:6404)
		# 4: GuardSlow, 5: GuardMedium, 10/11: GuardAlert, 13: Shooter, 14: GuardElevat, 19: GuardLorry,
		# 24: GuardSwitch, 25/27: Dog, 28: LorryShooter, 30: GuardFast, 31: Scorpion, 46: DesertSecurity, 48: Sentinel, 57: GuardSilencer
		var valid_enemy_types: Array[int] = [4, 5, 10, 11, 13, 14, 19, 24, 25, 27, 28, 30, 31, 46, 48, 57]

		for act_variant: Variant in actors_data:
			if not act_variant is Dictionary:
				continue
			var act: Dictionary = act_variant as Dictionary
			var type_id: int = int(act.get("actor_type_id", 0))
			if not type_id in valid_enemy_types:
				continue

			var spawn_pos := Vector2(float(act.get("x", 0)), float(act.get("y", 0)))

			var g: EnemyGuard = enemy_scene.instantiate() as EnemyGuard
			g.actor_type_id = type_id
			if type_id in [13, 57]:
				g.is_shooter = true
			# Mapeamento fiel das velocidades da ROM
			if type_id in [4, 14, 24, 31, 46, 48]:
				g.guard_type = EnemyGuard.GuardType.SLOW
			elif type_id in [25, 27, 30]:
				g.guard_type = EnemyGuard.GuardType.FAST
			else:
				g.guard_type = EnemyGuard.GuardType.MEDIUM

			g.position = spawn_pos

			var raw_path: Array = act.get("patrol_path", [])
			var waypoints: Array[Vector2] = []

			# Cães de guarda (ID 25, 27) não utilizam waypoints na ROM (dog.asm: InitDog / DogSleep)
			# Eles iniciam adormecidos/vigilantes no ponto de spawn e só perseguem com alarme
			if type_id in [25, 27]:
				raw_path = []

			for pt_variant: Variant in raw_path:
				if pt_variant is Array and (pt_variant as Array).size() >= 2:
					var pt: Array = pt_variant as Array
					# JSON armazena [y, x]
					waypoints.append(Vector2(float(pt[1]), float(pt[0])))

			if waypoints.is_empty():
				if type_id == 48 or type_id in [25, 27]:
					# Sentinela ou Cão no posto: permanece na posição de spawn
					waypoints.append(spawn_pos)
				else:
					var left_x: float = clampf(spawn_pos.x - 32.0, 16.0, 240.0)
					var right_x: float = clampf(spawn_pos.x + 32.0, 16.0, 240.0)
					waypoints.append(Vector2(left_x, spawn_pos.y))
					waypoints.append(Vector2(right_x, spawn_pos.y))

			g.set_patrol_path(waypoints)
			g.show_debug_vision = show_enemy_vision
			game_world.add_child(g)
			enemies.append(g)
	else:
		_spawn_room_enemies_fallback(room_id, enemy_scene)

func _spawn_room_enemies_fallback(room_id: int, enemy_scene: PackedScene) -> void:
	if room_id == 1:
		var g0: EnemyGuard = enemy_scene.instantiate() as EnemyGuard
		g0.guard_type = EnemyGuard.GuardType.MEDIUM
		g0.position = Vector2(64.0, 176.0)
		g0.set_patrol_path([Vector2(200.0, 176.0), Vector2(56.0, 176.0)])
		g0.show_debug_vision = show_enemy_vision
		game_world.add_child(g0)
		enemies.append(g0)

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

		var g2: EnemyGuard = enemy_scene.instantiate() as EnemyGuard
		g2.guard_type = EnemyGuard.GuardType.MEDIUM
		g2.position = Vector2(192.0, 24.0)
		g2.set_patrol_path([Vector2(56.0, 24.0), Vector2(200.0, 24.0)])
		g2.show_debug_vision = show_enemy_vision
		game_world.add_child(g2)
		enemies.append(g2)
	elif room_id == 2:
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
	elif room_id == 5:
		var g0: EnemyGuard = enemy_scene.instantiate() as EnemyGuard
		g0.guard_type = EnemyGuard.GuardType.MEDIUM
		g0.position = Vector2(112.0, 120.0)
		g0.set_patrol_path([Vector2(80.0, 120.0), Vector2(176.0, 120.0)])
		g0.show_debug_vision = show_enemy_vision
		game_world.add_child(g0)
		enemies.append(g0)
	elif room_id == 127:
		var g0: EnemyGuard = enemy_scene.instantiate() as EnemyGuard
		g0.guard_type = EnemyGuard.GuardType.MEDIUM
		g0.position = Vector2(72.0, 112.0)
		g0.set_patrol_path([Vector2(72.0, 88.0), Vector2(72.0, 112.0)])
		g0.show_debug_vision = show_enemy_vision
		game_world.add_child(g0)
		enemies.append(g0)

func _spawn_room_items(room_id: int) -> void:
	for box: ItemBox in item_boxes:
		if is_instance_valid(box):
			box.queue_free()
	item_boxes.clear()

	if not game_world:
		return

	var room_data: Dictionary = room_manager.load_room_actors(room_id)
	var items_data: Array = room_data.get("items", [])

	if not items_data.is_empty():
		for item_variant: Variant in items_data:
			if not item_variant is Dictionary:
				continue
			var item_dict: Dictionary = item_variant as Dictionary
			var type_id: int = int(item_dict.get("item_type_id", 0))
			var pos := Vector2(float(item_dict.get("x", 0)), float(item_dict.get("y", 0)))

			var b: ItemBox = ItemBox.new()
			b.room_id = room_id
			b.position = pos

			match type_id:
				1:
					b.item_id = WeaponSystem.WEAPON_HANDGUN
				2:
					b.item_id = WeaponSystem.WEAPON_SMG
				3:
					b.item_id = WeaponSystem.WEAPON_GRENADE_LAUNCHER
				8:
					b.item_id = InventoryManager.ITEM_SILENCER
				13:
					b.item_id = InventoryManager.ITEM_GAS_MASK
				17:
					b.item_id = InventoryManager.ITEM_BINOCULARS
				21, 30:
					b.item_id = InventoryManager.ITEM_RATION
				22:
					b.item_id = InventoryManager.ITEM_CARD1
				23:
					b.item_id = InventoryManager.ITEM_CARD2
				24:
					b.item_id = InventoryManager.ITEM_CARD3
				25:
					b.item_id = InventoryManager.ITEM_CARD4
				26:
					b.item_id = InventoryManager.ITEM_CARD5
				27:
					b.item_id = InventoryManager.ITEM_CARD6
				28:
					b.item_id = InventoryManager.ITEM_CARD7
				29:
					b.item_id = InventoryManager.ITEM_CARD8
				35:
					b.item_id = InventoryManager.ITEM_AMMO_CRATE
				_:
					b.item_id = InventoryManager.ITEM_RATION

			game_world.add_child(b)
			item_boxes.append(b)

	# Salas de progressão especial (salas < 122 onde itens são ativados por narrativa/chaves)
	if room_id == 4 and item_boxes.is_empty():
		var b: ItemBox = ItemBox.new()
		b.item_id = InventoryManager.ITEM_CARD1
		b.room_id = room_id
		b.position = Vector2(112.0, 80.0)
		game_world.add_child(b)
		item_boxes.append(b)
	elif room_id == 6 and item_boxes.is_empty():
		var b: ItemBox = ItemBox.new()
		b.item_id = InventoryManager.ITEM_RATION
		b.room_id = room_id
		b.position = Vector2(96.0, 64.0)
		game_world.add_child(b)
		item_boxes.append(b)


func _spawn_room_doors(room_id: int) -> void:
	for door: RoomDoor in room_doors:
		if is_instance_valid(door):
			door.queue_free()
	room_doors.clear()

	if not game_world:
		return

	# Portas interativas autênticas (data/doors.asm:308-320, 634-638)
	if room_id == 5:
		# Sala 005: Pátio dos 3 caminhões (DoorsRoom005 em data/doors.asm:311-316)
		# Caminhão 1 (Esquerda) -> leva à Sala 126
		var d1: RoomDoor = RoomDoor.new()
		d1.door_id = 101 # 0x65
		d1.room_id = room_id
		d1.is_lorry = true
		d1.orientation = RoomDoor.DoorOrientation.LORRY_ENTER
		d1.position = Vector2(36.0, 68.0)
		d1.trigger_rect = Rect2(32.0, 80.0, 32.0, 16.0)
		d1.destination_room = 126
		d1.entry_position = Vector2(196.0, 112.0)
		d1.destination_direction = PlayerController.Direction.LEFT
		game_world.add_child(d1)
		room_doors.append(d1)

		# Caminhão 2 (Meio) -> leva à Sala 127
		var d2: RoomDoor = RoomDoor.new()
		d2.door_id = 109 # 0x6D
		d2.room_id = room_id
		d2.is_lorry = true
		d2.orientation = RoomDoor.DoorOrientation.LORRY_ENTER
		d2.position = Vector2(100.0, 100.0)
		d2.trigger_rect = Rect2(96.0, 112.0, 32.0, 16.0)
		d2.destination_room = 127
		d2.entry_position = Vector2(196.0, 112.0)
		d2.destination_direction = PlayerController.Direction.LEFT
		game_world.add_child(d2)
		room_doors.append(d2)

		# Caminhão 3 (Direita) -> leva à Sala 128
		var d3: RoomDoor = RoomDoor.new()
		d3.door_id = 113 # 0x71
		d3.room_id = room_id
		d3.is_lorry = true
		d3.orientation = RoomDoor.DoorOrientation.LORRY_ENTER
		d3.position = Vector2(164.0, 68.0)
		d3.trigger_rect = Rect2(160.0, 80.0, 32.0, 16.0)
		d3.destination_room = 128
		d3.entry_position = Vector2(196.0, 112.0)
		d3.destination_direction = PlayerController.Direction.LEFT
		game_world.add_child(d3)
		room_doors.append(d3)

	elif room_id in [126, 127, 128]:
		# Saída da traseira de dentro do caminhão de volta ao pátio da Sala 5 (DoorsRoom126-128 em data/doors.asm:634-638)
		var exit_d: RoomDoor = RoomDoor.new()
		exit_d.room_id = room_id
		exit_d.is_lorry = true
		exit_d.orientation = RoomDoor.DoorOrientation.LORRY_EXIT
		exit_d.position = Vector2(208.0, 96.0)
		exit_d.trigger_rect = Rect2(204.0, 92.0, 24.0, 36.0)
		exit_d.destination_room = 5
		exit_d.destination_direction = PlayerController.Direction.DOWN

		if room_id == 126:
			exit_d.door_id = 101
			exit_d.entry_position = Vector2(48.0, 104.0)
		elif room_id == 127:
			exit_d.door_id = 109
			exit_d.entry_position = Vector2(112.0, 136.0)
		elif room_id == 128:
			exit_d.door_id = 113
			exit_d.entry_position = Vector2(176.0, 104.0)

		game_world.add_child(exit_d)
		room_doors.append(exit_d)

	elif room_id == 2:
		# Porta oeste trancada (exige CARD1!) para acessar a sala 4
		var d: RoomDoor = RoomDoor.new()
		d.door_id = 1
		d.room_id = room_id
		d.required_card = InventoryManager.ITEM_CARD1
		d.orientation = RoomDoor.DoorOrientation.WEST
		d.position = Vector2(16.0, 96.0)
		d.destination_room = 4
		d.entry_position = Vector2(230.0, 96.0)
		game_world.add_child(d)
		d.inject_collision(snapshot.collision)
		room_doors.append(d)
	elif room_id == 4:
		# Porta leste de retorno para a sala 2 (aberta pelo lado interno)
		var d: RoomDoor = RoomDoor.new()
		d.door_id = 2
		d.room_id = room_id
		d.required_card = ""
		d.orientation = RoomDoor.DoorOrientation.EAST
		d.position = Vector2(232.0, 96.0)
		d.destination_room = 2
		d.entry_position = Vector2(32.0, 96.0)
		game_world.add_child(d)
		d.inject_collision(snapshot.collision)
		room_doors.append(d)
	else:
		# Portas canônicas carregadas de stage5-batch/room-NNN-actors.json
		var room_data: Dictionary = room_manager.load_room_actors(room_id)
		var doors_data: Array = room_data.get("doors", [])
		for door_var: Variant in doors_data:
			if not door_var is Dictionary:
				continue
			var d_info: Dictionary = door_var as Dictionary
			var d_id: int = int(d_info.get("door_id", 0))
			var r_type: int = int(d_info.get("render_type_id", 1))
			var dest_room: int = int(d_info.get("destination_room_id", -1))
			var rule_id: int = int(d_info.get("open_rule_id", 1))
			var dx: float = float(d_info.get("draw_x", 0))
			var dy: float = float(d_info.get("draw_y", 0))

			# Portas dummy/invisíveis ou sem destino
			if r_type == 6 or dest_room == -1:
				continue

			var d: RoomDoor = RoomDoor.new()
			d.door_id = d_id
			d.room_id = room_id
			d.render_type_id = r_type
			d.open_rule_id = rule_id
			d.position = Vector2(dx, dy)
			d.destination_room = dest_room

			match r_type:
				1, 5:
					d.orientation = RoomDoor.DoorOrientation.NORTH
					d.entry_position = Vector2(dx + 8.0, 160.0)
					d.destination_direction = PlayerController.Direction.DOWN
				2:
					d.orientation = RoomDoor.DoorOrientation.SOUTH
					d.entry_position = Vector2(dx + 8.0, 32.0)
					d.destination_direction = PlayerController.Direction.UP
				3:
					d.orientation = RoomDoor.DoorOrientation.WEST
					d.entry_position = Vector2(230.0, dy)
					d.destination_direction = PlayerController.Direction.RIGHT
				4:
					d.orientation = RoomDoor.DoorOrientation.EAST
					d.entry_position = Vector2(24.0, dy)
					d.destination_direction = PlayerController.Direction.LEFT
				_:
					d.orientation = RoomDoor.DoorOrientation.NORTH
					d.entry_position = Vector2(dx + 8.0, 160.0)
					d.destination_direction = PlayerController.Direction.DOWN

			d.required_card = RoomDoor.get_card_for_rule(rule_id)

			game_world.add_child(d)
			if snapshot and snapshot.loaded:
				d.inject_collision(snapshot.collision)
			room_doors.append(d)

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
	for b: Bullet in bullets:
		if is_instance_valid(b):
			b.queue_free()
	bullets.clear()
	if snapshot:
		_spawn_room_enemies(snapshot.room_id)
		_spawn_room_items(snapshot.room_id)
		_spawn_room_doors(snapshot.room_id)

func _input(event: InputEvent) -> void:
	if radio_dialog and radio_dialog.is_active:
		if radio_dialog.handle_input(event):
			get_viewport().set_input_as_handled()
			return

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
		elif event.keycode == KEY_T or event.keycode == KEY_F4:
			if radio_dialog:
				if radio_dialog.is_active:
					radio_dialog.close_radio()
				else:
					radio_dialog.open_radio(radio_system, snapshot.room_id, radio_system.has_incoming_call)
				get_viewport().set_input_as_handled()
				return
		elif event.keycode == KEY_Q or event.keycode == KEY_1 or event.keycode == KEY_2:
			weapon_system.cycle_weapon()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_F:
			if player and not weapon_system.selected_weapon.is_empty():
				if weapon_system.can_fire():
					var b: Bullet = player.fire_weapon(weapon_system)
					if b != null:
						bullets.append(b)
						game_world.add_child(b)
						# Acústica e Alerta de tiro (ChkAlertTrigger em logic/checkweaponalert.asm:8-30)
						if not weapon_system.has_silencer and not snapshot.room_id in ROOMS_SHOT_SECURE:
							for enemy: EnemyGuard in enemies:
								if is_instance_valid(enemy) and not enemy.is_dead:
									enemy.trigger_alert()
							print("GUNSHOT_ALERT: Disparo sem silenciador na sala %d alertou a guarnição!" % snapshot.room_id)
						else:
							print("GUNSHOT_SILENT: Disparo furtivo com silenciador!")
				else:
					print("WEAPON_NO_AMMO: Arma sem munição! (Click SFX 15h)")
			elif player:
				player.punch()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M or event.keycode == KEY_Z or event.keycode == KEY_J:
			if player:
				player.punch()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E:
			inventory.cycle_item()
		elif event.keycode == KEY_U:
			inventory.use_selected_item(player)
		elif event.keycode == KEY_G:
			weapon_system.add_weapon(WeaponSystem.WEAPON_HANDGUN, 30)
			weapon_system.add_weapon(WeaponSystem.WEAPON_SMG, 30)
			weapon_system.set_silencer(not weapon_system.has_silencer)
			print("DEBUG_WEAPON_KIT: Kit de armas concedido! Handgun + SMG + Silenciador alternado.")
		elif event.keycode == KEY_R:
			reset_player()

func _physics_process(_delta: float) -> void:
	if not player:
		return

	# Pausa movimentação e combate de todos os atores enquanto o rádio estiver ativo
	if radio_dialog and radio_dialog.is_active:
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

	if is_in_elevator:
		# Mecânica de Elevador fiel ao MSX2 (Banks0123.asm:8540-8556 e logic/elevatorroom.asm)
		if elevator_state == ELEVATOR_STATE_MOVING:
			# Cabine em trânsito vertical a 1 px/tick (GameMode = GAME_MODE_ELEVATOR)
			# Snake fica imóvel (SetSprIdle) dentro da cabine
			player.is_moving = false
			var dir_y: float = -1.0 if elevator_target_y < elevator_y else 1.0
			elevator_y += dir_y * ElevatorSystem.ELEVATOR_SPEED
			if elevator_cabin:
				elevator_cabin.elevator_y = elevator_y
			# Snake é transportado pela cabine (PlayerY dec/inc junto com ElevatorY)
			player.position.y = elevator_y + 4.0
			player.queue_redraw()

			# Checar se atingiu o andar de destino
			if absf(elevator_y - elevator_target_y) < 0.5:
				elevator_y = elevator_target_y
				if elevator_cabin:
					elevator_cabin.elevator_y = elevator_y
				player.position.y = elevator_y + 4.0
				elevator_state = ELEVATOR_STATE_IDLE
				print("ELEVATOR_FLOOR_REACHED: Andar atingido (Y: %.1f)" % elevator_y)
		else:
			# Elevador parado no andar:
			# 1. Se Snake estiver na cabine (PlayerX <= 120), aceita CIMA/BAIXO para acionar o elevador
			if player.position.x <= ElevatorSystem.CABIN_TRIGGER_X and input_dir.y != 0:
				var target_info: Dictionary = ElevatorSystem.get_next_target_floor(snapshot.room_id, elevator_y, input_dir.y)
				if bool(target_info.get("has_target", false)):
					elevator_target_y = float(target_info.get("target_elev_y", elevator_y))
					elevator_state = ELEVATOR_STATE_MOVING
					player.is_moving = false
					player.queue_redraw()
					return

			# 2. Caminhada de Snake na passarela do andar:
			# No MSX2 (ControlPlayerH), a entrada vertical é filtrada (and 0Ch)!
			# Snake NUNCA se move no eixo Y por comando de pernas no elevador.
			var walk_dir := Vector2i(input_dir.x, 0)
			if walk_dir.x != 0:
				player.step_tick(walk_dir)
				# Limite esquerdo da cabine (parede esquerda)
				if player.position.x < ElevatorSystem.SHAFT_MIN_X:
					player.position.x = ElevatorSystem.SHAFT_MIN_X
					player.queue_redraw()

				# Checar se Snake atinge o limite direito para sair do elevador no andar correspondente
				var exit_res: Dictionary = ElevatorSystem.check_exit(snapshot.room_id, player.position, elevator_y)
				if bool(exit_res.get("should_exit", false)):
					var dest_room: int = int(exit_res.get("destination_room_id", -1))
					var dest_pos: Vector2 = exit_res.get("entry_position", Vector2(108.0, 36.0)) as Vector2
					var dest_dir: int = int(exit_res.get("destination_direction", PlayerController.Direction.DOWN))
					print("ELEVATOR_EXIT: Snake saiu do elevador %d para sala %d na posição %s" % [snapshot.room_id, dest_room, dest_pos])
					change_to_room(dest_room, dest_pos, dest_dir)
					return
			else:
				player.is_moving = false
				player.queue_redraw()
	else:
		var moved: bool = player.step_tick(input_dir)
		if moved:
			_check_and_handle_room_transition()

	# Atualizar caixas de itens e armas coletáveis
	for box: ItemBox in item_boxes:
		if is_instance_valid(box) and not box.collected:
			box.step_tick(player.position, inventory, weapon_system)

	# Atualizar portas interativas
	for door: RoomDoor in room_doors:
		if is_instance_valid(door):
			var target_room: int = door.check_interaction(player, inventory, snapshot.collision)
			if target_room != -1:
				change_to_room(target_room, door.entry_position, door.destination_direction, door.door_id)
				break

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
			elif not enemy.is_dead:
				# Inimigos atiradores ou em alerta tentam disparar contra Snake
				var enemy_shot: Bullet = enemy.try_shoot(player.position)
				if enemy_shot != null:
					bullets.append(enemy_shot)
					game_world.add_child(enemy_shot)

	# Atualizar física e colisões dos projéteis balísticos (balas de Snake e de soldados)
	var surviving_bullets: Array[Bullet] = []
	for b: Bullet in bullets:
		if not is_instance_valid(b):
			continue
		var alive: bool = b.step_tick(snapshot.collision)
		if not alive:
			b.queue_free()
			continue

		var hit: bool = false
		if b.is_enemy:
			# Projétil inimigo atinge Snake (raio <= 10 px)
			if b.position.distance_to(player.position) <= 10.0:
				player.apply_damage(b.damage)
				hit = true
		else:
			# Projétil de Snake atinge soldado inimigo
			for enemy: EnemyGuard in enemies:
				if is_instance_valid(enemy) and not enemy.is_dead:
					if enemy.check_bullet_hit(b.position):
						enemy.take_bullet_hit(b.damage)
						hit = true
						break

		if hit:
			b.queue_free()
		else:
			surviving_bullets.append(b)
	bullets = surviving_bullets

	# Evento canônico da Sala 150 (Banks0123.asm:6117, 13037):
	# Quando os 4 guardas silenciadores (actor_type_id 57) são eliminados, o SUPRESSOR é dropado em (36, 98)
	if snapshot.room_id == 150 and not silencer_dropped_room_150:
		var silencer_guards_alive: int = 0
		var silencer_guards_total: int = 0
		for enemy: EnemyGuard in enemies:
			if is_instance_valid(enemy) and enemy.actor_type_id == 57:
				silencer_guards_total += 1
				if not enemy.is_dead:
					silencer_guards_alive += 1
		if silencer_guards_total > 0 and silencer_guards_alive == 0:
			silencer_dropped_room_150 = true
			var silencer_box: ItemBox = ItemBox.new()
			silencer_box.item_id = InventoryManager.ITEM_SILENCER
			silencer_box.room_id = 150
			silencer_box.position = Vector2(36.0, 98.0)
			game_world.add_child(silencer_box)
			item_boxes.append(silencer_box)
			print("SILENCER_DROPPED: 4 guardas silenciadores derrotados! Silenciador liberado em (36, 98)!")

	var blocks: int = maxi(0, player.life / 3)
	var empty_blocks: int = maxi(0, (player.max_life - player.life) / 3)
	var life_bar: String = "■".repeat(blocks) + "□".repeat(empty_blocks)
	var item_str: String = inventory.get_status_text()
	var weapon_str: String = weapon_system.get_status_text()

	if radio_dialog and radio_dialog.is_active:
		status_label.text = "TRANSCEIVER CODEC ATIVO | Sintonize com A/D | Transmita com W | T/F4 para sair"
		status_label.modulate = Color("50e080")
		return

	var call_str: String = ""
	if radio_system.has_incoming_call:
		var flash: bool = (Engine.get_physics_frames() % 30 < 15)
		call_str = " | [CALL! Pressione T]" if flash else " | [      Pressione T]"

	if player.life <= 0:
		status_label.text = "SNAKE MORREU! [Pressione R para reiniciar]"
		status_label.modulate = Color(1.0, 0.1, 0.1)
	elif any_alert:
		status_label.text = "ALERTA! | ARMA: %s | VIDA: [%s] %02d/%02d | ITEM: %s%s (Derrotados: %d/%d)" % [
			weapon_str, life_bar, player.life, player.max_life, item_str, call_str, defeated_count, enemies.size()
		]
		status_label.modulate = Color(1.0, 0.3, 0.3)
	elif is_in_elevator:
		var state_str: String = "EM MOVIMENTO..." if elevator_state == ELEVATOR_STATE_MOVING else "PARADO (CIMA/BAIXO: Mover | DIREITA: Sair)"
		status_label.text = "ELEVADOR %d | Andar Y: %.0f | %s%s" % [
			snapshot.room_id, elevator_y, state_str, call_str
		]
		status_label.modulate = Color(0.9, 0.8, 0.3)
	elif snapshot.loaded:
		status_label.text = "Sala %03d | ARMA: %s | VIDA: [%s] %02d/%02d | ITEM: %s%s" % [
			snapshot.room_id, weapon_str, life_bar, player.life, player.max_life, item_str, call_str
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

func change_to_room(new_room_id: int, entry_pos: Vector2, entry_dir: int = -1, from_door_id: int = -1) -> bool:
	var old_room_id: int = snapshot.room_id if snapshot and snapshot.loaded else -1
	previous_room_id = old_room_id

	var snap: RoomSnapshot = room_manager.load_room_snapshot(new_room_id)
	if snap == null:
		print("ROOM_TRANSITION_ABORTED: snapshot para sala %d não encontrado localmente" % new_room_id)
		return false

	snapshot = snap
	_apply_snapshot()
	radio_system.check_incoming_call(new_room_id)

	for b: Bullet in bullets:
		if is_instance_valid(b):
			b.queue_free()
	bullets.clear()

	if ElevatorSystem.is_elevator_room(new_room_id):
		is_in_elevator = true
		elevator_state = ELEVATOR_STATE_IDLE
		var elev_state: Dictionary = ElevatorSystem.get_entry_state(new_room_id, old_room_id)
		elevator_y = float(elev_state.get("elevator_y", 180.0))
		elevator_target_y = elevator_y
		entry_pos = elev_state.get("player_pos", Vector2(216.0, 184.0)) as Vector2
		entry_dir = int(elev_state.get("player_dir", PlayerController.Direction.LEFT))
		if elevator_cabin:
			elevator_cabin.elevator_y = elevator_y
			elevator_cabin.visible = true
		print("ELEVATOR_ENTER: Snake entrou no elevador %d a partir da sala %d (Y: %.1f)" % [new_room_id, old_room_id, elevator_y])
	else:
		is_in_elevator = false
		elevator_state = ELEVATOR_STATE_IDLE
		if elevator_cabin:
			elevator_cabin.visible = false

		# Emparelhamento canônico de portas por IdDoorEnter (logic/nextroom.asm:398-453)
		if from_door_id != -1:
			var matched_door: RoomDoor = null
			for d: RoomDoor in room_doors:
				if is_instance_valid(d) and d.door_id == from_door_id:
					matched_door = d
					break
			if matched_door != null and not matched_door.is_lorry:
				var spawn_info: Dictionary = RoomDoor.get_door_spawn(matched_door.position, matched_door.render_type_id)
				entry_pos = spawn_info.get("pos", entry_pos) as Vector2
				entry_dir = int(spawn_info.get("dir", entry_dir))
				matched_door.open_door(snapshot.collision)
				print("DOOR_PAIR_MATCHED: Porta %d na sala %d (Render %d) -> Spawn em %s, Dir %d" % [
					from_door_id, new_room_id, matched_door.render_type_id, entry_pos, entry_dir
				])

	if player:
		player.set_grid_position(entry_pos.x, entry_pos.y)
		if entry_dir != -1:
			player.current_direction = entry_dir as PlayerController.Direction
		player.queue_redraw()
	print("ROOM_TRANSITION_OK: transição para sala %d na posição %s" % [new_room_id, entry_pos])
	return true
