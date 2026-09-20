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
	# 1. Testar lógica do RoomManager
	# Verificar mapeamento de conexões de salas chave
	if not require(RoomManager.get_next_room(121, PlayerController.Direction.UP) == 0, "Sala 121 norte deve ir para 0"): return
	if not require(RoomManager.get_next_room(121, PlayerController.Direction.DOWN) == RoomManager.NO_ROOM, "Sala 121 sul sem saída"): return

	if not require(RoomManager.get_next_room(0, PlayerController.Direction.UP) == 1, "Sala 0 norte deve ir para 1"): return
	if not require(RoomManager.get_next_room(0, PlayerController.Direction.DOWN) == 121, "Sala 0 sul deve ir para 121"): return
	if not require(RoomManager.get_next_room(0, PlayerController.Direction.RIGHT) == 4, "Sala 0 leste deve ir para 4"): return
	if not require(RoomManager.get_next_room(0, PlayerController.Direction.LEFT) == RoomManager.NO_ROOM, "Sala 0 oeste sem saída"): return

	if not require(RoomManager.get_next_room(1, PlayerController.Direction.UP) == 2, "Sala 1 norte deve ir para 2"): return
	if not require(RoomManager.get_next_room(1, PlayerController.Direction.DOWN) == 0, "Sala 1 sul deve ir para 0"): return
	if not require(RoomManager.get_next_room(1, PlayerController.Direction.RIGHT) == 5, "Sala 1 leste deve ir para 5"): return

	if not require(RoomManager.get_next_room(2, PlayerController.Direction.UP) == 3, "Sala 2 norte deve ir para 3"): return
	if not require(RoomManager.get_next_room(2, PlayerController.Direction.DOWN) == 1, "Sala 2 sul deve ir para 1"): return

	if not require(RoomManager.get_next_room(3, PlayerController.Direction.UP) == RoomManager.NO_ROOM, "Sala 3 norte sem saída de borda"): return
	if not require(RoomManager.get_next_room(3, PlayerController.Direction.DOWN) == 2, "Sala 3 sul deve ir para 2"): return

	# Faixas especiais
	if not require(RoomManager.get_next_room(208, PlayerController.Direction.UP) == 209, "Sala 208 norte deve ir para 209"): return
	if not require(RoomManager.get_next_room(240, PlayerController.Direction.UP) == RoomManager.NO_ROOM, "Sala 240 (elevador) sem conexão de borda"): return

	# Verificar detecção de limites de saída (ChkExitRoom)
	if not require(RoomManager.check_room_exit(Vector2(11.0, 100.0)) == PlayerController.Direction.LEFT, "X < 12 deve disparar LEFT"): return
	if not require(RoomManager.check_room_exit(Vector2(244.5, 100.0)) == PlayerController.Direction.RIGHT, "X >= 244 deve disparar RIGHT"): return
	if not require(RoomManager.check_room_exit(Vector2(100.0, 15.0)) == PlayerController.Direction.UP, "Y < 16 deve disparar UP"): return
	if not require(RoomManager.check_room_exit(Vector2(100.0, 186.0)) == PlayerController.Direction.DOWN, "Y >= 186 deve disparar DOWN"): return
	if not require(RoomManager.check_room_exit(Vector2(128.0, 104.0)) == 0, "Posição central não deve disparar saída"): return

	# Verificar posições de reentrada (EntryRoomXY)
	var entry := RoomManager.get_entry_position(PlayerController.Direction.UP, Vector2(128.0, 14.0))
	if not require(entry == Vector2(128.0, 184.0), "Entrada vinda de UP deve resultar em Y=184"): return

	entry = RoomManager.get_entry_position(PlayerController.Direction.DOWN, Vector2(128.0, 186.0))
	if not require(entry == Vector2(128.0, 18.0), "Entrada vinda de DOWN deve resultar em Y=18"): return

	entry = RoomManager.get_entry_position(PlayerController.Direction.LEFT, Vector2(10.0, 95.0))
	if not require(entry == Vector2(242.0, 95.0), "Entrada vinda de LEFT deve resultar em X=242"): return

	entry = RoomManager.get_entry_position(PlayerController.Direction.RIGHT, Vector2(245.0, 95.0))
	if not require(entry == Vector2(12.0, 95.0), "Entrada vinda de RIGHT deve resultar em X=12"): return

	# 2. Testar integração da cena sandbox_gameplay
	var packed: PackedScene = load("res://scenes/sandbox_gameplay.tscn") as PackedScene
	if not require(packed != null, "Falha ao carregar sandbox_gameplay.tscn"): return
	var sandbox: Control = packed.instantiate() as Control
	root.add_child(sandbox)
	await process_frame
	await process_frame

	var p: PlayerController = sandbox.get("player") as PlayerController
	var current_snap: RoomSnapshot = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 1, "Cena deve iniciar na Sala 1"): return

	# Transição Sala 1 -> Sala 2 (avançando ao Norte)
	# Na Sala 1, columns 12..19 são livres na borda norte
	p.set_grid_position(128.0, 18.0)
	p.step_tick(Vector2i(0, -1)) # Y vai para 16.0
	p.step_tick(Vector2i(0, -1)) # Y vai para 14.0 (< 16.0)
	sandbox.call("_check_and_handle_room_transition")

	current_snap = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 2, "Transição UP da Sala 1 deve carregar Sala 2"): return
	if not require(p.position == Vector2(128.0, 184.0), "Snake deve aparecer em (128, 184) na Sala 2"): return

	# Transição Sala 2 -> Sala 3 (avançando ao Norte pelo corredor direito: colunas 16..21, X=144)
	p.set_grid_position(144.0, 18.0)
	p.step_tick(Vector2i(0, -1))
	p.step_tick(Vector2i(0, -1))
	sandbox.call("_check_and_handle_room_transition")

	current_snap = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 3, "Transição UP da Sala 2 deve carregar Sala 3"): return
	if not require(p.position == Vector2(144.0, 184.0), "Snake deve aparecer em (144, 184) na Sala 3"): return

	# Transição Sala 3 -> Sala 2 (voltando ao Sul pelo mesmo corredor em X=144)
	p.set_grid_position(144.0, 184.0)
	p.step_tick(Vector2i(0, 1)) # Y vai para 186.0 (>= 186.0)
	sandbox.call("_check_and_handle_room_transition")

	current_snap = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 2, "Transição DOWN da Sala 3 deve retornar à Sala 2"): return
	if not require(p.position == Vector2(144.0, 18.0), "Snake deve aparecer em (144, 18) na Sala 2"): return

	# Transição Sala 2 -> Sala 1 (voltando ao Sul)
	p.set_grid_position(128.0, 184.0)
	p.step_tick(Vector2i(0, 1))
	sandbox.call("_check_and_handle_room_transition")

	current_snap = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 1, "Transição DOWN da Sala 2 deve retornar à Sala 1"): return
	if not require(p.position == Vector2(128.0, 18.0), "Snake deve aparecer em (128, 18) na Sala 1"): return

	# Transição Sala 1 -> Sala 0 (descendo para o pátio externo)
	p.set_grid_position(128.0, 184.0)
	p.step_tick(Vector2i(0, 1))
	sandbox.call("_check_and_handle_room_transition")

	current_snap = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 0, "Transição DOWN da Sala 1 deve carregar Sala 0"): return
	if not require(p.position == Vector2(128.0, 18.0), "Snake deve aparecer em (128, 18) na Sala 0"): return

	# Transição Sala 0 -> Sala 121 (descendo até a praia inicial)
	p.set_grid_position(128.0, 184.0)
	p.step_tick(Vector2i(0, 1))
	sandbox.call("_check_and_handle_room_transition")

	current_snap = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 121, "Transição DOWN da Sala 0 deve carregar Sala 121 (praia)"): return
	if not require(p.position == Vector2(128.0, 18.0), "Snake deve aparecer em (128, 18) na Sala 121"): return

	# 3. Testar Transição Leste para Sala 5 (Pátio dos Caminhões) e Entrada/Saída dos Caminhões
	# Voltar para Sala 1
	sandbox.call("change_to_room", 1, Vector2(128.0, 104.0))
	current_snap = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 1, "Deve carregar Sala 1"): return

	# Avançar para o Leste rumo à Sala 5
	p.set_grid_position(242.0, 104.0)
	p.step_tick(Vector2i(1, 0)) # X vai para 244.0 (limite RIGHT)
	sandbox.call("_check_and_handle_room_transition")

	current_snap = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 5, "Transição RIGHT da Sala 1 deve carregar Sala 5 (pátio dos caminhões)"): return
	if not require(p.position == Vector2(12.0, 104.0), "Snake deve aparecer em (12, 104) na Sala 5"): return

	# Entrar no caminhão central (Sala 127) pela traseira
	p.set_grid_position(108.0, 118.0)
	p.current_direction = PlayerController.Direction.UP
	sandbox.call("_physics_process", 1.0 / 60.0)

	current_snap = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 127, "Snake deve entrar no caminhão central (Sala 127)"): return
	if not require(p.position == Vector2(196.0, 112.0), "Snake deve aparecer em (196, 112) dentro do caminhão"): return
	if not require(p.current_direction == PlayerController.Direction.LEFT, "Snake deve estar virado para a esquerda dentro do caminhão"): return

	# Sair pela abertura direita da carroceria de volta à Sala 5
	p.set_grid_position(210.0, 100.0)
	p.current_direction = PlayerController.Direction.RIGHT
	sandbox.call("_physics_process", 1.0 / 60.0)

	current_snap = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 5, "Snake deve sair do caminhão de volta para o pátio da Sala 5"): return
	if not require(p.position == Vector2(112.0, 136.0), "Snake deve reaparecer abaixo do caminhão central em (112, 136)"): return
	if not require(p.current_direction == PlayerController.Direction.DOWN, "Snake deve sair virado para baixo"): return

	# Voltar para a Sala 1 pelo Oeste
	p.set_grid_position(12.0, 104.0)
	p.step_tick(Vector2i(-1, 0)) # X vai para 10.0 (< 12.0)
	sandbox.call("_check_and_handle_room_transition")

	current_snap = sandbox.get("snapshot") as RoomSnapshot
	if not require(current_snap.room_id == 1, "Transição LEFT da Sala 5 deve retornar à Sala 1"): return
	if not require(p.position == Vector2(242.0, 104.0), "Snake deve reaparecer na borda leste da Sala 1"): return

	sandbox.queue_free()
	await process_frame

	print("ROOM_TRANSITION_OK: room connections, authentic exit bounds, entry XY recalculation, bidirectional room changes, and lorry truck transitions")
	quit(0)
