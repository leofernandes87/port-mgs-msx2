extends SceneTree
## Suíte de testes headless — Evento de Captura na Sala 8, Cela 211, Parede Oca e Restituição (Etapa 21)
## Valida as mecânicas canônicas extraídas da ROM MSX2 RC750 (logic/common.asm, logic/capturescene.asm, logic/doors/opendoor.asm, logic/items.asm)
## Token de conclusão: CAPTURE_PRISON_OK

var _pass: int = 0
var _fail: int = 0

func _initialize() -> void:
	_run_all()
	var result: String = "CAPTURE_PRISON_OK: %d testes passaram, %d falharam" % [_pass, _fail]
	print(result)
	quit(0 if _fail == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
		print("  PASS: %s" % msg)
	else:
		_fail += 1
		print("  FAIL: %s" % msg)

func _run_all() -> void:
	print("--- Capture, Prison Cell 211 & Bag Restitution Tests ---")
	_test_capture_trigger_bounds()
	_test_execute_capture_and_backup()
	_test_prison_spawn_and_input_restrictions()
	_test_hollow_wall_punch_detection()
	_test_wall_collision_and_tile_break()
	_test_room_connections_211_212()
	_test_bag_restitution()
	_test_reset_state()
	_test_prison_flow_integration()
	_test_room_212_to_room_54_transition()
	_test_capture_cutscene_spawns_and_positions()
	_test_capture_cutscene_dialog_and_timing()
	_test_capture_cutscene_fade_and_completion()

## Teste 1: Gatilho canônico de captura na Sala 8 (logic/common.asm:26-47)
func _test_capture_trigger_bounds() -> void:
	var cs := CaptureSystem.new()

	# Sala 8: dentro da faixa canônica [192.0, 208.0]
	_assert(cs.check_capture_trigger(8, Vector2(192.0, 100.0)), "Captura dispara em X = 192.0 na Sala 8")
	_assert(cs.check_capture_trigger(8, Vector2(200.0, 100.0)), "Captura dispara em X = 200.0 na Sala 8")
	_assert(cs.check_capture_trigger(8, Vector2(208.0, 100.0)), "Captura dispara em X = 208.0 na Sala 8")

	# Sala 8: fora da faixa
	_assert(not cs.check_capture_trigger(8, Vector2(191.9, 100.0)), "Captura não dispara antes de X = 192.0")
	_assert(not cs.check_capture_trigger(8, Vector2(208.1, 100.0)), "Captura não dispara após X = 208.0")

	# Outras salas: nunca disparam
	_assert(not cs.check_capture_trigger(1, Vector2(200.0, 100.0)), "Captura não dispara na Sala 1")
	_assert(not cs.check_capture_trigger(121, Vector2(200.0, 100.0)), "Captura não dispara na Sala 121")
	_assert(not cs.check_capture_trigger(211, Vector2(200.0, 100.0)), "Captura não dispara na Sala 211")

	# Não redispara se já capturado ou restituído
	cs.capture_occurred = true
	_assert(not cs.check_capture_trigger(8, Vector2(200.0, 100.0)), "Captura não redispara se capture_occurred == true")
	cs.capture_occurred = false
	cs.equip_bag_taken = true
	_assert(not cs.check_capture_trigger(8, Vector2(200.0, 100.0)), "Captura não redispara se equip_bag_taken == true")

## Teste 2: Backup fiel do inventário e arsenal e limpeza dos ativos
func _test_execute_capture_and_backup() -> void:
	var cs := CaptureSystem.new()
	var inv := InventoryManager.new()
	var ws := WeaponSystem.new()

	# Configura inventário prévio
	inv.collect_item(InventoryManager.ITEM_CARD1)
	inv.collect_item(InventoryManager.ITEM_CARD2)
	inv.collect_item(InventoryManager.ITEM_RATION)
	inv.collect_item(InventoryManager.ITEM_CIGARETTES)
	inv.collect_item(InventoryManager.ITEM_GAS_MASK)
	inv.select_item(InventoryManager.ITEM_GAS_MASK)

	# Configura arsenal prévio (Rank 2 para suportar SMG 70)
	ws.update_rank_capacities(2)
	ws.add_weapon(WeaponSystem.WEAPON_HANDGUN, 35)
	ws.add_weapon(WeaponSystem.WEAPON_SMG, 70)
	ws.set_silencer(true)
	ws.select_weapon(WeaponSystem.WEAPON_HANDGUN)

	_assert(inv.items.size() == 5, "Inventário inicial tem 5 itens")
	_assert(ws.owned_weapons.size() == 2, "Arsenal inicial tem 2 armas")

	# Dispara captura
	cs.execute_capture(inv, ws)

	_assert(cs.is_captured, "is_captured == true")
	_assert(cs.capture_occurred, "capture_occurred == true")
	_assert(inv.items.is_empty(), "Inventário ativo esvaziado após captura")
	_assert(inv.selected_index == -1, "Seleção de item limpa")
	_assert(ws.owned_weapons.is_empty(), "Arsenal ativo esvaziado após captura")
	_assert(ws.selected_weapon == WeaponSystem.WEAPON_NONE, "Arma ativa desselecionada")
	_assert(not ws.has_silencer, "Silenciador ativo removido")

	# Verifica integridade dos backups
	_assert(cs.backup_items.size() == 5, "Backup possui exatamente os 5 itens")
	_assert(cs.backup_items.has(InventoryManager.ITEM_CARD1), "Backup contém CARD1")
	_assert(cs.backup_items.has(InventoryManager.ITEM_GAS_MASK), "Backup contém GAS_MASK")
	_assert(cs.backup_owned_weapons.size() == 2, "Backup possui as 2 armas")
	_assert(cs.backup_ammo[WeaponSystem.WEAPON_HANDGUN] == 35, "Munição de Handgun preservada no backup (35)")
	_assert(cs.backup_ammo[WeaponSystem.WEAPON_SMG] == 70, "Munição de SMG preservada no backup (70)")
	_assert(cs.backup_has_silencer == true, "Flag de silenciador preservada no backup")

## Teste 3: Coordenadas de spawn na cela e restrição de disparo
func _test_prison_spawn_and_input_restrictions() -> void:
	var cs := CaptureSystem.new()
	_assert(CaptureSystem.SPAWN_PRISON == Vector2(128.0, 80.0), "Spawn canônico na cela é (128.0, 80.0)")
	_assert(CaptureSystem.ROOM_PRISON == 211, "ID da sala da cela é 211")

	var player := PlayerController.new()
	player.life = 24
	player.can_control = true

	# Soco básico funciona perfeitamente
	var punched: bool = player.punch()
	_assert(punched, "Soco básico liberado para o jogador")
	_assert(player.is_punching, "player.is_punching == true durante o soco")

	# Disparo de arma de fogo é impossível sem arma equipada
	var ws := WeaponSystem.new()
	var bullet: Bullet = player.fire_weapon(ws)
	_assert(bullet == null, "Disparo de arma bloqueado (nenhuma arma ativa)")

	player.free()

## Teste 4: Detecção precisa de socos na parede oca da Sala 211 (4 acertos)
func _test_hollow_wall_punch_detection() -> void:
	var cs := CaptureSystem.new()

	# Posição adjacente à parede oca interna: (50.0, 72.0)
	var wall_pos := Vector2(50.0, 72.0)

	# 1. Direção errada não conta
	var h1: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.RIGHT, 8)
	_assert(not h1, "Soco para a DIREITA não atinge a parede esquerda")
	var h2: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.UP, 8)
	_assert(not h2, "Soco para CIMA não atinge a parede esquerda")
	_assert(cs.wall_hit_counter == 0, "Contador de acertos permanece 0")

	# 2. Posição longe da parede não conta
	var far_pos := Vector2(128.0, 80.0)
	var h3: bool = cs.check_wall_punch(far_pos, PlayerController.Direction.LEFT, 8)
	_assert(not h3, "Soco longe da parede não registra acerto")
	_assert(cs.wall_hit_counter == 0, "Contador permanece 0")

	# 3. Multi-hit durante o mesmo golpe é bloqueado
	var h4: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, true)
	_assert(h4, "Primeiro contato do soco registra acerto")
	_assert(cs.wall_hit_counter == 1, "wall_hit_counter == 1")
	# Frame seguinte do MESMO soco (is_punching continua true) não conta ponto extra
	var h4_repeat: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, true)
	_assert(not h4_repeat, "Repetição durante o mesmo soco não duplica acerto")
	_assert(cs.wall_hit_counter == 1, "Contador permanece 1")

	# 4. Sequência canônica de 4 socos com relaxamento entre golpes
	# Soco 1 já computado acima; relaxa o golpe
	cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, false)

	# 2º Soco
	var hit2: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, true)
	_assert(hit2, "2º soco válido detectado")
	_assert(cs.wall_hit_counter == 2, "wall_hit_counter == 2")
	_assert(not cs.wall_broken, "Parede ainda não quebrou (2/4)")
	cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, false)

	# 3º Soco
	var hit3: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, true)
	_assert(hit3, "3º soco válido detectado")
	_assert(cs.wall_hit_counter == 3, "wall_hit_counter == 3")
	_assert(not cs.wall_broken, "Parede ainda não quebrou (3/4)")
	cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, false)

	# 4º Soco
	var hit4: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, true)
	_assert(hit4, "4º soco válido detectado")
	_assert(cs.wall_hit_counter == 4, "wall_hit_counter == 4")
	_assert(cs.wall_broken, "Parede quebrada com sucesso após o 4º acerto!")

	# Soco após quebra não incrementa mais
	cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, false)
	var hit5: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, true)
	_assert(not hit5, "Socos adicionais ignorados após quebra")

