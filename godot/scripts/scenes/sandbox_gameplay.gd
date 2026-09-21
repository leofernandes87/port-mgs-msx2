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
var cameras: Array[SecurityCamera] = []
var laser_system: LaserSystem
var bullets: Array[Bullet] = []
var silencer_dropped_room_150: bool = false
var item_boxes: Array[ItemBox] = []
var room_doors: Array[RoomDoor] = []
var runtime_collision: Array = []
var room_texture: ImageTexture
var show_collision: bool = false
var show_enemy_vision: bool = false
var infinite_life: bool = false
var god_mode_btn: CheckButton
var zoom: float = 3.0
var canvas_origin: Vector2 = Vector2.ZERO
var alert_system: AlertSystem = AlertSystem.new()
var rank_system: RankSystem = RankSystem.new()
var prisoners: Array[Prisoner] = []
var dialog_banner_label: Label = null
var is_game_over: bool = false
var game_over_banner: Label = null

## Boss Shoot Gunner (Etapa 18) — ID_SHOT_GUNNER = 0x21 (33), Sala 57
var shot_gunner: ShotGunner = null
var shot_gunner_bullets: Array[ShotGunnerBullet] = []
var boss_dialog_label: Label = null

## Perigo de Gás Tóxico (Etapa 19) — logic/damagegas.asm e logic/actors/gas.asm
var gas_hazard_system: GasHazardSystem = GasHazardSystem.new()
var gas_clouds: Array[GasCloud] = []

## Míssil Teleguiado por Controle Remoto (Etapa 20) — logic/weapon/missile.asm
var active_missile: RemoteMissile = null

## Evento de Captura na Sala 8 e Cela da Sala 211 (Etapa 21)
var capture_system: CaptureSystem = CaptureSystem.new()
var tilemap_layer: TileMapLayer = null

## Pisos Eletrificados e Painéis de Força (Etapa 22) — logic/damageelectric.asm e logic/actors/powerswitch.asm
var electrified_floor_system: ElectrifiedFloorSystem = ElectrifiedFloorSystem.new()
var power_panel: PowerPanel = null
var is_player_shocked_flash: int = 0

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
var call_badge: Label

var weapon_menu: WeaponMenu
var item_menu: ItemMenu
var pause_menu: PauseMenu

# Posição inicial oficial na Sala 121 em terra firme (após introdução: X = 128.0, Y = 80.0)
const INITIAL_ROOM_ID: int = 121
const DEFAULT_SPAWN_X: float = 128.0
const DEFAULT_SPAWN_Y: float = 80.0

func _ready() -> void:
	print("BOOT_OK: cena principal pronta")
	# Montar interface
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	# Linha 1: Título, Status de Vida/Alerta e Botão de Pause
	var header_bar := HBoxContainer.new()
	header_bar.add_theme_constant_override("separation", 12)
	column.add_child(header_bar)

	var title := Label.new()
	title.text = "Metal Gear MSX2"
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	header_bar.add_child(title)

	call_badge = Label.new()
	call_badge.text = " CALL [R] "
	call_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	call_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	call_badge.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	call_badge.modulate = Color(0.0, 0.0, 0.0, 0.0)  # Inicia invisível sem afetar layout
	header_bar.add_child(call_badge)

	status_label = Label.new()
	status_label.text = "Carregando..."
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.clip_text = true
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.custom_minimum_size = Vector2(80, 0)
	header_bar.add_child(status_label)

	var pause_btn := Button.new()
	pause_btn.text = "PAUSE [ESC]"
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.pressed.connect(_toggle_pause_menu)
	header_bar.add_child(pause_btn)

	# Área central de jogo (Control que contém e centraliza o mundo do jogo)
	viewport_area = Control.new()
	viewport_area.custom_minimum_size = Vector2(256, 192)
	viewport_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_area.clip_contents = true
	viewport_area.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport_area.resized.connect(_on_viewport_resized)
	column.add_child(viewport_area)

	# Overlay flutuante de diálogo do boss (dentro de viewport_area, preservando a altura e o zoom 100%)
	boss_dialog_label = Label.new()
	boss_dialog_label.visible = false
	boss_dialog_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	boss_dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_dialog_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
	boss_dialog_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	boss_dialog_label.add_theme_constant_override("shadow_offset_x", 1)
	boss_dialog_label.add_theme_constant_override("shadow_offset_y", 1)
	viewport_area.add_child(boss_dialog_label)

	# Banner inferior de diálogos e mensagens de reféns (MSX2 Text Window)
	dialog_banner_label = Label.new()
	dialog_banner_label.visible = false
	dialog_banner_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_banner_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	dialog_banner_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	dialog_banner_label.add_theme_constant_override("shadow_offset_x", 1)
	dialog_banner_label.add_theme_constant_override("shadow_offset_y", 1)
	viewport_area.add_child(dialog_banner_label)

	# Banner central de GAME OVER (MSX2 Style)
	game_over_banner = Label.new()
	game_over_banner.visible = false
	game_over_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	game_over_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_banner.text = "G A M E   O V E R\n\n[ REINICIANDO MISSÃO... ]"
	game_over_banner.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	game_over_banner.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	game_over_banner.add_theme_constant_override("shadow_offset_x", 2)
	game_over_banner.add_theme_constant_override("shadow_offset_y", 2)
	game_over_banner.z_index = 100
	viewport_area.add_child(game_over_banner)

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

	# Sistema de Feixes Laser Infravermelhos (Etapa 16)
	laser_system = LaserSystem.new()
	game_world.add_child(laser_system)
	laser_system.laser_triggered.connect(_on_laser_triggered)

	# Instanciar Player no mundo nativo 256x192
	player = preload("res://scenes/player.tscn").instantiate() as PlayerController
	game_world.add_child(player)
	player.player_died.connect(_on_player_died)

	# Carregar sala inicial (tenta caminho real exportado, ou fallback sintético)
	_load_initial_room()
	reset_player()


	# Sistema de Rádio Transceptor (Etapa 15)
	radio_dialog = RadioDialog.new()
	add_child(radio_dialog)
	radio_dialog.radio_closed.connect(_on_radio_closed)
	if snapshot and snapshot.loaded:
		radio_system.check_incoming_call(snapshot.room_id)
	# Máquina de Estados de Alerta Global e Reforços (Etapa 17)
	alert_system.state_changed.connect(_on_alert_state_changed)
	alert_system.reinforcement_requested.connect(_on_reinforcement_requested)

	# Menus modais MSX2
	weapon_menu = WeaponMenu.new()
	weapon_menu.visible = false
	weapon_menu.weapon_selected.connect(_on_weapon_menu_selected)
	add_child(weapon_menu)

	item_menu = ItemMenu.new()
	item_menu.visible = false
	item_menu.item_selected.connect(_on_item_menu_selected)
	add_child(item_menu)

	pause_menu = PauseMenu.new()
	pause_menu.visible = false
	pause_menu.god_mode_toggled.connect(func(v: bool) -> void:
		infinite_life = v
		if player:
			player.infinite_life = v
			if v:
				player.life = player.max_life
				player.queue_redraw()
	)
	pause_menu.collision_toggled.connect(func(v: bool) -> void:
		show_collision = v
		if room_display:
			room_display.queue_redraw()
	)
	pause_menu.enemy_vision_toggled.connect(func(v: bool) -> void:
		show_enemy_vision = v
		for enemy: EnemyGuard in enemies:
			if is_instance_valid(enemy):
				enemy.show_debug_vision = v
				enemy.queue_redraw()
		for cam: SecurityCamera in cameras:
			if is_instance_valid(cam):
				cam.show_debug_vision = v
	)
	pause_menu.colliders_toggled.connect(func(v: bool) -> void:
		if player:
			player.show_debug_colliders = v
			player.queue_redraw()
	)
	pause_menu.give_arsenal_requested.connect(_give_debug_arsenal)
	pause_menu.reset_room_requested.connect(reset_player)
	add_child(pause_menu)

	call_deferred("_post_ready_layout")

func _on_weapon_menu_selected(w_name: String) -> void:
	if player:
		player.queue_redraw()
	print("WEAPON_MENU: Arma selecionada: %s" % (w_name if not w_name.is_empty() else "[DESARMADO]"))

func _on_item_menu_selected(i_name: String) -> void:
	if player:
		player.queue_redraw()
	print("ITEM_MENU: Item selecionado: %s" % (i_name if not i_name.is_empty() else "[NENHUM]"))

func _toggle_pause_menu() -> void:
	if pause_menu:
		if pause_menu.visible:
			pause_menu.close_menu()
		else:
			if weapon_menu and weapon_menu.visible:
				weapon_menu.close_menu()
			if item_menu and item_menu.visible:
				item_menu.close_menu()
			if radio_dialog and radio_dialog.is_active:
				radio_dialog.close_radio()
			pause_menu.open_menu(infinite_life, show_collision, show_enemy_vision, player.show_debug_colliders if player else false)

