extends SceneTree

# basement_and_plastic_bomb_test.gd
# Teste de validação e auditoria profunda do Basement (Building 1) e Bomba Plástica (C4)
# Salas 54 a 63 e salas de itens (168 a 172, 160) comparadas com a ROM MSX2 RC750.

func _init() -> void:
	call_deferred("_run_review")

func require(condition: bool, message: String) -> bool:
	if not condition:
		print("FAIL: %s" % message)
		quit(1)
		return false
	print("  PASS: %s" % message)
	return true

func _run_review() -> void:
	print("\n--- Canonical Basement & Plastic Bomb (C4) Review & Validation Tests ---")
	var tree_root: Window = get_root()
	var packed_sandbox: PackedScene = load("res://scenes/sandbox_gameplay.tscn") as PackedScene
	if not require(packed_sandbox != null, "Carregamento de sandbox_gameplay.tscn"): return

	var sandbox: Control = packed_sandbox.instantiate() as Control
	tree_root.add_child(sandbox)
	await process_frame
	await process_frame

	var player: PlayerController = sandbox.get("player") as PlayerController
	var weapon_sys: WeaponSystem = sandbox.get("weapon_system") as WeaponSystem
	var inv: InventoryManager = sandbox.get("inventory") as InventoryManager

	# -------------------------------------------------------------------------
	# 1. Testes Unitários de Bomba Plástica e Arsenal
	# -------------------------------------------------------------------------
	print("\n[1] Mecânica de Bomba Plástica e Capacidades de Arsenal")
	if not require(weapon_sys.add_weapon(WeaponSystem.WEAPON_PLASTIC_BOMB, 5), "Adicionar WEAPON_PLASTIC_BOMB ao arsenal"): return
	if not require(weapon_sys.ammo[WeaponSystem.WEAPON_PLASTIC_BOMB] == 5, "Munição inicial de bomba plástica deve ser 5"): return
	weapon_sys.update_rank_capacities(1)
	if not require(weapon_sys.max_ammo[WeaponSystem.WEAPON_PLASTIC_BOMB] == 5, "Capacidade de bombas no Rank 1 deve ser 5"): return
	weapon_sys.update_rank_capacities(2)
	if not require(weapon_sys.max_ammo[WeaponSystem.WEAPON_PLASTIC_BOMB] == 10, "Capacidade de bombas no Rank 2 deve ser 10"): return
	weapon_sys.update_rank_capacities(4)
	if not require(weapon_sys.max_ammo[WeaponSystem.WEAPON_PLASTIC_BOMB] == 20, "Capacidade de bombas no Rank 4 deve ser 20"): return

	# Offsets direcionais canônicos (plasticbomb.asm:80-84)
	if not require(PlasticBomb.get_spawn_offset(PlayerController.Direction.UP) == Vector2(0.0, -16.0), "Offset UP deve ser (0, -16)"): return
	if not require(PlasticBomb.get_spawn_offset(PlayerController.Direction.DOWN) == Vector2(0.0, 8.0), "Offset DOWN deve ser (0, 8)"): return
	if not require(PlasticBomb.get_spawn_offset(PlayerController.Direction.LEFT) == Vector2(-12.0, 0.0), "Offset LEFT deve ser (-12, 0)"): return
	if not require(PlasticBomb.get_spawn_offset(PlayerController.Direction.RIGHT) == Vector2(12.0, 0.0), "Offset RIGHT deve ser (12, 0)"): return

	# Entidade física e contagem regressiva
	var bomb: PlasticBomb = PlasticBomb.new()
	bomb.setup(Vector2(100.0, 100.0), PlayerController.Direction.UP)
	if not require(bomb.position == Vector2(100.0, 84.0), "Posição da bomba deve aplicar offset UP"): return
	if not require(bomb.timer == PlasticBomb.TIMER_ARMED_TICKS, "Timer da bomba deve ser %d ticks calibrado a 60 fps" % PlasticBomb.TIMER_ARMED_TICKS): return
	var result_tracker := {"exploded": false}
	bomb.bomb_exploded.connect(func(pos: Vector2, rad: float, dmg: int):
		result_tracker["exploded"] = true
		require(pos == Vector2(100.0, 84.0), "Posição de detonação correta")
		require(is_equal_approx(rad, 24.0), "Raio de detonação deve ser 24.0 px")
		require(dmg == 10, "Dano de detonação deve ser 10 HP")
	)
	for _i in range(PlasticBomb.TIMER_ARMED_TICKS):
		bomb.step_tick()
	if not require(bool(result_tracker["exploded"]), "Bomba deve detonar após contagem de ticks"): return
	bomb.queue_free()

	# -------------------------------------------------------------------------
	# 2. Auditoria das Salas do Basement (Salas 54 a 63)
	# -------------------------------------------------------------------------
	print("\n[2] Auditoria das Salas do Basement (Prisão, Cães, Shoot Gunner e Paredes Ocas)")

	# Sala 54: Isolamento / Saída da Cela
	sandbox.call("change_to_room", 54, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var doors_54: Array = sandbox.get("room_doors") as Array
	if not require(doors_54.size() == 2, "Sala 54 deve conter 2 portas (12 para Cela 212 e 13 para Sala 55)"): return

	# Sala 55: Canil 1 (2 cães de guarda)
	sandbox.call("change_to_room", 55, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_55: Array = sandbox.get("enemies") as Array
	if not require(em_55.size() == 2, "Sala 55 deve conter exatamente 2 cães"): return
	for d in em_55:
		var eg := d as EnemyGuard
		if not require(eg.is_dog, "Inimigo na Sala 55 deve ser cão"): return
		if not require(is_equal_approx(eg.speed, 1.3), "Velocidade do cão na Sala 55 deve ser 1.3 px/tick"): return

	# Sala 56: Canil 2 (4 cães de guarda)
	sandbox.call("change_to_room", 56, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_56: Array = sandbox.get("enemies") as Array
	if not require(em_56.size() == 4, "Sala 56 deve conter exatamente 4 cães"): return
	for d in em_56:
		var eg := d as EnemyGuard
		if not require(eg.is_dog, "Inimigo na Sala 56 deve ser cão"): return
		if not require(is_equal_approx(eg.speed, 1.3), "Velocidade do cão na Sala 56 deve ser 1.3 px/tick"): return

	# Sala 57: Arena do Chefe Shoot Gunner
	sandbox.call("change_to_room", 57, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var sg = sandbox.get("shot_gunner")
	if not require(sg != null, "Sala 57 deve conter o chefe Shoot Gunner"): return
	if not require(is_instance_valid(sg) and not sg.is_dead, "Shoot Gunner deve estar vivo inicialmente"): return
	var doors_57: Array = sandbox.get("room_doors") as Array
	if not require(doors_57.size() == 3, "Sala 57 deve conter 3 portas (15 para Sala 58, 154 para Sala 168 e 74 para Sala 122)"): return

	# Sala 58: Cão de Masmorra, Porta 17 (Card 4) e Parede Oca 140 (Soco RIGHT)
	sandbox.call("change_to_room", 58, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_58: Array = sandbox.get("enemies") as Array
	if not require(em_58.size() == 1, "Sala 58 deve conter 1 cão de masmorra"): return
	var doors_58: Array = sandbox.get("room_doors") as Array
	if not require(doors_58.size() == 3, "Sala 58 deve conter 3 portas/paredes (15, 17, 140)"): return
	var wall_140: RoomDoor = null
	for d in doors_58:
		var rd := d as RoomDoor
		if rd.door_id == 140:
			wall_140 = rd
			break
	if not require(wall_140 != null, "Parede 140 deve existir na Sala 58"): return
	if not require(wall_140.is_breakable_wall, "Parede 140 deve ser marcada como parede quebrável"): return
	if not require(not wall_140.is_open, "Parede 140 deve iniciar fechada"): return
	if not require(wall_140.punch_required_direction == PlayerController.Direction.RIGHT, "Parede 140 exige soco RIGHT"): return

	# Sala 59: Parede Oca 16 (Soco LEFT, Destino Sala 169)
	sandbox.call("change_to_room", 59, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var doors_59: Array = sandbox.get("room_doors") as Array
	if not require(doors_59.size() == 1, "Sala 59 deve conter 1 parede quebrável (Porta 16)"): return
	var wall_16: RoomDoor = doors_59[0] as RoomDoor
	if not require(wall_16.door_id == 16, "Porta 16 deve estar presente"): return
	if not require(wall_16.is_breakable_wall, "Porta 16 deve ser parede quebrável"): return
	if not require(not wall_16.is_open, "Porta 16 deve iniciar fechada"): return
	if not require(wall_16.destination_room == 169, "Porta 16 conecta à Sala 169 (Farda Inimiga)"): return
	if not require(wall_16.punch_required_direction == PlayerController.Direction.LEFT, "Porta 16 exige soco LEFT"): return

	# Sala 60: Cão de Masmorra e Parede Oca 142 (Soco DOWN)
	sandbox.call("change_to_room", 60, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_60: Array = sandbox.get("enemies") as Array
	if not require(em_60.size() == 1, "Sala 60 deve conter 1 cão de masmorra"): return
	var doors_60: Array = sandbox.get("room_doors") as Array
	if not require(doors_60.size() == 1, "Sala 60 deve conter Parede 142"): return
	var wall_142: RoomDoor = doors_60[0] as RoomDoor
	if not require(wall_142.is_breakable_wall and not wall_142.is_open, "Parede 142 deve ser quebrável e estar fechada"): return
	if not require(wall_142.punch_required_direction == PlayerController.Direction.DOWN, "Parede 142 exige soco DOWN"): return

	# Sala 61: Cão de Masmorra e Parede Oca 18 (Soco DOWN, Destino Sala 172)
	sandbox.call("change_to_room", 61, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_61: Array = sandbox.get("enemies") as Array
	if not require(em_61.size() == 1, "Sala 61 deve conter 1 cão de masmorra"): return
	var doors_61: Array = sandbox.get("room_doors") as Array
	if not require(doors_61.size() == 1, "Sala 61 deve conter Parede 18"): return
	var wall_18: RoomDoor = doors_61[0] as RoomDoor
	if not require(wall_18.destination_room == 172, "Parede 18 conecta à Sala 172 (Munição + Bomba Plástica)"): return
	if not require(wall_18.punch_required_direction == PlayerController.Direction.DOWN, "Parede 18 exige soco DOWN"): return

	# Sala 62: Porta 19 (Card 4, Destino Sala 170 - Bomb Blast Suit)
	sandbox.call("change_to_room", 62, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var doors_62: Array = sandbox.get("room_doors") as Array
	if not require(doors_62.size() == 1, "Sala 62 deve conter Porta 19"): return
	var door_19: RoomDoor = doors_62[0] as RoomDoor
	if not require(door_19.destination_room == 170, "Porta 19 conecta à Sala 170"): return

	# Sala 63: Cão de Masmorra, Parede Oca 141 (Soco LEFT) e Elevador 2 (Porta 20)
	sandbox.call("change_to_room", 63, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_63: Array = sandbox.get("enemies") as Array
	if not require(em_63.size() == 1, "Sala 63 deve conter 1 cão de masmorra"): return
	var doors_63: Array = sandbox.get("room_doors") as Array
	if not require(doors_63.size() == 2, "Sala 63 deve conter 2 portas (Parede 141 e Elevador 2)"): return
	var wall_141: RoomDoor = null
	for d in doors_63:
		var rd := d as RoomDoor
		if rd.door_id == 141:
			wall_141 = rd
			break
	if not require(wall_141 != null and wall_141.is_breakable_wall and not wall_141.is_open, "Parede 141 quebrável e fechada"): return
	if not require(wall_141.punch_required_direction == PlayerController.Direction.LEFT, "Parede 141 exige soco LEFT"): return

	# -------------------------------------------------------------------------
	# 3. Teste de Detonação de Paredes e Acesso a Salas Secretas
	# -------------------------------------------------------------------------
	print("\n[3] Detonação de Parede Oca com C4 e Transição para Sala 169 (Farda Inimiga)")

	sandbox.call("change_to_room", 59, Vector2(30.0, 80.0), PlayerController.Direction.LEFT)
	await process_frame

	doors_59 = sandbox.get("room_doors") as Array
	wall_16 = doors_59[0] as RoomDoor

	# Teste de som oco ao socar
	if not require(wall_16.check_punch(Vector2(26.0, 80.0), PlayerController.Direction.LEFT), "Soco à esquerda detecta parede oca 16"): return
	if not require(not wall_16.check_punch(Vector2(26.0, 80.0), PlayerController.Direction.RIGHT), "Soco na direção errada não detecta parede oca"): return
	if not require(not wall_16.is_open, "Soco não deve destruir a parede de masmorra"): return

	# Detonação da Bomba Plástica contra a parede
	var collision_grid: Array = sandbox.get("runtime_collision") as Array
	var destroyed: bool = wall_16.check_bomb_explosion(Vector2(16.0, 80.0), 24.0, collision_grid)
	if not require(destroyed, "Explosão de C4 deve destruir a parede 16"): return
	if not require(wall_16.is_open, "Parede 16 deve agora estar aberta"): return

	# Transição através da parede destruída para a Sala 169
	player.set_grid_position(10.0, 80.0)
	var next_room_target: int = wall_16.check_interaction(player, inv, collision_grid)
	if not require(next_room_target == 169, "Snake atravessando parede 16 deve entrar na Sala 169"): return

	sandbox.call("change_to_room", 169, Vector2(198.0, 112.0), PlayerController.Direction.LEFT, 16)
	await process_frame
	var items_169: Array = sandbox.get("item_boxes") as Array
	if not require(items_169.size() == 1, "Sala 169 deve conter 1 caixa de item"): return
	var uniform_box: ItemBox = items_169[0] as ItemBox
	if not require(uniform_box.item_id == InventoryManager.ITEM_UNIFORM, "Item na Sala 169 deve ser a Farda Inimiga (UNIFORM)"): return

	# Coleta da Farda
	player.set_grid_position(uniform_box.position.x, uniform_box.position.y)
	uniform_box.step_tick(player.position, inv, weapon_sys, null)
	if not require(inv.has_item(InventoryManager.ITEM_UNIFORM), "Snake deve possuir ITEM_UNIFORM no inventário"): return

	# Retorno para a Sala 59
	var doors_169: Array = sandbox.get("room_doors") as Array
	if not require(doors_169.size() == 1, "Sala 169 deve ter porta de retorno"): return
	var door_back_59: RoomDoor = doors_169[0] as RoomDoor
	if not require(door_back_59.is_open, "Porta de retorno deve estar aberta pois a parede foi destruída"): return
	player.set_grid_position(210.0, 80.0)
	var ret_room: int = door_back_59.check_interaction(player, inv, collision_grid)
	if not require(ret_room == 59, "Retorno da Sala 169 deve levar de volta à Sala 59"): return

	sandbox.call("change_to_room", 59, Vector2(24.0, 80.0), PlayerController.Direction.RIGHT, 16)
	await process_frame
	doors_59 = sandbox.get("room_doors") as Array
	wall_16 = doors_59[0] as RoomDoor
	if not require(wall_16.is_open, "Parede 16 na Sala 59 deve permanecer aberta (persistência de destruição)"): return

	# -------------------------------------------------------------------------
	# 4. Detonação na Sala 61 e Acesso à Sala 172 (Bomba Plástica e Munição)
	# -------------------------------------------------------------------------
	print("\n[4] Detonação de Parede Oca na Sala 61 e Acesso à Sala 172")
	sandbox.call("change_to_room", 61, Vector2(112.0, 160.0), PlayerController.Direction.DOWN)
	await process_frame
	doors_61 = sandbox.get("room_doors") as Array
	wall_18 = doors_61[0] as RoomDoor
	collision_grid = sandbox.get("runtime_collision") as Array
	destroyed = wall_18.check_bomb_explosion(Vector2(112.0, 180.0), 24.0, collision_grid)
	if not require(destroyed and wall_18.is_open, "Parede 18 detonada com sucesso"): return

	sandbox.call("change_to_room", 172, Vector2(116.0, 40.0), PlayerController.Direction.DOWN, 18)
	await process_frame
	var items_172: Array = sandbox.get("item_boxes") as Array
	if not require(items_172.size() == 2, "Sala 172 deve conter 2 itens (Munição + Bomba Plástica)"): return
	var has_ammo: bool = false
	var has_pbomb: bool = false
	for it in items_172:
		var ib := it as ItemBox
		if ib.item_id == InventoryManager.ITEM_AMMO_CRATE:
			has_ammo = true
		elif ib.item_id in [WeaponSystem.WEAPON_PLASTIC_BOMB, InventoryManager.ITEM_PLASTIC_BOMB, "PLASTIC_BOMB"]:
			has_pbomb = true
	if not require(has_ammo and has_pbomb, "Sala 172 deve conter Caixa de Munição e Bomba Plástica"): return

	# -------------------------------------------------------------------------
	# 5. Validação dos Itens do Basement e Detector de Minas
	# -------------------------------------------------------------------------
	print("\n[5] Validação das Demais Salas de Itens do Basement")

	# Sala 168: Saco com equipamentos de Snake após derrotar Shoot Gunner
	sandbox.call("change_to_room", 168, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var items_168: Array = sandbox.get("item_boxes") as Array
	if not require(items_168.size() == 1 and (items_168[0] as ItemBox).item_id == InventoryManager.ITEM_BAG, "Sala 168 deve conter ITEM_BAG"): return

	# Sala 170: Colete à prova de explosão (BOMB_BLAST_SUIT)
	sandbox.call("change_to_room", 170, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var items_170: Array = sandbox.get("item_boxes") as Array
	if not require(items_170.size() == 1 and (items_170[0] as ItemBox).item_id == InventoryManager.ITEM_BOMB_BLAST_SUIT, "Sala 170 deve conter ITEM_BOMB_BLAST_SUIT"): return

	# Sala 171: Colete balístico (BODY_ARMOR)
	sandbox.call("change_to_room", 171, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var items_171: Array = sandbox.get("item_boxes") as Array
	if not require(items_171.size() == 1 and (items_171[0] as ItemBox).item_id == InventoryManager.ITEM_BODY_ARMOR, "Sala 171 deve conter ITEM_BODY_ARMOR"): return

	# Sala 160: Detector de minas (MINE_DETECTOR)
	sandbox.call("change_to_room", 160, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var items_160: Array = sandbox.get("item_boxes") as Array
	if not require(items_160.size() == 1 and (items_160[0] as ItemBox).item_id == InventoryManager.ITEM_MINE_DETECTOR, "Sala 160 deve conter ITEM_MINE_DETECTOR"): return

	print("\nBASEMENT_AND_PLASTIC_BOMB_TEST_OK: Todas as 10 salas do Basement, mecânica de C4, paredes quebráveis e itens validados com sucesso!")
	quit(0)
