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
	print("\n--- Canonical Sleepy Guard (logic/actors/guard.asm) Tests ---")

	# 1. Testes de Inicialização do Guarda Sonolento (Banks0123.asm:6815-6844)
	var guard: EnemyGuard = EnemyGuard.new()
	guard.actor_type_id = 4
	guard.init_sleepy_guard()
	if not require(guard.is_sleepy_guard, "is_sleepy_guard deve ser true após init_sleepy_guard()"): return
	if not require(guard.sleepy_state == EnemyGuard.SleepyState.AWAKE, "Estado inicial deve ser AWAKE"): return
	if not require(guard.awake_timer == 5 or guard.awake_timer == 64, "awake_timer inicial deve ser sorteado entre 5 e 64 ticks (Banks0123.asm:6834-6837)"): return
	if not require(guard.sleep_timer == 256, "sleep_timer inicial deve ser 256 ticks"): return

	# Forçar timer para validação de ciclo
	guard.init_sleepy_guard(42)
	if not require(guard.awake_timer == 42, "init_sleepy_guard(42) deve fixar awake_timer"): return

	# 2. Transição para o Sono e Diálogo "I'm sleepy..." (guard.asm:198-216)
	var dialog_received: Array[String] = []
	guard.sleepy_dialog_called.connect(func(text: String): dialog_received.append(text))
	guard.awake_timer = 2
	guard.step_tick([], Vector2(0.0, 0.0))
	if not require(guard.awake_timer == 1, "awake_timer deve decrementar a cada tick em vigília"): return
	if not require(guard.sleepy_state == EnemyGuard.SleepyState.AWAKE, "Ainda deve estar AWAKE com timer > 0"): return

	guard.step_tick([], Vector2(0.0, 0.0))
	if not require(guard.sleepy_state == EnemyGuard.SleepyState.SLEEPING, "Ao zerar awake_timer, guarda deve passar para SLEEPING"): return
	if not require(guard.sleep_timer == 256, "Ao adormecer, sleep_timer deve ser resetado para 256 ticks"): return
	if not require(guard.current_direction == PlayerController.Direction.DOWN, "Ao adormecer, guarda deve virar para DOWN (SpriteId = 2 per guard.asm:204)"): return
	if not require(dialog_received.size() == 1 and dialog_received[0] == "I'm sleepy...", "Ao adormecer, deve emitir fala canônica 'I'm sleepy...' (Text 33)"): return

	# 3. Desativação de Linha de Visão durante o Sono (guard.asm:226-232)
	guard.position = Vector2(100.0, 100.0)
	var player_in_front := Vector2(100.0, 140.0)
	var sees_while_sleeping: bool = guard.check_line_of_sight(player_in_front, [])
	if not require(not sees_while_sleeping, "Guarda dormindo NÃO deve detectar Snake pela linha de visão"): return

	# Acordar temporariamente para confirmar que a mesma posição seria visível acordado
	guard.sleepy_state = EnemyGuard.SleepyState.AWAKE
	var sees_while_awake: bool = guard.check_line_of_sight(player_in_front, [])
	if not require(sees_while_awake, "Guarda acordado voltado para DOWN deve avistar Snake à frente"): return
	guard.sleepy_state = EnemyGuard.SleepyState.SLEEPING

	# 4. Despertar por Toque Físico com Snake (chkdiscover.asm:502-535)
	# Snake encostando a <= 12 px do guarda adormecido
	guard.step_tick([], Vector2(108.0, 100.0)) # dist = 8 px
	if not require(guard.sleepy_state == EnemyGuard.SleepyState.AWAKE, "Toque físico deve acordar o guarda sonolento"): return
	if not require(guard.state == EnemyGuard.GuardState.ALERT, "Toque físico deve transitar o guarda para GuardState.ALERT"): return
	if not require(guard.is_alert, "Toque físico deve ativar is_alert = true"): return

	# 5. Despertar Natural após 256 Ticks e Diálogo "Overslept!" (guard.asm:230-260)
	guard.reset_to_patrol()
	guard.init_sleepy_guard()
	guard.sleepy_state = EnemyGuard.SleepyState.SLEEPING
	guard.sleep_timer = 2
	dialog_received.clear()
	guard.step_tick([], Vector2(0.0, 0.0))
	if not require(guard.sleep_timer == 1, "sleep_timer deve decrementar a cada tick"): return
	guard.step_tick([], Vector2(0.0, 0.0))
	if not require(guard.sleepy_state == EnemyGuard.SleepyState.AWAKE, "Ao esgotar 256 ticks, guarda deve acordar"): return
	if not require(guard.awake_timer == 192, "Ao acordar naturalmente, próximo awake_timer deve ser 192 ticks (0C0h per guard.asm:233)"): return
	if not require(dialog_received.size() == 1 and dialog_received[0] == "Overslept!", "Ao acordar naturalmente, deve emitir fala canônica 'Overslept!' (Text 34)"): return

	# 6. Despertar por Soco de Snake (punchenemy.asm:29-87)
	guard.sleepy_state = EnemyGuard.SleepyState.SLEEPING
	guard.position = Vector2(100.0, 100.0)
	# Snake soca de baixo para cima
	var punch_pos := Vector2(100.0, 110.0)
	guard.step_tick([], punch_pos, true, PlayerController.Direction.UP)
	if not require(guard.sleepy_state == EnemyGuard.SleepyState.AWAKE, "Soco deve acordar o guarda do sono"): return
	if not require(guard.is_alert, "Guarda socado deve entrar em ALERTA"): return
	if not require(guard.stunned_timer == 64, "Guarda socado deve ser atordoado por 64 ticks"): return
	if not require(guard.punches_received == 1, "Guarda deve registrar 1 soco"): return

	# 7. Despertar por Disparo / transform_to_alert_guard()
	guard.reset_to_patrol()
	guard.sleepy_state = EnemyGuard.SleepyState.SLEEPING
	guard.transform_to_alert_guard()
	if not require(guard.sleepy_state == EnemyGuard.SleepyState.AWAKE, "transform_to_alert_guard() deve acordar o guarda"): return
	if not require(guard.state == EnemyGuard.GuardState.ALERT, "Deve estar em GuardState.ALERT"): return
	guard.free()

	# 8. Integração SandboxGameplay na Sala 138 (Gas Mask Room)
	var sandbox_scene: PackedScene = preload("res://scenes/sandbox_gameplay.tscn")
	var sandbox: Control = sandbox_scene.instantiate() as Control
	root.add_child(sandbox)
	await process_frame
	await process_frame

	var room_ok: bool = sandbox.call("change_to_room", 138, Vector2(112.0, 176.0), PlayerController.Direction.UP)
	if not require(room_ok, "Sala 138 deve carregar com sucesso no Sandbox"): return
	if not require(sandbox.get("snapshot") != null and sandbox.get("snapshot").room_id == 138, "Sandbox deve carregar Sala 138"): return
	var enemies: Array = sandbox.get("enemies") as Array
	if not require(enemies.size() == 1, "Sala 138 deve conter exatamente 1 guarda"): return

	var room_guard: EnemyGuard = enemies[0] as EnemyGuard
	if not require(room_guard.is_sleepy_guard, "Guarda da Sala 138 deve ser sleepy_guard"): return
	if not require(room_guard.actor_type_id == 4, "Guarda da Sala 138 deve ser GuardSlow (ID 4)"): return
	if not require(is_equal_approx(room_guard.position.x, 184.0) and is_equal_approx(room_guard.position.y, 88.0), "Guarda da Sala 138 deve spawnar nas coordenadas canônicas (184, 88)"): return
	if not require(room_guard.waypoints.size() == 2, "Guarda da Sala 138 deve ter rota de patrulha com 2 pontos"): return
	if not require(is_equal_approx(room_guard.waypoints[0].x, 72.0) and is_equal_approx(room_guard.waypoints[1].x, 184.0), "Waypoints da Sala 138 devem ser (72, 88) e (184, 88)"): return

	# 9. Preservação no Binóculo (Backup e Restore)
	room_guard.sleepy_state = EnemyGuard.SleepyState.SLEEPING
	room_guard.sleep_timer = 150
	sandbox.call("_backup_home_enemies")

	var backup_list: Array = sandbox.get("home_enemies_backup") as Array
	if not require(backup_list.size() == 1, "Backup deve conter 1 inimigo"): return
	if not require(bool(backup_list[0].get("is_sleepy_guard", false)), "Backup deve registrar is_sleepy_guard = true"): return
	if not require(int(backup_list[0].get("sleepy_state", 0)) == int(EnemyGuard.SleepyState.SLEEPING), "Backup deve registrar sleepy_state = SLEEPING"): return
	if not require(int(backup_list[0].get("sleep_timer", 0)) == 150, "Backup deve registrar sleep_timer = 150"): return

	sandbox.call("_restore_home_enemies")
	var restored_enemies: Array = sandbox.get("enemies") as Array
	if not require(restored_enemies.size() == 1, "Restauração deve recriar o guarda"): return
	var restored_guard: EnemyGuard = restored_enemies[0] as EnemyGuard
	if not require(restored_guard.is_sleepy_guard, "Guarda restaurado deve ter is_sleepy_guard = true"): return
	if not require(restored_guard.sleepy_state == EnemyGuard.SleepyState.SLEEPING, "Guarda restaurado deve estar em SLEEPING"): return
	if not require(restored_guard.sleep_timer == 150, "Guarda restaurado deve ter sleep_timer = 150"): return

	sandbox.free()
	print("SLEEPY_GUARD_TEST_OK: Todos os testes do guarda sonolento passaram com sucesso!")
	quit(0)
