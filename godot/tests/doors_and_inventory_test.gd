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

	# Snake toca na caixa (distância 5 px)
	touched = box.step_tick(Vector2(105.0, 100.0), inv)
	if not require(touched and box.collected, "ItemBox deve ser coletada ao contato com Snake"): return
	if not require(inv.has_item("CARD2"), "CARD2 deve estar no inventário após a coleta"): return

	# 2b. Teste de item sobre mesa ou obstáculo com colisão sólida (distância de 18 px ao encostar na borda)
	var table_box: ItemBox = ItemBox.new()
	table_box.item_id = "CARD3"
	table_box.room_id = 100
	table_box.position = Vector2(112.0, 80.0) # Caixa no centro da mesa
	root.add_child(table_box)
	await process_frame

	# Snake encostado na face inferior da mesa sólida em Y = 98.0 (18 px de distância do centro da caixa)
	var table_touched: bool = table_box.step_tick(Vector2(112.0, 98.0), inv)
	if not require(table_touched and table_box.collected, "ItemBox em cima de mesa com colisão deve ser coletada ao encostar na borda"): return
	if not require(inv.has_item("CARD3"), "CARD3 na mesa deve ser adicionado ao inventário"): return

	# 3. Teste de RoomDoor, Trancas e Injeção de Colisão
	# Usar inventário isolado para não contaminar com CARD1 já coletado acima
	var door_inv_no_card: InventoryManager = InventoryManager.new()  # sem nenhum cartão
	var door_inv_with_card: InventoryManager = InventoryManager.new()
	door_inv_with_card.collect_item(InventoryManager.ITEM_CARD1)

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

	# Snake se aproxima da porta sem nenhum cartão no inventário
	player.set_grid_position(28.0, 96.0)
	player.current_direction = PlayerController.Direction.LEFT
	var dest: int = door.check_interaction(player, door_inv_no_card, collision_grid)
	if not require(dest == -1 and not door.is_open, "Porta trancada NÃO deve abrir sem o cartão"): return

	# Snake possui CARD1 no inventário (sem precisar selecioná-lo — fiel à ROM)
	if not require(door_inv_with_card.has_item("CARD1"), "CARD1 deve estar no inventário"): return
	dest = door.check_interaction(player, door_inv_with_card, collision_grid)
	if not require(door.is_open, "Porta deve abrir ao contato com o cartão correto (basta possuir)"): return

	# Abertura deve limpar a colisão dos tiles para 0
	for idx: int in door.collision_tile_indices:
		if not require(collision_grid[idx] == 0, "Porta aberta deve liberar colisão (0) nos seus tiles"): return

	# Snake avança para dentro do vão da porta aberta (distância 6 px <= 10 px)
	player.set_grid_position(18.0, 96.0)
	dest = door.check_interaction(player, door_inv_with_card, collision_grid)
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
	# NORTH door: position=(36,64), open_trigger_rect = Rect2(36, 84, 32, 20) [pos.y + 20, h=20]
	# Player deve estar dentro do trigger → y entre 84 e 104, x entre 36 e 68
	var empty_inv: InventoryManager = InventoryManager.new()
	var dummy_player: PlayerController = packed_player.instantiate() as PlayerController
	root.add_child(dummy_player)
	dummy_player.position = Vector2(52.0, 90.0)  # dentro de Rect2(36,84,32,20)
	dummy_player.current_direction = PlayerController.Direction.UP

	var entered: int = door_c4.check_interaction(dummy_player, empty_inv, dummy_collision)
	if not require(entered == -1 and not door_c4.is_open, "Porta Card 4 deve permanecer fechada sem o cartão"): return

	# Snake possui Card 4 no inventário (SEM precisar selecioná-lo — fiel à ROM: CardLevelReg)
	# O cartão não está selecionado (selected_index aponta para outro item)
	card4_inv.collect_item(InventoryManager.ITEM_BINOCULARS) # Adiciona outro item
	card4_inv.select_item(InventoryManager.ITEM_BINOCULARS)  # Seleciona o binóculo, NÃO o cartão
	if not require(card4_inv.get_selected_item() == "BINOCULARS", "Binoculars deve ser o selecionado"): return
	if not require(card4_inv.has_item("CARD4"), "Card 4 deve estar no inventário"): return

	entered = door_c4.check_interaction(dummy_player, card4_inv, dummy_collision)
	if not require(door_c4.is_open, "Porta Card 4 deve abrir mesmo com Card 4 não selecionado (basta possuir)"): return

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

	# 7. Teste de bloqueio físico no SandboxGameplay contra portas trancadas por cartão
	var sandbox = load("res://scenes/sandbox_gameplay.tscn").instantiate()
	root.add_child(sandbox)
	await process_frame
	await process_frame

	# Carregar Sala 8 (Porta 1 trancada com CARD1)
	sandbox.change_to_room(8, Vector2(128.0, 128.0))
	var s8_door: RoomDoor = null
	for d: RoomDoor in sandbox.room_doors:
		if d.door_id == 1:
			s8_door = d
			break
	if not require(s8_door != null and not s8_door.is_open and s8_door.required_card == "CARD1", "Porta 1 da Sala 8 deve nascer fechada e exigir CARD1"): return

	# Posicionar Snake logo abaixo da porta e tentar avançar para cima sem cartão
	sandbox.player.position = Vector2(s8_door.position.x + 16.0, s8_door.position.y + 36.0)
	for step in range(20):
		sandbox.player.step_tick(Vector2i.UP)
		sandbox.call("_physics_process", 1.0 / 60.0)
	if not require(not s8_door.is_open, "Porta 1 NÃO deve abrir sem CARD1"): return
	if not require(sandbox.snapshot.room_id == 8, "Snake NÃO deve transicionar para Sala 138 sem CARD1"): return
	if not require(sandbox.player.position.y >= s8_door.position.y + 24.0, "Colisão da porta trancada deve bloquear Snake fisicamente"): return

	# Snake coleta CARD1 (sem precisar selecioná-lo) e toca na porta — fiel à ROM
	sandbox.inventory.collect_item(InventoryManager.ITEM_CARD1)
	# Confirmar que o cartão não está necessariamente selecionado (pode estar, mas não é exigência)
	if not require(sandbox.inventory.has_item("CARD1"), "CARD1 deve estar no inventário"): return
	sandbox.player.current_direction = PlayerController.Direction.UP
	sandbox.call("_physics_process", 1.0 / 60.0)
	# Snake avança para dentro da porta aberta e entra na Item Room 138
	sandbox.player.position = Vector2(s8_door.position.x + 16.0, s8_door.position.y + 16.0)
	sandbox.call("_physics_process", 1.0 / 60.0)
	if not require(sandbox.snapshot.room_id == 138, "Snake deve transicionar para Item Room 138 através da porta aberta"): return
	if not require(sandbox.item_boxes.size() > 0 and sandbox.item_boxes[0].item_id == "GAS_MASK", "Sala 138 deve conter a Máscara de Gás"): return

	# Snake sai pela porta sul de volta para a Sala 8
	var exit_138: RoomDoor = sandbox.room_doors[0]
	sandbox.player.position = Vector2(exit_138.position.x + 16.0, exit_138.position.y)
	sandbox.player.current_direction = PlayerController.Direction.DOWN
	sandbox.call("_physics_process", 1.0 / 60.0)
	if not require(sandbox.snapshot.room_id == 8, "Snake deve retornar para a Sala 8 ao sair da Item Room"): return

	# 8. Teste de Bloqueio de Borda da Sala 7 para Sala 11 (requer CARD4)
	sandbox.change_to_room(7, Vector2(128.0, 128.0))
	var fresh_inv: InventoryManager = InventoryManager.new()
	sandbox.inventory = fresh_inv
	# Snake tenta sair pela borda leste (X >= 244) sem CARD4
	sandbox.player.position = Vector2(242.0, 136.0)
	sandbox.player.step_tick(Vector2i.RIGHT)
	sandbox._check_and_handle_room_transition()
	if not require(sandbox.snapshot.room_id == 7, "Transição da Sala 7 para Sala 11 deve ser BARRADA sem CARD4"): return
	if not require(sandbox.player.position.x <= 244.0, "Snake deve ser empurrado de volta para dentro dos limites da Sala 7"): return

	# Snake adquire CARD4 e tenta atravessar para a Sala 11
	sandbox.inventory.collect_item(InventoryManager.ITEM_CARD4)
	sandbox.player.position = Vector2(242.0, 136.0)
	sandbox.player.step_tick(Vector2i.RIGHT)
	sandbox._check_and_handle_room_transition()
	if not require(sandbox.snapshot.room_id == 11, "Snake com CARD4 deve conseguir transicionar para a Sala 11"): return

	# 9. Teste da Porta 128 (Sala 32 <-> Sala 153) — Vão limpo e eliminação de blocos flutuantes
	sandbox.change_to_room(32, Vector2(128.0, 128.0))
	var d128_s32: RoomDoor = null
	for d in sandbox.room_doors:
		if d.door_id == 128:
			d128_s32 = d
			break
	if not require(d128_s32 != null and d128_s32.is_open, "Porta 128 na Sala 32 deve existir e estar aberta"): return
	# Verificar que os tiles do vão não têm blocos flutuantes
	for ty in range(7, 11):
		for tx in range(12, 14):
			var idx = ty * 32 + tx
			if not require(sandbox.runtime_collision[idx] == 0, "Vão da Porta 128 na Sala 32 deve estar desobstruído (0)"): return

	# Snake entra na Porta 128 na Sala 32
	sandbox.player.position = Vector2(d128_s32.position.x, d128_s32.position.y + 40.0)
	sandbox.player.current_direction = PlayerController.Direction.LEFT
	var dest_153 = d128_s32.check_interaction(sandbox.player, sandbox.inventory, sandbox.runtime_collision)
	if not require(dest_153 == 153, "Porta 128 deve conduzir à Sala 153"): return
	sandbox.change_to_room(dest_153, d128_s32.entry_position, d128_s32.destination_direction, d128_s32.door_id)
	if not require(sandbox.snapshot.room_id == 153, "Snake deve transicionar para a Sala 153"): return

	# Verificar eliminação do bloco de colisão flutuante em ty=11, tx=26 na Sala 153
	var float_idx = 11 * 32 + 26
	if not require(sandbox.runtime_collision[float_idx] == 0, "Bloco flutuante da Sala 153 (ty=11, tx=26) deve ter sido eliminado"): return

	# Snake retorna para a Sala 32 através da Porta 128
	var d128_s153: RoomDoor = null
	for d in sandbox.room_doors:
		if d.door_id == 128:
			d128_s153 = d
			break
	if not require(d128_s153 != null, "Porta 128 deve existir na Sala 153"): return
	sandbox.player.position = Vector2(d128_s153.position.x, d128_s153.position.y + 40.0)
	sandbox.player.current_direction = PlayerController.Direction.RIGHT
	var dest_32 = d128_s153.check_interaction(sandbox.player, sandbox.inventory, sandbox.runtime_collision)
	if not require(dest_32 == 32, "Porta 128 na Sala 153 deve conduzir de volta à Sala 32"): return
	sandbox.change_to_room(dest_32, d128_s153.entry_position, d128_s153.destination_direction, d128_s153.door_id)
	if not require(sandbox.snapshot.room_id == 32, "Snake deve retornar com sucesso para a Sala 32"): return

	# 10. Teste do Caminhão 128 (Sala 5 <-> Sala 128) — Desobstrução de saída limpa
	sandbox.change_to_room(5, Vector2(128.0, 128.0))
	var d113_truck: RoomDoor = null
	for d in sandbox.room_doors:
		if d.destination_room == 128:
			d113_truck = d
			break
	if not require(d113_truck != null, "Porta do caminhão 128 deve existir na Sala 5"): return
	sandbox.player.position = Vector2(d113_truck.position.x + 16.0, d113_truck.position.y + 24.0)
	sandbox.player.current_direction = PlayerController.Direction.UP
	var t128_dest = d113_truck.check_interaction(sandbox.player, sandbox.inventory, sandbox.runtime_collision)
	if not require(t128_dest == 128, "Snake deve entrar no caminhão 128"): return
	sandbox.change_to_room(t128_dest, d113_truck.entry_position, d113_truck.destination_direction, d113_truck.door_id)
	if not require(sandbox.snapshot.room_id == 128, "Snake deve estar na Sala 128 (interior do caminhão)"): return

	# Verificar desobstrução da parede de saída no caminhão 128
	for ty in range(11, 15):
		for tx in range(25, 32):
			var idx = ty * 32 + tx
			if not require(sandbox.runtime_collision[idx] == 0, "Saída do caminhão 128 (tx=%d, ty=%d) deve estar livre" % [tx, ty]): return

	# Snake sai do caminhão 128 de volta para a Sala 5
	var truck_exit: RoomDoor = sandbox.room_doors[0]
	sandbox.player.position = Vector2(216.0, 104.0)
	sandbox.player.current_direction = PlayerController.Direction.RIGHT
	var exit_target = truck_exit.check_interaction(sandbox.player, sandbox.inventory, sandbox.runtime_collision)
	if not require(exit_target == 5, "Snake deve sair do caminhão para a Sala 5"): return
	sandbox.change_to_room(exit_target, truck_exit.entry_position, truck_exit.destination_direction, truck_exit.door_id)
	if not require(sandbox.snapshot.room_id == 5, "Snake deve retornar com sucesso para a Sala 5"): return

	sandbox.queue_free()
	await process_frame

	print("DOORS_AND_INVENTORY_OK: item collection, cycle, ration healing, locked door collision, card unlock, lorry doors enter/exit, canonical truck items, Door 128 clearance, and floating blocks elimination")
	quit(0)

