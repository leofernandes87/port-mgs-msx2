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
	# 1. Testar PlayerController isoladamente
	var packed_player: PackedScene = load("res://scenes/player.tscn") as PackedScene
	if not require(packed_player != null, "Falha ao carregar scenes/player.tscn"): return
	var player: PlayerController = packed_player.instantiate() as PlayerController
	if not require(player != null, "Falha ao instanciar PlayerController"): return
	root.add_child(player)
	await process_frame

	# Estado inicial
	if not require(player.position == Vector2.ZERO, "Posição inicial incorreta"): return
	if not require(not player.is_moving, "Player não deve iniciar em movimento"): return
	if not require(player.frame_num == 0, "Frame inicial de animação deve ser 0 (parado)"): return

	# Movimentação em espaço aberto (sem colisão)
	player.set_grid_position(100.0, 100.0)
	if not require(player.position == Vector2(100.0, 100.0), "set_grid_position falhou"): return

	var spd: float = PlayerController.SPEED_NORMAL
	# Avanço UP (-spd px)
	var moved: bool = player.step_tick(Vector2i(0, -1))
	if not require(moved and player.position == Vector2(100.0, 100.0 - spd), "Movimento UP deve avançar exatamente -spd px"): return
	if not require(player.current_direction == PlayerController.Direction.UP, "Direção deve ser UP"): return

	# Avanço DOWN (+spd px)
	moved = player.step_tick(Vector2i(0, 1))
	if not require(moved and player.position == Vector2(100.0, 100.0), "Movimento DOWN deve avançar exatamente +spd px"): return
	if not require(player.current_direction == PlayerController.Direction.DOWN, "Direção deve ser DOWN"): return

	# Avanço LEFT (-spd px)
	moved = player.step_tick(Vector2i(-1, 0))
	if not require(moved and player.position == Vector2(100.0 - spd, 100.0), "Movimento LEFT deve avançar exatamente -spd px"): return
	if not require(player.current_direction == PlayerController.Direction.LEFT, "Direção deve ser LEFT"): return

	# Avanço RIGHT (+spd px)
	moved = player.step_tick(Vector2i(1, 0))
	if not require(moved and player.position == Vector2(100.0, 100.0), "Movimento RIGHT deve avançar exatamente +spd px"): return
	if not require(player.current_direction == PlayerController.Direction.RIGHT, "Direção deve ser RIGHT"): return

	# Ciclo de animação de passos (ANIM_TICKS_PER_FRAME ticks por frame: 0 -> 1 -> 2 -> 1)
	var anim_step: int = PlayerController.ANIM_TICKS_PER_FRAME
	player.anim_wait_cnt = 0
	player.frame_num = 0
	for i: int in range(anim_step - 1):
		player.step_tick(Vector2i(1, 0))
	if not require(player.frame_num == 0, "Frame deve ser 0 antes de completar anim_step ticks"): return
	player.step_tick(Vector2i(1, 0)) # anim_stepº tick
	if not require(player.frame_num == 1, "Frame deve avançar para 1 após anim_step ticks"): return
	for i: int in range(anim_step):
		player.step_tick(Vector2i(1, 0)) # +anim_step ticks
	if not require(player.frame_num == 2, "Frame deve avançar para 2 após 2*anim_step ticks"): return
	for i: int in range(anim_step):
		player.step_tick(Vector2i(1, 0)) # +anim_step ticks
	if not require(player.frame_num == 1, "Frame deve ciclar de volta para 1 após 3*anim_step ticks"): return
	player.step_tick(Vector2i.ZERO) # Parar
	if not require(player.frame_num == 0 and not player.is_moving, "Parar deve resetar frame para 0"): return

	# 2. Testar colisão sintética com BoxColliderDat (Shape 0)
	var collision_grid: Array = []
	collision_grid.resize(768)
	collision_grid.fill(0)
	# Obstáculo sólido no tile tx=10, ty=10 (pixels x: [80..87], y: [80..87])
	collision_grid[10 * 32 + 10] = 1
	player.set_collision_grid(collision_grid)

	# Teste UP: offsets (-6, -5) e (5, -5)
	# Ponto esquerdo (-6, -5): atinge (80, 86) a partir de next_pos=(86, 92 - spd)
	player.set_grid_position(86.0, 92.0)
	moved = player.step_tick(Vector2i(0, -1))
	if not require(not moved and player.position == Vector2(86.0, 92.0), "Colisor UP esquerdo (-6,-5) deve bloquear movimento"): return

	# Ponto direito (5, -5): atinge (85, 86) a partir de next_pos=(80, 92 - spd)
	player.set_grid_position(80.0, 92.0)
	moved = player.step_tick(Vector2i(0, -1))
	if not require(not moved and player.position == Vector2(80.0, 92.0), "Colisor UP direito (5,-5) deve bloquear movimento"): return

	# Passa raspando à esquerda (ponto direito em 79 < 80)
	player.set_grid_position(74.0, 92.0)
	moved = player.step_tick(Vector2i(0, -1))
	if not require(moved and player.position == Vector2(74.0, 92.0 - spd), "Movimento UP livre fora do obstáculo deve prosseguir"): return

	# Teste DOWN: offsets (-6, 4) e (5, 4)
	# Ponto esquerdo (-6, 4): atinge (80, 80) a partir de next_pos=(86, 76)
	player.set_grid_position(86.0, 76.0 - spd)
	moved = player.step_tick(Vector2i(0, 1))
	if not require(not moved and player.position == Vector2(86.0, 76.0 - spd), "Colisor DOWN esquerdo (-6,4) deve bloquear movimento"): return

	# Teste LEFT: offsets (-8, -4) e (-8, 3)
	# Ponto superior (-8, -4): atinge (86, 80) a partir de next_pos=(94, 84)
	player.set_grid_position(95.0 + spd, 84.0)
	moved = player.step_tick(Vector2i(-1, 0))
	if not require(not moved and player.position == Vector2(95.0 + spd, 84.0), "Colisor LEFT (-8,-4) deve bloquear movimento"): return

	# Teste RIGHT: offsets (7, -4) e (7, 3)
	# Ponto superior (7, -4): atinge (81, 80) a partir de next_pos=(74, 84)
	player.set_grid_position(74.0 - spd, 84.0)
	moved = player.step_tick(Vector2i(1, 0))
	if not require(not moved and player.position == Vector2(74.0 - spd, 84.0), "Colisor RIGHT (7,-4) deve bloquear movimento"): return

	# Teste de limites da tela (0..255, 0..191)
	player.set_grid_position(2.0, 50.0)
	moved = player.step_tick(Vector2i(-1, 0))
	if not require(not moved, "Borda esquerda da tela deve bloquear"): return

	player.set_grid_position(254.0, 50.0)
	moved = player.step_tick(Vector2i(1, 0))
	if not require(not moved, "Borda direita da tela deve bloquear"): return

	player.set_grid_position(50.0, 4.0)
	moved = player.step_tick(Vector2i(0, -1))
	if not require(not moved, "Borda superior da tela deve bloquear"): return

	player.set_grid_position(50.0, 187.0)
	moved = player.step_tick(Vector2i(0, 1))
	if not require(not moved, "Borda inferior da tela deve bloquear"): return

	player.queue_free()
	await process_frame

	# 3. Testar cena jogável sandbox_gameplay.tscn
	var packed_sandbox: PackedScene = load("res://scenes/sandbox_gameplay.tscn") as PackedScene
	if not require(packed_sandbox != null, "Falha ao carregar sandbox_gameplay.tscn"): return
	var sandbox: Control = packed_sandbox.instantiate() as Control
	root.add_child(sandbox)
	await process_frame

	var sandbox_player: PlayerController = sandbox.get("player") as PlayerController
	if not require(sandbox_player != null, "Sandbox não instanciou PlayerController"): return
	if not require(sandbox_player.collision_grid.size() == 768, "Sandbox não inicializou grade de colisão 768"): return
	if not require(sandbox.get("game_world") != null, "Sandbox não possui game_world 2D"): return
	if not require(sandbox.get("room_display") != null, "Sandbox não possui room_display"): return

	sandbox.queue_free()
	await process_frame

	print("PLAYER_MOVEMENT_OK: 2.0px speed, authentic BoxColliderDat points, 4-direction blocking, scene integration")
	quit(0)