func _give_debug_arsenal() -> void:
	weapon_system.add_weapon(WeaponSystem.WEAPON_HANDGUN, 50)
	weapon_system.add_weapon(WeaponSystem.WEAPON_SMG, 50)
	weapon_system.add_weapon(WeaponSystem.WEAPON_GRENADE_LAUNCHER, 15)
	weapon_system.has_silencer = true
	inventory.collect_item(InventoryManager.ITEM_SILENCER)
	inventory.collect_item(InventoryManager.ITEM_CARD1)
	inventory.collect_item(InventoryManager.ITEM_CARD2)
	inventory.collect_item(InventoryManager.ITEM_GOGGLES)
	inventory.collect_item(InventoryManager.ITEM_BOX)
	inventory.collect_item(InventoryManager.ITEM_RATION)
	inventory.collect_item(InventoryManager.ITEM_RATION)
	inventory.collect_item(InventoryManager.ITEM_RATION)
	if player:
		player.max_life = 24
		player.life = 24
		player.queue_redraw()
	print("DEBUG_ARSENAL: Arsenal e equipamentos completos concedidos!")

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
	# Névoa atmosférica sutil de gás tóxico nas salas canônicas (Etapa 19)
	if gas_hazard_system and snapshot and gas_hazard_system.is_gas_room(snapshot.room_id):
		room_display.draw_rect(Rect2(0, 0, 256, 192), Color(0.12, 0.40, 0.15, 0.20))
	# Pulso elétrico sutil sobre os pisos eletrificados ativos (Etapa 22 — logic/actors/powerswitch.asm)
	if electrified_floor_system and snapshot and electrified_floor_system.is_room_electrified(snapshot.room_id) and electrified_floor_system.is_power_on(snapshot.room_id):
		var pulse_phase: float = (sin(Time.get_ticks_msec() / 120.0) + 1.0) * 0.5
		var electric_color := Color(0.35, 0.70, 1.0, 0.12 + 0.18 * pulse_phase)
		var hazard_tiles: Array[Vector2i] = electrified_floor_system.get_hazard_coords(snapshot.room_id)
		for tile_coord: Vector2i in hazard_tiles:
			var tile_rect := Rect2(tile_coord.x * 8.0, tile_coord.y * 8.0, 8.0, 8.0)
			room_display.draw_rect(tile_rect, electric_color)

	if show_collision and not runtime_collision.is_empty():
		for i: int in range(768):
			if int(runtime_collision[i]) == 1:
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
				if ElevatorSystem.is_elevator_room(req_id):
					is_in_elevator = true
					var elev_state: Dictionary = ElevatorSystem.get_entry_state(req_id, -1)
					elevator_y = float(elev_state.get("elevator_y", 180.0))
					elevator_target_y = elevator_y
					if elevator_cabin:
						elevator_cabin.elevator_y = elevator_y
						elevator_cabin.visible = true
				_apply_snapshot()
				return

	# Carregar sala inicial oficial da ROM original (Sala 121: introdução na água)
	var initial_snap := room_manager.load_room_snapshot(INITIAL_ROOM_ID)
	if initial_snap != null:
		snapshot = initial_snap
		_apply_snapshot()
		if not inventory.has_item(InventoryManager.ITEM_CIGARETTES):
			inventory.collect_item(InventoryManager.ITEM_CIGARETTES)
		return

	# Fallback sintético limpo caso nenhuma extração esteja presente
	_create_synthetic_fallback_room()

func _apply_snapshot() -> void:
	room_texture = ImageTexture.create_from_image(snapshot.make_image())
	runtime_collision = Array(snapshot.collision)
	if snapshot.room_id == CaptureSystem.ROOM_PRISON and capture_system.wall_broken:
		for tile_coord: Vector2i in CaptureSystem.WALL_TILES:
			var idx: int = tile_coord.y * 32 + tile_coord.x
			if idx >= 0 and idx < runtime_collision.size():
				runtime_collision[idx] = 0
			if tilemap_layer != null:
				tilemap_layer.set_cell(tile_coord, 0, Vector2i(0, 0))
		if room_texture != null:
			var img: Image = room_texture.get_image()
			var floor_col: Color = img.get_pixel(64, 80)
			for py in range(64, 96):
				for px in range(0, 48):
					img.set_pixel(px, py, floor_col)
			room_texture.update(img)
	elif snapshot.room_id == CaptureSystem.ROOM_ADJACENT and capture_system.wall_broken:
		for tile_coord: Vector2i in CaptureSystem.ADJACENT_WALL_TILES:
			var idx: int = tile_coord.y * 32 + tile_coord.x
			if idx >= 0 and idx < runtime_collision.size():
				runtime_collision[idx] = 0
			if tilemap_layer != null:
				tilemap_layer.set_cell(tile_coord, 0, Vector2i(0, 0))
		if room_texture != null:
			var img: Image = room_texture.get_image()
			var floor_col: Color = img.get_pixel(192, 80)
			for py in range(64, 96):
				for px in range(208, 256):
					img.set_pixel(px, py, floor_col)
			room_texture.update(img)
	if player:
		player.set_collision_grid(runtime_collision)
	_spawn_room_enemies(snapshot.room_id)
	_spawn_room_items(snapshot.room_id)
	_spawn_room_doors(snapshot.room_id)
	_spawn_room_prisoners(snapshot.room_id)
	_spawn_room_power_panel(snapshot.room_id)
	print("SANDBOX_ROOM_LOADED: %d (Inimigos: %d, Câmeras: %d, Itens: %d, Portas: %d, Reféns: %d)" % [
		snapshot.room_id, enemies.size(), cameras.size(), item_boxes.size(), room_doors.size(), prisoners.size()
	])
	if room_display:
		room_display.queue_redraw()

