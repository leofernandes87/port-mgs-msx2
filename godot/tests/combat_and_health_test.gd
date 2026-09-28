extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
		return false
	return true

func _run() -> void:
	# 1. Carregar Player e Guarda
	var packed_player: PackedScene = load("res://scenes/player.tscn") as PackedScene
	if not require(packed_player != null, "Falha ao carregar scenes/player.tscn"): return
	var player: PlayerController = packed_player.instantiate() as PlayerController
	root.add_child(player)

	var packed_enemy: PackedScene = load("res://scenes/enemy.tscn") as PackedScene
	if not require(packed_enemy != null, "Falha ao carregar scenes/enemy.tscn"): return
	var enemy: EnemyGuard = packed_enemy.instantiate() as EnemyGuard
	root.add_child(enemy)
	await process_frame

	var dummy_collision: Array[int] = []
	dummy_collision.resize(768)
	dummy_collision.fill(0)

	# 2. Teste de Soco do Snake (8 ticks de duração e imobilização)
	player.set_grid_position(100.0, 100.0)
	if not require(player.life == 24, "Vida inicial de Snake deve ser 24 (Rank 1)"): return
	if not require(player.punch_timer == 0 and not player.is_punching, "Snake não deve iniciar socando"): return

	var punched: bool = player.punch()
	if not require(punched and player.punch_timer == 8 and player.is_punching, "punch() deve iniciar punch_timer em 8 e is_punching = true"): return

	# Durante o soco, entrada de movimento não deve mover Snake
	for i: int in range(7):
		var moved: bool = player.step_tick(Vector2i(1, 0))
		if not require(not moved and player.position == Vector2(100.0, 100.0), "Snake deve permanecer imóvel durante os 8 ticks de soco"): return
		if not require(player.is_punching, "Snake deve permanecer em estado de soco"): return

	# 8º tick: soco termina
	player.step_tick(Vector2i(1, 0))
	if not require(player.punch_timer == 0 and not player.is_punching, "Soco deve finalizar após 8 ticks"): return

	# Próximo tick: movimento volta a funcionar
	var moved_now: bool = player.step_tick(Vector2i(1, 0))
	if not require(moved_now and player.position.x == 100.0 + PlayerController.SPEED_NORMAL, "Snake deve voltar a se mover normalmente após o soco"): return

	# 3. Teste de Caixas de Impacto de Soco nas 4 Direções da ROM (logic/punchenemy.asm)
	enemy.position = Vector2(100.0, 100.0)
	enemy.is_dead = false
	enemy.stunned_timer = 0

	# UP: Snake está abaixo do guarda e soca para cima
	var hit: bool = enemy.check_punched(Vector2(100.0, 114.0), PlayerController.Direction.UP)
	if not require(hit, "Soco para UP deve acertar guarda acima de Snake"): return

	# DOWN: Snake está acima do guarda e soca para baixo
	hit = enemy.check_punched(Vector2(100.0, 86.0), PlayerController.Direction.DOWN)
	if not require(hit, "Soco para DOWN deve acertar guarda abaixo de Snake"): return

	# LEFT: Snake está à direita do guarda e soca para a esquerda
	hit = enemy.check_punched(Vector2(114.0, 100.0), PlayerController.Direction.LEFT)
	if not require(hit, "Soco para LEFT deve acertar guarda à esquerda de Snake"): return

	# RIGHT: Snake está à esquerda do guarda e soca para a direita
	hit = enemy.check_punched(Vector2(86.0, 100.0), PlayerController.Direction.RIGHT)
	if not require(hit, "Soco para RIGHT deve acertar guarda à direita de Snake"): return

	# Fora do raio do soco (distância > 24 px)
	hit = enemy.check_punched(Vector2(140.0, 100.0), PlayerController.Direction.RIGHT)
	if not require(not hit, "Soco fora de alcance não deve acertar o guarda"): return

	# 4. Teste de Atordoamento (64 ticks) e Morte com 3 Socos
	enemy.punches_received = 0
	enemy.receive_punch()
	if not require(enemy.punches_received == 1, "Guarda deve registrar 1 soco recebido"): return
	if not require(enemy.stunned_timer == 64, "Guarda deve ficar atordoado por 64 ticks (0x40)"): return
	if not require(enemy.state == EnemyGuard.GuardState.ALERT, "Guarda socado deve entrar em ALERTA"): return

	# Enquanto atordoado, novos socos imediatos não acumulam
	enemy.receive_punch()
	if not require(enemy.punches_received == 1, "Guarda atordoado não deve registrar novo dano antes do fim do stun"): return

	# Simular fim do atordoamento e 2º soco
	enemy.stunned_timer = 0
	enemy.receive_punch()
	if not require(enemy.punches_received == 2 and not enemy.is_dead, "2º soco não deve matar o guarda"): return

	# Simular fim do atordoamento e 3º soco (Morte do guarda)
	enemy.stunned_timer = 0
	enemy.receive_punch()
	if not require(enemy.punches_received == 3 and enemy.is_dead, "Guarda deve morrer após o 3º soco"): return

	# Guarda morto não avista jogador
	var sees: bool = enemy.check_line_of_sight(Vector2(140.0, 100.0), dummy_collision)
	if not require(not sees, "Guarda morto não deve ter linha de visão"): return

	# 5. Teste de Dano por Contato Físico (2 pontos) e Invulnerabilidade de 32 Ticks
	var enemy2: EnemyGuard = packed_enemy.instantiate() as EnemyGuard
	root.add_child(enemy2)
	await process_frame

	enemy2.position = Vector2(100.0, 100.0)
	enemy2.is_dead = false
	enemy2.stunned_timer = 0

	player.set_grid_position(104.0, 100.0) # Distância 4 px (contato direto)
	player.life = 24
	player.invulnerable_timer = 0

	# Tick com contato
	enemy2.step_tick(dummy_collision, player.position, false, PlayerController.Direction.DOWN, player)
	if not require(player.life == 22, "Contato físico com soldado deve subtrair 2 pontos de vida (24 -> 22)"): return
	if not require(player.invulnerable_timer == 32, "Snake deve receber 32 ticks (0x20) de invulnerabilidade após sofrer dano"): return

	# Próximo tick: ainda em invulnerabilidade, vida não deve diminuir
	enemy2.step_tick(dummy_collision, player.position, false, PlayerController.Direction.DOWN, player)
	player.step_tick(Vector2i.ZERO) # Decrementa invulnerabilidade
	if not require(player.life == 22, "Snake não deve sofrer dano contínuo durante o timer de invulnerabilidade"): return
	if not require(player.invulnerable_timer == 31, "Timer de invulnerabilidade deve decrementar a cada tick"): return

	# 6. Teste de Vida Infinita (God Mode de sandbox)
	player.infinite_life = true
	player.life = player.max_life
	var took_damage: bool = player.apply_damage(10)
	if not require(not took_damage and player.life == player.max_life, "Em modo infinite_life, Snake não deve sofrer dano"): return
	player.infinite_life = false

	# 7. Teste de Morte do Jogador e Bloqueio Imediato de Inputs (Game Over)
	player.life = 10
	player.invulnerable_timer = 0
	var player_died_emitted: Array[bool] = [false]
	player.player_died.connect(func() -> void: player_died_emitted[0] = true)

	# Aplica dano fatal (10 dano em 10 HP restante)
	var lethal_hit: bool = player.apply_damage(10)
	if not require(lethal_hit and player.life == 0, "Dano letal deve reduzir a vida a 0"): return
	if not require(player.is_dead, "Snake deve estar com is_dead = true após dano letal"): return
	if not require(not player.can_control, "Controles de Snake devem ser imediatamente bloqueados (can_control = false)"): return
	if not require(player_died_emitted[0], "Sinal player_died deve ser emitido ao zerar a vida"): return

	# Ações bloqueadas enquanto morto
	var moved_while_dead: bool = player.step_tick(Vector2i(1, 0))
	if not require(not moved_while_dead, "Snake morto não deve conseguir se mover"): return
	var punched_while_dead: bool = player.punch()
	if not require(not punched_while_dead, "Snake morto não deve conseguir socar"): return

	var test_weapon_sys := WeaponSystem.new()
	test_weapon_sys.owned_weapons = ["HANDGUN"]
	test_weapon_sys.selected_weapon = "HANDGUN"
	test_weapon_sys.ammo["HANDGUN"] = 10
	var bullet_while_dead: Bullet = player.fire_weapon(test_weapon_sys)
	if not require(bullet_while_dead == null, "Snake morto não deve conseguir atirar"): return

	# Restauração manual com revive()
	player.revive()
	if not require(not player.is_dead and player.can_control, "revive() deve restaurar is_dead = false e can_control = true"): return
	if not require(player.life == player.max_life and player.life == 24, "revive() deve restaurar a vida ao valor máximo (24 HP)"): return
	var moved_after_revive: bool = player.step_tick(Vector2i(1, 0))
	if not require(moved_after_revive, "Snake revivido deve se mover normalmente"): return

	# 8. Teste de Integração: Fluxo de Game Over Punitivo e Reset Absoluto no Sandbox
	var packed_sandbox: PackedScene = load("res://scenes/sandbox_gameplay.tscn") as PackedScene
	if not require(packed_sandbox != null, "Falha ao carregar sandbox_gameplay.tscn"): return
	var sandbox: Control = packed_sandbox.instantiate() as Control
	root.add_child(sandbox)
	await process_frame
	await process_frame

	var sb_player: PlayerController = sandbox.get("player") as PlayerController
	var sb_inventory: InventoryManager = sandbox.get("inventory") as InventoryManager
	var sb_weapons: WeaponSystem = sandbox.get("weapon_system") as WeaponSystem
	var sb_alert: AlertSystem = sandbox.get("alert_system") as AlertSystem

	# Simular progresso prévio na partida: coletar itens, armas e acionar alerta
	sb_inventory.collect_item("CARD1")
	sb_inventory.collect_item("CARD4")
	sb_inventory.collect_item(InventoryManager.ITEM_RATION)
	sb_weapons.add_weapon(WeaponSystem.WEAPON_HANDGUN, 30)
	sb_weapons.select_weapon(WeaponSystem.WEAPON_HANDGUN)
	sb_alert.trigger_alert(true, 4, 1)

	if not require(sb_inventory.has_item("CARD4"), "Sandbox deve conter CARD4 antes da morte"): return
	if not require(sb_weapons.owned_weapons.has("HANDGUN"), "Sandbox deve conter HANDGUN antes da morte"): return
	if not require(sb_alert.current_state == AlertSystem.AlertState.ALERT, "Alerta deve estar ativo antes da morte"): return

	# Provocar dano fatal no jogador da sandbox
	sb_player.apply_damage(sb_player.life)
	if not require(sb_player.is_dead and not sb_player.can_control, "Snake da sandbox deve estar morto e sem controles"): return
	if not require(bool(sandbox.get("is_game_over")), "is_game_over deve ser verdadeiro"): return

	# Executa a rotina de reset completo e recarregamento seguro da Sala 121
	sandbox.call("_execute_game_restart")

	# Validar o reset absoluto de estado
	if not require(not sb_inventory.has_item("CARD1") and not sb_inventory.has_item("CARD4"), "Todos os cartões devem ter sido removidos"): return
	if not require(not sb_inventory.has_item(InventoryManager.ITEM_RATION), "Rações devem ter sido removidas"): return
	if not require(sb_inventory.has_item(InventoryManager.ITEM_CIGARETTES), "CIGARETTES devem estar presentes como equipamento inicial"): return
	if not require(sb_weapons.owned_weapons.is_empty(), "Arsenal de armas deve ter sido totalmente esvaziado"): return
	if not require(sb_alert.current_state == AlertSystem.AlertState.NORMAL, "Sistema de alerta deve voltar a NORMAL/furtivo"): return

	# Validar recarregamento seguro na Sala 121 em terra firme
	var sb_snap: RoomSnapshot = sandbox.get("snapshot") as RoomSnapshot
	if not require(sb_snap.room_id == 121, "Jogo deve ser reiniciado na Sala 121"): return
	if not require(sb_player.position == Vector2(128.0, 80.0), "Snake deve surgir em terra firme (128, 80) na Sala 121"): return
	if not require(sb_player.life == 24 and sb_player.life == sb_player.max_life, "Vida de Snake deve ser restaurada a 24 HP"): return
	if not require(not sb_player.is_dead and sb_player.can_control, "Controles de Snake devem ser liberados no reinício"): return

	# Validar movimentação normal após o reset (sem softlock)
	var can_walk_after_game_over: bool = sb_player.step_tick(Vector2i(0, -1))
	if not require(can_walk_after_game_over, "Snake deve andar normalmente após o reinício da Sala 121"): return

	print("COMBAT_AND_HEALTH_OK: punch 8-ticks, 4-dir impact, 64-tick stun, 3-punch kill, touch damage, 32-tick invuln, god mode, death trigger, input lock, full state reset and safe room 121 reload")
	quit(0)