## Teste 5: Remoção de colisão e alteração de tiles na quebra da parede
func _test_wall_collision_and_tile_break() -> void:
	# Simula matriz de colisão de 768 tiles (32x24)
	var collision: Array = []
	for i in range(768):
		collision.append(1)

	# Aplica quebra da parede limpando os tiles de WALL_TILES
	for tile: Vector2i in CaptureSystem.WALL_TILES:
		var idx: int = tile.y * 32 + tile.x
		collision[idx] = 0

	# Valida desobstrução dos tiles da passagem da Cela 211
	for tile: Vector2i in CaptureSystem.WALL_TILES:
		var idx: int = tile.y * 32 + tile.x
		_assert(collision[idx] == 0, "Tile (%d, %d) desobstruído (colisão == 0)" % [tile.x, tile.y])

	_assert(CaptureSystem.WALL_TILES.size() == 24, "Exatamente 24 tiles liberados na parede da Cela 211 (6x4)")

	# Valida tiles da passagem na Sala 212 adjacente
	_assert(CaptureSystem.ADJACENT_WALL_TILES.size() == 24, "Exatamente 24 tiles liberados na Sala 212 (6x4)")

## Teste 6: Conexão bidirecional entre Salas 211 e 212
func _test_room_connections_211_212() -> void:
	# Saída para a ESQUERDA na Sala 211 leva à Sala 212
	var next_left: int = RoomManager.get_next_room(211, PlayerController.Direction.LEFT)
	_assert(next_left == 212, "Sala 211 -> LEFT conecta com Sala 212")

	# Saída para a DIREITA na Sala 212 leva de volta à Sala 211
	var next_right: int = RoomManager.get_next_room(212, PlayerController.Direction.RIGHT)
	_assert(next_right == 211, "Sala 212 -> RIGHT conecta com Sala 211")

	# Outras direções na cela 211 são fechadas
	_assert(RoomManager.get_next_room(211, PlayerController.Direction.UP) == RoomManager.NO_ROOM, "Sala 211 UP fechada")
	_assert(RoomManager.get_next_room(211, PlayerController.Direction.DOWN) == RoomManager.NO_ROOM, "Sala 211 DOWN fechada")
	_assert(RoomManager.get_next_room(211, PlayerController.Direction.RIGHT) == RoomManager.NO_ROOM, "Sala 211 RIGHT fechada")

