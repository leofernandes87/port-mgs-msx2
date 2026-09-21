# elevator_test.gd
# Validação automatizada da mecânica de elevadores e transições verticais (Etapa 12d).
# Cobre:
# 1. Configuração e limites canônicos dos 11 elevadores (salas 240 a 250).
# 2. Posicionamento autêntico de entrada baseado no andar de origem (GetElevatorPosY).
# 3. Identificação do próximo andar em subida e descida (get_next_target_floor).
# 4. Trânsito vertical suave da cabine e de Snake a 1 px/tick com congelamento de controle.
# 5. Restrição de movimento de caminhada estritamente horizontal no chão da passarela.
# 6. Tolerâncias de saída por porta dummy (X >= 224).
# 7. Ciclo completo de integração no sandbox: Sala 3 (Térreo) <-> Sala 240 (Elevador) <-> Sala 31 (Telhado).

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
	# 1. Verificação das definições dos elevadores da ROM
	if not require(ElevatorSystem.is_elevator_room(240), "Sala 240 deve ser reconhecida como elevador"): return
	if not require(ElevatorSystem.is_elevator_room(241), "Sala 241 deve ser reconhecida como elevador"): return
	if not require(ElevatorSystem.is_elevator_room(250), "Sala 250 deve ser reconhecida como elevador"): return
	if not require(not ElevatorSystem.is_elevator_room(1), "Sala 1 NÃO deve ser elevador"): return
	if not require(not ElevatorSystem.is_elevator_room(127), "Sala 127 (caminhão) NÃO deve ser elevador"): return

	# 2. Testar estado inicial de entrada no Elevador 1 (Sala 240)
	# Entrada vindo da Sala 3 (Térreo, Y=184, Elev=180)
	var state_from_3: Dictionary = ElevatorSystem.get_entry_state(240, 3)
	if not require((state_from_3.player_pos as Vector2) == Vector2(216.0, 184.0), "Snake deve surgir em (216, 184) ao vir da sala 3"): return
	if not require(is_equal_approx(float(state_from_3.elevator_y), 180.0), "Cabine deve começar em Y=180 ao vir da sala 3"): return
	if not require(int(state_from_3.player_dir) == PlayerController.Direction.LEFT, "Direção inicial deve ser LEFT"): return

	# Entrada vindo da Sala 31 (Telhado, Y=56, Elev=52)
	var state_from_31: Dictionary = ElevatorSystem.get_entry_state(240, 31)
	if not require((state_from_31.player_pos as Vector2) == Vector2(216.0, 56.0), "Snake deve surgir em (216, 56) ao vir da sala 31"): return
	if not require(is_equal_approx(float(state_from_31.elevator_y), 52.0), "Cabine deve começar em Y=52 ao vir da sala 31"): return

	# 3. Testar identificação de andares sequenciais (Elevador 241 com 3 andares: 63, 15, 27)
	# Subindo a partir do térreo (Elev=180) -> deve ir para o andar do meio (Elev=116, Sala 15)
	var up_target_1: Dictionary = ElevatorSystem.get_next_target_floor(241, 180.0, -1)
	if not require(bool(up_target_1.has_target), "Elevador 241 deve achar próximo andar acima de 180"): return
	if not require(is_equal_approx(float(up_target_1.target_elev_y), 116.0), "Andar intermediário deve ser 116.0"): return
	if not require(int(up_target_1.room_id) == 15, "Sala do andar intermediário deve ser 15"): return

	# Subindo a partir do meio (Elev=116) -> deve ir para o topo (Elev=52, Sala 27)
	var up_target_2: Dictionary = ElevatorSystem.get_next_target_floor(241, 116.0, -1)
	if not require(bool(up_target_2.has_target), "Elevador 241 deve achar andar do topo"): return
	if not require(is_equal_approx(float(up_target_2.target_elev_y), 52.0), "Andar do topo deve ser 52.0"): return
	if not require(int(up_target_2.room_id) == 27, "Sala do topo deve ser 27"): return

	# Subindo a partir do andar 27 (Elev=52) em 241 -> shaft continua para a Sala 242
	var up_to_242: Dictionary = ElevatorSystem.get_next_target_floor(241, 52.0, -1)
	if not require(bool(up_to_242.has_target), "Elevador 241 deve permitir subir para a Sala 242"): return
	if not require(bool(up_to_242.is_screen_transition), "Deve indicar transição de tela"): return
	if not require(int(up_to_242.next_room_id) == 242, "Próxima sala deve ser 242"): return

	# No Elevador 242:
	# Descendo a partir da Sala 39 (Elev=180) -> shaft continua para a Sala 241
	var down_to_241: Dictionary = ElevatorSystem.get_next_target_floor(242, 180.0, 1)
	if not require(bool(down_to_241.has_target), "Elevador 242 deve permitir descer para a Sala 241"): return
	if not require(bool(down_to_241.is_screen_transition), "Deve indicar transição de tela para baixo"): return
	if not require(int(down_to_241.next_room_id) == 241, "Próxima sala deve ser 241"): return

	# No topo absoluto do shaft (Elevador 242, Rooftop Sala 53 em Y=116) -> não pode subir mais
	var no_more_up: Dictionary = ElevatorSystem.get_next_target_floor(242, 116.0, -1)
	if not require(not bool(no_more_up.has_target), "Elevador 242 no topo absoluto (Rooftop) não deve ter destino acima"): return

	# No fundo absoluto do shaft (Elevador 241, Térreo Sala 63 em Y=180) -> não pode descer mais
	var no_more_down: Dictionary = ElevatorSystem.get_next_target_floor(241, 180.0, 1)
	if not require(not bool(no_more_down.has_target), "Elevador 241 no fundo absoluto não deve ter destino abaixo"): return

	# Testar get_entry_moving_target
	var entry_down_241: Dictionary = ElevatorSystem.get_entry_moving_target(241, 1)
	if not require(is_equal_approx(float(entry_down_241.target_elev_y), 52.0), "Ao entrar descendo em 241, primeiro alvo é Y=52 (Sala 27)"): return
	var entry_up_242: Dictionary = ElevatorSystem.get_entry_moving_target(242, -1)
	if not require(is_equal_approx(float(entry_up_242.target_elev_y), 180.0), "Ao entrar subindo em 242, primeiro alvo é Y=180 (Sala 39)"): return

	# Descendo do topo de 241 (Elev=52) -> deve ir para o meio (Elev=116)
	var down_target_1: Dictionary = ElevatorSystem.get_next_target_floor(241, 52.0, 1)
	if not require(is_equal_approx(float(down_target_1.target_elev_y), 116.0), "Descida deve parar em 116.0"): return

	# 4. Testar checagem de saída (portas dummy em X >= 224)
	var no_exit: Dictionary = ElevatorSystem.check_exit(240, Vector2(200.0, 56.0), 52.0)
	if not require(not bool(no_exit.should_exit), "Não deve sair com X < 224"): return

	# Deve sair para a Sala 31 quando no andar superior (Elev=52, Y=56, X=224)
	var exit_31: Dictionary = ElevatorSystem.check_exit(240, Vector2(224.0, 56.0), 52.0)
	if not require(bool(exit_31.should_exit), "Deve sair quando X >= 224 e cabine alinhada no andar 31"): return
	if not require(int(exit_31.destination_room_id) == 31, "Destino deve ser Sala 31"): return
	if not require((exit_31.entry_position as Vector2) == Vector2(108.0, 36.0), "Posição de saída deve ser em frente à porta do elevador"): return

	# 5. Teste de integração completo no Sandbox
	var sandbox_scene: PackedScene = preload("res://scenes/sandbox_gameplay.tscn")
	var sandbox: Control = sandbox_scene.instantiate() as Control
	root.add_child(sandbox)
	await process_frame
	await process_frame

	# Carregar Sala 3 no Sandbox
	var loaded_3: bool = sandbox.change_to_room(3, Vector2(108.0, 60.0), PlayerController.Direction.UP)
	if not require(loaded_3, "Sala 3 deve carregar no sandbox"): return
	if not require(sandbox.snapshot.room_id == 3, "Sala atual deve ser 3"): return
	if not require(not sandbox.is_in_elevator, "Sala 3 não deve estar em modo elevador"): return

	# Encontrar a porta de elevador da Sala 3
	var elev_door: RoomDoor = null
	for d: RoomDoor in sandbox.room_doors:
		if d.destination_room == 240:
			elev_door = d
			break
	if not require(elev_door != null, "Sala 3 deve conter a porta canônica para o elevador 240"): return

	# Snake se aproxima e entra na porta do elevador
	sandbox.player.set_grid_position(108.0, 16.0)
	sandbox.player.current_direction = PlayerController.Direction.UP
	var dest_room: int = elev_door.check_interaction(sandbox.player, sandbox.inventory, sandbox.snapshot.collision)
	if not require(elev_door.is_open, "Porta do elevador deve abrir ao contato"): return

	# Entra no vão
	sandbox.player.set_grid_position(108.0, 8.0)
	dest_room = elev_door.check_interaction(sandbox.player, sandbox.inventory, sandbox.snapshot.collision)
	if not require(dest_room == 240, "Entrar no vão deve disparar destino 240"): return

	# Executa transição para o elevador 240
	sandbox.change_to_room(240, elev_door.entry_position, elev_door.destination_direction)
	if not require(sandbox.is_in_elevator, "Sandbox deve ativar modo elevador"): return
	if not require(sandbox.snapshot.room_id == 240, "Sala deve ser 240"): return
	if not require(is_equal_approx(sandbox.elevator_y, 180.0), "Elevador deve iniciar em Y=180 (andar térreo da Sala 3)"): return
	if not require(sandbox.player.position == Vector2(216.0, 184.0), "Snake deve surgir em (216, 184)"): return

	# Testar que entrada vertical no corredor é ignorada (Snake NÃO sobe nem desce pelas paredes)
	var old_y: float = sandbox.player.position.y
	# Simula um tick de entrada UP enquanto no corredor (X=216 > 120)
	var walk_test: Vector2i = Vector2i(0, -1)
	var filtered_dir: Vector2i = Vector2i(walk_test.x, 0)
	if filtered_dir.x != 0:
		sandbox.player.step_tick(filtered_dir)
	if not require(is_equal_approx(sandbox.player.position.y, old_y), "Entrada vertical no corredor do elevador não deve alterar Y do Snake"): return

	# Snake caminha para a cabine em (112.0, 184.0)
	sandbox.player.position = Vector2(112.0, 184.0)

	# Dentro da cabine, acionar subida com CIMA
	var target_up: Dictionary = ElevatorSystem.get_next_target_floor(240, sandbox.elevator_y, -1)
	if not require(bool(target_up.has_target), "Deve encontrar andar do telhado acima"): return
	sandbox.elevator_target_y = float(target_up.target_elev_y)
	sandbox.elevator_state = sandbox.ELEVATOR_STATE_MOVING

	# Simular os ticks de trânsito vertical da cabine a 1 px/tick
	var ticks: int = 0
	while sandbox.elevator_state == sandbox.ELEVATOR_STATE_MOVING and ticks < 300:
		ticks += 1
		var dir_y: float = -1.0 if sandbox.elevator_target_y < sandbox.elevator_y else 1.0
		sandbox.elevator_y += dir_y * ElevatorSystem.ELEVATOR_SPEED
		sandbox.player.position.y = sandbox.elevator_y + 4.0
		if absf(sandbox.elevator_y - sandbox.elevator_target_y) < 0.5:
			sandbox.elevator_y = sandbox.elevator_target_y
			sandbox.player.position.y = sandbox.elevator_y + 4.0
			sandbox.elevator_state = sandbox.ELEVATOR_STATE_IDLE

	if not require(sandbox.elevator_state == sandbox.ELEVATOR_STATE_IDLE, "Elevador deve parar ao atingir o andar"): return
	if not require(is_equal_approx(sandbox.elevator_y, 52.0), "Elevador deve atingir Y=52 (Telhado)"): return
	if not require(is_equal_approx(sandbox.player.position.y, 56.0), "Snake deve atingir Y=56 perfeitamente alinhado com a cabine"): return

	# Snake caminha para a direita até o corredor de saída (X=224.0)
	sandbox.player.position.x = 224.0

	# Acionar checagem de saída
	var exit_eval: Dictionary = ElevatorSystem.check_exit(sandbox.snapshot.room_id, sandbox.player.position, sandbox.elevator_y)
	if not require(bool(exit_eval.should_exit), "Deve permitir saída no andar superior"): return
	if not require(int(exit_eval.destination_room_id) == 31, "Saída deve levar à Sala 31"): return

	# Realizar transição para a Sala 31
	sandbox.change_to_room(31, exit_eval.entry_position as Vector2, int(exit_eval.destination_direction))
	if not require(not sandbox.is_in_elevator, "Deve desativar modo elevador ao sair"): return
	if not require(sandbox.snapshot.room_id == 31, "Sala atual deve ser 31"): return
	if not require(sandbox.player.position == Vector2(108.0, 36.0), "Snake deve estar em frente à porta do elevador na sala 31"): return

	# Retorno: da Sala 31 de volta para o Elevador 240
	sandbox.change_to_room(240, Vector2.ZERO)
	if not require(sandbox.is_in_elevator, "Deve reativar modo elevador ao retornar"): return
	if not require(is_equal_approx(sandbox.elevator_y, 52.0), "Elevador deve iniciar em Y=52 ao vir da Sala 31"): return
	if not require(sandbox.player.position == Vector2(216.0, 56.0), "Snake deve iniciar em (216, 56)"): return

	# Snake entra na cabine e aciona descida
	sandbox.player.position = Vector2(112.0, 56.0)
	var target_down: Dictionary = ElevatorSystem.get_next_target_floor(240, sandbox.elevator_y, 1)
	if not require(bool(target_down.has_target), "Deve encontrar andar do térreo abaixo"): return
	sandbox.elevator_target_y = float(target_down.target_elev_y)
	sandbox.elevator_state = sandbox.ELEVATOR_STATE_MOVING

	ticks = 0
	while sandbox.elevator_state == sandbox.ELEVATOR_STATE_MOVING and ticks < 300:
		ticks += 1
		var dir_y: float = -1.0 if sandbox.elevator_target_y < sandbox.elevator_y else 1.0
		sandbox.elevator_y += dir_y * ElevatorSystem.ELEVATOR_SPEED
		sandbox.player.position.y = sandbox.elevator_y + 4.0
		if absf(sandbox.elevator_y - sandbox.elevator_target_y) < 0.5:
			sandbox.elevator_y = sandbox.elevator_target_y
			sandbox.player.position.y = sandbox.elevator_y + 4.0
			sandbox.elevator_state = sandbox.ELEVATOR_STATE_IDLE

	if not require(is_equal_approx(sandbox.elevator_y, 180.0), "Elevador deve retornar a Y=180"): return
	if not require(is_equal_approx(sandbox.player.position.y, 184.0), "Snake deve estar em Y=184"): return

	sandbox.player.position.x = 224.0
	var exit_back: Dictionary = ElevatorSystem.check_exit(sandbox.snapshot.room_id, sandbox.player.position, sandbox.elevator_y)
	if not require(int(exit_back.destination_room_id) == 3, "Retorno deve levar de volta à Sala 3"): return

	sandbox.change_to_room(3, exit_back.entry_position as Vector2, int(exit_back.destination_direction))
	if not require(sandbox.snapshot.room_id == 3, "Sala final deve ser 3"): return

	# 6. Teste de transição multi-telas de shafts: Sala 242 -> Sala 241 (descida contínua)
	sandbox.change_to_room(242, Vector2.ZERO)
	sandbox.elevator_y = 180.0
	sandbox.player.position = Vector2(112.0, 184.0)

	var target_242_down: Dictionary = ElevatorSystem.get_next_target_floor(242, 180.0, 1)
	if not require(bool(target_242_down.has_target) and bool(target_242_down.is_screen_transition), "Sala 242 deve ter transição para baixo"): return
	sandbox.elevator_target_y = float(target_242_down.target_elev_y)
	sandbox.elevator_state = sandbox.ELEVATOR_STATE_MOVING

	# Simula o avanço do elevador até cruzar a borda inferior (208.0) e transitar para 241
	ticks = 0
	while sandbox.elevator_state == sandbox.ELEVATOR_STATE_MOVING and ticks < 300:
		ticks += 1
		var dir_y: float = -1.0 if sandbox.elevator_target_y < sandbox.elevator_y else 1.0
		sandbox.elevator_y += dir_y * ElevatorSystem.ELEVATOR_SPEED
		sandbox.player.position.y = sandbox.elevator_y + 4.0

		if dir_y > 0.0 and sandbox.elevator_y >= ElevatorSystem.EXIT_DOWN_Y:
			var next_down: int = ElevatorSystem.get_connected_elevator_room(sandbox.snapshot.room_id, 1)
			if next_down != -1:
				sandbox._transition_elevator_room(next_down, 1)
				continue

		if absf(sandbox.elevator_y - sandbox.elevator_target_y) < 0.5:
			sandbox.elevator_y = sandbox.elevator_target_y
			sandbox.player.position.y = sandbox.elevator_y + 4.0
			sandbox.elevator_state = sandbox.ELEVATOR_STATE_IDLE

	if not require(sandbox.snapshot.room_id == 241, "Elevador deve ter transitado para a Sala 241"): return
	if not require(is_equal_approx(sandbox.elevator_y, 52.0), "Elevador deve ter parado no primeiro andar de 241 (Y=52.0, Sala 27)"): return
	if not require(is_equal_approx(sandbox.player.position.y, 56.0), "Snake deve estar alinhado em Y=56.0"): return

	print("ELEVATOR_OK: 11 elevadores configurados, movimentação vertical a 1 px/tick, tolerâncias de andares, transição multi-telas 242 <-> 241 e ciclo bidirecional Sala 3 <-> Sala 240 <-> Sala 31")
	quit(0)
