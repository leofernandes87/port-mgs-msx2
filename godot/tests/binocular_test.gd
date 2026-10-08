extends SceneTree
## Suíte de testes headless — Sistema de Binóculo / Telescópio (TELESCOPE MODE)
## Valida a mecânica autêntica revertida de logic/menuequipment.asm:295-361 e Banks0123.asm:12250-12604
## Token de conclusão: BINOCULARS_TEST_OK

var _pass: int = 0
var _fail: int = 0

func _initialize() -> void:
	_run_all()
	var result: String = "BINOCULARS_TEST_OK: %d testes passaram, %d falharam" % [_pass, _fail]
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
	print("--- Binoculars / Telescope Mode Tests ---")
	_test_binoculars_isolated_rooms()
	_test_binoculars_activation_and_blocking()
	_test_binoculars_look_direction_and_timer()
	_test_binoculars_timer_countdown_and_auto_return()
	_test_binoculars_blocked_direction()
	_test_binoculars_deactivation()
	_test_binoculars_overlay()
	_test_item_menu_and_inventory_constants()
	_test_binoculars_sandbox_exit_input()

## Teste 1: Regras canônicas de salas isoladas (ChkIsolatedRoom em Banks0123.asm:1030)
func _test_binoculars_isolated_rooms() -> void:
	# Salas normais de patrulha (permitidas)
	_assert(not BinocularSystem.is_room_isolated(0), "Sala 000 (Entrada / Início) permite binóculo")
	_assert(not BinocularSystem.is_room_isolated(1), "Sala 001 (Pátio sul) permite binóculo")
	_assert(not BinocularSystem.is_room_isolated(2), "Sala 002 (Pátio portão) permite binóculo")
	_assert(not BinocularSystem.is_room_isolated(7), "Sala 007 (Pátio dos 3 caminhões) permite binóculo")

	# Caminhões (isolados na ROM)
	_assert(BinocularSystem.is_room_isolated(126), "Caminhão 126 é isolado")
	_assert(BinocularSystem.is_room_isolated(127), "Caminhão 127 é isolado")
	_assert(BinocularSystem.is_room_isolated(128), "Caminhão 128 é isolado")
	_assert(BinocularSystem.is_room_isolated(130), "Caminhão 130 (Sala 7 - mina terrestre) é isolado")
	_assert(BinocularSystem.is_room_isolated(131), "Caminhão 131 (Sala 7 - vazio) é isolado")
	_assert(BinocularSystem.is_room_isolated(132), "Caminhão 132 (Sala 7 - emboscada) é isolado")

	# Elevadores (F0h - FAh na ROM, IDs 240 a 250)
	_assert(BinocularSystem.is_room_isolated(240), "Cabine do elevador 240 é isolada")
	_assert(BinocularSystem.is_room_isolated(245), "Cabine do elevador 245 é isolada")
	_assert(BinocularSystem.is_room_isolated(250), "Cabine do elevador 250 é isolada")

	# Salas de itens isoladas
	_assert(BinocularSystem.is_room_isolated(147), "Sala interna 147 é isolada")
	_assert(BinocularSystem.is_room_isolated(185), "Sala interna 185 é isolada")

## Teste 2: Ativação e bloqueio de uso
func _test_binoculars_activation_and_blocking() -> void:
	var bino: BinocularSystem = BinocularSystem.new()
	_assert(not bino.is_active, "Inicia inativo")
	_assert(bino.state == BinocularSystem.State.INACTIVE, "Estado inicial é INACTIVE")

	# Tentativa em sala isolada (deve falhar)
	var blocked: bool = bino.activate(130)
	_assert(not blocked, "Ativação no caminhão 130 deve falhar")
	_assert(not bino.is_active, "Permanece inativo após tentativa bloqueada")

	# Ativação em sala permitida (deve ter sucesso)
	var ok: bool = bino.activate(1)
	_assert(ok, "Ativação na Sala 001 tem sucesso")
	_assert(bino.is_active, "is_active é true")
	_assert(bino.state == BinocularSystem.State.IDLE, "Estado muda para IDLE")
	_assert(bino.home_room_id == 1, "home_room_id gravado como 1")
	_assert(bino.preview_room_id == 1, "preview_room_id inicial é 1")