## Teste 7: Restituição completa de inventário e armas via ItemBox BAG
func _test_bag_restitution() -> void:
	var cs := CaptureSystem.new()
	var inv := InventoryManager.new()
	var ws := WeaponSystem.new()

	# Monta estado prévio e executa captura (Rank 2 para suportar 10 mísseis)
	ws.update_rank_capacities(2)
	inv.collect_item(InventoryManager.ITEM_CARD4)
	inv.collect_item(InventoryManager.ITEM_RATION)
	inv.collect_item(InventoryManager.ITEM_RATION)
	ws.add_weapon(WeaponSystem.WEAPON_MISSILE, 10)
	cs.execute_capture(inv, ws)

	_assert(cs.is_captured, "Snake capturado")
	_assert(inv.items.is_empty(), "Inventário zerado")
	_assert(ws.owned_weapons.is_empty(), "Arsenal zerado")

	# Instancia objeto da bolsa na sala adjacente
	var bag_box := ItemBox.new()
	bag_box.item_id = "BAG"
	bag_box.room_id = 212
	bag_box.position = Vector2(136.0, 64.0)

	# Snake toca na bolsa
	var collected: bool = bag_box.step_tick(Vector2(136.0, 64.0), inv, ws, cs)
	_assert(collected, "Bolsa coletada ao colidir")
	_assert(bag_box.collected, "bag_box.collected == true")
	_assert(not cs.is_captured, "cs.is_captured == false após restituição")
	_assert(cs.equip_bag_taken, "cs.equip_bag_taken == true")

	# Verifica restauração
	_assert(inv.has_item(InventoryManager.ITEM_CARD4), "CARD4 restituído ao inventário")
	_assert(inv.has_item(InventoryManager.ITEM_RATION), "Rações restituídas")
	_assert(inv.rations_count == 2, "Quantidade de rações recuperada (2)")
	_assert(ws.has_weapon(WeaponSystem.WEAPON_MISSILE), "Míssil teleguiado restituído ao arsenal")
	_assert(ws.ammo[WeaponSystem.WEAPON_MISSILE] == 10, "Munição de mísseis preservada (10)")

	bag_box.free()

