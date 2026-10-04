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
		"input_sha256": "0".repeat(64)}
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
	if not require(model.decode(foreign) == OK and model.provenance == RomProvenance.Status.CANONICAL,
		"Canonical ROM provenance rejected"): return
	foreign["input_sha256"] = RomProvenance.LEGACY_PENDING_REEXTRACTION_SHA256
	if not require(model.decode(foreign) == OK and model.provenance == RomProvenance.Status.LEGACY_PENDING_REEXTRACTION,
		"Legacy snapshot not flagged as pending re-extraction"): return
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

	# Bloco 12-A: verifica que o RoomManager prioriza stage5-batch para rooms 0-125
	var rm: RoomManager = RoomManager.new()
	var real_snap: RoomSnapshot = rm.load_room_snapshot(0)
	if real_snap != null:
		if not require(real_snap.loaded, "stage5-batch room-000 carregou mas loaded=false"): return
		if not require(real_snap.room_id == 0, "room_id incorreto no snapshot real"): return
		if not require(real_snap.pixels.size() == 49152, "pixels size incorreto"): return
		if not require(real_snap.collision.size() == 768, "collision size incorreto"): return
		if not require(real_snap.colors.size() == 18, "palette size incorreto"): return
		if not require(real_snap.provenance in [RomProvenance.Status.CANONICAL, RomProvenance.Status.LEGACY_PENDING_REEXTRACTION],
			"snapshot real com proveniência inesperada"): return
		print("ROOM_SNAPSHOT_OK: stage5-batch room-000 carregado com sucesso (real ROM data)")
	else:
		# stage5-batch não disponível neste ambiente; testar apenas sintético
		print("ROOM_SNAPSHOT_OK: stage5-batch ausente; apenas snapshot sintético testado")

	# Bloco 12c: verifica que o RoomManager carrega salas lorry/isoladas de stage5-lorries (ex: room 126)
	var lorry_snap: RoomSnapshot = rm.load_room_snapshot(126)
	if lorry_snap != null:
		if not require(lorry_snap.loaded, "stage5-lorries room-126 carregou mas loaded=false"): return
		if not require(lorry_snap.room_id == 126, "room_id incorreto no snapshot lorry"): return
		if not require(lorry_snap.pixels.size() == 49152, "pixels size incorreto em room-126"): return
		print("ROOM_SNAPSHOT_OK: stage5-lorries room-126 carregado com sucesso")

	# Bloco 12d: verifica que o RoomManager carrega salas de elevador de stage5-elevators (ex: room 240)
	var elev_snap: RoomSnapshot = rm.load_room_snapshot(240)
	if elev_snap != null:
		if not require(elev_snap.loaded, "stage5-elevators room-240 carregou mas loaded=false"): return
		if not require(elev_snap.room_id == 240, "room_id incorreto no snapshot elevador"): return
		if not require(elev_snap.pixels.size() == 49152, "pixels size incorreto em room-240"): return
		print("ROOM_SNAPSHOT_OK: stage5-elevators room-240 carregado com sucesso")

	print("ROOM_SNAPSHOT_OK: synthetic pixels, validation, clearing, viewer and overlay")
	quit(0)
