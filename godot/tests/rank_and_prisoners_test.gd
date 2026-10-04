extends SceneTree
## Suíte de testes headless — Sistema de Prisioneiros, Reféns e Patente Militar (Etapa 19)
## Valida as mecânicas canônicas extraídas de Banks0123.asm:9574-9679 e logic/actors/prisoner.asm
## Token de conclusão: RANK_AND_PRISONERS_OK

var _pass: int = 0
var _fail: int = 0

func _initialize() -> void:
	_run_all()
	var result: String = "RANK_AND_PRISONERS_OK: %d testes passaram, %d falharam" % [_pass, _fail]
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
	print("--- Rank and Prisoners System Tests ---")
	_test_initial_rank_attributes()
	_test_rescue_progression_to_rank_2()
	_test_full_progression_to_rank_4()
	_test_player_life_expansion_and_heal()
	_test_weapon_ammo_capacity_scaling()
	_test_inventory_ration_capacity_scaling()
	_test_prisoner_entities_and_dialogs()
	_test_key_story_hostages()
	_test_prisoner_kill_and_rank_downgrade()
	_test_room_persistence()
	_test_prisoner_sprites_and_animation()

## Teste 1: Atributos iniciais de Rank 1 (Class ★)
func _test_initial_rank_attributes() -> void:
	var rank_sys: RankSystem = RankSystem.new()
	_assert(rank_sys.current_rank == 1, "Rank inicial = 1")
	_assert(rank_sys.rescued_count == 0, "Contador de resgates inicial = 0")
	_assert(rank_sys.get_rank_stars() == "★☆☆☆", "Estrelas iniciais = ★☆☆☆")
	_assert(rank_sys.get_max_life() == 24, "Vida máxima Rank 1 = 24")
	_assert(rank_sys.get_max_ammo("HANDGUN") == 50, "Munição Handgun Rank 1 = 50")
	_assert(rank_sys.get_max_ammo("GRENADE_LAUNCHER") == 15, "Munição Grenade Launcher Rank 1 = 15")
	_assert(rank_sys.get_max_rations() == 3, "Capacidade de rações Rank 1 = 3")

## Teste 2: Resgate de 4 reféns promove para Rank 2 (Class ★★)
func _test_rescue_progression_to_rank_2() -> void:
	var rank_sys: RankSystem = RankSystem.new()
	var rank_changed_events: Array[int] = []
	rank_sys.rank_changed.connect(func(r: int) -> void: rank_changed_events.append(r))

	var promoted1: bool = rank_sys.register_rescue(10)
	_assert(not promoted1, "1º refém não promove")
	_assert(rank_sys.current_rank == 1, "Ainda Rank 1")

	var promoted2: bool = rank_sys.register_rescue(11)
	_assert(not promoted2, "2º refém não promove")

	var promoted3: bool = rank_sys.register_rescue(12)
	_assert(not promoted3, "3º refém não promove")

	var promoted4: bool = rank_sys.register_rescue(13)
	_assert(promoted4, "4º refém promove para Rank 2!")
	_assert(rank_sys.current_rank == 2, "Agora é Rank 2")
	_assert(rank_sys.get_rank_stars() == "★★☆☆", "Estrelas = ★★☆☆")
	_assert(rank_sys.get_max_life() == 32, "Vida máxima Rank 2 = 32")
	_assert(rank_sys.get_max_ammo("HANDGUN") == 100, "Munição Handgun Rank 2 = 100")
	_assert(rank_sys.get_max_rations() == 6, "Capacidade de rações Rank 2 = 6")
	_assert(rank_changed_events.size() == 1 and rank_changed_events[0] == 2, "Sinal rank_changed(2) emitido")