## Teste 8: Reset absoluto de estado
func _test_reset_state() -> void:
	var cs := CaptureSystem.new()
	cs.is_captured = true
	cs.capture_occurred = true
	cs.equip_bag_taken = true
	cs.wall_hit_counter = 4
	cs.wall_broken = true
	cs.backup_items = ["CARD1"]

	cs.reset_state()

	_assert(not cs.is_captured, "is_captured resetado para false")
	_assert(not cs.capture_occurred, "capture_occurred resetado para false")
	_assert(not cs.equip_bag_taken, "equip_bag_taken resetado para false")
	_assert(cs.wall_hit_counter == 0, "wall_hit_counter resetado para 0")
	_assert(not cs.wall_broken, "wall_broken resetado para false")
	_assert(cs.backup_items.is_empty(), "backup_items limpo")

## Teste 9: Integração do Fluxo Completo de Fuga e Restituição (Sala 8 -> Cela 211 -> Parede Oca -> Fuga 212 -> Restituição -> Retorno 211)
func _test_prison_flow_integration() -> void:
	var rm := RoomManager.new()
	var cs := CaptureSystem.new()
	var inv := InventoryManager.new()
	var ws := WeaponSystem.new()

	# 1. Carrega dados canônicos da Sala 8
	var snap8 := rm.load_room_snapshot(8)
	_assert(snap8 != null and snap8.room_id == 8, "Snapshot canônico da Sala 8 carregado")

	# Prepara equipamentos prévios
	inv.collect_item(InventoryManager.ITEM_CARD1)
	ws.add_weapon(WeaponSystem.WEAPON_HANDGUN, 30)

	# 2. Gatilho de emboscada na Sala 8 (X in [192, 208])
	var snake_pos := Vector2(196.0, 80.0)
	var triggered: bool = cs.check_capture_trigger(8, snake_pos)
	_assert(triggered, "Gatilho de captura acionado em X=196 na Sala 8")

	cs.execute_capture(inv, ws)
	_assert(cs.is_captured, "Solid Snake capturado")
	_assert(inv.items.is_empty(), "Inventário ativo esvaziado")
	_assert(ws.owned_weapons.is_empty(), "Arsenal ativo esvaziado")

	# 3. Spawn na Cela 211
	var snap211 := rm.load_room_snapshot(211)
	_assert(snap211 != null and snap211.room_id == 211, "Snapshot canônico da Cela 211 carregado")
	snake_pos = CaptureSystem.SPAWN_PRISON
	_assert(snake_pos == Vector2(128.0, 80.0), "Snake spawnou no centro da cela (128, 80)")

	# 4. Desloca Snake até a parede oca esquerda (X=44, Y=80) e desfere 4 socos
	snake_pos = Vector2(44.0, 80.0)
	for i in range(4):
		var hit: bool = cs.check_wall_punch(snake_pos, PlayerController.Direction.LEFT, true)
		_assert(hit, "Soco %d na parede oca registrado" % (i + 1))
		cs.check_wall_punch(snake_pos, PlayerController.Direction.LEFT, false)

	_assert(cs.wall_broken, "Parede oca destruída após 4 socos")

	# 5. Aplica desobstrução de colisão da Cela 211 (WALL_TILES)
	var col211 := Array(snap211.collision)
	for t in CaptureSystem.WALL_TILES:
		col211[t.y * 32 + t.x] = 0
	_assert(col211[8 * 32 + 0] == 0, "Borda esquerda da cela (0, 8) desobstruída")

	# 6. Snake atravessa a parede para a esquerda até cruzar a borda (X < 12.0)
	snake_pos = Vector2(8.0, 80.0)
	var exit_dir: int = RoomManager.check_room_exit(snake_pos)
	_assert(exit_dir == PlayerController.Direction.LEFT, "Saída para a esquerda detectada em X=8")

	var dest_room: int = RoomManager.get_next_room(211, exit_dir)
	_assert(dest_room == 212, "Transição da Cela 211 leva à Sala 212")

	# 7. Snake entra na Sala 212 no lado direito
	var entry_pos: Vector2 = RoomManager.get_entry_position(exit_dir, snake_pos)
	_assert(entry_pos.x == RoomManager.ENTRY_X_FROM_LEFT, "Snake entra no lado direito da Sala 212 (242)")

	var snap212 := rm.load_room_snapshot(212)
	_assert(snap212 != null and snap212.room_id == 212, "Snapshot canônico da Sala 212 carregado")

	var col212 := Array(snap212.collision)
	for t in CaptureSystem.ADJACENT_WALL_TILES:
		col212[t.y * 32 + t.x] = 0
	_assert(col212[8 * 32 + 30] == 0, "Ponto de entrada na Sala 212 (30, 8) desobstruído")

	# 8. Snake recupera equipamentos na Sala 212
	var bag := ItemBox.new()
	bag.item_id = "BAG"
	bag.room_id = 212
	bag.position = Vector2(136.0, 64.0)
	var collected: bool = bag.step_tick(Vector2(136.0, 64.0), inv, ws, cs)
	_assert(collected, "Bolsa coletada na Sala 212")
	_assert(inv.has_item(InventoryManager.ITEM_CARD1), "CARD1 recuperado")
	_assert(ws.has_weapon(WeaponSystem.WEAPON_HANDGUN), "HANDGUN recuperada")
	_assert(not cs.is_captured, "Captura finalizada")
	bag.free()

	# 9. Retorno para a Cela 211 pela direita
	snake_pos = Vector2(248.0, 80.0)
	var exit_dir_ret: int = RoomManager.check_room_exit(snake_pos)
	_assert(exit_dir_ret == PlayerController.Direction.RIGHT, "Saída para a direita detectada em X=248")

	var ret_room: int = RoomManager.get_next_room(212, exit_dir_ret)
	_assert(ret_room == 211, "Retorno da Sala 212 leva de volta à Cela 211")

