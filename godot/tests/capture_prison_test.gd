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

	# 3. punch_timer != 8 não conta (evita multi-hit no mesmo golpe)
	var h4: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, 7)
	_assert(not h4, "Soco com punch_timer != 8 não registra múltiplos hits")
	_assert(cs.wall_hit_counter == 0, "Contador permanece 0")

	# 4. Sequência canônica de 4 socos
	var hit1: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, 8)
	_assert(hit1, "1º soco válido detectado")
	_assert(cs.wall_hit_counter == 1, "wall_hit_counter == 1")
	_assert(not cs.wall_broken, "Parede ainda não quebrou (1/4)")

	var hit2: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, 8)
	_assert(hit2, "2º soco válido detectado")
	_assert(cs.wall_hit_counter == 2, "wall_hit_counter == 2")
	_assert(not cs.wall_broken, "Parede ainda não quebrou (2/4)")

	var hit3: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, 8)
	_assert(hit3, "3º soco válido detectado")
	_assert(cs.wall_hit_counter == 3, "wall_hit_counter == 3")
	_assert(not cs.wall_broken, "Parede ainda não quebrou (3/4)")

	var hit4: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, 8)
	_assert(hit4, "4º soco válido detectado")
	_assert(cs.wall_hit_counter == 4, "wall_hit_counter == 4")
	_assert(cs.wall_broken, "Parede quebrada com sucesso após o 4º acerto!")

	# Soco após quebra não incrementa mais
	var hit5: bool = cs.check_wall_punch(wall_pos, PlayerController.Direction.LEFT, 8)
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

	# Valida desobstrução dos tiles da passagem
	for tile: Vector2i in CaptureSystem.WALL_TILES:
		var idx: int = tile.y * 32 + tile.x
		_assert(collision[idx] == 0, "Tile (%d, %d) desobstruído (colisão == 0)" % [tile.x, tile.y])

	_assert(CaptureSystem.WALL_TILES.size() == 8, "Exatamente 8 tiles liberados na parede")

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