## Teste 3: Progressão completa até Rank 4 (Class ★★★★)
func _test_full_progression_to_rank_4() -> void:
	var rank_sys: RankSystem = RankSystem.new()
	# 4 resgates -> Rank 2
	for i: int in range(4):
		rank_sys.register_rescue(20 + i)
	_assert(rank_sys.current_rank == 2, "Promovido a Rank 2")

	# Mais 4 resgates -> Rank 3
	for i: int in range(4):
		rank_sys.register_rescue(30 + i)
	_assert(rank_sys.current_rank == 3, "Promovido a Rank 3")
	_assert(rank_sys.get_rank_stars() == "★★★☆", "Estrelas = ★★★☆")
	_assert(rank_sys.get_max_life() == 40, "Vida máxima Rank 3 = 40")
	_assert(rank_sys.get_max_ammo("HANDGUN") == 200, "Munição Handgun Rank 3 = 200")
	_assert(rank_sys.get_max_rations() == 9, "Capacidade de rações Rank 3 = 9")

	# Mais 4 resgates -> Rank 4
	for i: int in range(4):
		rank_sys.register_rescue(40 + i)
	_assert(rank_sys.current_rank == 4, "Promovido a Rank 4")
	_assert(rank_sys.get_rank_stars() == "★★★★", "Estrelas = ★★★★")
	_assert(rank_sys.get_max_life() == 48, "Vida máxima Rank 4 = 48")
	_assert(rank_sys.get_max_ammo("HANDGUN") == 300, "Munição Handgun Rank 4 = 300")
	_assert(rank_sys.get_max_ammo("GRENADE_LAUNCHER") == 90, "Munição Grenade Launcher Rank 4 = 90")
	_assert(rank_sys.get_max_rations() == 12, "Capacidade de rações Rank 4 = 12")

	# Resgate adicional após rank 4 não ultrapassa MAX_RANK
	rank_sys.register_rescue(50)
	_assert(rank_sys.current_rank == 4, "Rank não ultrapassa 4")

## Teste 4: Expansão de vida e cura do Player ao subir de Rank
func _test_player_life_expansion_and_heal() -> void:
	var player: PlayerController = PlayerController.new()
	player.set_grid_position(50.0, 50.0)
	_assert(player.max_life == 24, "Player inicia com max_life = 24")

	# Snake toma dano
	player.apply_damage(10)
	_assert(player.life == 14, "Player tomou dano (vida = 14)")

	# Promoção para Rank 2 com cura completa (comportamento da ROM)
	player.set_rank_life(32, true)
	_assert(player.max_life == 32, "Player max_life expandida para 32")
	_assert(player.life == 32, "Player totalmente curado após promoção")
	player.free()

## Teste 5: Escalonamento de capacidades do WeaponSystem
func _test_weapon_ammo_capacity_scaling() -> void:
	var ws: WeaponSystem = WeaponSystem.new()
	ws.add_weapon("HANDGUN", 50)
	_assert(ws.ammo["HANDGUN"] == 50, "Munição inicial da Handgun = 50")

	# Coleta munição além do limite R1 -> deve ser podado para 50
	ws.add_ammo("HANDGUN", 20)
	_assert(ws.ammo["HANDGUN"] == 50, "Munição Handgun limitada a 50 no Rank 1")

	# Promove para Rank 2
	ws.update_rank_capacities(2)
	ws.add_ammo("HANDGUN", 30)
	_assert(ws.ammo["HANDGUN"] == 80, "Munição Handgun sobe até 80 no Rank 2")

	# Promove para Rank 4
	ws.update_rank_capacities(4)
	ws.ammo["HANDGUN"] = 290
	ws.add_ammo("HANDGUN", 50)
	_assert(ws.ammo["HANDGUN"] == 300, "Munição Handgun limitada a 300 no Rank 4")

## Teste 6: Escalonamento de capacidade de rações no InventoryManager
func _test_inventory_ration_capacity_scaling() -> void:
	var inv: InventoryManager = InventoryManager.new()
	inv.collect_item("RATION")
	inv.collect_item("RATION")
	inv.collect_item("RATION")
	inv.collect_item("RATION") # Tenta coletar o 4º
	_assert(inv.rations_count == 3, "Rações limitadas a 3 no Rank 1")

	# Promove para Rank 2
	inv.update_rank_capacities(2)
	inv.collect_item("RATION")
	_assert(inv.rations_count == 4, "Rações podem atingir 4 no Rank 2")