func _spawn_room_enemies(room_id: int) -> void:
	for enemy: EnemyGuard in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()

	for cam: SecurityCamera in cameras:
		if is_instance_valid(cam):
			cam.queue_free()
	cameras.clear()

	for gc: GasCloud in gas_clouds:
		if is_instance_valid(gc):
			gc.queue_free()
	gas_clouds.clear()

	# Limpa boss anterior ao trocar de sala
	if is_instance_valid(shot_gunner):
		shot_gunner.queue_free()
		shot_gunner = null
	for sgb: ShotGunnerBullet in shot_gunner_bullets:
		if is_instance_valid(sgb):
			sgb.queue_free()
	shot_gunner_bullets.clear()
	if boss_dialog_label:
		boss_dialog_label.visible = false

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
			var spawn_pos := Vector2(float(act.get("x", 0)), float(act.get("y", 0)))

			if type_id == 6:
				# Câmera de Vigilância (ID_CAMERA = 6)
				var cam_idx: int = cameras.size()
				var cam: SecurityCamera = SecurityCamera.new()
				var raw_path: Array = act.get("patrol_path", [])
				var waypoints: Array[Vector2] = []
				for pt_variant: Variant in raw_path:
					if pt_variant is Array and (pt_variant as Array).size() >= 2:
						var pt: Array = pt_variant as Array
						waypoints.append(Vector2(float(pt[1]), float(pt[0])))
				cam.setup(room_id, cam_idx, waypoints, spawn_pos)
				cam.show_debug_vision = show_enemy_vision
				cam.player_detected.connect(_on_camera_detected)
				game_world.add_child(cam)
				cameras.append(cam)
				print("CAMERA_SPAWNED: Câmera %d na sala %d em %s (Dir: %d)" % [cam_idx, room_id, spawn_pos, cam.facing_direction])
				continue

			# Nuvem de Gás Tóxico — ID_GAS = 8 (logic/actors/gas.asm)
			if type_id == 8:
				var gc: GasCloud = GasCloud.new(randf() > 0.5)
				gc.position = spawn_pos
				game_world.add_child(gc)
				gas_clouds.append(gc)
				continue

			# Boss Shoot Gunner — ID_SHOT_GUNNER = 0x21 = 33 (Etapa 18)
			if type_id == 33:
				var sg: ShotGunner = ShotGunner.new()
				var player_initial: Vector2 = player.position if player else Vector2(128.0, 96.0)
				sg.setup(spawn_pos, runtime_collision, player_initial)
				sg.boss_shot_fired.connect(_on_boss_shot_fired)
				sg.boss_defeated.connect(_on_boss_defeated)
				sg.intro_dialog.connect(_on_boss_intro_dialog)
				game_world.add_child(sg)
				shot_gunner = sg
				print("BOSS_SPAWNED: Shoot Gunner na sala %d em %s (HP: %d)" % [room_id, spawn_pos, sg.boss_hp])
				continue

			if not type_id in valid_enemy_types:
				continue

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

	# Configurar feixes laser da sala (Salas 24, 25, 72)
	if laser_system:
		laser_system.setup(room_id)

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
			var raw_item_id: String = str(item_dict.get("item_id", ""))
			var type_id: int = int(item_dict.get("item_type_id", item_dict.get("type_id", 0)))
			var pos := Vector2(float(item_dict.get("x", 0)), float(item_dict.get("y", 0)))

			var b: ItemBox = ItemBox.new()
			b.room_id = room_id
			b.position = pos

			if not raw_item_id.is_empty():
				b.item_id = raw_item_id
			else:
				match type_id:
					1:
						b.item_id = WeaponSystem.WEAPON_HANDGUN
					2:
						b.item_id = WeaponSystem.WEAPON_SMG
					3:
						b.item_id = WeaponSystem.WEAPON_GRENADE_LAUNCHER
					7:
						b.item_id = WeaponSystem.WEAPON_MISSILE
					8:
						b.item_id = InventoryManager.ITEM_SILENCER
					12:
						b.item_id = InventoryManager.ITEM_GOGGLES
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
					34:
						b.item_id = InventoryManager.ITEM_BAG
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

	# Portas canônicas carregadas de stage5-batch ou stage5-lorries
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

		# Exclusão canônica da ROM (logic/doors/enterdoor.asm:66-84):
		# - Portas sem destino (dest_room == -1)
		# - Portas dummy / invisíveis (r_type == 6)
		# - Destino à própria sala (paredes internas rachadas sem transição)
		# - Destino à Sala 204 (o limbo: tela 100% de parede sólida)
		# - Portas bloqueadas explicitamente na ROM (Door ID 64 na Sala 6 dos cães e Door ID 108 na Sala 5)
		# - Portas de paredes de explosivos ainda não detonadas (r_type > 6)
		if dest_room == -1 or dest_room == room_id or dest_room == 204 or d_id in [64, 108] or r_type >= 6:
			continue

		var d: RoomDoor = RoomDoor.new()
		d.door_id = d_id
		d.room_id = room_id
		d.render_type_id = r_type
		d.open_rule_id = rule_id
		d.position = Vector2(dx, dy)
		d.destination_room = dest_room

		# Portas de retorno de caminhões em movimento nos pátios (data/doors.asm:314, 335-337).
		# Nos pátios 5 e 9, as portas 117, 133, 146, 152 servem unicamente como âncoras de retorno
		# (para onde Snake é descarregado ao sair do caminhão móvel). Não devem permitir entrada a partir do pátio.
		if room_id in [5, 9] and d_id in [117, 133, 146, 152]:
			d.is_entry_disabled = true

		match r_type:
			1, 5:
				d.orientation = RoomDoor.DoorOrientation.NORTH
				d.entry_position = Vector2(dx + 12.0, dy + 40.0)
				d.destination_direction = PlayerController.Direction.DOWN
			2:
				d.orientation = RoomDoor.DoorOrientation.SOUTH
				d.entry_position = Vector2(dx + 16.0, dy - 8.0)
				d.destination_direction = PlayerController.Direction.UP
			3:
				d.orientation = RoomDoor.DoorOrientation.WEST
				d.entry_position = Vector2(dx + 16.0, dy + 48.0)
				d.destination_direction = PlayerController.Direction.RIGHT
			4:
				d.orientation = RoomDoor.DoorOrientation.EAST
				d.entry_position = Vector2(dx - 10.0, dy + 48.0)
				d.destination_direction = PlayerController.Direction.LEFT
			_:
				d.orientation = RoomDoor.DoorOrientation.NORTH
				d.entry_position = Vector2(dx + 12.0, dy + 40.0)
				d.destination_direction = PlayerController.Direction.DOWN

		d.required_card = RoomDoor.get_card_for_rule(rule_id)

		var lorry_rooms: Array[int] = [126, 127, 128, 130, 131, 132, 135, 173, 199, 213, 214, 215, 216, 217, 218, 219]
		if room_id in lorry_rooms or dest_room in lorry_rooms:
			d.is_lorry = true
			if room_id in lorry_rooms:
				d.orientation = RoomDoor.DoorOrientation.LORRY_EXIT

		# Portas que exigem cartão (regras 2 a 9: CARD1 a CARD8) NUNCA iniciam abertas
		if rule_id >= 2 and rule_id <= 9:
			d.is_open = false
		else:
			var raw_logic: int = int(d_info.get("open_logic_raw", 0))
			if (raw_logic & 0x80) != 0 or rule_id in [1, 10, 11] or dest_room in lorry_rooms or room_id in lorry_rooms:
				d.is_open = true

		game_world.add_child(d)
		d.inject_collision(runtime_collision)
		room_doors.append(d)

func _spawn_room_prisoners(room_id: int) -> void:
	for p: Prisoner in prisoners:
		if is_instance_valid(p):
			p.queue_free()
	prisoners.clear()

	if not game_world:
		return

	var room_data: Dictionary = room_manager.load_room_actors(room_id)
	var actors_data: Array = room_data.get("actors", [])
	for act_var: Variant in actors_data:
		if not act_var is Dictionary:
			continue
		var act: Dictionary = act_var as Dictionary
		var tid: int = int(act.get("actor_type_id", 0))
		if tid in [Prisoner.TYPE_PRISONER, Prisoner.TYPE_ELLEN, Prisoner.TYPE_GREY_FOX, Prisoner.TYPE_MADNAR, Prisoner.TYPE_FAKE_MADNAR]:
			var px: float = float(act.get("x", 128))
			var py: float = float(act.get("y", 96))
			var pris: Prisoner = Prisoner.new()
			pris.room_id = room_id
			pris.actor_type_id = tid
			pris.position = Vector2(px, py)
			if rank_system.is_room_rescued(room_id):
				pris.is_rescued = true

			pris.rescued.connect(func(p_node: Prisoner):
				var ranked_up: bool = rank_system.register_rescue(p_node.room_id, p_node.prisoner_name, p_node.message_text)
				if ranked_up:
					player.set_rank_life(rank_system.get_max_life(), true)
					weapon_system.update_rank_capacities(rank_system.current_rank)
					inventory.update_rank_capacities(rank_system.current_rank)
					show_dialog_message("PROMOÇÃO MILITAR!", "Solid Snake promovido para Rank ★%d (%s)!" % [
						rank_system.current_rank, rank_system.get_rank_stars()
					], 5.0)
				else:
					show_dialog_message(p_node.prisoner_name, p_node.message_text, 6.0)
			)

			pris.killed.connect(func(p_node: Prisoner):
				rank_system.register_kill(p_node.room_id, p_node.is_vital)
				player.set_rank_life(rank_system.get_max_life(), false)
				weapon_system.update_rank_capacities(rank_system.current_rank)
				inventory.update_rank_capacities(rank_system.current_rank)
				if p_node.is_vital:
					show_dialog_message("MISSÃO FALHOU!", "%s FOI MORTO! Big Boss: 'Snake! O que você fez?!'" % p_node.prisoner_name, 6.0)
				else:
					show_dialog_message("PUNIÇÃO DE PATENTE!", "Refém eliminado! Snake rebaixado para Rank ★%d (%s)!" % [
						rank_system.current_rank, rank_system.get_rank_stars()
					], 5.0)
			)

			game_world.add_child(pris)
			prisoners.append(pris)

func _spawn_room_power_panel(room_id: int) -> void:
	if is_instance_valid(power_panel):
		power_panel.queue_free()
		power_panel = null

	electrified_floor_system.setup_room(room_id)
	if not electrified_floor_system.is_room_electrified(room_id):
		return

	var panel_pos := Vector2.ZERO
	var has_panel: bool = false

	# 1. Tentar ler do JSON de atores se houver ator 44 (ID_POWER_SWITCH = 0x2C)
	var actors_data: Dictionary = room_manager.load_room_actors(room_id)
	var actors_list: Array = actors_data.get("actors", [])
	for a_entry: Variant in actors_list:
		if a_entry is Dictionary and int(a_entry.get("actor_type_id", -1)) == 44:
			panel_pos = Vector2(float(a_entry.get("x", 0.0)), float(a_entry.get("y", 0.0)))
			has_panel = true
			break

	# 2. Fallback para coordenadas canônicas desmontadas da ROM MSX2 RC750
	if not has_panel:
		match room_id:
			37:
				panel_pos = Vector2(100.0, 16.0)
				has_panel = true
			110:
				panel_pos = Vector2(68.0, 16.0)
				has_panel = true
			116:
				panel_pos = Vector2(32.0, 16.0)
				has_panel = true
			16:
				panel_pos = Vector2(36.0, 112.0)
				has_panel = true
			40:
				panel_pos = Vector2(68.0, 112.0)
				has_panel = true

	if has_panel:
		var is_destroyed: bool = not electrified_floor_system.is_power_on(room_id)
		power_panel = PowerPanel.new()
		power_panel.setup(room_id, panel_pos, is_destroyed)
		power_panel.panel_destroyed.connect(func(rid: int) -> void:
			electrified_floor_system.set_power(rid, false)
			print("POWER_PANEL_DESTROYED: Painel de força da Sala %d destruído! Piso elétrico desativado." % rid)
			if room_display:
				room_display.queue_redraw()
		)
		game_world.add_child(power_panel)