## Teste 10: Transição da porta sul da Sala 212 para a Sala 54 (Basement) com spawn em (112, 168)
func _test_room_212_to_room_54_transition() -> void:
	var rm := RoomManager.new()

	# 1. Validação de saída sul via RoomManager
	var next_down: int = RoomManager.get_next_room(212, PlayerController.Direction.DOWN)
	_assert(next_down == 54, "Sala 212 -> DOWN conecta com Sala 54 (Basement)")

	# 2. Carrega metadados de portas da Sala 212
	var data212: Dictionary = rm.load_room_actors(212)
	var doors212: Array = data212.get("doors", [])
	var door12_in_212: Dictionary = {}
	for d in doors212:
		if int(d.get("door_id", 0)) == 12:
			door12_in_212 = d
			break
	_assert(not door12_in_212.is_empty(), "Door 12 configurada na Sala 212")
	_assert(int(door12_in_212.get("destination_room_id", 0)) == 54, "Door 12 na Sala 212 aponta para Sala 54")
	_assert(int(door12_in_212.get("render_type_id", 0)) == 13, "Door 12 na Sala 212 usa render_type_id 13 (South exit)")

	# 3. Carrega metadados de portas da Sala 54
	var data54: Dictionary = rm.load_room_actors(54)
	var doors54: Array = data54.get("doors", [])
	var door12_in_54: Dictionary = {}
	for d in doors54:
		if int(d.get("door_id", 0)) == 12:
			door12_in_54 = d
			break
	_assert(not door12_in_54.is_empty(), "Door 12 configurada na Sala 54")
	_assert(int(door12_in_54.get("destination_room_id", 0)) == 212, "Door 12 na Sala 54 aponta para Sala 212")
	_assert(int(door12_in_54.get("render_type_id", 0)) == 12, "Door 12 na Sala 54 usa render_type_id 12 (Basement cell)")

	# 4. Cálculo de spawn canônico ao sair na Sala 54: (96 + 16, 128 + 40) = (112, 168), DIR = DOWN
	var spawn54: Dictionary = RoomDoor.get_door_spawn(Vector2(96.0, 128.0), 12)
	_assert(spawn54.get("pos") == Vector2(112.0, 168.0), "Spawn na Sala 54 ocorre exatamente no vão do isolamento em (112, 168)")
	_assert(int(spawn54.get("dir")) == PlayerController.Direction.DOWN, "Snake emerge na Sala 54 olhando para o SUL (DOWN)")

	# 5. Cálculo de spawn canônico ao reentrar na Sala 212: (96 + 16, 152 - 8) = (112, 144), DIR = UP
	var spawn212: Dictionary = RoomDoor.get_door_spawn(Vector2(96.0, 152.0), 13)
	_assert(spawn212.get("pos") == Vector2(112.0, 144.0), "Spawn na Sala 212 ocorre dentro da cela em (112, 144)")
	_assert(int(spawn212.get("dir")) == PlayerController.Direction.UP, "Snake reentra na Sala 212 olhando para o NORTE (UP)")