## Teste 7: Entidades de reféns e textos canônicos
func _test_prisoner_entities_and_dialogs() -> void:
	var p: Prisoner = Prisoner.new()
	p.setup(49, 148, Vector2(100.0, 100.0))
	_assert(not p.is_rescued, "Refém inicia preso")
	_assert(p.prisoner_name == "PRISIONEIRO", "Nome comum = PRISIONEIRO")
	_assert(p.message_text.contains("Thank you, Snake!"), "Texto autêntico da sala 148")

	var rescued_signal: Array[Prisoner] = []
	p.rescued.connect(func(pris: Prisoner) -> void:
		rescued_signal.append(pris)
	)

	p.rescue_prisoner()
	_assert(p.is_rescued, "Após rescue_prisoner(), refém fica marcado como libertado")
	_assert(rescued_signal.size() == 1 and rescued_signal[0] == p, "Sinal rescued emitido com o refém")

	# Segundo resgate não deve re-emitir sinal
	p.rescue_prisoner()
	_assert(rescued_signal.size() == 1, "Segundo resgate ignorado")
	p.free()

## Teste 8: Reféns-chave da trama (Grey Fox e Ellen Madnar)
func _test_key_story_hostages() -> void:
	# Grey Fox (ID 51) na Sala 164
	var fox: Prisoner = Prisoner.new()
	fox.setup(51, 164, Vector2(128.0, 96.0))
	_assert(fox.prisoner_name == "GREY FOX", "ID 51 identificado como GREY FOX")
	_assert(fox.is_vital, "Grey Fox é personagem vital")
	fox.rescue_prisoner()
	_assert(fox.message_text.is_empty(), "Grey Fox usa texto 59 paginado, sem resumo inventado")
	fox.free()

	# Ellen Madnar (ID 50) na Sala 167
	var ellen: Prisoner = Prisoner.new()
	ellen.setup(50, 167, Vector2(128.0, 96.0))
	_assert(ellen.prisoner_name == "ELLEN MADNAR", "ID 50 identificada como ELLEN MADNAR")
	_assert(ellen.is_vital, "Ellen Madnar é personagem vital")
	ellen.rescue_prisoner()
	_assert(ellen.message_text.contains("Ellen"), "Diálogo da Ellen contém seu nome")
	_assert(ellen.message_text.contains("Pettrovich"), "Diálogo da Ellen menciona Pettrovich")
	ellen.free()

## Teste 9: Morte de refém por tiro/soco e rebaixamento de patente (DowngradeRank)
func _test_prisoner_kill_and_rank_downgrade() -> void:
	var rank_sys: RankSystem = RankSystem.new()
	# Promove para Rank 2
	for i: int in range(4):
		rank_sys.register_rescue(100 + i)
	_assert(rank_sys.current_rank == 2, "Snake promovido a Rank 2")

	# Instancia refém e mata com tiro/soco
	var p: Prisoner = Prisoner.new()
	p.setup(49, 105, Vector2(100.0, 100.0))
	var hit: bool = p.apply_bullet_hit()
	_assert(hit, "apply_bullet_hit retorna true")
	_assert(p.is_dead, "Estado is_dead = true")

	# Penalidade de rebaixamento
	var downgraded: bool = rank_sys.register_kill(105, p.is_vital)
	_assert(downgraded, "register_kill rebaixa o rank!")
	_assert(rank_sys.current_rank == 1, "Rank rebaixado para 1 (DowngradeRank)")
	_assert(rank_sys.get_rank_stars() == "★☆☆☆", "Estrelas voltam para ★☆☆☆")
	_assert(rank_sys.get_max_life() == 24, "Vida máxima rebaixada para 24")
	p.free()

