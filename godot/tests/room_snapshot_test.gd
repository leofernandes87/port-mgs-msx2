extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
		return false
	return true

func _run() -> void:
	var pixels: Array[int] = []
	pixels.resize(49152)
	pixels.fill(0)
	pixels[0] = 1
	pixels[49151] = 2
	var collision: Array[int] = []
	collision.resize(768)
	collision.fill(0)
	collision[33] = 1
	var palette: Array = []
	for index: int in range(18):
		palette.append([0, 0, 0])
	palette[1] = [255, 0, 0]
	palette[2] = [0, 255, 0]
	var fixture: Dictionary = {"format_version": "1.0.0", "room_id": 0, "width": 256, "height": 192,
		"pixels": pixels, "collision": collision, "palette_rgb": palette, "source": "synthetic",
		"rom_profile": RomProvenance.SYNTHETIC_PROFILE, "input_sha256": "0".repeat(64)}
	var model: RoomSnapshot = RoomSnapshot.new()
	if not require(model.decode(fixture) == OK, model.error_message): return
	var image: Image = model.make_image()
	if not require(image.get_pixel(0, 0) == Color.RED and image.get_pixel(255, 191) == Color.GREEN,
		"Pixel orientation or palette mapping failed"): return
	if not require(model.collision[33] == 1, "Collision data lost"): return
	if not require(model.provenance == RomProvenance.Status.SYNTHETIC, "Synthetic fixture not classified"): return
	var foreign: Dictionary = fixture.duplicate(true)
	foreign["input_sha256"] = "89cfeee7d990a6bed050dcffa12ddff179e1632f13450247ee8860587adec6f4"
	if not require(model.decode(foreign) != OK and not model.loaded, "Non-canonical ROM provenance accepted"): return
	foreign["input_sha256"] = "a".repeat(64)
	if not require(model.decode(foreign) != OK, "Unknown ROM provenance accepted"): return
	foreign["input_sha256"] = RomProvenance.CANONICAL_SHA256
	if not require(model.decode(foreign) != OK, "Canonical hash accepted under the synthetic profile"): return
	foreign["rom_profile"] = RomProvenance.CANONICAL_PROFILE
	if not require(model.decode(foreign) == OK and model.provenance == RomProvenance.Status.CANONICAL,
		"Canonical ROM provenance rejected"): return
	# Snapshots derived from the former local Japanese dump are no longer accepted.
	foreign["input_sha256"] = "254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf"
	if not require(model.decode(foreign) != OK, "Japanese-derived snapshot accepted"): return
	foreign["rom_profile"] = "jp-rc750-local"
	if not require(model.decode(foreign) != OK, "Japanese profile accepted"): return
	foreign.erase("rom_profile")
	foreign["input_sha256"] = RomProvenance.CANONICAL_SHA256
	if not require(model.decode(foreign) != OK, "Snapshot without rom_profile accepted"): return
	var malformed: Dictionary = fixture.duplicate(true)
	var invalid_pixels: Array = []
	invalid_pixels.assign(pixels)
	invalid_pixels[0] = 1.5
	malformed["pixels"] = invalid_pixels
	if not require(model.decode(malformed) != OK and not model.loaded and model.make_image() == null,
		"Invalid import did not clear old state"): return
	malformed = fixture.duplicate(true)
	var invalid_collision: Array = []
	invalid_collision.assign(collision)
	invalid_collision[0] = true
	malformed["collision"] = invalid_collision
	if not require(model.decode(malformed) != OK, "Boolean accepted as collision integer"): return
	if not require(model.load_path("res://does-not-exist.json") != OK, "Missing file accepted"): return
	var packed: PackedScene = load("res://scenes/room_inspector.tscn") as PackedScene
	var inspector: Control = packed.instantiate() as Control
	root.add_child(inspector)
	await process_frame
	var canvas: RoomCanvas = inspector.get("canvas") as RoomCanvas
	if not require(model.decode(fixture) == OK, "Fixture reload failed"): return
	canvas.show_snapshot(model)
	inspector.call("_toggle_collision", true)
	if not require(canvas.show_collision and canvas.texture != null and (inspector.get("overlay_button") as CheckButton).button_pressed, "Viewer did not load/toggle overlay"): return
	inspector.queue_free()
	await process_frame

	var rm: RoomManager = RoomManager.new()
	for room_id: int in [0, 126, 240, 211]:
		var real_snap: RoomSnapshot = rm.load_room_snapshot(room_id)
		if real_snap == null:
			print("ROOM_SNAPSHOT_OK: room-%03d canônica ausente; apenas snapshot sintético testado" % room_id)
			continue
		if not require(real_snap.loaded and real_snap.room_id == room_id, "room-%03d carregada incorretamente" % room_id): return
		if not require(real_snap.pixels.size() == 49152 and real_snap.collision.size() == 768 and real_snap.colors.size() == 18,
			"room-%03d com tamanhos incorretos" % room_id): return
		if not require(real_snap.provenance == RomProvenance.Status.CANONICAL,
			"room-%03d não veio da ROM canônica %s" % [room_id, RomProvenance.CANONICAL_PROFILE]): return
		var actors: Dictionary = rm.load_room_actors(room_id)
		if not require(actors.is_empty() or RomProvenance.classify_record(actors) == RomProvenance.Status.CANONICAL,
			"atores da room-%03d sem proveniência canônica" % room_id): return
		print("ROOM_SNAPSHOT_OK: room-%03d carregada de %s" % [room_id, RomProvenance.CANONICAL_PROFILE])

	print("ROOM_SNAPSHOT_OK: synthetic pixels, validation, clearing, viewer and overlay")
	quit(0)
