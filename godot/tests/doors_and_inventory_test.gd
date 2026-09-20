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
	# 1. Teste de InventoryManager
	var inv: InventoryManager = InventoryManager.new()
	if not require(inv.get_selected_item() == "", "Inventário inicial deve estar vazio"): return
	if not require(inv.get_status_text() == "[NENHUM]", "Status inicial deve ser [NENHUM]"): return

	# Coleta de CARD1
	var collected: bool = inv.collect_item(InventoryManager.ITEM_CARD1)
	if not require(collected and inv.has_item("CARD1"), "CARD1 deve ser adicionado ao inventário"): return
	if not require(inv.get_selected_item() == "CARD1", "CARD1 deve ser o item selecionado inicialmente"): return

	# Coleta de Rações (RATION)
	inv.collect_item(InventoryManager.ITEM_RATION)
	inv.collect_item(InventoryManager.ITEM_RATION)
	if not require(inv.rations_count == 2, "Contagem de rações deve ser 2"): return
	if not require(inv.has_item("RATION"), "has_item('RATION') deve ser true"): return

	# Alternar itens no inventário
	inv.cycle_item()
	if not require(inv.get_selected_item() == "RATION", "cycle_item deve alternar para RATION"): return
	if not require(inv.get_status_text() == "[RAÇÃO x2]", "Status de ração incorreto"): return

	# Cura por Ração em Snake ferido
	var packed_player: PackedScene = load("res://scenes/player.tscn") as PackedScene
	if not require(packed_player != null, "Falha ao carregar scenes/player.tscn"): return
	var player: PlayerController = packed_player.instantiate() as PlayerController
	root.add_child(player)
	await process_frame

	player.life = 10 # Snake ferido
	var used: bool = inv.use_selected_item(player)
	if not require(used and player.life == 24, "Usar ração deve restaurar a vida ao máximo de 24 pontos"): return
	if not require(inv.rations_count == 1, "Ração consumida deve decrementar a quantidade para 1"): return

	# 2. Teste de ItemBox no mundo
	var box: ItemBox = ItemBox.new()
	box.item_id = "CARD2"
	box.room_id = 99
	box.position = Vector2(100.0, 100.0)
	root.add_child(box)
	await process_frame

	# Snake longe (distância 30 px)
	var touched: bool = box.step_tick(Vector2(130.0, 100.0), inv)
	if not require(not touched and not box.collected, "ItemBox longe não deve ser coletada"): return
	if not require(not inv.has_item("CARD2"), "CARD2 não deve estar no inventário antes da coleta"): return

	# Snake toca na caixa (distância 5 px <= 12 px)
	touched = box.step_tick(Vector2(105.0, 100.0), inv)
	if not require(touched and box.collected, "ItemBox deve ser coletada ao contato com Snake"): return
	if not require(inv.has_item("CARD2"), "CARD2 deve estar no inventário após a coleta"): return

	# 3. Teste de RoomDoor, Trancas e Injeção de Colisão
	var door: RoomDoor = RoomDoor.new()
	door.door_id = 1
	door.room_id = 2
	door.required_card = "CARD1"
	door.destination_room = 4
	door.entry_position = Vector2(230.0, 96.0)
	door.orientation = RoomDoor.DoorOrientation.WEST
	door.position = Vector2(16.0, 96.0) # tx = 2, ty = 12
	root.add_child(door)
	await process_frame

	var collision_grid: Array[int] = []
	collision_grid.resize(768)
	collision_grid.fill(0)

	door.inject_collision(collision_grid)
	for idx: int in door.collision_tile_indices:
		if not require(collision_grid[idx] == 1, "Porta fechada deve injetar colisão (1) nos seus tiles"): return

	# Snake se aproxima da porta sem o cartão correto selecionado
	inv.select_item("CARD2") # Seleciona cartão incorreto
	player.set_grid_position(28.0, 96.0)
	player.current_direction = PlayerController.Direction.LEFT
	var dest: int = door.check_interaction(player, inv, collision_grid)
	if not require(dest == -1 and not door.is_open, "Porta trancada NÃO deve abrir sem o cartão correto"): return

	# Snake seleciona CARD1 e se aproxima olhando para WEST
	inv.select_item("CARD1")
	dest = door.check_interaction(player, inv, collision_grid)
	if not require(door.is_open, "Porta deve abrir ao contato com o cartão correto"): return

	# Abertura deve limpar a colisão dos tiles para 0
	for idx: int in door.collision_tile_indices:
		if not require(collision_grid[idx] == 0, "Porta aberta deve liberar colisão (0) nos seus tiles"): return

	# Snake avança para dentro do vão da porta aberta (distância 6 px <= 10 px)
	player.set_grid_position(18.0, 96.0)
	dest = door.check_interaction(player, inv, collision_grid)
	if not require(dest == 4, "Atravessar porta aberta deve retornar a sala de destino (4)"): return

	# 4. Teste de Portas de Caminhão (Lorry Doors) e Interior de Caminhões (Salas 126, 127, 128)
	# Entrada no caminhão da Sala 5 -> Sala 127
	var lorry_door: RoomDoor = RoomDoor.new()
	lorry_door.door_id = 109
	lorry_door.room_id = 5
	lorry_door.is_lorry = true
	lorry_door.orientation = RoomDoor.DoorOrientation.LORRY_ENTER
	lorry_door.position = Vector2(100.0, 100.0)
	lorry_door.trigger_rect = Rect2(96.0, 112.0, 32.0, 16.0)
	lorry_door.destination_room = 127
	lorry_door.entry_position = Vector2(196.0, 112.0)
	lorry_door.destination_direction = PlayerController.Direction.LEFT
	root.add_child(lorry_door)
	await process_frame

	if not require(lorry_door.is_open, "Porta de caminhão deve estar aberta por padrão"): return
	if not require(lorry_door.collision_tile_indices.is_empty(), "Porta de caminhão não deve bloquear colisão de tiles"): return

	# Snake fora da zona de entrada
	player.set_grid_position(50.0, 50.0)
	player.current_direction = PlayerController.Direction.UP
	var lorry_dest: int = lorry_door.check_interaction(player, inv, collision_grid)
	if not require(lorry_dest == -1, "Snake longe do caminhão não deve entrar"): return

	# Snake entra na traseira do caminhão olhando para cima (UP)
	player.set_grid_position(108.0, 118.0) # Dentro de trigger_rect Rect2(96, 112, 32, 16)
	player.current_direction = PlayerController.Direction.UP
	lorry_dest = lorry_door.check_interaction(player, inv, collision_grid)
	if not require(lorry_dest == 127, "Snake deve entrar no caminhão (sala 127) ao subir pela traseira"): return

	# Saída de dentro do caminhão (Sala 127 -> Sala 5)
	var lorry_exit: RoomDoor = RoomDoor.new()
	lorry_exit.door_id = 109
	lorry_exit.room_id = 127
	lorry_exit.is_lorry = true
	lorry_exit.orientation = RoomDoor.DoorOrientation.LORRY_EXIT
	lorry_exit.position = Vector2(208.0, 96.0)
	lorry_exit.trigger_rect = Rect2(204.0, 92.0, 24.0, 36.0)
	lorry_exit.destination_room = 5
	lorry_exit.entry_position = Vector2(112.0, 136.0)
	lorry_exit.destination_direction = PlayerController.Direction.DOWN
	root.add_child(lorry_exit)
	await process_frame

	# Snake caminha para a direita para sair do caminhão
	player.set_grid_position(210.0, 100.0)
	player.current_direction = PlayerController.Direction.RIGHT
	var exit_dest: int = lorry_exit.check_interaction(player, inv, collision_grid)
	if not require(exit_dest == 5, "Snake deve sair do caminhão de volta para a sala 5 ao caminhar pela direita"): return

	# 5. Teste de Coleta dos Itens Canônicos dentro dos caminhões (Salas 126, 127, 128)
	var truck_inv: InventoryManager = InventoryManager.new()
	var box_126: ItemBox = ItemBox.new()
	box_126.item_id = InventoryManager.ITEM_RATION
	box_126.room_id = 126
	box_126.position = Vector2(80.0, 80.0)
	root.add_child(box_126)

	var box_127: ItemBox = ItemBox.new()
	box_127.item_id = InventoryManager.ITEM_CARD1
	box_127.room_id = 127
	box_127.position = Vector2(112.0, 80.0)
	root.add_child(box_127)

	var box_128: ItemBox = ItemBox.new()
	box_128.item_id = InventoryManager.ITEM_BINOCULARS
	box_128.room_id = 128
	box_128.position = Vector2(112.0, 64.0)
	root.add_child(box_128)
	await process_frame

	# Coleta da ração no caminhão 126
	box_126.step_tick(Vector2(80.0, 80.0), truck_inv)
	if not require(box_126.collected and truck_inv.has_item("RATION"), "Ração da sala 126 deve ser coletada"): return

	# Coleta do Card 1 no caminhão 127
	box_127.step_tick(Vector2(112.0, 80.0), truck_inv)
	if not require(box_127.collected and truck_inv.has_item("CARD1"), "Card 1 da sala 127 deve ser coletado"): return

	# Coleta dos Binóculos no caminhão 128
	box_128.step_tick(Vector2(112.0, 64.0), truck_inv)
	if not require(box_128.collected and truck_inv.has_item("BINOCULARS"), "Binóculos da sala 128 devem ser coletados"): return

	# 6. Teste de Portas Canônicas Automatizadas e Trancas por Card 4 (Etapa 12b)
	var card4_inv: InventoryManager = InventoryManager.new()
	card4_inv.collect_item(InventoryManager.ITEM_CARD4)

	var door_c4: RoomDoor = RoomDoor.new()
	door_c4.door_id = 3
	door_c4.room_id = 6
	door_c4.required_card = InventoryManager.ITEM_CARD4
	door_c4.orientation = RoomDoor.DoorOrientation.NORTH
	door_c4.position = Vector2(36.0, 64.0)
	door_c4.destination_room = 129
	root.add_child(door_c4)
	await process_frame

	var dummy_collision: Array = []
	dummy_collision.resize(768)
	dummy_collision.fill(0)
	door_c4.inject_collision(dummy_collision)

	# Snake tenta abrir sem cartão correto (usando inventário vazio)
	var empty_inv: InventoryManager = InventoryManager.new()
	var dummy_player: PlayerController = packed_player.instantiate() as PlayerController
	root.add_child(dummy_player)
	dummy_player.position = Vector2(36.0, 74.0)
	dummy_player.current_direction = PlayerController.Direction.UP

	var entered: int = door_c4.check_interaction(dummy_player, empty_inv, dummy_collision)
	if not require(entered == -1 and not door_c4.is_open, "Porta Card 4 deve permanecer fechada sem o cartão"): return

	# Snake usa Card 4 e abre a porta
	entered = door_c4.check_interaction(dummy_player, card4_inv, dummy_collision)
	if not require(door_c4.is_open, "Porta Card 4 deve abrir com Card 4 selecionado"): return

	# Testar carregamento dos metadados de portas da sala 6 via RoomManager
	var rm: RoomManager = RoomManager.new()
	var r6_data: Dictionary = rm.load_room_actors(6)
	if not r6_data.is_empty():
		var r6_doors: Array = r6_data.get("doors", [])
		if not require(r6_doors.size() == 3, "Sala 6 da ROM deve ter 3 portas"): return
		var r6_actors: Array = r6_data.get("actors", [])
		if not require(r6_actors.size() == 2, "Sala 6 da ROM deve ter 2 cães de guarda"): return

	door_c4.queue_free()
	dummy_player.queue_free()
	await process_frame

	print("DOORS_AND_INVENTORY_OK: item collection, cycle, ration healing, locked door collision, card unlock, lorry doors enter/exit, and canonical truck items")
	quit(0)