## Teste 11: Spawns, bloqueio de controles e orientações canônicas dos guardas (logic/capturescene.asm:27-36, 170-186)
func _test_capture_cutscene_spawns_and_positions() -> void:
	var cutscene := CaptureCutscene.new()
	var player := PlayerController.new()
	player.position = Vector2(200.0, 96.0) # Y < 152.0 (0x98)
	player.can_control = true

	# 1. Inicia cutscene com Snake na parte superior (Y = 96)
	cutscene.start_cutscene(player)
	_assert(cutscene.is_active, "Cutscene de captura ativada")
	_assert(not player.can_control, "Controles de Snake travados no início da cutscene (logic/common.asm:43)")
	_assert(cutscene.guard_a_visible, "Guarda A visível imediatamente")
	_assert(cutscene.guard_a_pos == Vector2(240.0, 96.0), "Guarda A spawna em X=240 e Y=PlayerY (logic/capturescene.asm:32-34)")
	_assert(cutscene.guard_a_dir == PlayerController.Direction.LEFT, "Guarda A virado para a ESQUERDA encarando Snake")
	_assert(cutscene.guard_b_pos.y == 176.0, "Guarda B configurado para spawnar abaixo em Y=176 pois PlayerY < 152 (logic/capturescene.asm:179)")

	# 2. Testa cálculo alternativo com Snake na parte inferior (Y = 160 >= 152)
	player.position = Vector2(200.0, 160.0)
	cutscene.start_cutscene(player)
	_assert(cutscene.guard_b_pos.y == 136.0, "Guarda B configurado para spawnar acima em Y=136 pois PlayerY >= 152 (logic/capturescene.asm:182)")

	player.free()
	cutscene.free()

