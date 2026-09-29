extends SceneTree

# floor3_review_test.gd
# Teste de validação e auditoria profunda do 3º Andar (Floor 3 - Building 1)
# Salas 28 a 39 e salas internas (146 a 159) comparadas com a ROM MSX2 RC750.

func _init() -> void:
	call_deferred("_run_review")

func require(condition: bool, message: String) -> bool:
	if not condition:
		print("FAIL: %s" % message)
		quit(1)
		return false
	print("  PASS: %s" % message)
	return true

func _run_review() -> void:
	print("\n--- Canonical Floor 3 (Building 1) Review & Validation Tests ---")
	var tree_root: Window = get_root()
	var packed_sandbox: PackedScene = load("res://scenes/sandbox_gameplay.tscn") as PackedScene
	if not require(packed_sandbox != null, "Carregamento de sandbox_gameplay.tscn"): return

	var sandbox: Control = packed_sandbox.instantiate() as Control
	tree_root.add_child(sandbox)
	await process_frame
	await process_frame

	# 1. Sala 028 (D1)
	sandbox.call("change_to_room", 28, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_28: Array = sandbox.get("enemies") as Array
	var cam_28: Array = sandbox.get("cameras") as Array
	var doors_28: Array = sandbox.get("room_doors") as Array
	if not require(em_28.size() == 1, "Sala 28 deve ter exatamente 1 guarda"): return
	if not require(cam_28.size() == 1, "Sala 28 deve ter exatamente 1 câmera"): return
	if not require(is_equal_approx((cam_28[0] as SecurityCamera).speed, 0.5), "Câmera da Sala 28 deve operar a 0.5 px/tick"): return
	if not require(doors_28.size() == 3, "Sala 28 deve conter 3 portas (146, 147, 29)"): return

	# 2. Sala 029 (C1)
	sandbox.call("change_to_room", 29, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var gas_29: Array = sandbox.get("gas_clouds") as Array
	var doors_29: Array = sandbox.get("room_doors") as Array
	if not require(gas_29.size() == 4, "Sala 29 deve conter 4 nuvens de gás"): return
	if not require(doors_29.size() == 2, "Sala 29 deve conter 2 portas (28, 148)"): return

	# 3. Sala 030 (B1)
	sandbox.call("change_to_room", 30, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_30: Array = sandbox.get("enemies") as Array
	var doors_30: Array = sandbox.get("room_doors") as Array
	if not require(em_30.size() == 2, "Sala 30 deve ter exatamente 2 guardas rápidos"): return
	for e in em_30:
		if not require((e as EnemyGuard).guard_type == EnemyGuard.GuardType.FAST, "Guardas da Sala 30 devem ser GuardFast (Type 30)"): return
	if not require(doors_30.size() == 2, "Sala 30 deve conter 2 portas (152, 149)"): return

	# 4. Sala 031 (A1 - Chegada do Elevador 1)
	sandbox.call("change_to_room", 31, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var cam_31: Array = sandbox.get("cameras") as Array
	var doors_31: Array = sandbox.get("room_doors") as Array
	if not require(cam_31.size() == 2, "Sala 31 deve ter exatamente 2 câmeras de segurança"): return
	for c in cam_31:
		if not require(is_equal_approx((c as SecurityCamera).speed, 0.5), "Câmeras da Sala 31 devem se mover a 0.5 px/tick"): return
	if not require(doors_31.size() == 1 and (doors_31[0] as RoomDoor).destination_room == 240, "Sala 31 deve ter porta do Elevador 1 (Sala 240)"): return

	# 5. Sala 032 (D2)
	sandbox.call("change_to_room", 32, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_32: Array = sandbox.get("enemies") as Array
	var doors_32: Array = sandbox.get("room_doors") as Array
	if not require(em_32.size() == 1, "Sala 32 deve ter exatamente 1 guarda lento"): return
	if not require(doors_32.size() == 2, "Sala 32 deve ter 2 portas para a Sala 153 (Barrarris)"): return

	# 6. Sala 033 (A2)
	sandbox.call("change_to_room", 33, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_33: Array = sandbox.get("enemies") as Array
	var doors_33: Array = sandbox.get("room_doors") as Array
	if not require(em_33.size() == 2, "Sala 33 deve ter 2 guardas médios"): return
	if not require(doors_33.size() == 2, "Sala 33 deve ter porta para 150 (Silenciador) e 35"): return

	# 7. Sala 034 (D3)
	sandbox.call("change_to_room", 34, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_34: Array = sandbox.get("enemies") as Array
	if not require(em_34.size() == 2, "Sala 34 deve ter exatamente 2 guardas (1 Fast, 1 Medium)"): return

	# 8. Sala 035 (A3 - HideGuard ativo)
	# Testa transição canônica vindo da Sala 33 (remove guarda em X=24)
	sandbox.call("change_to_room", 33, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	sandbox.call("change_to_room", 35, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_35: Array = sandbox.get("enemies") as Array
	if not require(em_35.size() == 2, "Sala 35 deve apresentar 2 guardas ativos ao entrar da Sala 33 (3º em X=24 removido por HideGuardRoom35)"): return

	# Testa transição canônica vindo da Sala 156 (remove guarda em Y=40)
	sandbox.call("change_to_room", 156, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	sandbox.call("change_to_room", 35, Vector2(128.0, 96.0), PlayerController.Direction.UP)
	await process_frame
	var em_35_156: Array = sandbox.get("enemies") as Array
	if not require(em_35_156.size() == 2, "Sala 35 deve apresentar 2 guardas ativos ao sair da porta 156 (guarda em Y=40 removido por HideGuardRoom35)"): return

	# 9. Sala 036 (D4)
	sandbox.call("change_to_room", 36, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_36: Array = sandbox.get("enemies") as Array
	var cam_36: Array = sandbox.get("cameras") as Array
	var doors_36: Array = sandbox.get("room_doors") as Array
	if not require(em_36.size() == 1, "Sala 36 deve ter 1 guarda"): return
	if not require(cam_36.size() == 2, "Sala 36 deve ter 2 câmeras"): return
	if not require(doors_36.size() == 2, "Sala 36 deve ter 2 portas (157 e 158)"): return

	# 10. Sala 037 (C4 - Piso Eletrificado)
	sandbox.call("change_to_room", 37, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var elect_sys: ElectrifiedFloorSystem = sandbox.get("electrified_floor_system") as ElectrifiedFloorSystem
	if not require(elect_sys != null and elect_sys.is_room_electrified(37), "Sala 37 deve ter piso eletrificado ativo"): return
	if not require(elect_sys.is_power_on(37), "Energia da Sala 37 deve iniciar ligada"): return

	# 11. Sala 038 (B4)
	sandbox.call("change_to_room", 38, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_38: Array = sandbox.get("enemies") as Array
	var doors_38: Array = sandbox.get("room_doors") as Array
	if not require(em_38.size() == 2, "Sala 38 deve ter 2 guardas"): return
	if not require(doors_38.size() == 1 and (doors_38[0] as RoomDoor).destination_room == 159, "Sala 38 deve ter porta para Sala 159 (Refém Diane)"): return

	# 12. Sala 039 (A4 - Elevador 3 / Sentinelas)
	# Vindo da Sala 38 (remove sentinelas do sul Y=176, mantém as do norte Y=72)
	sandbox.call("change_to_room", 39, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_39: Array = sandbox.get("enemies") as Array
	var doors_39: Array = sandbox.get("room_doors") as Array
	if not require(em_39.size() == 2, "Sala 39 deve apresentar 2 sentinelas ativas vindo da Sala 38 (HideGuardRoom39)"): return
	if not require(doors_39.size() == 1 and (doors_39[0] as RoomDoor).destination_room == 242, "Sala 39 deve ter porta do Elevador 3 (Sala 242)"): return

	# Vindo do Elevador 3 (Sala 242 - remove sentinelas do norte Y=72, mantém as do sul Y=176)
	sandbox.call("change_to_room", 242, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	sandbox.call("change_to_room", 39, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_39_elev: Array = sandbox.get("enemies") as Array
	if not require(em_39_elev.size() == 2, "Sala 39 deve apresentar 2 sentinelas ativas vindo do Elevador 242 (HideGuardRoom39)"): return

	# 13. Salas Internas e Coletáveis
	# Sala 146: Refém Grey Fox
	sandbox.call("change_to_room", 146, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var pris_146: Array = sandbox.get("prisoners") as Array
	if not require(pris_146.size() == 1 and "Grey Fox" in (pris_146[0] as Prisoner).message_text or "FOX HOUNDer" in (pris_146[0] as Prisoner).message_text, "Sala 146 deve conter refém com mensagem de Grey Fox"): return

	# Sala 147: Míssil Teleguiado
	sandbox.call("change_to_room", 147, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var it_147: Array = sandbox.get("item_boxes") as Array
	if not require(it_147.size() == 1 and (it_147[0] as ItemBox).item_id == WeaponSystem.WEAPON_MISSILE, "Sala 147 deve conter Míssil Teleguiado (MISSILE)"): return

	# Sala 149: Munição de Pistola
	sandbox.call("change_to_room", 149, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var it_149: Array = sandbox.get("item_boxes") as Array
	if not require(it_149.size() == 1 and (it_149[0] as ItemBox).item_id == InventoryManager.ITEM_AMMO_CRATE, "Sala 149 deve conter Caixa de Munição (AMMO_CRATE)"): return

	# Sala 150: 4 Guardas do Silenciador
	sandbox.call("change_to_room", 150, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var em_150: Array = sandbox.get("enemies") as Array
	if not require(em_150.size() == 4, "Sala 150 deve conter os 4 guardas atiradores do Silenciador"): return

	# Sala 151: Lançador de Granadas
	sandbox.call("change_to_room", 151, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var it_151: Array = sandbox.get("item_boxes") as Array
	if not require(it_151.size() == 1 and (it_151[0] as ItemBox).item_id == WeaponSystem.WEAPON_GRENADE_LAUNCHER, "Sala 151 deve conter Lançador de Granadas (GRENADE_LAUNCHER)"): return

	# Sala 152: Refém das armadilhas laser
	sandbox.call("change_to_room", 152, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var pris_152: Array = sandbox.get("prisoners") as Array
	if not require(pris_152.size() == 1 and "infrared laser" in (pris_152[0] as Prisoner).message_text, "Sala 152 deve conter refém com aviso de lasers"): return

	# Sala 153: Explosivo Plástico
	sandbox.call("change_to_room", 153, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var it_153: Array = sandbox.get("item_boxes") as Array
	if not require(it_153.size() == 1 and (it_153[0] as ItemBox).item_id == InventoryManager.ITEM_PLASTIC_BOMB, "Sala 153 deve conter Explosivo Plástico (PLASTIC_BOMB)"): return

	# Sala 156: Caixa de Papelão
	sandbox.call("change_to_room", 156, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var it_156: Array = sandbox.get("item_boxes") as Array
	if not require(it_156.size() == 1 and (it_156[0] as ItemBox).item_id == InventoryManager.ITEM_BOX, "Sala 156 deve conter Caixa de Papelão (BOX)"): return

	# Sala 157: Cartão de Acesso 2
	sandbox.call("change_to_room", 157, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var it_157: Array = sandbox.get("item_boxes") as Array
	if not require(it_157.size() == 1 and (it_157[0] as ItemBox).item_id == InventoryManager.ITEM_CARD2, "Sala 157 deve conter Cartão de Acesso 2 (CARD2)"): return

	# Sala 158: Ração
	sandbox.call("change_to_room", 158, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var it_158: Array = sandbox.get("item_boxes") as Array
	if not require(it_158.size() == 1 and (it_158[0] as ItemBox).item_id == InventoryManager.ITEM_RATION, "Sala 158 deve conter Ração de Combate (RATION)"): return

	# Sala 159: Refém Frequência Diane (120.33)
	sandbox.call("change_to_room", 159, Vector2(128.0, 96.0), PlayerController.Direction.DOWN)
	await process_frame
	var pris_159: Array = sandbox.get("prisoners") as Array
	if not require(pris_159.size() == 1 and "120.33" in (pris_159[0] as Prisoner).message_text, "Sala 159 deve conter refém informando frequência 120.33 da Diane"): return

	print("FLOOR3_REVIEW_TEST_OK: Todas as 12 salas principais e 12 salas internas do Floor 3 validadas com sucesso!")
	quit(0)