func show_dialog_message(speaker: String, text: String, duration_seconds: float = 6.0) -> void:
	if dialog_banner_label:
		dialog_banner_label.text = "[ %s ]\n\"%s\"" % [speaker, text]
		dialog_banner_label.visible = true
		var timer := get_tree().create_timer(duration_seconds)
		timer.timeout.connect(func():
			if is_instance_valid(dialog_banner_label):
				dialog_banner_label.visible = false
		)

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

func _is_position_safe(pos: Vector2) -> bool:
	if not player:
		return true
	# Limites da sala jogável (fora de bordas de transição de tela 256x192)
	if pos.x < 24.0 or pos.x > 232.0 or pos.y < 24.0 or pos.y > 168.0:
		return false
	if snapshot and not snapshot.collision.is_empty():
		for dir in [PlayerController.Direction.UP, PlayerController.Direction.DOWN, PlayerController.Direction.LEFT, PlayerController.Direction.RIGHT]:
			if player.is_colliding_at(pos, dir):
				return false
	return true

func _get_safe_spawn_position() -> Vector2:
	var pref_pos := Vector2(DEFAULT_SPAWN_X, DEFAULT_SPAWN_Y)
	if is_in_elevator and elevator_cabin:
		pref_pos = Vector2(216.0, elevator_y + 4.0)
		return pref_pos
	elif snapshot and snapshot.room_id == 121:
		pref_pos = Vector2(128.0, 80.0)
		return pref_pos
	elif snapshot and snapshot.room_id == 0:
		pref_pos = Vector2(128.0, 100.0)
	elif snapshot and snapshot.room_id == 1:
		pref_pos = Vector2(128.0, 104.0)

	if _is_position_safe(pref_pos):
		return pref_pos

	# Se a posição preferida colidir com paredes ou objetos sólidos,
	# busca em espiral o tile livre mais próximo em passos de 8 pixels
	for radius in range(1, 24):
		for dx in range(-radius, radius + 1):
			for dy in [-radius, radius]:
				var test_pos := pref_pos + Vector2(dx * 8.0, dy * 8.0)
				if _is_position_safe(test_pos):
					return test_pos
		for dy in range(-radius + 1, radius):
			for dx in [-radius, radius]:
				var test_pos := pref_pos + Vector2(dx * 8.0, dy * 8.0)
				if _is_position_safe(test_pos):
					return test_pos

	return pref_pos

func reset_player() -> void:
	if player:
		player.revive()
		var spawn_pos: Vector2 = _get_safe_spawn_position()
		player.set_grid_position(spawn_pos.x, spawn_pos.y)
		player.current_direction = PlayerController.Direction.UP
		player.is_moving = false
		player.life = player.max_life
		player.invulnerable_timer = 0
		player.punch_timer = 0
		player.infinite_life = infinite_life
		player.can_control = true
		player.queue_redraw()
		print("RESET_PLAYER: Snake reiniciado na posição segura %s (Vida Inf: %s)" % [spawn_pos, infinite_life])
	for b: Bullet in bullets:
		if is_instance_valid(b):
			b.queue_free()
	bullets.clear()
	for sgb: ShotGunnerBullet in shot_gunner_bullets:
		if is_instance_valid(sgb):
			sgb.queue_free()
	shot_gunner_bullets.clear()
	if snapshot:
		_spawn_room_enemies(snapshot.room_id)
		_spawn_room_items(snapshot.room_id)
		_spawn_room_doors(snapshot.room_id)
	alert_system.stop_alert()

## Reseta e limpa absolutamente todas as variáveis de estado, inventário e atores (evita vazamento de memória)
func reset_game_state() -> void:
	# 1. Limpar e liberar projéteis e entidades dinâmicas
	for b: Bullet in bullets:
		if is_instance_valid(b):
			b.queue_free()
	bullets.clear()

	for sgb: ShotGunnerBullet in shot_gunner_bullets:
		if is_instance_valid(sgb):
			sgb.queue_free()
	shot_gunner_bullets.clear()

	for enemy: EnemyGuard in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()

	for cam: SecurityCamera in cameras:
		if is_instance_valid(cam):
			cam.queue_free()
	cameras.clear()

	for box: ItemBox in item_boxes:
		if is_instance_valid(box):
			box.queue_free()
	item_boxes.clear()

	for door: RoomDoor in room_doors:
		if is_instance_valid(door):
			door.queue_free()
	room_doors.clear()

	for pris: Prisoner in prisoners:
		if is_instance_valid(pris):
			pris.queue_free()
	prisoners.clear()

	for gc: GasCloud in gas_clouds:
		if is_instance_valid(gc):
			gc.queue_free()
	gas_clouds.clear()

	if is_instance_valid(active_missile):
		active_missile.queue_free()
		active_missile = null

	if is_instance_valid(shot_gunner):
		shot_gunner.queue_free()
		shot_gunner = null

	if is_instance_valid(power_panel):
		power_panel.queue_free()
		power_panel = null

	# 2. Reset absoluto dos subsistemas
	inventory.reset()
	weapon_system.reset()
	rank_system.reset()
	alert_system.reset()
	if gas_hazard_system:
		gas_hazard_system.reset()
	if capture_system:
		capture_system.reset_state()
	if electrified_floor_system:
		electrified_floor_system.reset_state()
	ItemBox.collected_boxes.clear()

	# 3. Reset de variáveis de ambiente e flags de sala
	silencer_dropped_room_150 = false
	is_in_elevator = false
	elevator_state = ELEVATOR_STATE_IDLE
	if elevator_cabin:
		elevator_cabin.visible = false
	previous_room_id = -1

	# 4. Fechar menus e ocultar mensagens modais
	if weapon_menu:
		weapon_menu.visible = false
	if item_menu:
		item_menu.visible = false
	if pause_menu:
		pause_menu.visible = false
	if radio_dialog and radio_dialog.is_active:
		radio_dialog.close_radio()
	if dialog_banner_label:
		dialog_banner_label.visible = false
	if boss_dialog_label:
		boss_dialog_label.visible = false

	print("GAME_STATE_RESET: Estado global limpo com sucesso.")

func _on_player_died() -> void:
	trigger_game_over(false)

func trigger_game_over(instant: bool = false) -> void:
	if is_game_over:
		return
	is_game_over = true

	if player and not player.is_dead:
		player.die()

	if game_over_banner:
		game_over_banner.visible = true

	print("GAME_OVER: Snake eliminado! Bloqueio de inputs ativo. Aguardando reset.")

	if instant or not is_inside_tree():
		_execute_game_restart()
	else:
		var timer := get_tree().create_timer(1.2)
		timer.timeout.connect(_execute_game_restart)

func _execute_game_restart() -> void:
	is_game_over = false
	if game_over_banner:
		game_over_banner.visible = false

	# 1. Reset absoluto do estado (inventário, cartões, armas, alerta, rank, entidades)
	reset_game_state()

	# 2. Recarregamento seguro da cena
	if get_tree() and get_tree().current_scene == self:
		print("GAME_RESTART: Recarregando cena sandbox_gameplay.tscn...")
		get_tree().reload_current_scene()
	else:
		# Em ambiente de teste / instâncias manuais sem SceneTree root = self:
		print("GAME_RESTART: Reinicializando Sala 121 in-place...")
		var snap := room_manager.load_room_snapshot(INITIAL_ROOM_ID)
		if snap != null:
			snapshot = snap
			_apply_snapshot()
			if not inventory.has_item(InventoryManager.ITEM_CIGARETTES):
				inventory.collect_item(InventoryManager.ITEM_CIGARETTES)
		else:
			_create_synthetic_fallback_room()
		reset_player()

