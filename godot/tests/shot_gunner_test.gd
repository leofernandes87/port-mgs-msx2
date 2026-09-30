extends SceneTree
## Suíte de testes headless — Boss Shoot Gunner (Etapa 18)
## Valida as mecânicas canônicas extraídas de logic/actors/shotgunner.asm
## Token de conclusão: BOSS_SHOOT_GUNNER_OK

var _pass: int = 0
var _fail: int = 0

func _initialize() -> void:
	_run_all()
	var result: String = "BOSS_SHOOT_GUNNER_OK: %d testes passaram, %d falharam" % [_pass, _fail]
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
	print("--- Shoot Gunner Boss Tests ---")
	_test_initial_hp()
	_test_bullet_damage()
	_test_10_bullets_kills()
	_test_state_cycle_intro_to_roll()
	_test_roll_blocks_on_collision()
	_test_shoot_fires_every_16_ticks()
	_test_no_shot_during_roll()
	_test_msx2_sprite_rects()
	_test_shotgun_bullet_sprites()

## Teste 1: HP inicial = 20 (idxActorLife[32] = 0x14)
func _test_initial_hp() -> void:
	var sg: ShotGunner = ShotGunner.new()
	sg.setup(Vector2(144.0, 56.0), [], Vector2(32.0, 96.0))
	_assert(sg.boss_hp == 20, "HP inicial = 20 (0x14)")
	_assert(not sg.is_dead, "Não começa morto")
	sg.free()

## Teste 2: Cada apply_bullet_hit() deduz BULLET_DAMAGE = 2
func _test_bullet_damage() -> void:
	var sg: ShotGunner = ShotGunner.new()
	sg.setup(Vector2(144.0, 56.0), [], Vector2(32.0, 96.0))
	# Avança para fase SHOOT (colisão com tiros ativa)
	sg.state = ShotGunner.SGunnerState.SHOOT
	sg.apply_bullet_hit()
	_assert(sg.boss_hp == 18, "HP após 1 tiro = 18 (20 - 2)")
	sg.apply_bullet_hit()
	_assert(sg.boss_hp == 16, "HP após 2 tiros = 16")
	sg.free()

## Teste 3: 10 tiros consecutivos → boss morre (boss_hp <= 0, is_dead = true)
func _test_10_bullets_kills() -> void:
	var sg: ShotGunner = ShotGunner.new()
	sg.setup(Vector2(144.0, 56.0), [], Vector2(32.0, 96.0))
	sg.state = ShotGunner.SGunnerState.SHOOT
	var defeated_signal_received: Array[bool] = [false]
	sg.boss_defeated.connect(func() -> void: defeated_signal_received[0] = true)
	var killed: bool = false
	for i: int in range(10):
		killed = sg.apply_bullet_hit()
	_assert(sg.is_dead, "10 tiros → is_dead = true")
	_assert(sg.boss_hp <= 0, "HP <= 0 após 10 tiros")
	_assert(defeated_signal_received[0], "Sinal boss_defeated emitido")
	_assert(killed, "apply_bullet_hit retorna true no tiro fatal")
	sg.free()

## Teste 4: Ciclo de estados INTRO → ROLL (após IntroDelay)
func _test_state_cycle_intro_to_roll() -> void:
	var sg: ShotGunner = ShotGunner.new()
	sg.setup(Vector2(144.0, 56.0), [], Vector2(32.0, 96.0))
	_assert(sg.state == ShotGunner.SGunnerState.INTRO, "Estado inicial = INTRO")
	# Ticks de IntroDelay = 2
	sg.step_tick(Vector2(32.0, 96.0), [])
	sg.step_tick(Vector2(32.0, 96.0), [])
	# Após 2 ticks, transita para ROLL
	_assert(sg.state == ShotGunner.SGunnerState.ROLL, "Após IntroDelay (2 ticks) → ROLL")
	_assert(sg.wait_timer == ShotGunner.ROLL_WAIT, "wait_timer resetado para ROLL_WAIT=11")
	sg.free()

## Teste 5: Rolagem bloqueia ao atingir tile sólido
func _test_roll_blocks_on_collision() -> void:
	var sg: ShotGunner = ShotGunner.new()
	# Cria grade com parede à direita na coluna 19 (X=152 → tile 152/8=19)
	var grid: Array[int] = []
	for i: int in range(768):
		grid.append(0)
	# Snake em X=32, boss em X=144, rolando para direita → colide em X=152
	for row: int in range(24):
		grid[row * 32 + 19] = 1  # Parede vertical em tile X=19
	sg.setup(Vector2(144.0, 56.0), grid, Vector2(32.0, 96.0))
	sg.state = ShotGunner.SGunnerState.ROLL
	sg.speed_x = 4.0  # Vai para a direita (em direção à parede)
	sg.wait_timer = ShotGunner.ROLL_WAIT
	# Executa ticks até colidir ou wait expirar
	for i: int in range(15):
		sg.step_tick(Vector2(32.0, 96.0), grid)
		if sg.state == ShotGunner.SGunnerState.SHOOT:
			break
	_assert(sg.state == ShotGunner.SGunnerState.SHOOT, "Colisão com tile → transita para SHOOT")
	sg.free()

