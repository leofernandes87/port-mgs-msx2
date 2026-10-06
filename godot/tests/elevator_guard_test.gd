extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	print("FAIL: " + message)
	quit(1)

func require(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	print("  PASS: " + message)
	return true

func _run() -> void:
	print("\n--- Elevator Guard & Chow Time Tests (Room 003) ---")

	var sandbox_scene: PackedScene = preload("res://scenes/sandbox_gameplay.tscn")
	var sandbox: Control = sandbox_scene.instantiate() as Control
	root.add_child(sandbox)
	await process_frame
	await process_frame

	# 1. Carregar Sala 3 no Sandbox
	var ok: bool = sandbox.call("change_to_room", 3, Vector2(144.0, 184.0), PlayerController.Direction.UP)
	if not require(ok, "Sala 3 deve carregar com sucesso"): return
	if not require(sandbox.get("snapshot").room_id == 3, "Sala atual deve ser 3"): return

	var enemies: Array = sandbox.get("enemies") as Array
	if not require(enemies.size() == 2, "Sala 3 deve iniciar com exatamente 2 guardas de elevador"): return

	var g_left: EnemyGuard = null
	var g_right: EnemyGuard = null
	for e in enemies:
		if e is EnemyGuard and e.is_elevator_guard:
			if is_equal_approx(e.position.x, 80.0):
				g_left = e
			elif is_equal_approx(e.position.x, 144.0):
				g_right = e

	if not require(g_left != null, "Guarda esquerdo deve estar presente em X=80"): return
	if not require(g_right != null, "Guarda direito deve estar presente em X=144"): return
	if not require(is_equal_approx(g_left.position.y, 48.0), "Guarda esquerdo deve estar em Y=48"): return
	if not require(is_equal_approx(g_right.position.y, 48.0), "Guarda direito deve estar em Y=48"): return
	if not require(g_left.elev_guard_state == EnemyGuard.ElevatorGuardState.IDLE, "Guarda esquerdo deve iniciar em IDLE"): return
	if not require(g_right.elev_guard_state == EnemyGuard.ElevatorGuardState.IDLE, "Guarda direito deve iniciar em IDLE"): return
	if not require(g_left.is_relieve_speaker, "Guarda esquerdo deve ser o porta-voz do revezamento"): return
	if not require(is_equal_approx(g_left.speed, 0.7), "Guarda do elevador deve ter velocidade 0.7 (guardMedium)"): return
	if not require(g_left.guard_type == EnemyGuard.GuardType.MEDIUM, "Guarda do elevador deve ser guard_type MEDIUM"): return

	# 2. Simular alguns ticks e verificar que eles permanecem parados e não olham para UP
	var seen_directions: Dictionary = {}
	for i in range(120):
		sandbox.call("game_tick")
		seen_directions[g_left.current_direction] = true
		seen_directions[g_right.current_direction] = true
		if not require(is_equal_approx(g_left.position.x, 80.0) and is_equal_approx(g_left.position.y, 48.0), "Guarda esquerdo deve permanecer parado no posto durante IDLE"): return
		if not require(is_equal_approx(g_right.position.x, 144.0) and is_equal_approx(g_right.position.y, 48.0), "Guarda direito deve permanecer parado no posto durante IDLE"): return

	if not require(not seen_directions.has(PlayerController.Direction.UP), "Guardas nunca devem olhar para UP contra a parede"): return
	print("  PASS: Guardas vigiam parados alternando visões válidas (DOWN/LEFT/RIGHT)")

	# 3. Avançar até o esgotamento do idle timer (~tick 256) e conferir "Chow time!!"
	var chow_time_seen: bool = false
	var banner: Label = sandbox.get("dialog_banner_label") as Label
	for i in range(160):
		sandbox.call("game_tick")
		if banner and banner.visible and "Chow time" in banner.text:
			chow_time_seen = true

	if not require(chow_time_seen, "Mensagem 'Chow time!!' deve ser disparada ao fim do tempo de guarda"): return
	if not require(g_left.elev_guard_state == EnemyGuard.ElevatorGuardState.LEAVING, "Guarda esquerdo deve mudar para LEAVING"): return
	if not require(g_right.elev_guard_state == EnemyGuard.ElevatorGuardState.LEAVING, "Guarda direito deve mudar para LEAVING"): return
	if not require(g_left.current_direction == PlayerController.Direction.RIGHT, "Guarda esquerdo deve virar para RIGHT ao sair"): return
	if not require(g_right.current_direction == PlayerController.Direction.RIGHT, "Guarda direito deve virar para RIGHT ao sair"): return

	# 4. Avançar 260 ticks: a 0.7 px/tick, guardas devem sair completamente da tela sem que novos guardas surjam ainda
	for i in range(260):
		sandbox.call("game_tick")

	var active_leaving_guards: int = 0
	var relieve_spawned_premature: bool = false
	for e in sandbox.get("enemies"):
		if is_instance_valid(e) and not e.is_queued_for_deletion() and e.is_elevator_guard:
			if e.elev_guard_state == EnemyGuard.ElevatorGuardState.LEAVING:
				active_leaving_guards += 1
			elif e.elev_guard_state == EnemyGuard.ElevatorGuardState.ENTERING:
				relieve_spawned_premature = true

	if not require(active_leaving_guards == 0, "Guardas anteriores devem sair completamente da tela e desaparecer"): return
	if not require(not relieve_spawned_premature, "Não deve haver retorno prematuro: corredor deve ter intervalo vazio"): return

	# 5. Avançar 160 ticks adicionais (~2.5s de intervalo): os sentinelas de revezamento devem agora surgir da direita
	for i in range(160):
		sandbox.call("game_tick")

	var relieve_spawned: bool = false
	for e in sandbox.get("enemies"):
		if is_instance_valid(e) and not e.is_queued_for_deletion() and e.is_elevator_guard:
			if e.elev_guard_state == EnemyGuard.ElevatorGuardState.ENTERING:
				relieve_spawned = true

	if not require(relieve_spawned, "Após o intervalo de ~2.5s, spawner do elevador deve gerar sentinelas de revezamento entrando da direita"): return

	# 6. Avançar 270 ticks: novos guardas devem alcançar seus postos (X=144 e X=80) a 0.7 px/tick e entrar em IDLE
	for i in range(270):
		sandbox.call("game_tick")

	var settled_left: bool = false
	var settled_right: bool = false
	for e in sandbox.get("enemies"):
		if is_instance_valid(e) and e.is_elevator_guard:
			if is_equal_approx(e.position.x, 80.0) and e.elev_guard_state == EnemyGuard.ElevatorGuardState.IDLE:
				settled_left = true
			elif is_equal_approx(e.position.x, 144.0) and e.elev_guard_state == EnemyGuard.ElevatorGuardState.IDLE:
				settled_right = true

	if not require(settled_left and settled_right, "Ambos os sentinelas de revezamento devem assumir os postos em X=80 e X=144 em IDLE"): return

	# 7. Testar comportamento ao sair do elevador 240
	sandbox.call("change_to_room", 240, Vector2(216.0, 184.0))
	sandbox.call("change_to_room", 3, Vector2(108.0, 48.0))
	var post_elev_guards: int = 0
	for e in sandbox.get("enemies"):
		if is_instance_valid(e) and e.is_elevator_guard and e.elev_guard_state == EnemyGuard.ElevatorGuardState.IDLE:
			post_elev_guards += 1
	if not require(post_elev_guards == 0, "Ao sair do elevador 240, os guardas não devem estar na porta inicialmente"): return
	if not require(sandbox.get("elevator_spawner_timer") <= 150, "Timer de spawner deve ser curto (~150 ticks / 2.5s) ao vir do elevador"): return

	sandbox.queue_free()
	await process_frame
	print("ELEVATOR_GUARD_OK: Todos os testes de sentinelas do elevador e Chow Time passaram com sucesso!")
	quit(0)