func _input(event: InputEvent) -> void:
	if player and (player.is_dead or not player.can_control or is_game_over):
		return

	# 1. Repasse para menus modais abertos

	if radio_dialog and radio_dialog.is_active:
		if radio_dialog.handle_input(event):
			get_viewport().set_input_as_handled()
			return

	if weapon_menu and weapon_menu.visible:
		if weapon_menu.handle_input(event):
			get_viewport().set_input_as_handled()
			return

	if item_menu and item_menu.visible:
		if item_menu.handle_input(event):
			get_viewport().set_input_as_handled()
			return

	if pause_menu and pause_menu.visible:
		if pause_menu.handle_input(event):
			get_viewport().set_input_as_handled()
			return

	# 2. Tela Cheia: Tecla F11 ou Alt+Enter
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
			if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			get_viewport().set_input_as_handled()
			return

	# 3. Tecla ESC: Alternar Tela de Pause / Opções
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_toggle_pause_menu()
			get_viewport().set_input_as_handled()
			return

	# 3. Rádio Transceptor: Tecla R ou Tab (e T / F4 para compatibilidade)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_R, KEY_TAB, KEY_T, KEY_F4]:
			if radio_dialog:
				if radio_dialog.is_active:
					radio_dialog.close_radio()
				else:
					radio_dialog.open_radio(radio_system, snapshot.room_id, radio_system.has_incoming_call)
				get_viewport().set_input_as_handled()
				return

	# 4. Menu de Armas: Tecla Q ou pressionar Shift
	if event is InputEventKey:
		if event.pressed and not event.echo and (event.keycode == KEY_Q or event.keycode == KEY_SHIFT):
			if capture_system.is_captured:
				print("CAPTURE_RESTRICTION: Armas confiscadas na cela! Apenas soco básico permitido.")
				get_viewport().set_input_as_handled()
				return
			if weapon_menu:
				weapon_menu.open_menu(weapon_system)
				get_viewport().set_input_as_handled()
				return

	# 5. Menu de Itens: Tecla E ou pressionar Ctrl / Alt
	if event is InputEventKey:
		if event.pressed and not event.echo and (event.keycode == KEY_E or event.keycode == KEY_CTRL or event.keycode == KEY_ALT):
			if capture_system.is_captured:
				print("CAPTURE_RESTRICTION: Itens confiscados na cela! Apenas soco básico permitido.")
				get_viewport().set_input_as_handled()
				return
			if item_menu:
				item_menu.open_menu(inventory)
				get_viewport().set_input_as_handled()
				return

	# 6. Soco dedicado (com arma equipada): Tecla K ou X
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K or event.keycode == KEY_X:
			if player:
				player.punch()
				print("PUNCH_DEDICATED: Soco corpo a corpo com arma equipada!")
			get_viewport().set_input_as_handled()
			return

	# 7. Atirar / Socar: Tecla J ou Z (ou Espaço / F) ou Clique Esquerdo do Mouse
	var is_fire_action: bool = false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		is_fire_action = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_J, KEY_Z, KEY_SPACE, KEY_F]:
			is_fire_action = true

	if is_fire_action:
		if capture_system.is_captured:
			if player:
				player.punch()
			get_viewport().set_input_as_handled()
			return
		elif player and not weapon_system.selected_weapon.is_empty():
			if weapon_system.selected_weapon == WeaponSystem.WEAPON_MISSILE:
				if is_instance_valid(active_missile):
					print("MISSILE_BUSY: Míssil teleguiado já em voo!")
				elif weapon_system.can_fire():
					weapon_system.consume_ammo()
					var m: RemoteMissile = RemoteMissile.new()
					m.setup(player.position, player.current_direction)
					m.missile_exploded.connect(_on_missile_exploded)
					game_world.add_child(m)
					active_missile = m
					print("MISSILE_LAUNCHED: Míssil teleguiado disparado em %s! Controle transferido." % player.position)
				else:
					print("WEAPON_NO_AMMO: Sem mísseis!")
			elif weapon_system.can_fire():
				var b: Bullet = player.fire_weapon(weapon_system)
				if b != null:
					bullets.append(b)
					game_world.add_child(b)
					if not weapon_system.has_silencer and not snapshot.room_id in ROOMS_SHOT_SECURE:
						alert_system.trigger_alert(false, inventory.get_card_level(), snapshot.room_id)
						for enemy: EnemyGuard in enemies:
							if is_instance_valid(enemy) and not enemy.is_dead:
								enemy.transform_to_alert_guard()
						print("GUNSHOT_ALERT: Disparo sem silenciador na sala %d alertou a guarnição!" % snapshot.room_id)
					else:
						print("GUNSHOT_SILENT: Disparo furtivo com silenciador!")
			else:
				print("WEAPON_NO_AMMO: Arma sem munição! (Click SFX 15h)")
		elif player:
			player.punch()
		get_viewport().set_input_as_handled()
		return

	# 8. Atalhos de Debug rápidos opcionais no teclado
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			show_collision = not show_collision
			if room_display:
				room_display.queue_redraw()
			print("COLLISION_TOGGLE: Colisão %s" % ("LIGADA" if show_collision else "DESLIGADA"))
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_V:
			if player:
				player.show_debug_colliders = not player.show_debug_colliders
				player.queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_B:
			show_enemy_vision = not show_enemy_vision
			for enemy: EnemyGuard in enemies:
				if is_instance_valid(enemy):
					enemy.show_debug_vision = show_enemy_vision
			for cam: SecurityCamera in cameras:
				if is_instance_valid(cam):
					cam.show_debug_vision = show_enemy_vision
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_I:
			infinite_life = not infinite_life
			if player:
				player.infinite_life = infinite_life
				if infinite_life:
					player.life = player.max_life
					player.queue_redraw()
			print("GOD_MODE: Vida infinita %s" % ("LIGADA" if infinite_life else "DESLIGADA"))
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_U:
			inventory.use_selected_item(player)
			get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if not player:
		return

	# Bloqueio de física e ações durante Game Over / morte de Snake
	if player.is_dead or not player.can_control or is_game_over:
		return

	# Pausa física e lógica de todos os atores enquanto qualquer modal estiver aberto
	if (radio_dialog and radio_dialog.is_active) or (weapon_menu and weapon_menu.visible) or (item_menu and item_menu.visible) or (pause_menu and pause_menu.visible):
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

	# Se um míssil teleguiado estiver ativo, o controle direcional é transferido exclusivamente para ele (Banks0123.asm:8468)
	if is_instance_valid(active_missile):
		if input_dir != Vector2i.ZERO:
			active_missile.steer(input_dir)
		player.is_moving = false
		player.queue_redraw()

		var missile_alive: bool = active_missile.step_tick(runtime_collision)

		# Colisão do míssil com soldados inimigos (Etapa 20)
		if is_instance_valid(active_missile) and active_missile.state == RemoteMissile.MissileState.FLIGHT:
			for enemy: EnemyGuard in enemies:
				if is_instance_valid(enemy) and not enemy.is_dead:
					if active_missile.check_actor_hit(enemy.position, 12.0):
						enemy.take_bullet_hit(active_missile.damage)
						active_missile.explode()
						break

		# Colisão do míssil com o chefe Shoot Gunner
		if is_instance_valid(active_missile) and active_missile.state == RemoteMissile.MissileState.FLIGHT:
			if is_instance_valid(shot_gunner) and not shot_gunner.is_dead and shot_gunner.state == ShotGunner.SGunnerState.SHOOT:
				if active_missile.check_actor_hit(shot_gunner.position, 16.0):
					for _i in range(3):
						shot_gunner.apply_bullet_hit()
					active_missile.explode()

		# Colisão do míssil com o painel de força (Etapa 22 — logic/damagetoenemy.asm)
		if is_instance_valid(active_missile) and active_missile.state == RemoteMissile.MissileState.FLIGHT:
			if is_instance_valid(power_panel) and not power_panel.is_destroyed:
				if active_missile.check_actor_hit(power_panel.position, 12.0):
					power_panel.take_hit("MISSILE", active_missile.damage)
					active_missile.explode()

		if not missile_alive:
			active_missile.queue_free()
			active_missile = null
	elif is_in_elevator:
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

			# Checar se atingiu a borda de saída da sala para outro elevador do mesmo shaft
			if dir_y < 0.0 and elevator_y <= ElevatorSystem.EXIT_UP_Y:
				var next_up_room: int = ElevatorSystem.get_connected_elevator_room(snapshot.room_id, -1)
				if next_up_room != -1:
					_transition_elevator_room(next_up_room, -1)
					return
			elif dir_y > 0.0 and elevator_y >= ElevatorSystem.EXIT_DOWN_Y:
				var next_down_room: int = ElevatorSystem.get_connected_elevator_room(snapshot.room_id, 1)
				if next_down_room != -1:
					_transition_elevator_room(next_down_room, 1)
					return

			# Checar se atingiu o andar de destino
			if absf(elevator_y - elevator_target_y) < 0.5:
				elevator_y = elevator_target_y
				if elevator_cabin:
					elevator_cabin.elevator_y = elevator_y
				player.position.y = elevator_y + 4.0
				elevator_state = ELEVATOR_STATE_IDLE
				print("ELEVATOR_FLOOR_REACHED: Andar atingido na sala %d (Y: %.1f)" % [snapshot.room_id, elevator_y])
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

	# Checar evento de captura na Sala 8 (logic/common.asm:26-47)
	if snapshot and snapshot.room_id == CaptureSystem.ROOM_CAPTURE and capture_system.check_capture_trigger(snapshot.room_id, player.position):
		_trigger_capture_event()
		return

	# Checar socos contra a parede oca na Cela da Sala 211 (logic/doors/opendoor.asm:300-320)
	if snapshot and snapshot.room_id == CaptureSystem.ROOM_PRISON and not capture_system.wall_broken:
		var hit: bool = capture_system.check_wall_punch(player.position, player.current_direction, player.is_punching, player.punch_timer)
		if hit:
			if capture_system.wall_broken:
				break_prison_wall()
			elif status_label != null:
				status_label.text = "[PAREDE OCA! ACERTO %d/4]" % capture_system.wall_hit_counter

	# Atualizar caixas de itens e armas coletáveis
	for box: ItemBox in item_boxes:
		if is_instance_valid(box) and not box.collected:
			box.step_tick(player.position, inventory, weapon_system, capture_system)

	# Atualizar portas interativas
	for door: RoomDoor in room_doors:
		if is_instance_valid(door):
			var target_room: int = door.check_interaction(player, inventory, runtime_collision)
			if target_room != -1:
				var ok: bool = change_to_room(target_room, door.entry_position, door.destination_direction, door.door_id)
				if not ok:
					# Sala destino ainda não extraída (item rooms 128+): mostrar aviso ao jogador
					show_dialog_message("Sala %d" % target_room, "[Sala ainda não extraída — dados indisponíveis]", 2.5)
				break

	# Atualizar prisioneiros / reféns (resgate por toque desarmado ou dano por soco/tiro)
	for pris: Prisoner in prisoners:
		if is_instance_valid(pris) and not pris.is_dead:
			pris.check_touch(player.position, player.is_punching)
			for b: Bullet in bullets:
				if is_instance_valid(b) and not b.is_enemy:
					if pris.position.distance_to(b.position) <= 12.0:
						pris.apply_bullet_hit()
						b.queue_free()
						break

	# Atualizar soldados inimigos, perseguição e combate
	var in_box: bool = (inventory.get_selected_item() == InventoryManager.ITEM_BOX and not player.is_moving)
	var any_enemy_sees_snake: bool = false
	var active_guards: int = 0
	var defeated_count: int = 0

	for enemy: EnemyGuard in enemies:
		if is_instance_valid(enemy):
			enemy.step_tick(runtime_collision, player.position, player.is_punching, player.current_direction, player)
			if enemy.is_dead:
				defeated_count += 1
			else:
				active_guards += 1
				# Inimigos atiradores ou em alerta tentam disparar contra Snake
				var enemy_shot: Bullet = enemy.try_shoot(player.position)
				if enemy_shot != null:
					bullets.append(enemy_shot)
					game_world.add_child(enemy_shot)
				if not in_box and enemy.check_line_of_sight(player.position, runtime_collision):
					any_enemy_sees_snake = true

	# Atualizar câmeras de vigilância móveis (Etapa 16)
	var is_alert_active: bool = (alert_system.current_state == AlertSystem.AlertState.ALERT)
	for cam: SecurityCamera in cameras:
		if is_instance_valid(cam):
			cam.show_debug_vision = show_enemy_vision
			cam.tick(player.position, runtime_collision, in_box, is_alert_active)
			if not in_box and (cam.has_seen_player or cam.alert_flashing):
				any_enemy_sees_snake = true

	# Atualizar sistema de feixes laser infravermelhos (Etapa 16)
	if laser_system:
		var goggles_on: bool = (inventory.get_selected_item() == InventoryManager.ITEM_GOGGLES)
		laser_system.tick(player.position, goggles_on, is_alert_active)

	# Atualizar nuvens visuais de gás (Etapa 19)
	for gc: GasCloud in gas_clouds:
		if is_instance_valid(gc):
			gc.step_tick()

	# Atualizar sistema de perigo de gás tóxico (Etapa 19 — logic/damagegas.asm)
	if gas_hazard_system and snapshot:
		gas_hazard_system.tick(snapshot.room_id, player, inventory)

	# Atualizar sistema de pisos eletrificados e choque elétrico (Etapa 22 — logic/damageelectric.asm)
	if electrified_floor_system and snapshot and not is_in_elevator:
		var shock_damage: int = electrified_floor_system.check_player_hazard(player.position, snapshot.room_id)
		if shock_damage > 0:
			player.apply_damage(shock_damage)
			is_player_shocked_flash = 4
			print("ELECTRIC_SHOCK: Snake eletrocutado! Dano: %d, Vida: %d/%d" % [shock_damage, player.life, player.max_life])
		if is_player_shocked_flash > 0:
			is_player_shocked_flash -= 1
			player.modulate = Color(0.35, 0.70, 1.0) if (is_player_shocked_flash % 2 == 0) else Color(1.0, 1.0, 1.0)
		else:
			player.modulate = Color(1.0, 1.0, 1.0)

	if is_instance_valid(power_panel):
		power_panel.tick()

	# Se Snake for detectado durante o estado NORMAL, aciona ALERTA
	if any_enemy_sees_snake and alert_system.current_state == AlertSystem.AlertState.NORMAL:
		alert_system.trigger_alert(false, inventory.get_card_level(), snapshot.room_id if snapshot and snapshot.loaded else 0)
		_trigger_alarm()

	# Atualização do subsistema de alerta (respawn, transição para evasão e temporizador regressivo)
	alert_system.tick(any_enemy_sees_snake, active_guards, snapshot.room_id if snapshot and snapshot.loaded else 0)

	# Atualizar física e colisões dos projéteis balísticos (balas de Snake e de soldados)
	var surviving_bullets: Array[Bullet] = []
	for b: Bullet in bullets:
		if not is_instance_valid(b):
			continue
		var alive: bool = b.step_tick(runtime_collision)
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

		# Projétil atinge o painel de força (blindado contra armas de fogo)
		if not hit and is_instance_valid(power_panel) and not power_panel.is_destroyed:
			if power_panel.collides_with_point(b.position, 8.0):
				power_panel.take_hit("BULLET", 0)
				hit = true


		if hit:
			b.queue_free()
		else:
			surviving_bullets.append(b)
	bullets = surviving_bullets

	# -----------------------------------------------------------------------
	# Tick do Boss Shoot Gunner (Etapa 18)
	# -----------------------------------------------------------------------
	if is_instance_valid(shot_gunner) and not shot_gunner.is_dead:
		shot_gunner.step_tick(player.position, runtime_collision)
		shot_gunner.queue_redraw()

	# Tick dos projéteis do boss — colisão com player já tratada por sinal hit_player
	var surviving_boss_bullets: Array[ShotGunnerBullet] = []
	for sgb: ShotGunnerBullet in shot_gunner_bullets:
		if is_instance_valid(sgb) and sgb.is_active:
			sgb.step_tick(player.position, runtime_collision)
			sgb.queue_redraw()
			surviving_boss_bullets.append(sgb)
	shot_gunner_bullets = surviving_boss_bullets

	# Colisão de balas do player com o boss
	var surviving_bullets2: Array[Bullet] = []
	for b: Bullet in bullets:
		if is_instance_valid(b):
			if _check_boss_bullet_collision(b):
				b.queue_free()
			else:
				surviving_bullets2.append(b)
	bullets = surviving_bullets2

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
	var rank_str: String = rank_system.get_rank_stars() if rank_system else "★☆☆☆"

	# Atualizar indicador visual de chamada recebida (CALL) de forma estável
	if call_badge:
		if radio_system.has_incoming_call:
			var flash: bool = (Engine.get_physics_frames() % 30 < 15)
			# Alterna entre vermelho intenso e amarelo de alerta mantendo alfa 1.0 (sem oscilar largura)
			call_badge.modulate = Color(1.0, 0.2, 0.2, 1.0) if flash else Color(1.0, 0.85, 0.1, 0.9)
		else:
			call_badge.modulate = Color(0.0, 0.0, 0.0, 0.0)

	if radio_dialog and radio_dialog.is_active:
		status_label.text = "TRANSCEIVER CODEC ATIVO | Sintonize: A/D | Enviar: W | R/Tab sair"
		status_label.modulate = Color("50e080")
		return

	var life_val_str: String = "INF" if infinite_life else "%02d/%02d" % [player.life, player.max_life]

	# String de HP do boss (Etapa 18)
	var boss_hp_str: String = ""
	if is_instance_valid(shot_gunner) and not shot_gunner.is_dead:
		var hp_blocks: String = "■".repeat(shot_gunner.boss_hp / 2) + "□".repeat((ShotGunner.BOSS_HP - shot_gunner.boss_hp) / 2)
		var phase_name: String = ["INTRO", "ROLAGEM", "TIRO"][int(shot_gunner.state)]
		boss_hp_str = " | BOSS [%s] HP:%02d %s" % [phase_name, shot_gunner.boss_hp, hp_blocks]

	if (player.is_dead or player.life <= 0) and not infinite_life:
		for sgb: ShotGunnerBullet in shot_gunner_bullets:
			if is_instance_valid(sgb):
				sgb.queue_free()
		shot_gunner_bullets.clear()
		status_label.text = "G A M E   O V E R  |  SNAKE FOI ELIMINADO!  |  [REINICIANDO...]"
		status_label.modulate = Color(1.0, 0.1, 0.1)
	elif is_instance_valid(shot_gunner) and not shot_gunner.is_dead:
		# Modo Boss Fight — destaque vermelho com HP do boss
		status_label.text = "BOSS! | %s | %s | VIDA: [%s] %s | %s%s" % [
			rank_str, weapon_str, life_bar, life_val_str, item_str, boss_hp_str
		]
		status_label.modulate = Color(1.0, 0.3, 0.0)
	elif alert_system.current_state == AlertSystem.AlertState.ALERT:
		var alert_tag: String = "ALERTA VERMELHO!" if alert_system.is_red_alert else "ALERTA!"
		status_label.text = "%s (Ref:%d) | %s | %s | VIDA: [%s] %s | %s (%d/%d)" % [
			alert_tag, alert_system.num_respawn_guards, rank_str, weapon_str, life_bar, life_val_str, item_str, defeated_count, enemies.size()
		]
		status_label.modulate = Color(1.0, 0.2, 0.2)
	elif alert_system.current_state == AlertSystem.AlertState.EVASION:
		status_label.text = "EVASÃO [%02d] | %s | %s | VIDA: [%s] %s | %s (%d/%d)" % [
			alert_system.evasion_timer, rank_str, weapon_str, life_bar, life_val_str, item_str, defeated_count, enemies.size()
		]
		status_label.modulate = Color(1.0, 0.65, 0.1)
	elif is_in_elevator:
		var state_str: String = "MOVENDO..." if elevator_state == ELEVATOR_STATE_MOVING else "PARADO"
		status_label.text = "ELEVADOR %d | Y: %.0f | %s" % [
			snapshot.room_id, elevator_y, state_str
		]
		status_label.modulate = Color(0.9, 0.8, 0.3)
	elif snapshot.loaded:
		var gas_tag: String = ""
		if gas_hazard_system and gas_hazard_system.is_gas_room(snapshot.room_id):
			if gas_hazard_system.is_player_protected(inventory):
				gas_tag = " [MÁSCARA ATIVA]"
			else:
				gas_tag = " [GÁS TÓXICO!]"
		elif snapshot.room_id == CaptureSystem.ROOM_PRISON:
			if not capture_system.wall_broken:
				gas_tag = " [CELA: SOQUE A PAREDE ESQUERDA (%d/4)]" % capture_system.wall_hit_counter
			else:
				gas_tag = " [CELA: PAREDE QUEBRADA - FUGA ABERTA]"
		elif snapshot.room_id == CaptureSystem.ROOM_ADJACENT:
			if not capture_system.equip_bag_taken:
				gas_tag = " [DEPÓSITO: RECUPERE SUA BOLSA]"
			else:
				gas_tag = " [DEPÓSITO: EQUIPAMENTOS RECUPERADOS]"
		elif electrified_floor_system and electrified_floor_system.is_room_electrified(snapshot.room_id):
			if electrified_floor_system.is_power_on(snapshot.room_id):
				gas_tag = " [PISO ELETRIFICADO: ATIVO]"
			else:
				gas_tag = " [PAINEL DE FORÇA DESTRUÍDO]"

		status_label.text = "Sala %03d%s | %s | %s | VIDA: [%s] %s | %s" % [
			snapshot.room_id, gas_tag, rank_str, weapon_str, life_bar, life_val_str, item_str
		]
		if gas_tag != "":
			if "GÁS TÓXICO" in gas_tag:
				status_label.modulate = Color(0.9, 0.4, 0.2)
			elif "MÁSCARA" in gas_tag or "DESTRUÍDO" in gas_tag:
				status_label.modulate = Color(0.4, 0.95, 0.4)
			elif "PISO ELETRIFICADO" in gas_tag:
				status_label.modulate = Color(0.35, 0.70, 1.0)
			elif "CELA" in gas_tag or "DEPÓSITO" in gas_tag:
				status_label.modulate = Color(0.9, 0.8, 0.3)
		else:
			status_label.modulate = Color(1.0, 1.0, 1.0)


