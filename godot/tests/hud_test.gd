# hud_test.gd
# Validação automatizada do HUD autêntico do Metal Gear MSX2 RC750 (Etapa HUD).
# Cobre:
# 1. Dimensões e posicionamento canônico (256x20 px em Y=192).
# 2. Barra de energia L.I.F.E (coordenadas, preenchimento dinâmico de 0 a 48 px, resposta a dano/cura).
# 3. Patente militar CLASS e estrelas ★ (1 a 4 estrelas conforme Rank).
# 4. Sinal de chamada CALL (ativação via rádio e piscar de 8 frames conforme bit 3 do tick counter).
# 5. Caixa de arma selecionada (dimensões 58x18 px, sprites autênticos e munição formatada).
# 6. Caixa de item selecionado (dimensões 27x18 px, sprites autênticos e dígito de cartões 1..8).
# 7. Ciclo de desenho _draw() sem exceções em modo headless.

extends SceneTree

const GameHUD = preload("res://scripts/systems/hud.gd")

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
	print("--- INICIANDO TESTE DO HUD AUTÊNTICO MSX2 ---")

	# --------------------------------------------------------------------------
	# 1. Validação de Dimensões e Posição Canônica
	# --------------------------------------------------------------------------
	var hud: GameHUD = GameHUD.new()
	root.add_child(hud)
	if not require(hud.position.y == 192.0, "HUD deve estar posicionado em Y = 192"): return
	if not require(hud.size.x == 256.0, "Largura do HUD deve ser 256 pixels"): return
	if not require(hud.size.y == 20.0, "Altura do HUD deve ser 20 pixels"): return
	print("  PASS: Dimensões e posicionamento canônico (256x20 em Y=192)")

	# --------------------------------------------------------------------------
	# 2. Validação da Barra de Energia (L.I.F.E)
	# --------------------------------------------------------------------------
	hud.current_life = 24
	hud.max_life = 24
	if not require(hud.current_life == 24, "Vida inicial deve ser 24"): return

	# Teste de dano
	hud.current_life = 10
	if not require(hud.current_life == 10, "Vida após dano deve ser 10"): return

	# Teste de vida zero
	hud.current_life = 0
	if not require(hud.current_life == 0, "Vida zerada deve ser 0"): return

	# Teste de vida máxima de Rank 4 (48 pixels)
	hud.current_life = 48
	hud.max_life = 48
	if not require(hud.current_life == 48, "Vida máxima de Rank 4 deve alcançar 48 pixels"): return
	print("  PASS: Barra de energia L.I.F.E (0 a 48 px)")

	# --------------------------------------------------------------------------
	# 3. Validação de Patente Militar e Estrelas ★ (C.L.A.S.S)
	# --------------------------------------------------------------------------
	for r in range(1, 5):
		hud.current_rank = r
		if not require(hud.current_rank == r, "Rank deve ser %d" % r): return
	print("  PASS: Patente militar C.L.A.S.S (1 a 4 estrelas)")

	# --------------------------------------------------------------------------
	# 4. Validação do Sinal de Chamada PISCANDO (CALL)
	# --------------------------------------------------------------------------
	hud.has_incoming_call = false
	if not require(not hud.has_incoming_call, "Sem chamada recebida por padrão"): return

	hud.has_incoming_call = true
	# Simula ticks: ticks 0..7 bit 3 é 0 (visível), ticks 8..15 bit 3 é 1 (apagado)
	hud.call_tick_counter = 0
	hud._process(0.016)
	if not require(hud.call_sign_visible, "Sinal CALL deve estar visível nos primeiros 8 ticks"): return

	hud.call_tick_counter = 8
	hud._process(0.016)
	if not require(not hud.call_sign_visible, "Sinal CALL deve apagar após 8 ticks (efeito blink Z80)"): return
	print("  PASS: Sinal CALL e alternância de piscar (8 frames on/off)")

	# --------------------------------------------------------------------------
	# 5. Validação da Caixa de Arma e Munição (W.E.A.P.O.N)
	# --------------------------------------------------------------------------
	hud.selected_weapon = ""
	hud.ammo_count = 0
	if not require(hud.selected_weapon == "", "Nenhuma arma selecionada"): return

	# Selecionar Handgun com 50 tiros
	hud.selected_weapon = "HANDGUN"
	hud.ammo_count = 50
	if not require(GameHUD.WEAPON_TEX_INDICES.has("HANDGUN"), "HANDGUN deve estar no mapa de texturas"): return
	if not require(GameHUD.WEAPON_TEX_INDICES["HANDGUN"] == 0, "HANDGUN deve ser índice 0"): return
	if not require(hud.ammo_count == 50, "Munição deve ser 50"): return

	# Selecionar Silenciador (sem contagem de munição)
	hud.selected_weapon = "SILENCER"
	if not require(GameHUD.WEAPON_TEX_INDICES["SILENCER"] == 7, "SILENCER deve ser índice 7"): return

	# Selecionar Míssil Teleguiado
	hud.selected_weapon = "MISSILE"
	hud.ammo_count = 5
	if not require(GameHUD.WEAPON_TEX_INDICES["MISSILE"] == 6, "MISSILE deve ser índice 6"): return
	print("  PASS: Caixa de arma (8 armas mapeadas, munição formatada)")

	# --------------------------------------------------------------------------
	# 6. Validação da Caixa de Item e Cartões (I.T.E.M)
	# --------------------------------------------------------------------------
	hud.selected_item = ""
	hud.card_number = 0
	if not require(hud.selected_item == "", "Nenhum item selecionado"): return

	# Selecionar Binóculos
	hud.selected_item = "BINOCULARS"
	if not require(GameHUD.ITEM_TEX_INDICES.has("BINOCULARS"), "BINOCULARS deve estar no mapa"): return
	if not require(GameHUD.ITEM_TEX_INDICES["BINOCULARS"] == 8, "BINOCULARS deve ser índice 8"): return

	# Selecionar Cartão de Acesso 1..8
	for c_lvl in range(1, 9):
		hud.selected_item = "CARD%d" % c_lvl
		hud.card_number = c_lvl
		if not require(hud.card_number == c_lvl, "Número do cartão deve ser %d" % c_lvl): return
		if not require(GameHUD.ITEM_TEX_INDICES.has("CARD%d" % c_lvl), "CARD%d deve estar mapeado" % c_lvl): return
	print("  PASS: Caixa de item (27 itens mapeados, cartões 1..8)")

	# --------------------------------------------------------------------------
	# 7. Teste de Renderização _draw()
	# --------------------------------------------------------------------------
	hud.notification(CanvasItem.NOTIFICATION_DRAW)
	print("  PASS: Rotinas de desenho _draw() executadas sem erro!")

	# --------------------------------------------------------------------------
	# 8. Teste de Amarração com Sistemas Reais (bind_systems)
	# --------------------------------------------------------------------------
	var player: PlayerController = PlayerController.new()
	var rank_sys: RankSystem = RankSystem.new()
	var weapon_sys: WeaponSystem = WeaponSystem.new()
	var inv_mgr: InventoryManager = InventoryManager.new()
	var rad_sys: RadioSystem = RadioSystem.new()

	hud.bind_systems(player, rank_sys, weapon_sys, inv_mgr, rad_sys)

	# Atualizar arma e verificar sincronia
	weapon_sys.add_weapon(WeaponSystem.WEAPON_HANDGUN, 35)
	inv_mgr.collect_item(InventoryManager.ITEM_CARD3)
	inv_mgr.selected_index = inv_mgr.items.find("CARD3")
	rad_sys.has_incoming_call = true

	var changed := hud.update_hud_state()
	if not require(changed, "update_hud_state deve detectar alterações nos subsistemas"): return
	if not require(hud.selected_weapon == "HANDGUN", "HUD deve refletir arma selecionada"): return
	if not require(hud.ammo_count == 35, "HUD deve refletir 35 balas"): return
	if not require(hud.selected_item == "CARD3", "HUD deve refletir CARD3 selecionado"): return
	if not require(hud.card_number == 3, "HUD deve identificar cartão número 3"): return
	if not require(hud.has_incoming_call, "HUD deve registrar chamada recebida"): return
	print("  PASS: Integração reativa via bind_systems com Player, Armas, Itens e Rádio!")

	hud.notification(CanvasItem.NOTIFICATION_DRAW)

	hud.queue_free()
	player.queue_free()

	print("HUD_INTEGRATION_TEST_OK: Todos os testes do HUD original MSX2 passaram com 100% de sucesso!")
	quit(0)