## Teste 3: Observação direcional e temporizador canônico de 128 ticks (80h)
func _test_binoculars_look_direction_and_timer() -> void:
	var bino: BinocularSystem = BinocularSystem.new()
	bino.activate(1)

	# Observar para CIMA (Norte) a partir da Sala 1 -> Sala 2
	var target: int = bino.look_direction(PlayerController.Direction.UP)
	_assert(target == 2, "Olhar para CIMA na Sala 1 revela Sala 2")
	_assert(bino.state == BinocularSystem.State.LOOKING, "Estado agora é LOOKING")
	_assert(bino.preview_room_id == 2, "preview_room_id é 2")
	_assert(bino.looking_direction == int(PlayerController.Direction.UP), "looking_direction é UP")
	_assert(bino.preview_timer == BinocularSystem.PREVIEW_DURATION_TICKS, "Temporizador inicial é 128 ticks (80h na ROM)")

	# Enquanto estiver em LOOKING, outras direções não interrompem
	var re_look: int = bino.look_direction(PlayerController.Direction.DOWN)
	_assert(re_look == -1, "Comandos adicionais ignorados enquanto LOOKING")
	_assert(bino.preview_room_id == 2, "Permanece observando a Sala 2")

## Teste 4: Contagem do temporizador e retorno automático à sala de origem
func _test_binoculars_timer_countdown_and_auto_return() -> void:
	var bino: BinocularSystem = BinocularSystem.new()
	bino.activate(1)
	bino.look_direction(PlayerController.Direction.UP)

	# Executa 127 ticks
	for _i in range(127):
		var res: Dictionary = bino.step_tick()
		_assert(not res["returned_home"], "Ainda não retornou no tick intermediário")
		_assert(res["state"] == BinocularSystem.State.LOOKING, "Ainda em modo LOOKING")

	_assert(bino.preview_timer == 1, "Resta exatamente 1 tick")

	# 128º tick: término do temporizador e retorno automático (Banks0123.asm:12513-12515)
	var final_res: Dictionary = bino.step_tick()
	_assert(final_res["returned_home"] == true, "128º tick dispara retorno automático")
	_assert(bino.state == BinocularSystem.State.IDLE, "Retorna ao estado IDLE")
	_assert(bino.preview_room_id == 1, "preview_room_id volta a ser a home_room (1)")
	_assert(bino.home_room_id == 1, "home_room_id preservado (1)")
	_assert(bino.is_active == true, "Binóculo continua ativo aguardando nova direção ou saída")

## Teste 5: Direção bloqueada (sem sala conectada)
func _test_binoculars_blocked_direction() -> void:
	var bino: BinocularSystem = BinocularSystem.new()
	bino.activate(1)

	# Sala 1 não possui saída para ESQUERDA (NO_ROOM = 255)
	var next_left: int = RoomManager.get_next_room(1, PlayerController.Direction.LEFT)
	_assert(next_left == RoomManager.NO_ROOM, "Sala 1 tem borda esquerda bloqueada")

	var target: int = bino.look_direction(PlayerController.Direction.LEFT)
	_assert(target == -1, "look_direction para borda sem sala retorna -1")
	_assert(bino.state == BinocularSystem.State.IDLE, "Permanece no estado IDLE")
	_assert(bino.preview_room_id == 1, "preview_room_id continua sendo 1")

## Teste 6: Desativação do binóculo
func _test_binoculars_deactivation() -> void:
	var bino: BinocularSystem = BinocularSystem.new()
	bino.activate(1)
	bino.look_direction(PlayerController.Direction.DOWN)
	_assert(bino.is_active, "Ativo")

	bino.deactivate()
	_assert(not bino.is_active, "is_active é false após deactivate()")
	_assert(bino.state == BinocularSystem.State.INACTIVE, "Estado volta a INACTIVE")
	_assert(bino.home_room_id == -1, "home_room_id resetado")
	_assert(bino.preview_room_id == -1, "preview_room_id resetado")