func _check_and_handle_room_transition() -> void:
	if not player or not snapshot:
		return

	var exit_dir: int = RoomManager.check_room_exit(player.position)
	if exit_dir == 0:
		return

	# Verificar se existe porta com cartão na direção de saída (ROM: lógica de opendoor.asm).
	# A porta trancada bloqueia tanto a interação direta quanto a travessia pela borda da sala.
	for door: RoomDoor in room_doors:
		if not is_instance_valid(door) or door.is_lorry or door.required_card.is_empty():
			continue
		# Mapear direção de saída → orientação canônica da porta
		var door_exit_matches: bool = false
		match exit_dir:
			PlayerController.Direction.UP:
				door_exit_matches = (door.orientation == RoomDoor.DoorOrientation.NORTH)
			PlayerController.Direction.DOWN:
				door_exit_matches = (door.orientation == RoomDoor.DoorOrientation.SOUTH)
			PlayerController.Direction.LEFT:
				door_exit_matches = (door.orientation == RoomDoor.DoorOrientation.WEST)
			PlayerController.Direction.RIGHT:
				door_exit_matches = (door.orientation == RoomDoor.DoorOrientation.EAST)
		if door_exit_matches and not door.is_open:
			if not inventory.has_item(door.required_card):
				# Porta trancada bloqueia a borda: empurrar Snake de volta e avisar
				_clamp_to_room_bounds(exit_dir)
				print("DOOR_CARD_FAIL: Borda bloqueada pela porta %d — requer %s." % [door.door_id, door.required_card])
				return
			else:
				# Possui o cartão: abrir a porta e permitir passagem
				door.open_door(runtime_collision)

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

	for sgb: ShotGunnerBullet in shot_gunner_bullets:
		if is_instance_valid(sgb):
			sgb.queue_free()
	shot_gunner_bullets.clear()

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
			if matched_door != null:
				var spawn_info: Dictionary = RoomDoor.get_door_spawn(matched_door.position, matched_door.render_type_id)
				entry_pos = spawn_info.get("pos", entry_pos) as Vector2
				entry_dir = int(spawn_info.get("dir", entry_dir))
				matched_door.open_door(runtime_collision)
				print("DOOR_PAIR_MATCHED: Porta %d na sala %d (Render %d) -> Spawn em %s, Dir %d" % [
					from_door_id, new_room_id, matched_door.render_type_id, entry_pos, entry_dir
				])

		# Detecção de caminhão em movimento (Moving Lorry: logic/lorry.asm:23)
		if new_room_id in [199, 217, 219, 213, 215, 173]:
			print("MOVING_LORRY: Caminhão em deslocamento! (ROM: 'I goofed. The lorry started to move')")

	if player:
		player.set_grid_position(entry_pos.x, entry_pos.y)
		if entry_dir != -1:
			player.current_direction = entry_dir as PlayerController.Direction
		player.queue_redraw()
	print("ROOM_TRANSITION_OK: transição para sala %d na posição %s" % [new_room_id, entry_pos])
	alert_system.on_room_transition(new_room_id)
	if alert_system.current_state == AlertSystem.AlertState.ALERT:
		for enemy: EnemyGuard in enemies:
			if is_instance_valid(enemy) and not enemy.is_dead:
				enemy.transform_to_alert_guard()
	return true