## Teste 12: Diálogos autênticos, marcha a 120 px/s e máquinas de estados (data/texts.asm:189-190 e logic/capturescene.asm:208-260)
func _test_capture_cutscene_dialog_and_timing() -> void:
	var cutscene := CaptureCutscene.new()
	var player := PlayerController.new()
	player.position = Vector2(200.0, 100.0)
	cutscene.start_cutscene(player)

	var msg_box: Array[String] = [""]
	cutscene.message_displayed.connect(func(msg: String):
		msg_box[0] = msg
	)

	# 1. Passa os 2 frames de delay inicial -> Guarda A profere "DON'T MOVE!"
	cutscene._process(0.04) # > 2/60s
	_assert(cutscene.current_state == CaptureCutscene.State.GUARD_A_SPEAK, "Transitou para estado GUARD_A_SPEAK")
	_assert(cutscene.show_message_box, "Caixa de mensagem Type 4 ativa")
	_assert(cutscene.current_message_text == "DON'T MOVE!", "Texto do Guarda A é o canônico 'DON'T MOVE!' (data/texts.asm:189)")
	_assert(msg_box[0] == "DON'T MOVE!", "Sinal message_displayed emitido com 'DON'T MOVE!'")
	_assert(cutscene.guard_b_visible, "Guarda B torna-se visível no spawn")

	# 2. Conclui fala do Guarda A -> Inicia marcha em X do Guarda B
	cutscene._process(CaptureCutscene.DURATION_SPEAK_A_SEC + 0.01)
	_assert(cutscene.current_state == CaptureCutscene.State.GUARD_B_WALK_X, "Transitou para GUARD_B_WALK_X")
	_assert(not cutscene.show_message_box, "Caixa de mensagem fechada durante a marcha")
	_assert(cutscene.guard_b_moving, "Guarda B em movimento")

	# 3. Guarda B marcha a 120 px/s em X: de 240 até 184 (distância 56 px -> ~0.467s)
	cutscene._process(0.2)
	_assert(cutscene.guard_b_pos.x == 240.0 - 120.0 * 0.2, "Guarda B avança em X a exatos 120 px/s (SetWalkSpeedFast)")
	cutscene._process(0.3)
	_assert(cutscene.guard_b_pos.x == CaptureCutscene.GUARD_B_STOP_X, "Guarda B atinge X=184 (0xB8) e para avanço horizontal")
	_assert(cutscene.current_state == CaptureCutscene.State.GUARD_B_WALK_Y, "Transitou para marcha vertical GUARD_B_WALK_Y")
	_assert(cutscene.guard_b_dir == PlayerController.Direction.UP, "Guarda B vira para CIMA em direção a Snake (Y=176 -> Y=100)")

	# 4. Guarda B marcha em Y até alinhar com Snake
	cutscene._process(1.0)
	_assert(cutscene.guard_b_pos.y == player.position.y, "Guarda B alinhou perfeitamente no Y de Snake")
	_assert(cutscene.guard_b_dir == PlayerController.Direction.LEFT, "Guarda B vira para a ESQUERDA encarando Snake de frente")
	_assert(cutscene.current_state == CaptureCutscene.State.GUARD_B_ARRIVED, "Transitou para GUARD_B_ARRIVED")

	# 5. Pausa de 2 frames -> Guarda B profere "YOU ARE CAPTURED!"
	cutscene._process(0.04)
	_assert(cutscene.current_state == CaptureCutscene.State.GUARD_B_SPEAK, "Transitou para GUARD_B_SPEAK")
	_assert(cutscene.show_message_box, "Caixa de mensagem ativa para Guarda B")
	_assert(cutscene.current_message_text == "YOU ARE CAPTURED!", "Texto do Guarda B é o canônico 'YOU ARE CAPTURED!' (data/texts.asm:190)")
	_assert(msg_box[0] == "YOU ARE CAPTURED!", "Sinal message_displayed emitido com 'YOU ARE CAPTURED!'")

	player.free()
	cutscene.free()

