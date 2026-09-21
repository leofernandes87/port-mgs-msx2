extends SceneTree
## Suíte de testes headless — Perigo de Gás Tóxico e Gas Mask (Etapa 19)
## Valida as mecânicas canônicas extraídas de logic/damagegas.asm e logic/actors/gas.asm
## Token de conclusão: GAS_HAZARD_OK

var _pass: int = 0
var _fail: int = 0

func _initialize() -> void:
	_run_all()
	var result: String = "GAS_HAZARD_OK: %d testes passaram, %d falharam" % [_pass, _fail]
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
	print("--- Gas Hazard & Gas Mask Tests ---")
	_test_canonical_gas_rooms()
	_test_no_damage_outside_gas_room()
	_test_damage_in_gas_room_without_mask()
	_test_damage_interval_16_ticks()
	_test_protection_with_gas_mask_equipped()
	_test_protection_fails_if_mask_unselected()
	_test_gas_cloud_actor_cycle()
	_test_death_by_gas_hazard()

## Teste 1: 9 salas canônicas identificadas no MSX2 RC750 (damagegas.asm:53)
func _test_canonical_gas_rooms() -> void:
	var ghs: GasHazardSystem = GasHazardSystem.new()
	var expected_rooms: Array[int] = [29, 94, 96, 97, 98, 100, 101, 112, 114]
	for r: int in expected_rooms:
		_assert(ghs.is_gas_room(r), "Sala %d identificada como sala de gás" % r)
	_assert(not ghs.is_gas_room(1), "Sala 1 não é sala de gás")
	_assert(not ghs.is_gas_room(121), "Sala 121 (início) não é sala de gás")
	_assert(not ghs.is_gas_room(57), "Sala 57 (Shoot Gunner) não é sala de gás")

## Teste 2: Nenhum dano fora de salas com gás
func _test_no_damage_outside_gas_room() -> void:
	var ghs: GasHazardSystem = GasHazardSystem.new()
	var player: PlayerController = PlayerController.new()
	player.life = 12
	var inv: InventoryManager = InventoryManager.new()

	var res: Dictionary = ghs.tick(121, player, inv)
	_assert(not bool(res.get("in_gas", true)), "Sala 121: in_gas == false")
	_assert(not bool(res.get("damaged", true)), "Sala 121: damaged == false")
	_assert(player.life == 12, "Vida do jogador inalterada fora de sala de gás")
	player.free()

## Teste 3: Dano de 2 HP ao entrar em sala de gás desprotegido (damagegas.asm:45)
func _test_damage_in_gas_room_without_mask() -> void:
	var ghs: GasHazardSystem = GasHazardSystem.new()
	var player: PlayerController = PlayerController.new()
	player.life = 12
	var inv: InventoryManager = InventoryManager.new()

	var damage_signal_received: Array[int] = [0]
	ghs.gas_damage_taken.connect(func(dmg: int, _rem: int) -> void: damage_signal_received[0] = dmg)

	var res: Dictionary = ghs.tick(29, player, inv)
	_assert(bool(res.get("in_gas", false)), "Sala 29: in_gas == true")
	_assert(not bool(res.get("protected", true)), "Sala 29 sem máscara: protected == false")
	_assert(bool(res.get("damaged", false)), "Sala 29 sem máscara: damaged == true")
	_assert(player.life == 10, "Vida reduzida de 12 para 10 (2 HP)")
	_assert(damage_signal_received[0] == 2, "Sinal gas_damage_taken emitido com dano 2")
	_assert(player.invulnerable_timer == GasHazardSystem.DAMAGE_INTERVAL_TICKS, "invulnerable_timer configurado para 16 ticks")
	player.free()

