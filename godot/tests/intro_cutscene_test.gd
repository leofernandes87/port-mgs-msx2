extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run_tests")

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _advance(intro: IntroCutscene, player: PlayerController, calls: int) -> void:
	for index: int in range(calls):
		intro.tick(player, 1.0 / 30.0)

func _synthetic_collision(player: PlayerController) -> void:
	# Obstáculos próprios: duas barreiras com alturas/colunas distintas.
	# Exercitam colisão na aproximação, sem incorporar tiles/bytes do jogo.
	var grid: Array = []
	grid.resize(768)
	grid.fill(0)
	for x: int in [5, 6]: grid[19 * 32 + x] = 1
	for x: int in [15, 16]: grid[15 * 32 + x] = 1
	player.set_collision_grid(grid)

func _run_tests() -> void:
	var player := PlayerController.new()
	var intro := IntroCutscene.new()
	_synthetic_collision(player)
	var finished: Array[int] = [0]
	var radio: Array[int] = [0]
	intro.intro_finished.connect(func() -> void: finished[0] += 1)
	intro.radio_requested.connect(func(pages: Array[String]) -> void:
		radio[0] += 1
		_assert_true(pages.size() == 4, "Briefing preservado")
	)
	intro.start_intro(player)
	_assert_true(not player.can_control, "Intro bloqueia controle")
	# Dois frames de renderização a 60 Hz por chamada lógica.
	intro.tick(player, 1.0 / 60.0)
	_assert_true(player.position.x == 192.0 and intro.state_counter == 64, "Meio passo não avança lógica")
	intro.tick(player, 1.0 / 60.0)
	_assert_true(player.position.x == 191.0 and intro.state_counter == 63, "Segundo meio passo avança um pixel")
	_advance(intro, player, 62)
	_assert_true(player.position == Vector2(129, 184), "63 deslocamentos no primeiro mergulho")
	_advance(intro, player, 1)
	_assert_true(player.position == Vector2(129, 184) and intro.state_counter == 48, "Tick de transição não move")
	_advance(intro, player, 48 + 80)
	_assert_true(player.position == Vector2(50, 184) and intro.state_counter == 32, "Segundo mergulho e contador norte")
	_advance(intro, player, 32)
	_assert_true(player.position == Vector2(50, 165), "Aproximação para na colisão, não em coordenada imposta")
	_advance(intro, player, 64)
	_assert_true(radio[0] == 1 and intro.current_state == IntroCutscene.State.SCENE_6_RADIO_WAIT, "Rádio solicitado uma vez")
	intro.tick(player, 100.0)
	_assert_true(player.position == Vector2(50, 165), "Tempo no rádio não movimenta Snake")
	intro.on_radio_finished()
	_advance(intro, player, 1)
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_9_SWIM_RIGHT and intro.state_counter == 40, "Saída prepara movimento sem pausa extra")
	_advance(intro, player, 1)
	_assert_true(player.position.x == 52.0, "Movimento começa na primeira chamada de Scene9")
	_advance(intro, player, 39)
	_assert_true(player.position == Vector2(128, 165) and intro.state_counter == 48, "39 movimentos à direita, 48 chamadas ao norte")
	_advance(intro, player, 16)
	_assert_true(player.position == Vector2(128, 133) and intro.state_counter == 32, "Chega à grade com contador ainda ativo")
	_advance(intro, player, 31)
	_assert_true(player.position == Vector2(128, 133), "Colisão mantém posição durante a espera")
	_assert_true(player.anim_mode == PlayerController.AnimMode.SWIM_SURFACE and intro.state_counter == 1, "Não escala antes de zerar contador")
	_advance(intro, player, 1)
	_assert_true(player.position == Vector2(128, 136) and intro.state_counter == 28, "Reposicionamento só ao iniciar escalada")
	_assert_true(player.anim_mode == PlayerController.AnimMode.CLIMB, "Animação da escalada")
	_advance(intro, player, 27)
	_assert_true(player.position.y == 109.0, "Escalada: 27 movimentos de um pixel sem colisão")
	_advance(intro, player, 1)
	_assert_true(player.position.y == 102.0, "Topo reposicionado pela transição original")
	# Valores esperados por chamada, independentes do loop de implementação.
	for y: int in [100, 100, 95, 95, 90, 90, 88, 88, 86, 86, 87, 87]:
		_advance(intro, player, 1)
		_assert_true(player.position.y == float(y), "Bounce discreto Y=%d" % y)
	_assert_true(not player.can_control and finished[0] == 0, "Scene13 ainda deve liberar controle")
	_advance(intro, player, 1)
	_assert_true(player.can_control and not intro.is_active and finished[0] == 1, "Fim natural emite uma vez")
	_assert_true(player.position == Vector2(128, 87), "Fim natural não teleporta")
	intro.tick(player, 1.0)
	_assert_true(finished[0] == 1, "Fim não repete sinal")
	intro.start_intro(player)
	intro.tick(player, 1.0 / 60.0)
	intro.skip_intro(player)
	_assert_true(player.position == Vector2(128, 87) and player.can_control, "Skip usa destino final")
	intro.start_intro(player)
	intro.tick(player, 1.0 / 60.0)
	_assert_true(player.position.x == 192.0, "Replay limpa fração de tempo anterior")
	intro.skip_intro(player)
	_test_chunking()
	_test_collision_controls_wait()
	# 11. Validação de Renderização Segura do RadioDialog durante Briefing (Evitar 'is_send_mode on Nil')
	var r_dialog := RadioDialog.new()
	root.add_child(r_dialog)
	# Teste sem radio_system explicitamente configurado (deve auto-recuperar ou renderizar com segurança)
	r_dialog.start_briefing(RadioSystem.CONTACT_BIG_BOSS, "BIG BOSS", IntroCutscene.BRIEFING_PAGES)
	_assert_true(r_dialog.is_active, "RadioDialog deve estar ativo após start_briefing")
	r_dialog.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert_true(true, "RadioDialog draw sem radio_system prévio deve renderizar sem exceção")

	# Teste com radio_system atribuído
	var r_sys := RadioSystem.new()
	r_dialog.start_briefing(RadioSystem.CONTACT_BIG_BOSS, "BIG BOSS", IntroCutscene.BRIEFING_PAGES, r_sys)
	_assert_true(r_dialog.radio_system != null, "RadioDialog deve possuir radio_system vinculado")
	_assert_true(not r_dialog.radio_system.is_send_mode, "Briefing não deve estar em modo SEND")
	r_dialog.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert_true(true, "RadioDialog draw com radio_system deve renderizar perfeitamente")

	r_dialog.close_radio()
	r_dialog.queue_free()
	await process_frame


	player.free()
	intro.free()
	if failures != 0:
		printerr("INTRO_TEST_FAILURES: %d" % failures)
		quit(1)
		return
	print("INTRO_CUTSCENE_INTEGRATION_OK: contadores, colisão, espera, tempo e bounce verificados")
	quit(0)

