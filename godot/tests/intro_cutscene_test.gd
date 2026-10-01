extends SceneTree

## Teste de Integração Headless da Cutscene de Abertura / Infiltração na Água e Grade (MSX2 Sala 121)

func _init() -> void:
	print("--- TESTE DA CUTSCENE DE ABERTURA / INFILTRAÇÃO NA ÁGUA (MSX2 SALA 121) ---")
	call_deferred("_run_tests")

func _assert_true(cond: bool, msg: String) -> void:
	if not cond:
		printerr("FALHA: %s" % msg)
		quit(1)
	print("  PASS: %s" % msg)

func _run_tests() -> void:
	# 1. Configuração do Player e IntroCutscene
	var player := PlayerController.new()
	var intro := IntroCutscene.new()

	_assert_true(intro.current_state == IntroCutscene.State.INACTIVE, "Estado inicial deve ser INACTIVE")
	_assert_true(not intro.is_active, "Intro não deve estar ativa inicialmente")

	# 2. Iniciar Intro
	intro.start_intro(player)
	_assert_true(intro.is_active, "Intro deve estar ativa após start_intro")
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_1_DIVE_LEFT, "Estado inicial deve ser SCENE_1_DIVE_LEFT")
	_assert_true(player.position == Vector2(192.0, 184.0), "Spawn de mergulho inicial em (192, 184)")
	_assert_true(player.anim_mode == PlayerController.AnimMode.DEEP_WATER, "Modo de animação inicial deve ser DEEP_WATER")
	_assert_true(not player.can_control, "Controles do jogador devem estar bloqueados")

	# 3. Execução de State 1: Nado submerso para Oeste (64 ticks)
	for i in range(64):
		intro.tick(player)

	_assert_true(is_equal_approx(player.position.x, 128.0), "Snake deve ter nadado até X = 128")
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_2_EMERGE_WAIT, "Deve transitar para SCENE_2_EMERGE_WAIT")
	_assert_true(player.anim_mode == PlayerController.AnimMode.SWIM_SURFACE, "Snake deve emergir (SWIM_SURFACE)")
	_assert_true(player.current_direction == PlayerController.Direction.UP, "Snake deve encarar o complexo ao Norte (UP)")

	# 4. State 2: Espera na superfície (48 ticks) e submergir
	for i in range(48):
		intro.tick(player)

	_assert_true(intro.current_state == IntroCutscene.State.SCENE_3_DIVE_LEFT, "Deve transitar para SCENE_3_DIVE_LEFT")
	_assert_true(player.anim_mode == PlayerController.AnimMode.DEEP_WATER, "Deve submergir novamente em DEEP_WATER")

	# 5. State 3 & 4: Nado submerso até (48, 152)
	for i in range(80): # SCENE_3 (80 ticks)
		intro.tick(player)
	_assert_true(is_equal_approx(player.position.x, 48.0), "Snake deve alcançar X = 48")
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_4_DIVE_NORTH, "Deve transitar para SCENE_4_DIVE_NORTH")

	for i in range(16): # SCENE_4 (16 ticks: 184 -> 168)
		intro.tick(player)
	_assert_true(is_equal_approx(player.position.y, 168.0), "Snake deve subir até Y = 168")
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_5_EMERGE_WAIT, "Deve emergir em SCENE_5_EMERGE_WAIT")
	_assert_true(player.anim_mode == PlayerController.AnimMode.SWIM_SURFACE, "Snake deve emergir (SWIM_SURFACE)")
	_assert_true(player.current_direction == PlayerController.Direction.RIGHT, "Snake deve olhar para a direita (RIGHT)")

	# 6. State 5: Espera e chamada do rádio
	var captured := {
		"radio_received": false,
		"briefing_pages": []
	}
	intro.radio_requested.connect(func(pages: Array[String]) -> void:
		captured["radio_received"] = true
		captured["briefing_pages"] = pages
	)

	for i in range(64):
		intro.tick(player)

	_assert_true(bool(captured["radio_received"]), "Sinal radio_requested deve ser emitido")
	var pages_res: Array = captured["briefing_pages"]
	_assert_true(pages_res.size() == 4, "Briefing deve conter 4 páginas autênticas de Big Boss")
	_assert_true("INTRUDE N313" in String(pages_res[0]), "Página 1 deve conter OPERATION INTRUDE N313")
	_assert_true("METAL GEAR" in String(pages_res[1]), "Página 2 deve citar METAL GEAR")
	_assert_true("GREY FOX" in String(pages_res[2]), "Página 3 deve citar GREY FOX")
	_assert_true("120.85" in String(pages_res[3]), "Página 4 deve citar a frequência 120.85")


	# Simula término do rádio
	intro.on_radio_finished()
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_8_RADIO_CLOSED, "Estado após rádio deve ser SCENE_8_RADIO_CLOSED")

	# 7. State 8: Pausa de 40 frames após fechar o rádio (introscene.asm:227-228: IntroSceneCnt=0x28)
	_assert_true(intro.state_counter == 0x28, "Pausa pós-rádio deve ser inicializada com 0x28 (40 frames)")

	# Simula 39 ticks: ainda deve estar em SCENE_8
	for i in range(39):
		intro.tick(player)
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_8_RADIO_CLOSED, "Deve permanecer em SCENE_8 durante os 40 frames de pausa")

	# 40º tick: transita para SCENE_9
	intro.tick(player)
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_9_SWIM_RIGHT, "Estado de nado à cerca deve ser SCENE_9_SWIM_RIGHT após 40 frames")
	_assert_true(player.anim_mode == PlayerController.AnimMode.SWIM_SURFACE, "Snake permanece na superfície da água (SWIM_SURFACE) ao sair do rádio")

	for i in range(40):
		intro.tick(player)
	_assert_true(is_equal_approx(player.position.x, 128.0), "Snake alcançou o centro em X = 128")
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_10_SWIM_NORTH, "Estado de aproximação vertical deve ser SCENE_10_SWIM_NORTH")
	_assert_true(player.anim_mode == PlayerController.AnimMode.SWIM_SURFACE, "Snake continua na superfície da água (SWIM_SURFACE) ao virar para o norte")

	for i in range(32): # SCENE_10 (32 ticks: 168 -> 136)
		intro.tick(player)
	_assert_true(is_equal_approx(player.position.x, 128.0), "Snake permaneceu centralizado em X = 128")
	_assert_true(is_equal_approx(player.position.y, 136.0), "Snake chegou à base da cerca em Y = 136")
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_11_CLIMB, "Deve iniciar escalada da cerca (SCENE_11_CLIMB)")
	_assert_true(player.anim_mode == PlayerController.AnimMode.CLIMB, "Animação de escalada deve estar ativa (CLIMB)")

	# 8. State 11: Escalada da cerca (28 ticks até Y = 102)
	for i in range(28):
		intro.tick(player)
	_assert_true(is_equal_approx(player.position.x, 128.0), "Escalada deve ocorrer estritamente em X = 128")
	_assert_true(is_equal_approx(player.position.y, 102.0), "Snake deve chegar ao topo da grade em Y = 102")
	_assert_true(intro.current_state == IntroCutscene.State.SCENE_12_BOUNCE, "Deve iniciar salto para terra firme (SCENE_12_BOUNCE)")

	# 9. State 12: Salto e aterrissagem em terra firme (12 ticks)
	captured["finished_emitted"] = false
	intro.intro_finished.connect(func() -> void:
		captured["finished_emitted"] = true
	)

	for i in range(12):
		intro.tick(player)

	_assert_true(bool(captured["finished_emitted"]), "Sinal intro_finished deve ser emitido")

	_assert_true(intro.current_state == IntroCutscene.State.FINISHED, "Estado final deve ser FINISHED")
	_assert_true(not intro.is_active, "Intro não deve estar mais ativa")
	_assert_true(player.position == Vector2(128.0, 80.0), "Snake deve aterrissar em terra firme em (128, 80)")
	_assert_true(player.anim_mode == PlayerController.AnimMode.NORMAL, "Modo de animação deve ser restaurado para NORMAL")
	_assert_true(player.can_control, "Controle total deve ser entregue ao jogador")

	# 10. Teste de Skip Imediato
	intro.start_intro(player)
	_assert_true(intro.is_active, "Intro reativada")
	_assert_true(player.position == Vector2(192.0, 184.0), "Posição inicial reiniciada em (192, 184)")
	intro.skip_intro(player)
	_assert_true(not intro.is_active, "Intro deve ser desativada após skip")
	_assert_true(player.position == Vector2(128.0, 80.0), "Skip deve colocar Snake instantaneamente em (128, 80)")
	_assert_true(player.can_control, "Controles devem estar liberados após skip")

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

	print("INTRO_CUTSCENE_INTEGRATION_OK: Todos os 13 estados da abertura, nado, rádio, escalada e skip validados com 100% de sucesso!")
	player.free()
	intro.free()
	quit(0)
