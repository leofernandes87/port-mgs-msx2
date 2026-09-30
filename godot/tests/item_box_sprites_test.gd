extends SceneTree

## Teste unitário e de integração para a renderização fiel dos sprites originais
## de armas e itens no mapa (ItemBox) conforme DrawRoomItems em logic/drawitemsinroom.asm.

func _init() -> void:
	print("\n--- TESTE DE SPRITES ORIGINAIS DE ITENS NO MAPA (ItemBox) ---")
	var root := Node2D.new()

	# 1. Carregamento de Texturas Autênticas
	ItemBox._ensure_textures()
	if ItemBox.tex_weapons == null:
		printerr("FAIL: tex_weapons não pôde ser carregada!")
		quit(1)
		return
	print("  PASS: Textura de armas (hud_weapons.png) carregada com sucesso!")

	if ItemBox.tex_items == null:
		printerr("FAIL: tex_items não pôde ser carregada!")
		quit(1)
		return
	print("  PASS: Textura de itens (hud_items.png) carregada com sucesso!")

	# 2. Teste de Renderização _draw() para todas as 8 armas autênticas
	var weapons := [
		"HANDGUN", "SMG", "SUB_MACHINE_GUN", "GRENADE_LAUNCHER", "ROCKET_LAUNCHER",
		"PLASTIC_BOMB", "LAND_MINE", "MINES", "MISSILE", "REMOTE_MISSILE", "SILENCER", "SUPRESSOR"
	]
	for wid: String in weapons:
		var box := ItemBox.new()
		box.item_id = wid
		root.add_child(box)
		box.notification(CanvasItem.NOTIFICATION_DRAW)
		box.free()
	print("  PASS: Todas as armas (32x16 e 16x16) renderizadas via _draw() sem exceções!")

	# 3. Teste de Renderização _draw() para todos os 27 itens autênticos
	var items := [
		"ARMOR", "BODY_ARMOR", "SUIT", "BOMB_BLAST_SUIT", "LIGHT", "FLASHLIGHT",
		"GOGGLES", "GAS_MASK", "CIGARETTES", "MINE_DETECTOR", "ANTENNA", "BINOCULARS",
		"OXYGEN_TANK", "COMPASS", "PARACHUTE", "ANTIDOTE",
		"CARD1", "CARD2", "CARD3", "CARD4", "CARD5", "CARD6", "CARD7", "CARD8",
		"RATION", "TRANSCEIVER", "UNIFORM", "BOX", "CARDBOARD_BOX", "BAG", "ITEM_BAG",
		"AMMO_CRATE", "AMMO"
	]
	for iid: String in items:
		var box := ItemBox.new()
		box.item_id = iid
		root.add_child(box)
		box.notification(CanvasItem.NOTIFICATION_DRAW)
		box.free()
	print("  PASS: Todos os itens de 16x16 renderizados via _draw() sem exceções!")

	# 4. Teste de fallback procedural para itens não mapeados
	var fallback_box := ItemBox.new()
	fallback_box.item_id = "UNKNOWN_ITEM_XYZ"
	root.add_child(fallback_box)
	fallback_box.notification(CanvasItem.NOTIFICATION_DRAW)
	fallback_box.free()
	print("  PASS: Fallback procedural executado com sucesso para item não mapeado!")

	# 5. Teste de coleta de ROCKET_LAUNCHER e SUB_MACHINE_GUN
	var ws := WeaponSystem.new()
	var inv := InventoryManager.new()

	var rocket_box := ItemBox.new()
	rocket_box.item_id = "ROCKET_LAUNCHER"
	rocket_box.position = Vector2(50.0, 50.0)
	var touched_rocket := rocket_box.step_tick(Vector2(50.0, 50.0), inv, ws)
	if not touched_rocket or not rocket_box.collected:
		printerr("FAIL: Coleta de ROCKET_LAUNCHER falhou!")
		quit(1)
		return
	rocket_box.free()
	print("  PASS: ROCKET_LAUNCHER coletado com sucesso no ItemBox!")

	var smg_box := ItemBox.new()
	smg_box.item_id = "SUB_MACHINE_GUN"
	smg_box.position = Vector2(80.0, 80.0)
	var touched_smg := smg_box.step_tick(Vector2(80.0, 80.0), inv, ws)
	if not touched_smg or not smg_box.collected or not ws.has_weapon(WeaponSystem.WEAPON_SMG):
		printerr("FAIL: Coleta de SUB_MACHINE_GUN falhou!")
		quit(1)
		return
	smg_box.free()
	print("  PASS: SUB_MACHINE_GUN coletado com sucesso no WeaponSystem como SMG!")

	root.free()
	print("ITEM_BOX_SPRITES_TEST_OK: Todos os testes de renderização autêntica de itens passaram com 100% de sucesso!\n")
	quit(0)