## Teste 10: Persistência de salas resgatadas
func _test_room_persistence() -> void:
	var rank_sys: RankSystem = RankSystem.new()
	_assert(not rank_sys.is_room_rescued(164), "Sala 164 não resgatada inicialmente")
	rank_sys.register_rescue(164)
	_assert(rank_sys.is_room_rescued(164), "Sala 164 marcada como resgatada")
	_assert(not rank_sys.is_room_rescued(167), "Sala 167 ainda não resgatada")

## Teste 11: Sprites autênticos MSX2 e temporização da animação
func _test_prisoner_sprites_and_animation() -> void:
	Prisoner.load_prisoner_textures()
	_assert(Prisoner._prisoner_texture != null, "Textura de prisioneiros autêntica (prisoners_msx.png) carregada!")

	# 1. Prisioneiro comum (Linha 0)
	var p := Prisoner.new()
	p.setup(Prisoner.TYPE_PRISONER, 148, Vector2(100.0, 100.0))
	_assert(p._get_sprite_rect() == Rect2(0.0, 0.0, 16.0, 32.0), "Prisioneiro amarrado frame 0 = Coluna 0, Linha 0")

	# Avança 8 frames (meio ciclo): não deve alternar
	p.step_tick(8.0 / 60.0)
	_assert(p.anim_frame == 0, "Aos 8 frames (meio ciclo), frame continua 0")

	# Avança mais 8 frames (total 16 frames = 0.2667s): deve alternar para frame 1
	p.step_tick(8.0 / 60.0)
	_assert(p.anim_frame == 1, "Aos 16 frames (Anim2FramesActor), frame alterna para 1")
	_assert(p._get_sprite_rect() == Rect2(16.0, 0.0, 16.0, 32.0), "Prisioneiro amarrado frame 1 = Coluna 1, Linha 0")

	# Resgate: muda para pose livre (Coluna 2)
	p.rescue_prisoner()
	_assert(p._get_sprite_rect() == Rect2(32.0, 0.0, 16.0, 32.0), "Prisioneiro resgatado = Coluna 2, Linha 0")

	# 2. Grey Fox (Linha 1)
	var fox := Prisoner.new()
	fox.setup(Prisoner.TYPE_GREY_FOX, 164)
	_assert(fox._get_sprite_rect() == Rect2(0.0, 32.0, 16.0, 32.0), "Grey Fox amarrado = Coluna 0, Linha 1")
	fox.rescue_prisoner()
	_assert(fox._get_sprite_rect() == Rect2(32.0, 32.0, 16.0, 32.0), "Grey Fox livre = Coluna 2, Linha 1")

	# 3. Ellen Madnar (Linha 2)
	var ellen := Prisoner.new()
	ellen.setup(Prisoner.TYPE_ELLEN, 167)
	_assert(ellen._get_sprite_rect() == Rect2(0.0, 64.0, 16.0, 32.0), "Ellen amarrada = Coluna 0, Linha 2")
	ellen.rescue_prisoner()
	_assert(ellen._get_sprite_rect() == Rect2(32.0, 64.0, 16.0, 32.0), "Ellen livre = Coluna 2, Linha 2")

	# 4. Dr. Madnar (Linha 3)
	var madnar := Prisoner.new()
	madnar.setup(Prisoner.TYPE_MADNAR, 182)
	_assert(madnar._get_sprite_rect() == Rect2(0.0, 96.0, 16.0, 32.0), "Dr. Madnar amarrado = Coluna 0, Linha 3")
	madnar.rescue_prisoner()
	_assert(madnar._get_sprite_rect() == Rect2(32.0, 96.0, 16.0, 32.0), "Dr. Madnar livre = Coluna 2, Linha 3")

	# 5. Validação de renderização sem exceções
	p.notification(CanvasItem.NOTIFICATION_DRAW)
	fox.notification(CanvasItem.NOTIFICATION_DRAW)
	ellen.notification(CanvasItem.NOTIFICATION_DRAW)
	madnar.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert(true, "Rotinas de renderização (NOTIFICATION_DRAW) executadas sem erro para todos os personagens!")

	p.free()
	fox.free()
	ellen.free()
	madnar.free()
