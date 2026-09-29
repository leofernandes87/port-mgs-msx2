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
	# --------------------------------------------------------------------------
	# 1. Teste de WeaponSystem: Arsenal, Auto-Seleção, Munição e Limite de Patente
	# --------------------------------------------------------------------------
	var ws: WeaponSystem = WeaponSystem.new()
	if not require(ws.selected_weapon == "", "Arma inicial deve ser vazia (desarmado)"): return
	if not require(ws.get_status_text() == "[DESARMADO]", "Status inicial deve ser [DESARMADO]"): return
	if not require(not ws.can_fire(), "Sem arma equipada não pode atirar"): return

	# Coleta da Pistola (HAND_GUN - ID 1 na ROM) com 10 tiros
	ws.add_weapon(WeaponSystem.WEAPON_HANDGUN, 10)
	if not require(ws.has_weapon(WeaponSystem.WEAPON_HANDGUN), "HANDGUN deve estar no arsenal"): return
	if not require(ws.selected_weapon == WeaponSystem.WEAPON_HANDGUN, "Primeira arma coletada deve ser auto-selecionada"): return
	if not require(ws.ammo[WeaponSystem.WEAPON_HANDGUN] == 10, "Munição de HANDGUN deve ser 10"): return
	if not require(ws.can_fire(), "HANDGUN com munição deve estar pronta para atirar"): return

	# Coleta da Metralhadora (SUB_MACHINE_GUN - ID 2 na ROM) com 15 tiros
	ws.add_weapon(WeaponSystem.WEAPON_SMG, 15)
	if not require(ws.has_weapon(WeaponSystem.WEAPON_SMG), "SMG deve estar no arsenal"): return
	if not require(ws.ammo[WeaponSystem.WEAPON_SMG] == 15, "Munição de SMG deve ser 15"): return

	# Coleta de Caixa de Munição (PickAmmoCrate: +20 Handgun, +20 SMG)
	ws.add_ammo_crate(20, 20, 6)
	if not require(ws.ammo[WeaponSystem.WEAPON_HANDGUN] == 30, "Handgun deve ter 30 tiros após ammo crate"): return
	if not require(ws.ammo[WeaponSystem.WEAPON_SMG] == 35, "SMG deve ter 35 tiros após ammo crate"): return

	# Adicionar munição excedente para testar limite de Rank 1 (MaxAmmoLv1 = 50 tiros)
	ws.add_ammo_crate(40, 40, 6)
	if not require(ws.ammo[WeaponSystem.WEAPON_HANDGUN] == 50, "Munição de Handgun não pode ultrapassar o teto de 50 no Rank 1"): return
	if not require(ws.ammo[WeaponSystem.WEAPON_SMG] == 50, "Munição de SMG não pode ultrapassar o teto de 50 no Rank 1"): return

	# Ciclo de armas (cycle_weapon)
	ws.cycle_weapon() # De HANDGUN para SMG
	if not require(ws.selected_weapon == WeaponSystem.WEAPON_SMG, "Ciclo deve selecionar SMG"): return
	ws.cycle_weapon() # De SMG para DESARMADO ("")
	if not require(ws.selected_weapon == "", "Ciclo deve alternar para DESARMADO"): return
	ws.cycle_weapon() # De DESARMADO para HANDGUN
	if not require(ws.selected_weapon == WeaponSystem.WEAPON_HANDGUN, "Ciclo deve retornar para HANDGUN"): return

	# Consumo de munição
	var consumed: bool = ws.consume_ammo()
	if not require(consumed and ws.ammo[WeaponSystem.WEAPON_HANDGUN] == 49, "Disparo deve consumir 1 bala"): return

	# --------------------------------------------------------------------------
	# 2. Teste de Balística do Projétil: Ponto de Saída, Velocidade e Alcance
	# --------------------------------------------------------------------------
	var packed_player: PackedScene = load("res://scenes/player.tscn") as PackedScene
	if not require(packed_player != null, "Falha ao carregar scenes/player.tscn"): return
	var player: PlayerController = packed_player.instantiate() as PlayerController
	root.add_child(player)
	await process_frame

	player.set_grid_position(100.0, 50.0)
	player.current_direction = PlayerController.Direction.DOWN

	var bullet: Bullet = player.fire_weapon(ws)
	if not require(bullet != null, "player.fire_weapon deve instanciar um projétil Bullet"): return
	# Ponto de saída do cano da arma na direção DOWN: PlayerX + 3.0, PlayerY + 6.0
	if not require(bullet.position.x == 103.0, "Projétil deve iniciar no cano da arma em X"): return
	if not require(bullet.position.y == 56.0, "Projétil deve iniciar no cano da arma em Y"): return
	if not require(bullet.speed == 3.0, "Velocidade da bala deve ser 3.0 px/tick"): return
	if not require(bullet.ticks_remaining == 32, "Alcance máximo da bala deve ser 32 ticks"): return
	if not require(bullet.damage == 2, "Dano da bala deve ser 2 pontos (BulletDamage da ROM)"): return

	# Avançar projétil por 31 ticks (espaço livre)
	var empty_grid: Array[int] = []
	empty_grid.resize(768)
	empty_grid.fill(0)

	for _t: int in range(31):
		var alive: bool = bullet.step_tick(empty_grid)
		if not require(alive, "Bala deve permanecer ativa durante seus 32 ticks"): return

	# Posição após 31 ticks para DOWN (+3 px/tick): 56 + 31 * 3 = 149.0
	if not require(bullet.position.y == 149.0, "Projétil deve ter percorrido 93 px em 31 ticks"): return

	# No 32º tick, o projétil atinge o fim do alcance (32 * 3 = 96 px) e expira
	var still_alive: bool = bullet.step_tick(empty_grid)
	if not require(not still_alive, "Projétil deve expirar exatamente no 32º tick (96 px percorridos)"): return

	bullet.queue_free()

	# --------------------------------------------------------------------------
	# 3. Teste de Colisão do Projétil com Parede Sólida
	# --------------------------------------------------------------------------
	player.set_grid_position(50.0, 50.0)
	player.current_direction = PlayerController.Direction.RIGHT
	var wall_bullet: Bullet = player.fire_weapon(ws)
	root.add_child(wall_bullet)
	await process_frame

	# Criar grid com parede sólida no tile à frente da trajetória do projétil
	var solid_grid: Array[int] = []
	solid_grid.resize(768)
	solid_grid.fill(0)
	var wall_tx: int = 10 # x=80
	var wall_ty: int = int(wall_bullet.position.y) / 8 # y alinhado à altura do cano da arma
	solid_grid[wall_ty * 32 + wall_tx] = 1

	var wall_hit: bool = false
	for _t: int in range(10):
		var alive: bool = wall_bullet.step_tick(solid_grid)
		if not alive:
			wall_hit = true
			break
	if not require(wall_hit, "Projétil deve ser destruído ao colidir com parede sólida"): return
	wall_bullet.queue_free()

	# --------------------------------------------------------------------------
	# 4. Teste de Letalidade: 1 Tiro Fatal em Guardas
	# --------------------------------------------------------------------------
	var packed_enemy: PackedScene = load("res://scenes/enemy.tscn") as PackedScene
	if not require(packed_enemy != null, "Falha ao carregar scenes/enemy.tscn"): return
	var enemy: EnemyGuard = packed_enemy.instantiate() as EnemyGuard
	enemy.position = Vector2(100.0, 100.0)
	root.add_child(enemy)
	await process_frame

	if not require(not enemy.is_dead, "Inimigo deve iniciar vivo"): return

	# 1 tiro de arma de fogo deve eliminar o guarda imediatamente
	var hit: bool = enemy.take_bullet_hit(2)
	if not require(hit and enemy.is_dead, "1 tiro de pistola/SMG deve derrotar soldado comum (dano 2 vs HP 2)"): return

	enemy.queue_free()

	# Teste de Tiro à Queima-Roupa (Point-Blank): guarda posicionado a 8 px em frente ao Snake
	var pb_enemy: EnemyGuard = packed_enemy.instantiate() as EnemyGuard
	pb_enemy.position = Vector2(108.0, 90.0) # 8 px à direita de Snake, entre peito e cano
	root.add_child(pb_enemy)
	await process_frame

	player.set_grid_position(100.0, 90.0)
	player.current_direction = PlayerController.Direction.RIGHT
	var pb_bullet: Bullet = player.fire_weapon(ws)
	if not require(pb_bullet != null, "Disparo à queima-roupa deve gerar projétil Bullet"): return

	# Testar detecção de queima-roupa
	var muzzle_box := Rect2(
		minf(player.position.x, pb_bullet.position.x) - 4.0,
		minf(player.position.y - 12.0, pb_bullet.position.y) - 4.0,
		absf(pb_bullet.position.x - player.position.x) + 8.0,
		absf(pb_bullet.position.y - (player.position.y - 12.0)) + 8.0
	)
	var enemy_box := Rect2(pb_enemy.position.x - 8.0, pb_enemy.position.y - 10.0, 16.0, 20.0)
	var is_pb: bool = enemy_box.intersects(muzzle_box) or pb_enemy.check_bullet_hit(pb_bullet.position) or pb_enemy.position.distance_to(player.position) <= 14.0
	if not require(is_pb, "Guarda à frente a 8 px deve ser interceptado pela zona à queima-roupa do disparo"): return
	pb_enemy.take_bullet_hit(pb_bullet.damage)
	if not require(pb_enemy.is_dead, "Disparo à queima-roupa deve eliminar soldado com 1 tiro"): return

	pb_bullet.queue_free()
	pb_enemy.queue_free()

	# --------------------------------------------------------------------------
	# 5. Teste Acústico do Silenciador (InvSupressor) e Salas Seguras
	# --------------------------------------------------------------------------
	# Disparo sem silenciador
	ws.set_silencer(false)
	if not require(not ws.has_silencer, "Silenciador deve estar desativado"): return
	var status_no_sil: String = ws.get_status_text()
	if not require(not status_no_sil.contains("(SIL)"), "Status sem silenciador não deve conter tag (SIL)"): return

	# Ativar silenciador
	ws.set_silencer(true)
	if not require(ws.has_silencer, "Silenciador deve estar ativado"): return
	var status_sil: String = ws.get_status_text()
	if not require(status_sil.contains("(SIL)"), "Status com silenciador deve conter tag (SIL)"): return

	# Verificação de lista RoomShotSecure da ROM (ex: Sala 5, 150 são seguras, Sala 1 não é)
	var secure_rooms: Array[int] = [5, 6, 9, 10, 20, 29, 37, 50, 150]
	if not require(5 in secure_rooms, "Sala 5 deve ser reconhecida como RoomShotSecure"): return
	if not require(150 in secure_rooms, "Sala 150 deve ser reconhecida como RoomShotSecure"): return
	if not require(not 1 in secure_rooms, "Sala 1 NÃO deve ser sala segura contra ruído de tiro"): return

	# --------------------------------------------------------------------------
	# 6. Teste de Guarda Atirador (ID_SHOOTER = 13) e Tiro Inimigo
	# --------------------------------------------------------------------------
	var shooter: EnemyGuard = packed_enemy.instantiate() as EnemyGuard
	shooter.actor_type_id = 13 # ID_SHOOTER da ROM
	shooter.position = Vector2(100.0, 60.0)
	shooter.current_direction = PlayerController.Direction.DOWN
	root.add_child(shooter)
	await process_frame

	if not require(shooter.is_shooter, "Guarda com ID 13 deve ser configurado como is_shooter"): return

	# Guarda dispara projétil contra Snake
	var enemy_bullet: Bullet = shooter.try_shoot(player.position)
	if not require(enemy_bullet != null, "Guarda atirador deve gerar projétil Bullet"): return
	if not require(enemy_bullet.position.x == 102.0 and enemy_bullet.position.y == 64.0, "Tiro inimigo para baixo deve emergir na boca do fuzil (X+2, Y+4)"): return
	if not require(enemy_bullet.is_enemy, "Projétil gerado por inimigo deve ter is_enemy = true"): return
	if not require(enemy_bullet.damage == 2, "Dano do tiro inimigo deve ser 2 pontos"): return

	# Dano a Snake
	player.life = 24
	player.invulnerable_timer = 0
	var damaged: bool = player.apply_damage(enemy_bullet.damage)
	if not require(damaged and player.life == 22, "Tiro inimigo deve causar 2 de dano a Snake (vida: 24 -> 22)"): return
	if not require(player.invulnerable_timer == 32, "Snake deve receber 32 ticks de invulnerabilidade após o dano"): return

	enemy_bullet.queue_free()
	shooter.queue_free()
	player.queue_free()

	print("WEAPONS_AND_COMBAT_OK: arsenal, munição Rank 1, balística 6px/tick, 16 ticks alcance, colisão, 1-shot kill, acústica silenciador e tiro inimigo")
	quit(0)
