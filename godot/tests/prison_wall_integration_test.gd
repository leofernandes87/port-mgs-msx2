extends SceneTree
## Private-data integration. Synthetic coverage lives in capture_prison_test.gd.
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_test")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func find_wall(game: Control, id: int = 103) -> PrisonWallDoor:
	for door: RoomDoor in game.get("room_doors"):
		if door is PrisonWallDoor and door.door_id == id:
			return door
	return null

func run_test() -> void:
	if not FileAccess.file_exists("res://../data/extracted/prison-walls/wall-14.json"):
		print("PRISON_WALL_INTEGRATION_OK: SKIP private wall extraction absent")
		quit(0)
		return
	var game: Control = load("res://scenes/sandbox_gameplay.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.call("change_to_room", 211, Vector2(80, 72), PlayerController.Direction.LEFT)
	var player: PlayerController = game.get("player")
	var cs: CaptureSystem = game.get("capture_system")
	var wall: PrisonWallDoor = find_wall(game)
	check(wall != null, "Door 103 must not be filtered out")
	if wall == null:
		quit(1)
		return
	check(wall.wall_texture != null, "Original tile graphic loaded")
	check(not wall.is_open, "Wall starts closed")
	var snapshot: RoomSnapshot = game.get("snapshot")
	var background: PackedByteArray = game.get("room_texture").get_image().get_data()
	# Approach using actual collision instead of teleporting to the punch point.
	for i: int in range(45):
		player.step_tick(Vector2i.LEFT, 1.0 / 60)
	check(wall.get_open_trigger_rect().has_point(player.position), "Collision stops player within original punch area")
	check(player.position.x >= 48, "Closed wall cannot be crossed")
	for i: int in range(4):
		player.punch()
		while player.is_punching:
			game.call("_update_prison_wall", 1.0 / 60)
			player.step_tick(Vector2i.ZERO, 1.0 / 60)
	check(cs.wall_hit_counter == 32 and not wall.is_open, "Four full punches leave eight life ticks")
	if "--render-check" in OS.get_cmdline_user_args():
		await capture_pixels(game, wall, "closed")
	player.punch()
	while player.is_punching:
		game.call("_update_prison_wall", 1.0 / 60)
		player.step_tick(Vector2i.ZERO, 1.0 / 60)
	check(cs.wall_broken and wall.is_open, "Fifth full punch opens wall")
	check(PackedByteArray(game.get("runtime_collision")) == snapshot.collision, "Exact original background collision restored")
	check(game.get("room_texture").get_image().get_data() == background, "No flat-color hole painted into room")
	if "--render-check" in OS.get_cmdline_user_args():
		await capture_pixels(game, wall, "open")
	for i: int in range(12):
		player.step_tick(Vector2i.LEFT, 1.0 / 60)
		var destination: int = wall.check_interaction(player, game.get("inventory"), game.get("runtime_collision"))
		if destination != -1:
			game.call("change_to_room", destination, Vector2.ZERO, -1, 103)
			break
	check(game.get("snapshot").room_id == 212, "Walk through opening reaches adjacent room")
	check(player.position == Vector2(200, 80), "Original destination spawn (200,80)")
	wall = find_wall(game)
	check(wall != null and wall.is_open, "Reverse wall shares broken state")
	# Return through the opposite door and ensure the wall remains absent.
	player.position = Vector2(210, 80)
	check(wall.check_interaction(player, game.get("inventory"), game.get("runtime_collision")) == 211, "Return trigger")
	game.call("change_to_room", 211, Vector2.ZERO, -1, 103)
	check(player.position == Vector2(56, 80), "Original return spawn (56,80)")
	check(find_wall(game).is_open, "Wall remains open on reentry")
	cs.reset_state()
	game.call("change_to_room", 211, Vector2(80,72), PlayerController.Direction.LEFT)
	check(not find_wall(game).is_open, "New game restores wall")
	await test_south_wall(game)
	game.queue_free()
	await process_frame
	print("PRISON_WALL_INTEGRATION_OK: failures=%d" % failures)
	quit(0 if failures == 0 else 1)

func capture_pixels(game: Control, wall: PrisonWallDoor, state: String) -> void:
	# Independent 1:1 viewport tests actual _draw output, with no window scaling.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 192)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = game.get("room_texture")
	viewport.add_child(bg)
	var rendered := PrisonWallDoor.new()
	rendered.render_type_id = wall.render_type_id
	rendered.position = wall.position
	rendered.wall_texture = wall.wall_texture
	rendered.is_open = wall.is_open
	viewport.add_child(rendered)
	await process_frame
	await RenderingServer.frame_post_draw
	var actual: Image = viewport.get_texture().get_image()
	var expected: Image = bg.texture.get_image()
	expected.convert(Image.FORMAT_RGBA8)
	if not wall.is_open:
		expected.blit_rect(wall.wall_texture.get_image(), Rect2i(Vector2i.ZERO, wall.wall_texture.get_size()), Vector2i(wall.position))
	var mismatches: int = 0
	for y: int in range(192):
		for x: int in range(256):
			if actual.get_pixel(x,y) != expected.get_pixel(x,y):
				mismatches += 1
	check(mismatches == 0, "%s render pixels differ: %d" % [state, mismatches])
	actual.save_png(ProjectSettings.globalize_path("res://../reports/prison-wall-%s.png" % state))
	print("PRISON_WALL_RENDER: %s mismatches=%d / 49152" % [state, mismatches])
	viewport.queue_free()

func test_south_wall(game: Control) -> void:
	var cs: CaptureSystem = game.get("capture_system")
	var player: PlayerController = game.get("player")
	cs.reset_state()
	cs.wall_broken = true
	cs.wall_hit_counter = 40
	game.call("change_to_room", 212, Vector2(112, 120), PlayerController.Direction.DOWN)
	var wall: PrisonWallDoor = find_wall(game, 12)
	check(wall != null and not wall.is_open, "South wall starts closed despite lateral wall broken")
	if wall == null:
		return
	check(wall.wall_texture != null and wall.wall_texture.get_size() == Vector2(32,8), "South wall original tile strip loaded")
	for i: int in range(50):
		player.step_tick(Vector2i.DOWN, 1.0 / 60)
	check(wall.get_open_trigger_rect().has_point(player.position), "Walking stops in south punch area")
	check(player.position.y < 152, "South wall blocks walking")
	check(wall.check_interaction(player, game.get("inventory"), game.get("runtime_collision")) == -1 and not wall.is_open, "Interaction cannot auto-open south wall")
	for i: int in range(4):
		player.punch()
		while player.is_punching:
			game.call("_update_prison_wall", 1.0 / 60)
			player.step_tick(Vector2i.ZERO, 1.0 / 60)
	check(cs.south_wall_hit_counter == 32 and not wall.is_open, "South wall survives four complete punches")
	if "--render-check" in OS.get_cmdline_user_args():
		await capture_pixels(game, wall, "south-closed")
	player.punch()
	while player.is_punching:
		game.call("_update_prison_wall", 1.0 / 60)
		player.step_tick(Vector2i.ZERO, 1.0 / 60)
	check(cs.south_wall_broken and wall.is_open, "Fifth punch opens south wall")
	check(cs.wall_hit_counter == 40 and cs.wall_broken, "Lateral wall state unchanged")
	var collision: Array = game.get("runtime_collision")
	var snapshot: RoomSnapshot = game.get("snapshot")
	for x: int in range(12,16):
		check(collision[19*32+x] == snapshot.collision[19*32+x], "South background collision restored")
	if "--render-check" in OS.get_cmdline_user_args():
		await capture_pixels(game, wall, "south-open")
	for i: int in range(15):
		player.step_tick(Vector2i.DOWN, 1.0 / 60)
		var destination: int = wall.check_interaction(player, game.get("inventory"), game.get("runtime_collision"))
		if destination != -1:
			game.call("change_to_room", destination, Vector2.ZERO, -1, 12)
			break
	check(game.get("snapshot").room_id == 54, "South opening leads to room 54")
	check(player.position == Vector2(112,168), "Door 12 destination spawn")
	wall = find_wall(game, 12)
	check(wall != null and wall.is_open, "Exterior shares Door 12 broken state")
	for i: int in range(25):
		player.step_tick(Vector2i.UP, 1.0 / 60)
		var destination: int = wall.check_interaction(player, game.get("inventory"), game.get("runtime_collision"))
		if destination != -1:
			game.call("change_to_room", destination, Vector2.ZERO, -1, 12)
			break
	check(game.get("snapshot").room_id == 212 and player.position == Vector2(112,144), "Return through Door 12")
	check(find_wall(game,12).is_open, "South wall remains broken on return")
	cs.reset_state()
	game.call("change_to_room", 212, Vector2(112,120), PlayerController.Direction.DOWN)
	check(not find_wall(game,12).is_open and not find_wall(game,103).is_open, "Reset restores both walls independently")