## Teste 7: Overlay visual do binóculo
func _test_binoculars_overlay() -> void:
	var overlay: BinocularOverlay = BinocularOverlay.new()
	_assert(not overlay.visible, "Overlay inicia invisível")

	overlay.update_state(true, BinocularSystem.State.IDLE, -1, 1, 1)
	_assert(overlay.visible, "Overlay fica visível quando ativo")
	_assert(overlay.title_label.text == "TELESCOPE MODE", "Título TELESCOPE MODE autêntico")
	_assert("OBSERVAR" in overlay.subtitle_label.text, "Instruções exibidas no subtítulo em IDLE")

	overlay.update_state(true, BinocularSystem.State.LOOKING, int(PlayerController.Direction.UP), 2, 1)
	_assert("SALA 002" in overlay.subtitle_label.text, "Subtítulo indica Sala 002 sendo observada")
	_assert("NORTE" in overlay.subtitle_label.text, "Subtítulo indica direção NORTE")

	overlay.update_state(false, BinocularSystem.State.INACTIVE, -1, -1, -1)
	_assert(not overlay.visible, "Overlay volta a ficar invisível quando inativo")
	overlay.free()

## Teste 8: Constantes do inventário e integração com ItemMenu
func _test_item_menu_and_inventory_constants() -> void:
	_assert(InventoryManager.ITEM_BINOCULARS == "BINOCULARS", "Constante ITEM_BINOCULARS definida")

	var inv: InventoryManager = InventoryManager.new()
	inv.items.append(InventoryManager.ITEM_BINOCULARS)
	_assert(inv.select_item(InventoryManager.ITEM_BINOCULARS), "Binóculo selecionável no inventário")
	_assert(inv.get_selected_item() == "BINOCULARS", "Item atual é BINOCULARS")

## Teste 9: Fechamento via teclas E e ESC no Sandbox
func _test_binoculars_sandbox_exit_input() -> void:
	var sandbox = preload("res://scripts/scenes/sandbox_gameplay.gd").new()
	sandbox._ready()
	sandbox.inventory.items.append(InventoryManager.ITEM_BINOCULARS)
	sandbox.inventory.select_item(InventoryManager.ITEM_BINOCULARS)

	# Abre binóculo na Sala inicial
	var opened: bool = sandbox.open_binoculars()
	_assert(opened, "Binóculo aberto no sandbox")
	_assert(sandbox.binocular_system.is_active, "binocular_system.is_active é true")
	_assert(not sandbox.player.can_control, "player.can_control é false durante binóculo")

	# Simula pressionar tecla E
	var event_e := InputEventKey.new()
	event_e.keycode = KEY_E
	event_e.pressed = true
	sandbox._input(event_e)

	_assert(not sandbox.binocular_system.is_active, "Tecla E fecha o binóculo com sucesso")
	_assert(sandbox.player.can_control, "player.can_control restaurado após tecla E")
	_assert(sandbox.player.visible, "player.visible restaurado após tecla E")

	# Abre novamente e testa ESC
	sandbox.open_binoculars()
	_assert(sandbox.binocular_system.is_active, "Binóculo reaberto")
	var event_esc := InputEventKey.new()
	event_esc.keycode = KEY_ESCAPE
	event_esc.pressed = true
	sandbox._input(event_esc)

	_assert(not sandbox.binocular_system.is_active, "Tecla ESC fecha o binóculo com sucesso")
	_assert(sandbox.player.can_control, "player.can_control restaurado após tecla ESC")

	# Abre novamente, olha para uma direção válida (UP conecta à Sala 0 a partir da 121)
	sandbox.open_binoculars()
	sandbox._binocular_look(PlayerController.Direction.UP)
	_assert(sandbox.binocular_system.state == BinocularSystem.State.LOOKING, "Em modo LOOKING")
	sandbox._input(event_e)
	_assert(not sandbox.binocular_system.is_active, "Tecla E fecha binóculo mesmo durante LOOKING")
	_assert(sandbox.player.can_control, "player.can_control restaurado após fechar de LOOKING")

	sandbox.free()

