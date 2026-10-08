# game_clock_test.gd
# Single gameplay time base: InterruptTick runs GameStatusLogic once per VDP interrupt and skips
# interrupts while an iteration is in progress (Banks0123.asm:440-471); TickCounter is 8 bits
# (Banks0123.asm:10058-10060). Cadence per mode measured with tools/emulation/tick_rate.tcl.

extends SceneTree

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error("FALHA: " + message)
		printerr("FALHA: " + message)
		quit(1)
		return false
	return true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# 1. Playing cadence: one iteration every 2 interrupts.
	var clock := GameClock.new()
	var runs: Array[bool] = []
	for i: int in range(6):
		runs.append(clock.interrupt(GameClock.CADENCE_PLAYING))
	if not require(runs == [false, true, false, true, false, true], "GameMode 0: iteração a cada 2 interrupções"): return
	if not require(clock.tick_counter == 3 and clock.interrupt_count == 6, "TickCounter conta iterações, não interrupções"): return

	# 2. Text window: every interrupt; switching mode mid-gap runs immediately.
	clock.interrupt(GameClock.CADENCE_PLAYING)
	if not require(clock.interrupt(GameClock.CADENCE_TEXT_BOX), "Janela de texto itera na interrupção seguinte"): return
	if not require(clock.interrupt(GameClock.CADENCE_TEXT_BOX), "Janela de texto itera a cada interrupção"): return

	# 3. TickCounter wraps at 8 bits.
	var wrap := GameClock.new()
	wrap.tick_counter = 0xFF
	wrap.interrupt(GameClock.CADENCE_TEXT_BOX)
	if not require(wrap.tick_counter == 0, "TickCounter volta a 0 após FFh"): return

	# 4. One iteration advances ported counters by exactly one tick unit.
	if not require(is_equal_approx(GameClock.TICK_DELTA * 60.0, 1.0), "TICK_DELTA = 1 tick dos contadores X/60"): return
	if not require(is_equal_approx(IntroCutscene.LOGIC_STEP_SEC, GameClock.CADENCE_PLAYING * GameClock.TICK_DELTA), "Intro deriva sua cadência do GameClock"): return

	# 5. Sandbox: interrupts drive game_tick at the playing cadence, independent of the real delta.
	var sandbox: SandboxGameplay = (load("res://scenes/sandbox_gameplay.tscn") as PackedScene).instantiate()
	root.add_child(sandbox)
	sandbox.set_physics_process(false)
	await process_frame
	if not require(Engine.physics_ticks_per_second == GameClock.INTERRUPT_HZ, "Física do Godot = interrupção de 60 Hz"): return
	if sandbox.intro_cutscene and sandbox.intro_cutscene.is_active:
		sandbox.intro_cutscene.is_active = false
	sandbox.radio_system.force_pending_call()
	var timer_before: int = sandbox.radio_system.incoming_call_timer
	sandbox._physics_process(0.5)
	if not require(sandbox.radio_system.incoming_call_timer == timer_before, "1ª interrupção não itera (delta real ignorado)"): return
	sandbox._physics_process(0.0)
	if not require(sandbox.radio_system.incoming_call_timer == timer_before - 1, "2ª interrupção roda uma iteração"): return
	for i: int in range(4):
		sandbox._physics_process(1.0 / 60.0)
	if not require(sandbox.radio_system.incoming_call_timer == timer_before - 3, "6 interrupções = 3 iterações"): return
	if not require(sandbox.hud.call_tick_counter == sandbox.game_clock.tick_counter, "HUD pisca pelo TickCounter do relógio"): return
	sandbox.game_tick()
	if not require(sandbox.radio_system.incoming_call_timer == timer_before - 4, "game_tick() é exatamente uma iteração"): return
	sandbox.queue_free()
	await process_frame

	print("GAME_CLOCK_OK: interrupção 60 Hz, cadência por modo, TickCounter de 8 bits e game_tick determinístico")
	quit(0)