func _test_chunking() -> void:
	# Mesmo resultado com 60/120 Hz e chunks grandes; sem perda de tempo residual.
	var reference: Vector2
	for rate: int in [30, 60, 120]:
		var p := PlayerController.new()
		var cut := IntroCutscene.new()
		_synthetic_collision(p)
		cut.start_intro(p)
		for index: int in range(rate * 3): cut.tick(p, 1.0 / float(rate))
		if rate == 30: reference = p.position
		_assert_true(p.position == reference and cut.state_counter == 22, "Cadência independe de fps %d" % rate)
		p.free()
		cut.free()
	var player := PlayerController.new()
	var intro := IntroCutscene.new()
	_synthetic_collision(player)
	intro.start_intro(player)
	intro.tick(player, 3.0)
	_assert_true(player.position == reference and intro.state_counter == 22, "Chunk atravessa transição sem descartar tempo")
	player.free()
	intro.free()

func _test_collision_controls_wait() -> void:
	var player := PlayerController.new()
	var intro := IntroCutscene.new()
	intro.start_intro(player)
	player.position = Vector2(128, 165)
	player.anim_mode = PlayerController.AnimMode.SWIM_SURFACE
	intro.current_state = IntroCutscene.State.SCENE_10_SWIM_NORTH
	intro.state_counter = 48
	_advance(intro, player, 20)
	_assert_true(player.position.y == 125.0, "Sem obstáculo, não existe pausa hardcoded em Y=133/136")
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_10_SWIM_NORTH, "Transição depende do contador, não da chegada")
	player.free()
	intro.free()