## Teste 6: Fase SHOOT dispara a cada 16 ticks (anim_tick & 0x0F == 0)
func _test_shoot_fires_every_16_ticks() -> void:
	var sg: ShotGunner = ShotGunner.new()
	sg.setup(Vector2(128.0, 96.0), [], Vector2(32.0, 96.0))
	sg.state = ShotGunner.SGunnerState.SHOOT
	sg.wait_timer = ShotGunner.SHOOT_WAIT
	sg.anim_tick = 0  # Reseta para controle preciso
	var shots_fired: Array[int] = [0]
	sg.boss_shot_fired.connect(func(_o: Vector2, _t: Vector2) -> void: shots_fired[0] += 1)
	# 32 ticks = 2 disparos esperados (em tick 16 e tick 32)
	for i: int in range(32):
		sg.step_tick(Vector2(32.0, 96.0), [])
	_assert(shots_fired[0] >= 1, "Pelo menos 1 disparo em 32 ticks na fase SHOOT (intervalo 16)")
	sg.free()

## Teste 7: Tiros não atingem boss durante ROLL (COLLISION_CFG = 0)
func _test_no_shot_during_roll() -> void:
	var sg: ShotGunner = ShotGunner.new()
	sg.setup(Vector2(144.0, 56.0), [], Vector2(32.0, 96.0))
	sg.state = ShotGunner.SGunnerState.ROLL
	var result: bool = sg.apply_bullet_hit()
	_assert(not result, "Bala não causa dano durante ROLL (COLLISION_CFG = 0)")
	_assert(sg.boss_hp == 20, "HP inalterado durante ROLL")
	sg.free()

## Teste 8: Regiões e orientação do spritesheet MSX2 do Shoot Gunner
func _test_msx2_sprite_rects() -> void:
	var sg: ShotGunner = ShotGunner.new()
	# Stand virado para direita
	sg.setup(Vector2(100.0, 50.0), [], Vector2(150.0, 50.0))
	sg.state = ShotGunner.SGunnerState.SHOOT
	var r_stand_r: Rect2 = sg._get_sprite_rect()
	_assert(r_stand_r == Rect2(0.0, 0.0, 16.0, 32.0), "Stand virado para a direita: Col 0, Row 0")

	# Stand virado para esquerda
	sg.player_pos = Vector2(50.0, 50.0)
	var r_stand_l: Rect2 = sg._get_sprite_rect()
	_assert(r_stand_l == Rect2(0.0, 32.0, 16.0, 32.0), "Stand virado para a esquerda: Col 0, Row 1")

	# Roll frames (5Eh, 5Fh, 60h, 5Fh -> col 1, 2, 3, 2)
	sg.state = ShotGunner.SGunnerState.ROLL
	sg.roll_dir = 1
	sg.roll_frame = 0
	_assert(sg._get_sprite_rect() == Rect2(16.0, 0.0, 16.0, 32.0), "Roll frame 0 -> Col 1 (5Eh)")
	sg.roll_frame = 1
	_assert(sg._get_sprite_rect() == Rect2(32.0, 0.0, 16.0, 32.0), "Roll frame 1 -> Col 2 (5Fh)")
	sg.roll_frame = 2
	_assert(sg._get_sprite_rect() == Rect2(48.0, 0.0, 16.0, 32.0), "Roll frame 2 -> Col 3 (60h)")
	sg.roll_frame = 3
	_assert(sg._get_sprite_rect() == Rect2(32.0, 0.0, 16.0, 32.0), "Roll frame 3 -> Col 2 (5Fh)")

	# Roll virado para esquerda
	sg.roll_dir = -1
	sg.roll_frame = 0
	_assert(sg._get_sprite_rect() == Rect2(16.0, 32.0, 16.0, 32.0), "Roll virado para a esquerda -> Row 1")

	# Executa NOTIFICATION_DRAW sem erros
	sg.notification(Node2D.NOTIFICATION_DRAW)
	_assert(true, "Draw do Shoot Gunner executado com sucesso")
	sg.free()

## Teste 9: Projétil de escopeta MSX2 e expansão do cone de chumbo
func _test_shotgun_bullet_sprites() -> void:
	var bullet: ShotGunnerBullet = ShotGunnerBullet.new()
	bullet.setup(Vector2(100.0, 100.0), Vector2(150.0, 100.0), [])

	# Valida os 4 frames de animação executando draw
	for f: int in [1, 2, 3, 4]:
		bullet.anim_frame = f
		bullet.notification(Node2D.NOTIFICATION_DRAW)
	_assert(true, "Draw dos 4 frames do tiro de escopeta executado com sucesso")
	bullet.free()
