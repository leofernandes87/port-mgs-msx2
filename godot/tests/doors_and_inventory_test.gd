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

	print("DOORS_AND_INVENTORY_OK: item collection, cycle, ration healing, locked door collision, card unlock and door entry")
	quit(0)