## Transição contínua entre salas de um mesmo poço de elevador multi-telas (ROM: logic/nextroom.asm:64-98 SetNextRoomElev)
func _transition_elevator_room(next_room_id: int, move_dir_y: int) -> void:
	var old_room_id: int = snapshot.room_id if snapshot and snapshot.loaded else -1
	var snap: RoomSnapshot = room_manager.load_room_snapshot(next_room_id)
	if snap == null:
		print("ELEVATOR_TRANSITION_FAIL: snapshot para sala %d não encontrado localmente" % next_room_id)
		return

	snapshot = snap
	_apply_snapshot()
	radio_system.check_incoming_call(next_room_id)

	if move_dir_y < 0:
		# Entrou por baixo (subindo): inicia em Y = ENTRY_UP_Y (208.0)
		elevator_y = ElevatorSystem.ENTRY_UP_Y
	else:
		# Entrou por cima (descendo): inicia em Y = ENTRY_DOWN_Y (24.0)
		elevator_y = ElevatorSystem.ENTRY_DOWN_Y

	player.position.y = elevator_y + 4.0
	if elevator_cabin:
		elevator_cabin.elevator_y = elevator_y
		elevator_cabin.visible = true

	var target_info: Dictionary = ElevatorSystem.get_entry_moving_target(next_room_id, move_dir_y)
	if bool(target_info.get("has_target", false)):
		elevator_target_y = float(target_info.get("target_elev_y", elevator_y))
	else:
		elevator_target_y = elevator_y

	is_in_elevator = true
	elevator_state = ELEVATOR_STATE_MOVING
	player.is_moving = false
	player.queue_redraw()
	print("ELEVATOR_ROOM_TRANSITION: Elevador transitou da sala %d para %d (Y: %.1f, Alvo: %.1f)" % [
		old_room_id, next_room_id, elevator_y, elevator_target_y
	])