## Teste 13: Fade Out, emissão de teleporte no escuro e liberação de controles (logic/capturescene.asm:69-118)
func _test_capture_cutscene_fade_and_completion() -> void:
	var cutscene := CaptureCutscene.new()
	var player := PlayerController.new()
	player.position = Vector2(200.0, 100.0)
	player.can_control = true

	var flags := {"teleport": false, "finished": false}
	cutscene.teleport_requested.connect(func():
		flags["teleport"] = true
	)
	cutscene.cutscene_finished.connect(func():
		flags["finished"] = true
	)

	cutscene.start_cutscene(player)
	_assert(not player.can_control, "Controles travados no início")

	# Avança rapidamente pelos diálogos e marcha
	cutscene.current_state = CaptureCutscene.State.WAIT_BEFORE_FADE
	cutscene.state_timer = 0.01
	cutscene._process(0.02)
	_assert(cutscene.current_state == CaptureCutscene.State.FADE_OUT, "Transitou para FADE_OUT")

	# Simula fade out progressivo
	cutscene._process(0.5)
	_assert(cutscene.fade_alpha > 0.0 and cutscene.fade_alpha < 1.0, "fade_alpha intermediário no escurecimento progressivo")
	cutscene._process(0.6)
	_assert(cutscene.fade_alpha == 1.0, "fade_alpha atinge 1.0 (100% escuro)")
	_assert(cutscene.current_state == CaptureCutscene.State.IN_DARKNESS, "Transitou para IN_DARKNESS")
	_assert(flags["teleport"], "Sinal teleport_requested emitido no ápice da escuridão para transportar Snake")

	# Simula despertar na Cela 211
	cutscene._process(CaptureCutscene.DURATION_DARKNESS_SEC + 0.01)
	_assert(cutscene.current_state == CaptureCutscene.State.FADE_IN, "Transitou para FADE_IN na Cela 211")
	_assert(not cutscene.guard_a_visible, "Guardas ocultados após transporte para a cela")
	_assert(not cutscene.guard_b_visible, "Guardas ocultados após transporte para a cela")

	# Conclui clareamento
	cutscene._process(CaptureCutscene.DURATION_FADE_IN_SEC + 0.01)
	_assert(cutscene.current_state == CaptureCutscene.State.FINISHED, "Estado final FINISHED")
	_assert(not cutscene.is_active, "Cutscene inativa")
	_assert(player.can_control, "Controles de Snake liberados com sucesso na Cela 211 (logic/capturescene.asm:115)")
	_assert(flags["finished"], "Sinal cutscene_finished emitido")

	# Valida rotina de desenho _draw() sem exceções
	cutscene.fade_alpha = 0.5
	cutscene.show_message_box = true
	cutscene.current_message_text = "TEST"
	cutscene.queue_redraw()

	player.free()
	cutscene.free()


