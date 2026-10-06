extends SceneTree

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func key(code: Key, echo: bool = false) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.echo = echo
	return event

func ticks(dialog: PrisonerDialog, count: int) -> void:
	for i: int in range(count):
		dialog.step_tick(1.0 / 60.0)

func run() -> void:
	var dialog: PrisonerDialog = PrisonerDialog.new()
	root.add_child(dialog)
	check(not dialog.open_pages([[0xa1]], null), "Reject compressed tokens at runtime")
	check(not dialog.open_pages([[65.5]], null), "Reject fractional glyph code")
	var overflow: Array = []
	for i: int in range(58):
		overflow.append(65)
	check(not dialog.open_pages([overflow], null), "Do not silently repaginate overflowing data")
	check(dialog.open_pages([[65, 0x97, 66, 0xfe, 67], [68]], null), "Open synthetic two-page dialogue")
	dialog.tick_counter = 0
	dialog.handle_input(key(KEY_ENTER))
	ticks(dialog, 19)
	check(dialog.state == PrisonerDialog.State.APPEAR, "Animation needs 19 calls after Init")
	check(dialog.get("_frame_rect") == PrisonerDialog.BOX, "18 growth steps reach exact 160x41 box")
	ticks(dialog, 2)
	check(dialog.page_index == 0 and dialog.glyphs.is_empty(), "Opening input does not skip page")
	ticks(dialog, 3)
	check(dialog.glyphs.size() == 1, "First letter at tick mask 3 == 0")
	ticks(dialog, 16)
	check(dialog.state == PrisonerDialog.State.WAIT and dialog.glyphs.size() == 4, "Newline consumes no extra print interval")
	check(dialog.glyphs[2]["position"] == Vector2(64, 12), "Apostrophe advances four pixels")
	check(dialog.glyphs[3]["position"] == Vector2(52, 24), "Explicit newline advances twelve pixels")
	check(not dialog.prompt_active(), "TW_TextEnd tick does not run DrawEnterIcon")
	ticks(dialog, 1)
	dialog.tick_counter = 16
	check(dialog.prompt_visible(), "Pending page prompt lights on bit four")
	dialog.tick_counter = 0
	check(not dialog.prompt_visible(), "Prompt blink off")
	ticks(dialog, 600)
	check(dialog.page_index == 0 and dialog.is_active, "No six-second timeout or automatic advance")
	dialog.handle_input(key(KEY_ENTER, true))
	ticks(dialog, 2)
	check(dialog.page_index == 0, "Key echo cannot advance")
	dialog.handle_input(key(KEY_SPACE))
	ticks(dialog, 2)
	check(dialog.page_index == 0, "Fire1 is not the text advance key")
	dialog.handle_input(key(KEY_M))
	ticks(dialog, 2)
	check(dialog.page_index == 1 and dialog.glyphs.is_empty(), "M clears page before loading next")
	ticks(dialog, 10)
	dialog.tick_counter = 16
	check(dialog.state == PrisonerDialog.State.WAIT and not dialog.prompt_visible(), "Last page waits without prompt")
	ticks(dialog, 600)
	check(dialog.is_active, "Last page also requires confirmation")
	dialog.handle_input(key(KEY_N))
	ticks(dialog, 3)
	check(not dialog.is_active and not dialog.visible, "N closes last page and restores background")
	check(dialog.open_pages([[65, 66, 67], [68]], null), "Reopen starts fresh")
	ticks(dialog, 21)
	dialog.handle_input(key(KEY_ENTER))
	ticks(dialog, 2)
	check(dialog.page_index == 1 and dialog.glyphs.is_empty(), "Skipping unfinished text discards current page")
	dialog.close()
	prompt_cell_timing(dialog)
	dialog.free()
	prisoner_state_machine()
	await sandbox_rescue_tick()
	await private_integration()
	print("PRISONER_DIALOG_OK: %d assertions, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func full_page() -> Array:
	var page: Array = []
	for i: int in range(57):
		page.append(65)
	return page

# TW_TextEnd -> TW_Wait -> DrawEnterIcon; C=0 erases the prompt cell. Banks0123.asm:8102-8107,8179-8218,4726-4744.
func prompt_cell_timing(dialog: PrisonerDialog) -> void:
	check(dialog.open_pages([full_page(), [66]], null), "Open 57 glyphs filling all three lines")
	var guard: int = 0
	while dialog.state != PrisonerDialog.State.WAIT and guard < 1000:
		ticks(dialog, 1)
		guard += 1
	check(dialog.glyphs.back()["position"] == PrisonerDialog.PROMPT_ORIGIN, "19th glyph of line 3 shares the prompt cell")
	check(not dialog.prompt_active(), "No DrawEnterIcon in the TW_TextEnd tick")
	ticks(dialog, 1)
	check(dialog.prompt_active(), "Prompt cell owned by DrawEnterIcon from the first TW_Wait tick")
	dialog.handle_input(key(KEY_ENTER))
	ticks(dialog, 1)
	check(dialog.state == PrisonerDialog.State.DECODE and not dialog.prompt_active(), "Advance key erases text without drawing the prompt")
	dialog.close()

# PlayModeLogic runs actors before CommonLogic: TOUCH_INFO set at T is read at T+1.
# prisoner.asm:90-95,199-203,244-256; touchenemy.asm:55-57,107; Banks0123.asm:12223-12224.
func prisoner_state_machine() -> void:
	var p: Prisoner = Prisoner.new()
	p.setup(Prisoner.TYPE_PRISONER, 148, Vector2(100, 100))
	var log: Dictionary = {"tick": 0, "emitted": []}
	p.rescued.connect(func(_who: Prisoner) -> void: log["emitted"].append(log["tick"]))
	var near: Vector2 = Vector2(100, 100)
	var away: Vector2 = Vector2(0, 0)
	for t: int in range(7):
		log["tick"] = t
		p.actor_tick()
		p.check_touch(near if t == 0 else away, false)
		match t:
			0:
				check(p.touch_flag and p.status == Prisoner.Status.IDLE and not p.is_freed(), "T: touch only flags TOUCH_INFO")
			1:
				check(p.status == Prisoner.Status.WAIT and p.is_freed() and p.wait_timer == 2, "T+1: sprite 40h and TIMER=2 although Snake left")
			2:
				check(p.status == Prisoner.Status.WAIT and p.wait_timer == 1, "T+2: TIMER counts down")
			3:
				check(p.status == Prisoner.Status.RESCUED and not p.is_rescued, "T+3: next status, not yet rescued")
	check(log["emitted"] == [4], "SetText/IncRescued exactly once at T+4")
	check(p.is_rescued and p.status == Prisoner.Status.DONE, "PrisonerDummy afterwards")
	check(not p.check_touch(near, false), "Freed prisoner ignores later touches")
	p.free()
	var punched: Prisoner = Prisoner.new()
	punched.setup(Prisoner.TYPE_PRISONER, 148, Vector2(100, 100))
	check(not punched.check_touch(near, true) and punched.is_dead and not punched.touch_flag, "Punch path unchanged")
	punched.free()

# Generic prisoner (no private data): IncRescued draws class/life in the rescue tick and
# the remainder of that tick still runs. Banks0123.asm:9651-9677,7824-7829,12072-12087.
func sandbox_rescue_tick() -> void:
	var game: SandboxGameplay = load("res://scenes/sandbox_gameplay.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	var p: Prisoner = Prisoner.new()
	p.setup(Prisoner.TYPE_PRISONER, 148, game.player.position)
	game.game_world.add_child(p)
	game.prisoners.append(p)
	p.rescued.connect(game._on_prisoner_rescued)
	game.rank_system.rescued_count = 3
	game.player.life = 10
	game.hud.update_hud_state()
	for t: int in range(4):
		game.game_tick()
	check(not p.is_rescued and game.hud.current_life == 10, "No rescue before T+4")
	var shot: Bullet = Bullet.new()
	shot.position = Vector2(128, 40)
	game.bullets.append(shot)
	game.game_world.add_child(shot)
	game.game_tick()
	check(p.is_rescued and game.rank_system.current_rank == 2, "Rescue and promotion at T+4")
	check(game.hud.current_life == 32 and game.hud.max_life == 32 and game.hud.current_rank == 2, "HUD life/class redrawn in the rescue tick")
	check(shot.ticks_remaining == 15, "Rest of the rescue tick still runs (player shots)")
	game.queue_free()
	await process_frame

func private_integration() -> void:
	if not FileAccess.file_exists(RomProvenance.canonical_path(PrisonerDialog.DATA_FILE)):
		print("Grey Fox private integration SKIP: extraction absent")
		return
	var data: Dictionary = RomProvenance.load_canonical_json(PrisonerDialog.DATA_FILE)
	check(not data.is_empty(), "Grey Fox dialogue extracted from the canonical ROM")
	if data.is_empty():
		return
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(PrisonerDialog.FONT_PATH))
	var all_pixels_match: bool = true
	for code: String in data["glyphs"]:
		var spec: Dictionary = data["glyphs"][code]
		var cell: int = PrisonerDialog.atlas_cell(int(code))
		check(cell == int(spec["atlas_cell"]), "Raw glyph mapping agrees with source export")
		for y: int in range(8):
			for x: int in range(8):
				var expected: bool = (int(spec["rows"][y]) & (0x80 >> x)) != 0
				all_pixels_match = all_pixels_match and ((image.get_pixel((cell % 16) * 8 + x, (cell / 16) * 8 + y).a > 0.5) == expected)
	check(all_pixels_match, "Every needed atlas pixel matches English gfx/font.asm, including apostrophe/comma")
	var game: SandboxGameplay = load("res://scenes/sandbox_gameplay.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check(game.change_to_room(212, Vector2(128, 96)), "Load Grey Fox room")
	check(not game.prisoners.is_empty(), "Room has Grey Fox actor")
	if game.prisoners.is_empty():
		game.queue_free()
		await process_frame
		return
	var fox: Prisoner = game.prisoners[0]
	var dialog: PrisonerDialog = game.prisoner_dialog
	game.rank_system.rescued_count = 3
	game.player.position = fox.position
	game.player.life = 10
	game.hud.update_hud_state()
	game.game_tick()
	check(fox.touch_flag and not fox.is_freed() and not dialog.is_active, "T: ChkTouchEnemies flags Grey Fox")
	game.game_tick()
	check(fox.status == Prisoner.Status.WAIT and fox.is_freed() and not dialog.is_active, "T+1: freed sprite, dialogue not open")
	game.game_tick()
	game.game_tick()
	check(fox.status == Prisoner.Status.RESCUED and not dialog.is_active, "T+3: still no SetText")
	var shot: Bullet = Bullet.new()
	shot.position = Vector2(128, 40)
	game.bullets.append(shot)
	game.game_world.add_child(shot)
	game.game_tick()
	check(dialog.is_active and dialog.state == PrisonerDialog.State.INIT and dialog.pages.size() == 10, "T+4: SetText opens all ten English pages")
	check(shot.ticks_remaining == 15, "T+4: rest of the rescue tick still runs")
	check(game.rank_system.current_rank == 2, "Simultaneous promotion still applied")
	check(game.hud.current_life == 32 and game.hud.current_rank == 2, "HUD shows promotion while the world is frozen")
	game.game_tick()
	check(dialog.state == PrisonerDialog.State.APPEAR and dialog.get("_appear_remaining") == 19, "T+5: TW_Init only")
	check(shot.ticks_remaining == 15, "T+5: world frozen in GAME_MODE_TEXT_BOX")
	game.game_tick()
	check(dialog.get("_appear_remaining") == 18, "T+6: first growth step")
	check(dialog.z_index == PrisonerDialog.BITMAP_LAYER_Z and game.player.z_index > dialog.z_index, "Text box is bitmap, Snake sprite above it")
	check(not game.dialog_banner_label.visible, "Promotion and obsolete prose banner do not obscure dialogue")
	check(game.game_world.process_mode == Node.PROCESS_MODE_DISABLED, "Independent actor processing paused")
	var before: Vector2 = game.player.position
	game._input(key(KEY_X))
	game._input(key(KEY_R))
	game.game_tick()
	check(not game.player.is_punching and not game.radio_dialog.is_active, "Combat and radio input consumed")
	check(game.player.position == before, "Player does not move while message advances")
	for page: int in range(10):
		ticks(dialog, 300)
		check(dialog.page_index == page and dialog.state == PrisonerDialog.State.WAIT, "Page %d remains on its exact source boundary" % page)
		if OS.get_cmdline_user_args().has("--render") and page == 2:
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../reports/grey-fox-room.png"))
		dialog.handle_input(key(KEY_ENTER))
		ticks(dialog, 3)
	check(not dialog.is_active and game.game_world.process_mode == Node.PROCESS_MODE_INHERIT, "Final confirmation restores processing")
	check(game.rank_system.total_rescued == 1, "Rescue counted only once")
	game.change_to_room(211, Vector2(80, 72))
	game.change_to_room(212, Vector2(128, 96))
	check(game.prisoners[0].is_rescued and not game.prisoner_dialog.is_active, "Reentering room does not repeat message")
	check(dialog.open_grey_fox(), "Private dialogue can reopen")
	game.game_world.process_mode = Node.PROCESS_MODE_DISABLED
	game.reset_game_state()
	check(not dialog.is_active and game.game_world.process_mode == Node.PROCESS_MODE_INHERIT, "Reset closes modal and unfreezes world")
	game.queue_free()
	await process_frame
	if OS.get_cmdline_user_args().has("--render"):
		await render_pages(data)

func render_pages(data: Dictionary) -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(256, 192)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background: ColorRect = ColorRect.new()
	background.size = Vector2(256, 192)
	background.color = Color.BLUE
	viewport.add_child(background)
	var dialog: PrisonerDialog = PrisonerDialog.new()
	viewport.add_child(dialog)
	check(dialog.open_grey_fox(), "Open actual font for OpenGL rendering")
	for page: int in range(10):
		ticks(dialog, 300)
		dialog.tick_counter = 0
		dialog.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var actual: Image = viewport.get_texture().get_image()
		actual.convert(Image.FORMAT_RGBA8)
		# Independent reference compositor uses raw font rows from English source.
		var expected: Image = Image.create(256, 192, false, Image.FORMAT_RGBA8)
		expected.fill(Color.BLUE)
		expected.fill_rect(Rect2i(48, 8, 160, 41), Color.WHITE)
		expected.fill_rect(Rect2i(49, 9, 158, 39), Color.BLACK)
		var x: int = 52
		var y: int = 12
		for raw: Variant in data["pages"][page]:
			var code: int = int(raw)
			if code == 254:
				x = 52
				y += 12
				continue
			if x > 196:
				x = 52
				y += 12
			var rows: Array = data["glyphs"][str(code)]["rows"]
			for gy: int in range(8):
				for gx: int in range(8):
					expected.set_pixel(x + gx, y + gy, Color.WHITE if (int(rows[gy]) & (128 >> gx)) != 0 else Color.BLACK)
			x += 4 if code == 151 else 8
		check(actual.get_data() == expected.get_data(), "Rendered page %d matches all 49152 reference pixels" % (page + 1))
		if page in [0, 2, 9]:
			actual.save_png(ProjectSettings.globalize_path("res://../reports/grey-fox-page-%02d.png" % (page + 1)))
		dialog.handle_input(key(KEY_ENTER))
		ticks(dialog, 3)
	check(dialog.open_pages([full_page(), [66]], dialog.font_texture), "Open synthetic page ending on the prompt cell")
	ticks(dialog, 400)
	for lit: bool in [false, true]:
		dialog.tick_counter = 16 if lit else 0
		dialog.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var cell: Image = viewport.get_texture().get_image()
		cell.convert(Image.FORMAT_RGBA8)
		var rows: Array = data["glyphs"]["63"]["rows"] if lit else [0, 0, 0, 0, 0, 0, 0, 0]
		var cell_ok: bool = true
		for gy: int in range(8):
			for gx: int in range(8):
				var want: Color = Color.WHITE if (int(rows[gy]) & (128 >> gx)) != 0 else Color.BLACK
				cell_ok = cell_ok and cell.get_pixel(196 + gx, 36 + gy) == want
		check(cell_ok, "Prompt cell shows %s, never the glyph printed under it" % ("prompt" if lit else "blank"))
	dialog.close()
	viewport.queue_free()
	await process_frame