func _on_camera_detected(_cam: SecurityCamera) -> void:
	print("CAMERA_ALERT: Câmera detectou Snake na sala %d!" % (snapshot.room_id if snapshot and snapshot.loaded else -1))
	alert_system.trigger_alert(true, inventory.get_card_level(), snapshot.room_id if snapshot and snapshot.loaded else 0)
	_trigger_alarm()

func _on_laser_triggered(_laser_id: int = 0) -> void:
	print("LASER_ALERT: Snake violou feixe laser na sala %d!" % (snapshot.room_id if snapshot and snapshot.loaded else -1))
	alert_system.trigger_alert(true, inventory.get_card_level(), snapshot.room_id if snapshot and snapshot.loaded else 0)
	_trigger_alarm()

func _trigger_alarm() -> void:
	for enemy: EnemyGuard in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			enemy.transform_to_alert_guard()

func _on_alert_state_changed(_old_state: AlertSystem.AlertState, new_state: AlertSystem.AlertState) -> void:
	if new_state == AlertSystem.AlertState.ALERT:
		_trigger_alarm()
	elif new_state == AlertSystem.AlertState.NORMAL:
		for enemy: EnemyGuard in enemies:
			if is_instance_valid(enemy) and not enemy.is_dead:
				enemy.reset_to_patrol()

func _on_reinforcement_requested(enemy_id: int, spawn_pos: Vector2) -> void:
	var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
	var g: EnemyGuard = enemy_scene.instantiate() as EnemyGuard
	g.actor_type_id = enemy_id
	g.guard_type = EnemyGuard.GuardType.FAST
	g.speed = 1.5
	g.state = EnemyGuard.GuardState.ALERT
	g.is_alert = true
	g.position = spawn_pos
	g.show_debug_vision = show_enemy_vision
	if enemy_id == 11:
		g.is_shooter = true
	game_world.add_child(g)
	enemies.append(g)

# ---------------------------------------------------------------------------
# Handlers do Boss Shoot Gunner (Etapa 18)
# ---------------------------------------------------------------------------

func _on_boss_intro_dialog(text: String) -> void:
	if boss_dialog_label:
		boss_dialog_label.text = "[ " + text.replace("\n", " ") + " ]"
		boss_dialog_label.visible = true
	print("BOSS_DIALOG: %s" % text)

func _on_boss_shot_fired(origin: Vector2, target: Vector2) -> void:
	# Garante que nenhum tiro residual anterior permaneça ativo na sala
	for old_sgb: ShotGunnerBullet in shot_gunner_bullets:
		if is_instance_valid(old_sgb):
			old_sgb.queue_free()
	shot_gunner_bullets.clear()

	var sgb: ShotGunnerBullet = ShotGunnerBullet.new()
	sgb.setup(origin, target, runtime_collision)
	sgb.hit_player.connect(_on_boss_bullet_hit_player)
	sgb.bullet_destroyed.connect(func() -> void:
		shot_gunner_bullets.erase(sgb)
		if is_instance_valid(sgb):
			sgb.queue_free()
	)
	game_world.add_child(sgb)
	shot_gunner_bullets.append(sgb)
	print("BOSS_SHOT: Disparo de escopeta (spray de chumbo) em direção a Snake!")

func _on_boss_bullet_hit_player(damage: int) -> void:
	if player:
		var damaged: bool = player.apply_damage(damage)
		if damaged:
			player.invulnerable_timer = 45  # Invulnerabilidade de 45 ticks (0.75s) para dar tempo de esquiva/reação
		print("BOSS_HIT_PLAYER: Snake atingido pelo tiro do Shoot Gunner! Dano: %d" % damage)

func _on_boss_defeated() -> void:
	# Limpa qualquer projétil do boss imediatamente na vitória
	for sgb: ShotGunnerBullet in shot_gunner_bullets:
		if is_instance_valid(sgb):
			sgb.queue_free()
	shot_gunner_bullets.clear()
	if boss_dialog_label:
		boss_dialog_label.text = "[ SHOOT GUNNER DERROTADO! ]"
		boss_dialog_label.visible = true
	print("BOSS_DEFEATED: Shoot Gunner eliminado! (ShotGunnerStat bit0 = 1)")

## Verifica colisão de balas do player com o boss Shoot Gunner
## Chamado dentro do loop de bullets em _physics_process
func _check_boss_bullet_collision(b: Bullet) -> bool:
	if not is_instance_valid(shot_gunner) or shot_gunner.is_dead:
		return false
	if b.is_enemy:
		return false
	if b.position.distance_to(shot_gunner.position) <= 10.0:
		var killed: bool = shot_gunner.apply_bullet_hit()
		shot_gunner.queue_redraw()
		if killed:
			print("BOSS_KILLED: Bala final atingiu Shoot Gunner!")
		return true
	return false

func _on_missile_exploded(pos: Vector2) -> void:
	if snapshot and not snapshot.room_id in ROOMS_SHOT_SECURE:
		alert_system.trigger_alert(false, inventory.get_card_level(), snapshot.room_id)
		for enemy: EnemyGuard in enemies:
			if is_instance_valid(enemy) and not enemy.is_dead:
				enemy.transform_to_alert_guard()
		print("MISSILE_ALERT: Explosão na sala %d alertou a guarnição!" % snapshot.room_id)

# ---------------------------------------------------------------------------
# Handlers do Evento de Captura na Sala 8 e Cela da Sala 211 (Etapa 21)
# ---------------------------------------------------------------------------

func _trigger_capture_event() -> void:
	capture_system.execute_capture(inventory, weapon_system)
	change_to_room(CaptureSystem.ROOM_PRISON, CaptureSystem.SPAWN_PRISON, PlayerController.Direction.UP)
	if status_label:
		status_label.text = "[EMBOSCADA! CAPTURADO!]"
	print("CAPTURE_SPAWN: Snake transportado para a cela da Sala 211 sem armas nem itens.")

func break_prison_wall() -> void:
	capture_system.wall_broken = true
	# 1. Limpa a colisão dos tiles da parede na grade runtime_collision
	for tile_coord: Vector2i in CaptureSystem.WALL_TILES:
		var idx: int = tile_coord.y * 32 + tile_coord.x
		if idx >= 0 and idx < runtime_collision.size():
			runtime_collision[idx] = 0
		if tilemap_layer != null:
			tilemap_layer.set_cell(tile_coord, 0, Vector2i(0, 0))

	if player != null:
		player.set_collision_grid(runtime_collision)

	# 2. Atualiza a textura da sala abrindo o buraco de passagem
	if room_texture != null:
		var img: Image = room_texture.get_image()
		var floor_col: Color = img.get_pixel(64, 80)
		for py in range(64, 96):
			for px in range(0, 48):
				img.set_pixel(px, py, floor_col)
		room_texture.update(img)

	if room_display != null:
		room_display.queue_redraw()

	if status_label != null:
		status_label.text = "[PAREDE QUEBRADA - FUGA ABERTA!]"
	print("PRISON_WALL_BROKEN: Parede oca destruída após 4 acertos! Caminho de fuga aberto.")

func _on_equipment_restored() -> void:
	if status_label != null:
		status_label.text = "[EQUIPAMENTO RECUPERADO!]"
	if room_display != null:
		room_display.queue_redraw()
	print("EQUIPMENT_RESTORED: Solid Snake recuperou todas as suas armas e itens da bolsa!")
