extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	print("FAIL: " + message)
	quit(1)

func require(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	print("  PASS: " + message)
	return true

func _run() -> void:
	print("\n--- Canonical Room 007 Patrol & Lorries Test ---")

	var sandbox_scene: PackedScene = preload("res://scenes/sandbox_gameplay.tscn")
	var sandbox: Control = sandbox_scene.instantiate() as Control
	root.add_child(sandbox)
	await process_frame
	await process_frame

	# 1. Carregar Sala 007 no Sandbox
	var ok: bool = sandbox.call("change_to_room", 7, Vector2(192.0, 184.0), PlayerController.Direction.UP)
	if not require(ok, "Sala 7 deve carregar com sucesso"): return
	if not require(sandbox.get("snapshot").room_id == 7, "Sala atual deve ser 7"): return

	var enemies: Array = sandbox.get("enemies") as Array
	if not require(enemies.size() == 2, "Sala 7 deve inicializar com exatamente 2 guardas de caminhão"): return

	var g_mid: EnemyGuard = null
	var g_right: EnemyGuard = null
	for e in enemies:
		if e is EnemyGuard and e.is_lorry_guard:
			if is_equal_approx(e.position.x, 80.0):
				g_mid = e
			elif is_equal_approx(e.position.x, 112.0):
				g_right = e

	if not require(g_mid != null, "Guarda do caminhão do meio (X=80) deve estar presente"): return
	if not require(g_right != null, "Guarda do caminhão da direita (X=112) deve estar presente"): return

	# Velocidades e atributos canônicos
	if not require(g_mid.guard_type == EnemyGuard.GuardType.SLOW, "Guarda do meio deve ter velocidade SLOW (0.4 px/tick)"): return
	if not require(is_equal_approx(g_mid.speed, 0.4), "Velocidade numérica do guarda do meio deve ser 0.4"): return
	if not require(g_mid.lorry_id == 2, "Guarda do meio deve ter lorry_id == 2"): return

	if not require(g_right.guard_type == EnemyGuard.GuardType.MEDIUM, "Segundo guarda da Sala 7 deve ter velocidade MEDIUM (0.7 px/tick per guardlorry.asm:32)"): return
	if not require(is_equal_approx(g_right.speed, 0.7), "Velocidade numérica do segundo guarda deve ser 0.7"): return
	if not require(g_right.lorry_id == 3, "Segundo guarda deve ter lorry_id == 3"): return

	# Inicialmente escondidos dentro da carroceria
	if not require(not g_mid.visible, "Guarda do meio deve iniciar invisível dentro da carroceria"): return
	if not require(not g_right.visible, "Guarda da direita deve iniciar invisível dentro da carroceria"): return
	if not require(g_mid.lorry_timer > 0, "Guarda do meio deve ter temporizador de saída armado"): return
	if not require(g_right.lorry_timer > 0, "Guarda da direita deve ter temporizador de saída armado"): return

	# 2. Testar saída do guarda do caminhão do meio (Y=120 -> Y=136 -> patrulha)
	g_mid.lorry_timer = 1
	sandbox.call("_physics_process", 1.0 / 60.0)
	if not require(g_mid.visible, "Guarda do meio deve tornar-se visível ao zerar o timer"): return
	if not require(g_mid.is_exiting_lorry, "Guarda do meio deve iniciar animação de saída da caçamba"): return
	if not require(g_mid.current_direction == PlayerController.Direction.DOWN, "Guarda deve sair caminhando para o Sul (DOWN)"): return

	# Avançar até concluir a saída (16 pixels)
	var max_ticks: int = 60
	while g_mid.is_exiting_lorry and max_ticks > 0:
		sandbox.call("_physics_process", 1.0 / 60.0)
		max_ticks -= 1
	if not require(not g_mid.is_exiting_lorry, "Guarda do meio deve concluir a descida da carroceria"): return
	if not require(is_equal_approx(g_mid.position.y, 136.0), "Guarda do meio deve estar em Y=136 (waypoint 0) ao fim da saída"): return

	# 3. Teste do Caminhão Esquerdo (Sala 130) e coleta da Handgun (ID 1)
	ok = sandbox.call("change_to_room", 130, Vector2(198.0, 112.0), PlayerController.Direction.LEFT, 118)
	if not require(ok, "Transição para o caminhão da esquerda (Sala 130) deve ter sucesso"): return
	if not require(sandbox.get("snapshot").room_id == 130, "Sala atual deve ser 130"): return

	var enemies_130: Array = sandbox.get("enemies") as Array
	if not require(enemies_130.is_empty(), "Caminhão 130 deve estar vazio (sem inimigos)"): return

	var item_boxes: Array = sandbox.get("item_boxes") as Array
	var gun_box: ItemBox = null
	for b in item_boxes:
		if b is ItemBox and b.item_id == WeaponSystem.WEAPON_HANDGUN:
			gun_box = b
			break
	if not require(gun_box != null, "Caixa da Handgun deve estar presente na Sala 130"): return
	if not require(is_equal_approx(gun_box.position.x, 64.0) and is_equal_approx(gun_box.position.y, 96.0), "Handgun deve estar na posição canônica (64, 96)"): return

	# Snake coleta a Handgun
	var weapon_system: WeaponSystem = sandbox.get("weapon_system") as WeaponSystem
	var inventory: InventoryManager = sandbox.get("inventory") as InventoryManager
	var player: PlayerController = sandbox.get("player") as PlayerController
	gun_box.step_tick(Vector2(64.0, 96.0), inventory, weapon_system)
	if not require(weapon_system.has_weapon(WeaponSystem.WEAPON_HANDGUN), "Snake deve possuir a Handgun após coletar a caixa"): return
	if not require(weapon_system.ammo[WeaponSystem.WEAPON_HANDGUN] == 0, "Fiel ao MSX: Handgun coletada vem descarregada (0 balas per ItemTakeAmount)"): return

	# Retornar à Sala 007
	ok = sandbox.call("change_to_room", 7, Vector2(48.0, 172.0), PlayerController.Direction.DOWN, 118)
	if not require(ok, "Retorno à Sala 007 via porta 118 deve ter sucesso"): return

	# 4. Teste do Caminhão do Meio (Sala 131) — Emboscada de 4 soldados vs Descarte se guarda fora
	# Caso A: Se Snake entrar com o guarda fora (guard2_exited_lorry = true)
	var enemies_room7: Array = sandbox.get("enemies") as Array
	var g_mid_new: EnemyGuard = null
	for e in enemies_room7:
		if e is EnemyGuard and e.lorry_id == 2:
			g_mid_new = e
			break
	if not require(g_mid_new != null, "Guarda do meio deve ser encontrado na Sala 7 recarregada"): return

	# Fazer o guarda sair da caçamba
	g_mid_new.lorry_timer = 1
	for i in range(50):
		sandbox.call("_physics_process", 1.0 / 60.0)
	if not require(g_mid_new.visible, "Guarda do meio deve estar fora da caçamba"): return

	# Entrar no caminhão 131 enquanto o guarda está fora
	ok = sandbox.call("change_to_room", 131, Vector2(198.0, 112.0), PlayerController.Direction.LEFT, 119)
	if not require(ok, "Entrada no caminhão 131 deve ter sucesso"): return
	if not require(sandbox.get("guard2_exited_lorry") == true, "guard2_exited_lorry deve ser true"): return
	var enemies_131_empty: Array = sandbox.get("enemies") as Array
	if not require(enemies_131_empty.is_empty(), "Emboscada da Sala 131 deve ser descartada quando o guarda saiu para a patrulha"): return

	# Retornar à Sala 007
	ok = sandbox.call("change_to_room", 7, Vector2(80.0, 140.0), PlayerController.Direction.DOWN, 119)
	if not require(ok, "Retorno à Sala 007 via porta 119 deve ter sucesso"): return
	if not require(sandbox.get("guard2_exited_lorry") == false, "guard2_exited_lorry deve resetar ao retornar à Sala 7"): return

	# Caso B: Entrar no caminhão 131 com o guarda ainda dentro da caçamba (emboscada ativa!)
	ok = sandbox.call("change_to_room", 131, Vector2(198.0, 112.0), PlayerController.Direction.LEFT, 119)
	if not require(ok, "Entrada no caminhão 131 com guarda dentro deve ter sucesso"): return
	if not require(sandbox.get("guard2_exited_lorry") == false, "guard2_exited_lorry deve ser false"): return
	var enemies_131_ambush: Array = sandbox.get("enemies") as Array
	if not require(enemies_131_ambush.size() == 4, "Emboscada na Sala 131 deve conter exatamente 4 soldados de alerta"): return
	for amb_guard in enemies_131_ambush:
		if not require(amb_guard.actor_type_id == 10, "Inimigos da emboscada devem ser GuardAlert (ID 10)"): return

	# Retornar à Sala 007
	ok = sandbox.call("change_to_room", 7, Vector2(80.0, 140.0), PlayerController.Direction.DOWN, 119)
	if not require(ok, "Retorno à Sala 007 deve ter sucesso"): return

	# 5. Teste do Caminhão da Direita (Sala 132) e Minas Terrestres (WEAPON_LAND_MINE = ID 6)
	enemies_room7 = sandbox.get("enemies") as Array
	var g_right_new: EnemyGuard = null
	for e in enemies_room7:
		if e is EnemyGuard and e.lorry_id == 3:
			g_right_new = e
			break
	if not require(g_right_new != null, "Segundo guarda da Sala 7 deve ser encontrado"): return

	# Fazer o segundo guarda sair da caçamba
	g_right_new.lorry_timer = 1
	for i in range(50):
		sandbox.call("_physics_process", 1.0 / 60.0)
	if not require(g_right_new.visible, "Segundo guarda deve estar visível fora do caminhão"): return

	# Entrar no caminhão 132 com o guarda fora
	ok = sandbox.call("change_to_room", 132, Vector2(198.0, 112.0), PlayerController.Direction.LEFT, 120)
	if not require(ok, "Entrada no caminhão 132 deve ter sucesso"): return
	if not require(sandbox.get("guard3_exited_lorry") == true, "guard3_exited_lorry deve ser true"): return
	var enemies_132: Array = sandbox.get("enemies") as Array
	if not require(enemies_132.is_empty(), "Guarda da Sala 132 deve ser descartado quando o segundo guarda saiu para patrulha"): return

	# Verificar caixa de Minas Terrestres (LAND_MINE, ID 6) em (96, 64)
	item_boxes = sandbox.get("item_boxes") as Array
	var mine_box: ItemBox = null
	for b in item_boxes:
		if b is ItemBox and b.item_id == WeaponSystem.WEAPON_LAND_MINE:
			mine_box = b
			break
	if not require(mine_box != null, "Caixa de Minas Terrestres (WEAPON_LAND_MINE) deve estar presente na Sala 132"): return
	if not require(is_equal_approx(mine_box.position.x, 96.0) and is_equal_approx(mine_box.position.y, 64.0), "Minas Terrestres devem estar na posição canônica (96, 64)"): return

	# Coletar Minas Terrestres
	mine_box.step_tick(Vector2(96.0, 64.0), inventory, weapon_system)
	if not require(weapon_system.has_weapon(WeaponSystem.WEAPON_LAND_MINE), "Snake deve adquirir WEAPON_LAND_MINE no arsenal"): return
	if not require(weapon_system.ammo[WeaponSystem.WEAPON_LAND_MINE] == 5, "Coleta de minas deve conceder exatamente 5 unidades"): return

	# Retornar à Sala 007
	ok = sandbox.call("change_to_room", 7, Vector2(112.0, 140.0), PlayerController.Direction.DOWN, 120)
	if not require(ok, "Retorno à Sala 007 via porta 120 deve ter sucesso"): return
	if not require(sandbox.get("guard3_exited_lorry") == false, "guard3_exited_lorry deve resetar ao retornar à Sala 7"): return

	print("ROOM_007_PATROL_OK: Patrulhas canônicas da Sala 007, velocidades dos caminhões, emboscadas e itens validados com sucesso!")
	quit(0)
