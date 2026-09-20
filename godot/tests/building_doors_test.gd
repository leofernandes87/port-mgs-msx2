# building_doors_test.gd
# Validação automatizada do sistema de portas e transições bidirecionais dos interiores de edifícios (Etapa 14).
# Cobre:
# 1. Tabela canônica PlayerInDoorDat da ROM (logic/nextroom.asm:457-480) para todos os render types (1 a 5).
# 2. Regras de cartões de acesso (CARD1 a CARD8) baseadas em open_rule_id.
# 3. Ciclo bidirecional Sala 7 <-> Sala 130 (Arsenal da Pistola) via Porta 118 com spawn exato e coleta de arma.
# 4. Ciclo Sala 8 <-> Sala 138 (Depósito trancado por CARD1) via Porta 1 com desbloqueio e retorno ao corredor.

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
	# --------------------------------------------------------------------------
	# 1. Teste da Tabela Canônica PlayerInDoorDat (logic/nextroom.asm:457-480)
	# --------------------------------------------------------------------------
	var base_xy := Vector2(100.0, 100.0)

	# Render 1 (Norte / Parede Superior): Offset Y=+40, Offset X=+12, Dir=DOWN (2)
	var spawn_r1: Dictionary = RoomDoor.get_door_spawn(base_xy, 1)
	if not require((spawn_r1.pos as Vector2) == Vector2(112.0, 140.0), "Render 1: spawn deve ser (112, 140)"): return
	if not require(int(spawn_r1.dir) == PlayerController.Direction.DOWN, "Render 1: direção deve ser DOWN"): return

	# Render 2 (Sul / Parede Inferior): Offset Y=-8, Offset X=+16, Dir=UP (1)
	var spawn_r2: Dictionary = RoomDoor.get_door_spawn(base_xy, 2)
	if not require((spawn_r2.pos as Vector2) == Vector2(116.0, 92.0), "Render 2: spawn deve ser (116, 92)"): return
	if not require(int(spawn_r2.dir) == PlayerController.Direction.UP, "Render 2: direção deve ser UP"): return

	# Render 3 (Oeste / Parede Esquerda): Offset Y=+48, Offset X=+16, Dir=RIGHT (4)
	var spawn_r3: Dictionary = RoomDoor.get_door_spawn(base_xy, 3)
	if not require((spawn_r3.pos as Vector2) == Vector2(116.0, 148.0), "Render 3: spawn deve ser (116, 148)"): return
	if not require(int(spawn_r3.dir) == PlayerController.Direction.RIGHT, "Render 3: direção deve ser RIGHT"): return

	# Render 4 (Leste / Parede Direita): Offset Y=+48, Offset X=-10, Dir=LEFT (3)
	var spawn_r4: Dictionary = RoomDoor.get_door_spawn(base_xy, 4)
	if not require((spawn_r4.pos as Vector2) == Vector2(90.0, 148.0), "Render 4: spawn deve ser (90, 148)"): return
	if not require(int(spawn_r4.dir) == PlayerController.Direction.LEFT, "Render 4: direção deve ser LEFT"): return

	# Render 5 (Elevador): Offset Y=+40, Offset X=+12, Dir=DOWN (2)
	var spawn_r5: Dictionary = RoomDoor.get_door_spawn(base_xy, 5)
	if not require((spawn_r5.pos as Vector2) == Vector2(112.0, 140.0), "Render 5: spawn deve ser (112, 140)"): return
	if not require(int(spawn_r5.dir) == PlayerController.Direction.DOWN, "Render 5: direção deve ser DOWN"): return

	# --------------------------------------------------------------------------
	# 2. Teste de Regras de Cartões de Acesso (Enums.asm:113-122)
	# --------------------------------------------------------------------------
	if not require(RoomDoor.get_card_for_rule(1) == "", "Regra 1 deve ser sem exigência de cartão (porta livre)"): return
	if not require(RoomDoor.get_card_for_rule(2) == InventoryManager.ITEM_CARD1, "Regra 2 deve exigir CARD1"): return
	if not require(RoomDoor.get_card_for_rule(3) == InventoryManager.ITEM_CARD2, "Regra 3 deve exigir CARD2"): return
	if not require(RoomDoor.get_card_for_rule(4) == InventoryManager.ITEM_CARD3, "Regra 4 deve exigir CARD3"): return
	if not require(RoomDoor.get_card_for_rule(5) == InventoryManager.ITEM_CARD4, "Regra 5 deve exigir CARD4"): return
	if not require(RoomDoor.get_card_for_rule(6) == InventoryManager.ITEM_CARD5, "Regra 6 deve exigir CARD5"): return
	if not require(RoomDoor.get_card_for_rule(7) == InventoryManager.ITEM_CARD6, "Regra 7 deve exigir CARD6"): return
	if not require(RoomDoor.get_card_for_rule(8) == InventoryManager.ITEM_CARD7, "Regra 8 deve exigir CARD7"): return
	if not require(RoomDoor.get_card_for_rule(9) == InventoryManager.ITEM_CARD8, "Regra 9 deve exigir CARD8"): return

	# --------------------------------------------------------------------------
	# 3. Teste de Integração no Sandbox: Ciclo Sala 7 <-> Sala 130 (Arsenal)
	# --------------------------------------------------------------------------
	var sandbox_scene: PackedScene = preload("res://scenes/sandbox_gameplay.tscn")
	var sandbox: Control = sandbox_scene.instantiate() as Control
	root.add_child(sandbox)
	await process_frame
	await process_frame

	# Carregar Sala 7 no Sandbox (Corredor do Prédio 1)
	var loaded_7: bool = sandbox.change_to_room(7, Vector2(48.0, 160.0), PlayerController.Direction.UP)
	if not require(loaded_7, "Sala 7 deve carregar no sandbox"): return
	if not require(sandbox.snapshot.room_id == 7, "Sala atual deve ser 7"): return

	# Verificar que a porta 118 existe na Sala 7 e aponta para a Sala 130
	var door_118_r7: RoomDoor = null
	for d: RoomDoor in sandbox.room_doors:
		if d.door_id == 118:
			door_118_r7 = d
			break
	if not require(door_118_r7 != null, "Sala 7 deve conter a porta 118"): return
	if not require(door_118_r7.destination_room == 130, "Porta 118 na Sala 7 deve levar à Sala 130"): return
	if not require(door_118_r7.render_type_id == 1, "Porta 118 na Sala 7 deve ter render_type_id 1 (Norte)"): return
	if not require(door_118_r7.position == Vector2(36.0, 132.0), "Porta 118 na Sala 7 deve estar em (36, 132)"): return

	# Snake entra na porta 118 rumo à Sala 130
	var moved_to_130: bool = sandbox.change_to_room(130, Vector2.ZERO, -1, 118)
	if not require(moved_to_130, "Transição para Sala 130 deve ocorrer com sucesso"): return
	if not require(sandbox.snapshot.room_id == 130, "Sala atual deve ser 130"): return

	# Verificar spawn exato de Snake em frente à porta 118 na Sala 130 (render_type 4: draw_x=208, draw_y=64)
	# PlayerX = 208 + (-10) = 198.0, PlayerY = 64 + 48 = 112.0, Dir = LEFT (3)
	if not require(sandbox.player.position == Vector2(198.0, 112.0), "Snake deve surgir em (198, 112) na Sala 130"): return
	if not require(sandbox.player.current_direction == PlayerController.Direction.LEFT, "Snake deve estar virado para LEFT ao sair da porta leste"): return

	# Verificar presença da porta 118 na Sala 130 com destino de volta para a Sala 7
	var door_118_r130: RoomDoor = null
	for d: RoomDoor in sandbox.room_doors:
		if d.door_id == 118:
			door_118_r130 = d
			break
	if not require(door_118_r130 != null, "Sala 130 deve conter a porta 118 de retorno"): return
	if not require(door_118_r130.destination_room == 7, "Porta 118 na Sala 130 deve levar de volta à Sala 7"): return
	if not require(door_118_r130.render_type_id == 4, "Porta 118 na Sala 130 deve ter render_type_id 4 (Leste)"): return

	# Verificar presença e coleta da Pistola (HANDGUN) na Sala 130 em (64, 96)
	var gun_box: ItemBox = null
	for b: ItemBox in sandbox.item_boxes:
		if b.item_id == WeaponSystem.WEAPON_HANDGUN:
			gun_box = b
			break
	if not require(gun_box != null, "Sala 130 deve conter a caixa da Pistola (HANDGUN)"): return
	if not require(gun_box.position == Vector2(64.0, 96.0), "Pistola deve estar na posição autêntica (64, 96)"): return

	# Snake coleta a Pistola
	gun_box.step_tick(gun_box.position, sandbox.inventory, sandbox.weapon_system)
	if not require(gun_box.collected, "Pistola deve ser coletada ao contato"): return
	if not require(sandbox.weapon_system.has_weapon(WeaponSystem.WEAPON_HANDGUN), "WeaponSystem deve conter HANDGUN após coleta"): return

	# Snake retorna pela porta 118 da Sala 130 para a Sala 7
	var moved_back_7: bool = sandbox.change_to_room(7, Vector2.ZERO, -1, 118)
	if not require(moved_back_7, "Retorno para Sala 7 deve ocorrer com sucesso"): return
	if not require(sandbox.snapshot.room_id == 7, "Sala atual deve ser 7 novamente"): return

	# Verificar spawn exato de Snake ao emergir na Sala 7
	# Porta 118 na Sala 7: render_type 1, draw_x=36, draw_y=132 -> spawn em (36+12=48, 132+40=172), Dir=DOWN
	if not require(sandbox.player.position == Vector2(48.0, 172.0), "Snake deve reaparecer em (48, 172) na Sala 7"): return
	if not require(sandbox.player.current_direction == PlayerController.Direction.DOWN, "Snake deve estar virado para DOWN ao sair da porta norte"): return
	if not require(sandbox.weapon_system.has_weapon(WeaponSystem.WEAPON_HANDGUN), "Snake deve manter a Pistola após retornar ao corredor"): return

	# --------------------------------------------------------------------------
	# 4. Teste de Tranca por Cartão e Transição Sala 8 <-> Sala 138 (CARD1)
	# --------------------------------------------------------------------------
	# Carregar Sala 8 (Corredor com porta 1 trancada por CARD1)
	var loaded_8: bool = sandbox.change_to_room(8, Vector2(80.0, 120.0), PlayerController.Direction.UP)
	if not require(loaded_8, "Sala 8 deve carregar no sandbox"): return

	var door_1_r8: RoomDoor = null
	for d: RoomDoor in sandbox.room_doors:
		if d.door_id == 1:
			door_1_r8 = d
			break
	if not require(door_1_r8 != null, "Sala 8 deve conter a Porta 1"): return
	if not require(door_1_r8.destination_room == 138, "Porta 1 na Sala 8 deve levar à Sala 138"): return
	if not require(door_1_r8.required_card == InventoryManager.ITEM_CARD1, "Porta 1 na Sala 8 deve exigir CARD1"): return

	# Snake tenta interagir sem CARD1
	sandbox.inventory.clear_selection()
	sandbox.player.set_grid_position(door_1_r8.position.x + 8.0, door_1_r8.position.y + 20.0)
	sandbox.player.current_direction = PlayerController.Direction.UP
	var denied: int = door_1_r8.check_interaction(sandbox.player, sandbox.inventory, sandbox.snapshot.collision)
	if not require(denied == -1 and not door_1_r8.is_open, "Porta 1 NÃO deve abrir sem CARD1 selecionado"): return

	# Snake adquire e seleciona CARD1
	sandbox.inventory.collect_item(InventoryManager.ITEM_CARD1)
	sandbox.inventory.select_item(InventoryManager.ITEM_CARD1)
	var opened: int = door_1_r8.check_interaction(sandbox.player, sandbox.inventory, sandbox.snapshot.collision)
	if not require(door_1_r8.is_open, "Porta 1 deve abrir com CARD1 selecionado"): return

	# Snake entra na Porta 1 para Sala 138
	var moved_to_138: bool = sandbox.change_to_room(138, Vector2.ZERO, -1, 1)
	if not require(moved_to_138, "Transição para Sala 138 deve ocorrer"): return
	if not require(sandbox.snapshot.room_id == 138, "Sala atual deve ser 138"): return

	# Spawn exato na Sala 138 (Porta 1: render_type 2, draw_x=96, draw_y=184 -> spawn em (96+16=112, 184-8=176), Dir=UP)
	if not require(sandbox.player.position == Vector2(112.0, 176.0), "Snake deve surgir em (112, 176) na Sala 138"): return
	if not require(sandbox.player.current_direction == PlayerController.Direction.UP, "Snake deve estar virado para UP ao sair da porta sul"): return

	# Retorno para Sala 8 via Porta 1
	var moved_back_8: bool = sandbox.change_to_room(8, Vector2.ZERO, -1, 1)
	if not require(moved_back_8, "Retorno para Sala 8 deve ocorrer"): return
	# Porta 1 na Sala 8: render_type 1, draw_x=68, draw_y=64 -> spawn em (68+12=80, 64+40=104), Dir=DOWN
	if not require(sandbox.player.position == Vector2(80.0, 104.0), "Snake deve surgir em (80, 104) na Sala 8"): return
	if not require(sandbox.player.current_direction == PlayerController.Direction.DOWN, "Snake deve estar virado para DOWN ao retornar à Sala 8"): return

	print("BUILDING_DOORS_OK: pareamento por IdDoorEnter, tabela PlayerInDoorDat (5 renders), regras de cartão e trânsito bidirecional 7<->130 e 8<->138 validados")
	quit(0)