## Teste 4: Dano ocorre a cada 16 ticks (0x10)
func _test_damage_interval_16_ticks() -> void:
	var ghs: GasHazardSystem = GasHazardSystem.new()
	var player: PlayerController = PlayerController.new()
	player.life = 12
	var inv: InventoryManager = InventoryManager.new()

	# Tick 0: sofre dano
	ghs.tick(94, player, inv)
	_assert(player.life == 10, "Tick 0: vida = 10")

	# Ticks 1 a 15: invulnerabilidade ativa, sem dano
	for i: int in range(15):
		player.invulnerable_timer -= 1
		var res: Dictionary = ghs.tick(94, player, inv)
		_assert(not bool(res.get("damaged", true)), "Tick %d: invulnerável a dano de gás" % (i + 1))
	_assert(player.life == 10, "Vida mantida em 10 durante intervalo de 15 ticks")

	# Tick 16: temporizador expira e próximo dano é aplicado
	player.invulnerable_timer -= 1
	var res2: Dictionary = ghs.tick(94, player, inv)
	_assert(bool(res2.get("damaged", false)), "Tick 16: novo dano aplicado")
	_assert(player.life == 8, "Vida reduzida para 8 após 16 ticks")
	player.free()

## Teste 5: Proteção 100% com Gas Mask equipada (SelectedItem == SELECTED_GAS_MASK)
func _test_protection_with_gas_mask_equipped() -> void:
	var ghs: GasHazardSystem = GasHazardSystem.new()
	var player: PlayerController = PlayerController.new()
	player.life = 12
	var inv: InventoryManager = InventoryManager.new()
	inv.collect_item(InventoryManager.ITEM_GAS_MASK)
	inv.select_item(InventoryManager.ITEM_GAS_MASK)

	var protection_signal: Array[bool] = [false]
	ghs.gas_protection_status_changed.connect(func(prot: bool) -> void: protection_signal[0] = prot)

	for i: int in range(32):
		var res: Dictionary = ghs.tick(96, player, inv)
		_assert(bool(res.get("in_gas", false)), "in_gas == true")
		_assert(bool(res.get("protected", false)), "protected == true com Gas Mask selecionada")
		_assert(not bool(res.get("damaged", true)), "damaged == false")
	_assert(player.life == 12, "Vida 100% preservada com Gas Mask equipada")
	_assert(protection_signal[0], "Sinal gas_protection_status_changed emitido com true")
	player.free()

## Teste 6: Máscara no inventário mas NÃO selecionada não protege
func _test_protection_fails_if_mask_unselected() -> void:
	var ghs: GasHazardSystem = GasHazardSystem.new()
	var player: PlayerController = PlayerController.new()
	player.life = 12
	var inv: InventoryManager = InventoryManager.new()
	inv.collect_item(InventoryManager.ITEM_GAS_MASK)
	# Seleciona outro item (ex: Cigarros)
	inv.collect_item(InventoryManager.ITEM_CIGARETTES)
	inv.select_item(InventoryManager.ITEM_CIGARETTES)

	var res: Dictionary = ghs.tick(97, player, inv)
	_assert(not bool(res.get("protected", true)), "protected == false se Gas Mask não estiver selecionada")
	_assert(bool(res.get("damaged", false)), "damaged == true")
	_assert(player.life == 10, "Sofre dano porque máscara está na mochila mas desequipada")
	player.free()

## Teste 7: Ciclo visual e propriedades do ator GasCloud (ID_GAS = 8)
func _test_gas_cloud_actor_cycle() -> void:
	var gc: GasCloud = GasCloud.new(true)
	_assert(gc.is_visible_phase, "GasCloud inicia com visibilidade ativa quando start_visible = true")
	_assert(gc.anim_frame == 0, "anim_frame inicial = 0")
	# Ciclo de animação: avança frame a cada 8 ticks
	for i: int in range(8):
		gc.step_tick()
	_assert(gc.anim_frame == 1, "anim_frame avança para 1 após 8 ticks")
	for i: int in range(8):
		gc.step_tick()
	_assert(gc.anim_frame == 0, "anim_frame alterna de volta para 0 após 16 ticks")
	gc.free()

## Teste 8: Morte do jogador por asfixia em sala de gás
func _test_death_by_gas_hazard() -> void:
	var ghs: GasHazardSystem = GasHazardSystem.new()
	var player: PlayerController = PlayerController.new()
	player.life = 2
	var inv: InventoryManager = InventoryManager.new()

	var died_signal_received: Array[bool] = [false]
	player.player_died.connect(func() -> void: died_signal_received[0] = true)

	var res: Dictionary = ghs.tick(100, player, inv)
	_assert(player.life == 0, "Vida zerada pelo dano de gás")
	_assert(player.is_dead, "player.is_dead == true")
	_assert(died_signal_received[0], "Sinal player.player_died emitido após dano fatal de gás")
	player.free()
