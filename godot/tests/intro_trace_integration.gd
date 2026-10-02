extends SceneTree
## Integração privada opcional: --trace /caminho/trace.csv
## Compara entradas da lógica com a captura openMSX, sem embutir dados do jogo.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var trace_path: String = ""
	for index: int in range(args.size() - 1):
		if args[index] == "--trace": trace_path = args[index + 1]
	var file: FileAccess = FileAccess.open(trace_path, FileAccess.READ)
	var manager := RoomManager.new()
	var snapshot: RoomSnapshot = manager.load_room_snapshot(121)
	if file == null or snapshot == null:
		push_error("Trace e snapshot privado da sala 121 são obrigatórios")
		quit(1)
		return
	var player := PlayerController.new()
	player.set_collision_grid(Array(snapshot.collision))
	var intro := IntroCutscene.new()
	intro.start_intro(player)
	file.get_csv_line()
	var matched: int = 0
	var passed: bool = true
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() != 7: continue
		var state: int = int(row[1])
		# Radio/ExitRadio uses the existing Godot UI; it is not emulated here.
		if state in [5, 6, 7]: continue
		if state == 8 and intro.current_state == IntroCutscene.State.SCENE_6_RADIO_WAIT:
			intro.on_radio_finished()
			intro.tick(player, IntroCutscene.LOGIC_STEP_SEC)
		var expected_position := Vector2(float(row[3]) / 256.0, float(row[4]) / 256.0)
		if int(intro.current_state) != state + 1 or intro.state_counter != int(row[2]) or player.position != expected_position or int(player.anim_mode) != int(row[6]):
			printerr("TRACE_MISMATCH row=%d original=%s Godot=state %d count %d pos %s anim %d" % [matched,row,intro.current_state,intro.state_counter,player.position,player.anim_mode])
			passed = false
			break
		matched += 1
		intro.tick(player, IntroCutscene.LOGIC_STEP_SEC)
	passed = passed and matched > 400 and not intro.is_active and player.can_control
	player.free()
	intro.free()
	if not passed:
		quit(1)
		return
	print("INTRO_TRACE_OK: %d entradas coincidentes em estado/contador/posição/animação" % matched)
	quit(0)
