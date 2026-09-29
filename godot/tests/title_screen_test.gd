extends SceneTree
## Teste de integração headless da cena de abertura e tela de título (Etapa 4/5).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/title_screen.tscn") as PackedScene
	if packed == null:
		_fail("Falha ao carregar res://scenes/title_screen.tscn")
		return

	var scene: Control = packed.instantiate() as Control
	if scene == null:
		_fail("Instância de TitleScreen não é Control")
		return

	root.add_child(scene)
	await process_frame

	# 1. Validação de texturas
	if scene.get("tex_konami_ribbon") == null:
		_fail("tex_konami_ribbon não foi carregada")
		return
	if scene.get("tex_metalgear_logo") == null:
		_fail("tex_metalgear_logo não foi carregada")
		return
	if scene.get("tex_copyright") == null:
		_fail("tex_copyright não foi carregada")
		return
	if scene.get("tex_press_start") == null:
		_fail("tex_press_start não foi carregada")
		return
	if scene.get("tex_push_space") == null:
		_fail("tex_push_space não foi carregada")
		return
	if scene.get("tex_play_start") == null:
		_fail("tex_play_start não foi carregada")
		return

	print("TITLE_SCREEN_TEXTURES_OK: Todas as 6 texturas protegidas foram carregadas!")

	# 2. Estado inicial
	var state: int = scene.get("current_state")
	if state != 0: # State.KONAMI_WIPE
		_fail("Estado inicial não é KONAMI_WIPE (esperado 0, obtido %d)" % state)
		return

	# 3. Teste de avanço/skip de corte
	scene.call("_handle_action_press")
	await process_frame

	state = scene.get("current_state")
	if state != 3: # State.TITLE_IDLE
		_fail("Skip no logo da Konami deveria levar direto a TITLE_IDLE (esperado 3, obtido %d)" % state)
		return
	print("TITLE_SCREEN_SKIP_OK: Skip de introdução levou direto a TITLE_IDLE!")

	# 4. Alternância de prompt PRESS START / PUSH SPACE
	var initial_prompt: bool = scene.get("use_press_start_prompt")
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_T
	key_event.pressed = true
	scene._unhandled_input(key_event)
	if scene.get("use_press_start_prompt") == initial_prompt:
		_fail("Tecla T deveria alternar use_press_start_prompt")
		return
	print("TITLE_SCREEN_PROMPT_TOGGLE_OK: Alternância entre PRESS START e PUSH SPACE funciona!")

	# 5. Confirmação Play Start
	scene.call("_handle_action_press")
	await process_frame
	state = scene.get("current_state")
	if state != 4: # State.PLAY_START
		_fail("Acionamento em TITLE_IDLE deveria entrar em PLAY_START (esperado 4, obtido %d)" % state)
		return
	print("TITLE_SCREEN_PLAY_START_OK: Estado de confirmação PLAY_START ativo com sucesso!")

	scene.queue_free()
	await process_frame
	print("TITLE_SCREEN_INTEGRATION_OK: Abertura e tela de título validadas com sucesso!")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
