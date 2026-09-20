extends SceneTree
## Optional private integration. --snapshot JSON --expected PNG [--screenshots PREFIX]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var expected_path: String = ""
	var screenshots: String = ""
	for index: int in range(arguments.size() - 1):
		if arguments[index] == "--expected": expected_path = arguments[index + 1]
		if arguments[index] == "--screenshots": screenshots = arguments[index + 1]
	var packed: PackedScene = load("res://scenes/room_inspector.tscn") as PackedScene
	var inspector: Control = packed.instantiate() as Control
	root.add_child(inspector)
	await process_frame
	var model: RoomSnapshot = inspector.get("snapshot") as RoomSnapshot
	var expected: Image = Image.new()
	if not model.loaded or expected.load(expected_path) != OK:
		push_error("Snapshot/expected image unavailable")
		quit(1)
		return
	expected.convert(Image.FORMAT_RGB8)
	if model.make_image().get_data() != expected.get_data():
		push_error("Godot image differs from Python image")
		quit(1)
		return
	if not screenshots.is_empty():
		for overlay: bool in [false, true]:
			inspector.call("_toggle_collision", overlay)
			await process_frame
			await RenderingServer.frame_post_draw
			var path: String = screenshots + ("-overlay.png" if overlay else "-plain.png")
			if FileAccess.file_exists(path) or root.get_texture().get_image().save_png(path) != OK:
				push_error("Screenshot destination exists or cannot be written")
				quit(1)
				return
	print("ROOM_INTEGRATION_OK: %d pixels matched Python; room %d" % [49152, model.room_id])
	inspector.queue_free()
	await process_frame
	quit(0)
