# elevator_test.gd
# Validação automatizada da mecânica de elevadores e transições verticais (Etapa 12d).
# Cobre:
# 1. Configuração e limites canônicos dos 11 elevadores (salas 240 a 250).
# 2. Posicionamento autêntico de entrada baseado no andar de origem (GetElevatorPosY).
# 3. Movimentação vertical da cabine e de Snake a 1 px/tick (MoveElevator).
# 4. Detecção de andares e tolerâncias de saída (doors dummy 224, Y).
# 5. Ciclo completo de integração no sandbox: Sala 3 (Térreo) <-> Sala 240 (Elevador) <-> Sala 31 (Telhado).

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

	# 3. Testar movimentação vertical da cabine e de Snake (1 px/tick)
	# Fora da cabine (X=140 > 120): elevador NÃO deve se mover
	var outside_res: Dictionary = ElevatorSystem.step_movement(240, Vector2(140.0, 184.0), 180.0, -1)
	if not require(not bool(outside_res.is_moving), "Elevador não deve mover se Snake estiver fora da cabine"): return
	if not require(is_equal_approx(float(outside_res.elevator_y), 180.0), "Elevador não deve alterar Y"): return

	# Dentro da cabine (X=112 <= 120): subir 1 px/tick
	var step1: Dictionary = ElevatorSystem.step_movement(240, Vector2(112.0, 184.0), 180.0, -1)
	if not require(bool(step1.is_moving), "Elevador deve mover com Snake na cabine e input_y=-1"): return
	if not require(is_equal_approx(float(step1.elevator_y), 179.0), "Cabine deve subir para 179.0"): return
	if not require(is_equal_approx((step1.player_pos as Vector2).y, 183.0), "Snake deve subir junto para 183.0"): return

	# Descer 1 px/tick
	var step_down: Dictionary = ElevatorSystem.step_movement(240, Vector2(112.0, 183.0), 179.0, 1)
	if not require(bool(step_down.is_moving), "Elevador deve mover para baixo"): return
	if not require(is_equal_approx(float(step_down.elevator_y), 180.0), "Cabine deve descer para 180.0"): return
	if not require(is_equal_approx((step_down.player_pos as Vector2).y, 184.0), "Snake deve descer para 184.0"): return

	# 4. Testar checagem de saída (portas dummy em X >= 224)
	# Não deve sair se Snake estiver em X < 224
	var no_exit: Dictionary = ElevatorSystem.check_exit(240, Vector2(200.0, 56.0), 52.0)
	if not require(not bool(no_exit.should_exit), "Não deve sair com X < 224"): return

	# Deve sair para a Sala 31 quando no andar superior (Elev=52, Y=56, X=224)
	var exit_31: Dictionary = ElevatorSystem.check_exit(240, Vector2(224.0, 56.0), 52.0)
	if not require(bool(exit_31.should_exit), "Deve sair quando X >= 224 e cabine alinhada no andar 31"): return
	if not require(int(exit_31.destination_room_id) == 31, "Destino deve ser Sala 31"): return
	if not require((exit_31.entry_position as Vector2) == Vector2(108.0, 36.0), "Posição de saída deve ser em frente à porta do elevador"): return

	# Deve sair para a Sala 3 quando no andar inferior (Elev=180, Y=184, X=224)
	var exit_3: Dictionary = ElevatorSystem.check_exit(240, Vector2(224.0, 184.0), 180.0)
	if not require(bool(exit_3.should_exit), "Deve sair quando X >= 224 e cabine alinhada no andar 3"): return
	if not require(int(exit_3.destination_room_id) == 3, "Destino deve ser Sala 3"): return

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

	# Snake caminha para a cabine em (112.0, 184.0)
	sandbox.player.position = Vector2(112.0, 184.0)

	# Simular subida até o andar da Sala 31 (Y=52)
	while sandbox.elevator_y > 52.0:
		var m: Dictionary = ElevatorSystem.step_movement(240, sandbox.player.position, sandbox.elevator_y, -1)
		sandbox.elevator_y = float(m.elevator_y)
		sandbox.player.position.y = (m.player_pos as Vector2).y

	if not require(is_equal_approx(sandbox.elevator_y, 52.0), "Elevador deve atingir Y=52 (Telhado)"): return
	if not require(is_equal_approx(sandbox.player.position.y, 56.0), "Snake deve atingir Y=56"): return

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

	# Agora retorno: da Sala 31 de volta para o Elevador 240
	sandbox.change_to_room(240, Vector2.ZERO)
	if not require(sandbox.is_in_elevator, "Deve reativar modo elevador ao retornar"): return
	if not require(is_equal_approx(sandbox.elevator_y, 52.0), "Elevador deve iniciar em Y=52 ao vir da Sala 31"): return
	if not require(sandbox.player.position == Vector2(216.0, 56.0), "Snake deve iniciar em (216, 56)"): return

	# Desce de volta para o térreo
	sandbox.player.position = Vector2(112.0, 56.0)
	while sandbox.elevator_y < 180.0:
		var m: Dictionary = ElevatorSystem.step_movement(240, sandbox.player.position, sandbox.elevator_y, 1)
		sandbox.elevator_y = float(m.elevator_y)
		sandbox.player.position.y = (m.player_pos as Vector2).y

	if not require(is_equal_approx(sandbox.elevator_y, 180.0), "Elevador deve retornar a Y=180"): return
	sandbox.player.position.x = 224.0
	var exit_back: Dictionary = ElevatorSystem.check_exit(sandbox.snapshot.room_id, sandbox.player.position, sandbox.elevator_y)
	if not require(int(exit_back.destination_room_id) == 3, "Retorno deve levar de volta à Sala 3"): return

	sandbox.change_to_room(3, exit_back.entry_position as Vector2, int(exit_back.destination_direction))
	if not require(sandbox.snapshot.room_id == 3, "Sala final deve ser 3"): return

	print("ELEVATOR_OK: 11 elevadores configurados, movimentação vertical a 1 px/tick, tolerâncias de andares e ciclo bidirecional Sala 3 <-> Sala 240 <-> Sala 31")
	quit(0)
