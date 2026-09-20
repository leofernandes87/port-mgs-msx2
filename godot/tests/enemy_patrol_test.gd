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
	# 1. Carregar e instanciar EnemyGuard
	var packed_enemy: PackedScene = load("res://scenes/enemy.tscn") as PackedScene
	if not require(packed_enemy != null, "Falha ao carregar scenes/enemy.tscn"): return
	var enemy: EnemyGuard = packed_enemy.instantiate() as EnemyGuard
	if not require(enemy != null, "Falha ao instanciar EnemyGuard"): return
	root.add_child(enemy)
	await process_frame

	# 2. Configurações de velocidade por tipo canônico
	enemy.guard_type = EnemyGuard.GuardType.SLOW
	enemy._ready()
	if not require(is_equal_approx(enemy.speed, 0.5), "GuardType.SLOW deve ter velocidade 0.5"): return

	enemy.guard_type = EnemyGuard.GuardType.MEDIUM
	enemy._ready()
	if not require(is_equal_approx(enemy.speed, 1.0), "GuardType.MEDIUM deve ter velocidade 1.0"): return

	enemy.guard_type = EnemyGuard.GuardType.FAST
	enemy._ready()
	if not require(is_equal_approx(enemy.speed, 1.5), "GuardType.FAST deve ter velocidade 1.5"): return

	# 3. Patrulha de waypoints e vai-e-vem
	enemy.guard_type = EnemyGuard.GuardType.MEDIUM
	enemy.speed = 1.0
	enemy.position = Vector2(50.0, 50.0)
	enemy.set_patrol_path([Vector2(60.0, 50.0), Vector2(60.0, 70.0)])
	if not require(enemy.current_direction == PlayerController.Direction.RIGHT, "Direção inicial para target deve ser RIGHT"): return

	# Avançar 10 ticks a 1.0 px/tick até alcançar a coordenada X do primeiro waypoint (60, 50)
	var dummy_collision: Array[int] = []
	dummy_collision.resize(768)
	dummy_collision.fill(0)
	for i: int in range(10):
		enemy.step_tick(dummy_collision, Vector2(-100, -100))
	if not require(enemy.position == Vector2(60.0, 50.0), "Inimigo deve atingir (60, 50) em 10 ticks"): return

	# Tick 11: detecta chegada ao waypoint, comuta para o próximo e alinha direção para DOWN
	enemy.step_tick(dummy_collision, Vector2(-100, -100))
	if not require(enemy.current_direction == PlayerController.Direction.DOWN, "Direção deve mudar para DOWN rumo ao 2º waypoint"): return

	# Tick 12: avança em Y em direção a (60, 70)
	enemy.step_tick(dummy_collision, Vector2(-100, -100))
	if not require(enemy.position.y > 50.0, "Inimigo deve avançar no eixo Y"): return

	# 4. Linha de visão horizontal e tolerância (|diff_y| <= 6)
	enemy.position = Vector2(100.0, 100.0)
	enemy.current_direction = PlayerController.Direction.RIGHT

	# Snake diretamente em frente (distância 40 px, diff_y = 0)
	var sees: bool = enemy.check_line_of_sight(Vector2(140.0, 100.0), dummy_collision)
	if not require(sees, "Inimigo olhando para RIGHT deve ver Snake diretamente à sua frente"): return

	# Snake dentro da tolerância vertical (+5 px <= 6 px)
	sees = enemy.check_line_of_sight(Vector2(140.0, 105.0), dummy_collision)
	if not require(sees, "Inimigo olhando para RIGHT deve ver Snake dentro da tolerância vertical (|Y| <= 6)"): return

	# Snake fora da tolerância vertical (+8 px > 6 px)
	sees = enemy.check_line_of_sight(Vector2(140.0, 108.0), dummy_collision)
	if not require(not sees, "Inimigo olhando para RIGHT NÃO deve ver Snake fora da tolerância (|Y| > 6)"): return

	# Snake atrás do inimigo (x < enemy.x)
	sees = enemy.check_line_of_sight(Vector2(60.0, 100.0), dummy_collision)
	if not require(not sees, "Inimigo não deve ver Snake atrás de si"): return

	# Snake além do alcance máximo de visão (> 160 px)
	sees = enemy.check_line_of_sight(Vector2(280.0, 100.0), dummy_collision)
	if not require(not sees, "Inimigo não deve ver Snake além de MAX_VIEW_DISTANCE"): return

	# 5. Linha de visão vertical e tolerância (|diff_x| <= 8)
	enemy.current_direction = PlayerController.Direction.UP

	# Snake diretamente acima
	sees = enemy.check_line_of_sight(Vector2(100.0, 60.0), dummy_collision)
	if not require(sees, "Inimigo olhando para UP deve ver Snake diretamente acima"): return

	# Snake dentro da tolerância horizontal (+7 px <= 8 px)
	sees = enemy.check_line_of_sight(Vector2(107.0, 60.0), dummy_collision)
	if not require(sees, "Inimigo olhando para UP deve ver Snake dentro da tolerância horizontal (|X| <= 8)"): return

	# Snake fora da tolerância horizontal (+10 px > 8 px)
	sees = enemy.check_line_of_sight(Vector2(110.0, 60.0), dummy_collision)
	if not require(not sees, "Inimigo olhando para UP NÃO deve ver Snake fora da tolerância horizontal (|X| > 8)"): return

	# 6. Oclusão de visão por obstáculos sólidos na grade de colisão
	enemy.current_direction = PlayerController.Direction.RIGHT
	var occluded_collision: Array[int] = []
	occluded_collision.resize(768)
	occluded_collision.fill(0)
	# Colocar bloco obstáculo em x=128 (tile x=16, y=12 => idx = 12 * 32 + 16 = 400)
	# O feixe de (100, 100) a (160, 100) passa por x=128, y=100
	var obstacle_tx: int = 16
	var obstacle_ty: int = 12
	occluded_collision[obstacle_ty * 32 + obstacle_tx] = 1

	sees = enemy.check_line_of_sight(Vector2(160.0, 100.0), occluded_collision)
	if not require(not sees, "Linha de visão deve ser bloqueada quando há obstáculo sólido (colisão = 1) no trajeto"): return

	# Sem obstáculo (grid limpo)
	sees = enemy.check_line_of_sight(Vector2(160.0, 100.0), dummy_collision)
	if not require(sees, "Sem obstáculo, a visão deve alcançar Snake normalmente"): return

	# 7. Disparo de alerta e sinalização
	enemy.is_alert = false
	enemy.position = Vector2(100.0, 100.0)
	enemy.set_patrol_path([Vector2(200.0, 100.0), Vector2(50.0, 100.0)])
	enemy.step_tick(dummy_collision, Vector2(160.0, 100.0))
	if not require(enemy.is_alert, "step_tick deve ativar is_alert quando Snake é avistado"): return
	if not require(enemy.state == EnemyGuard.GuardState.ALERT, "Estado deve mudar para GuardState.ALERT"): return
	if not require(enemy.alert_timer == 60.0, "Timer de alerta deve ser inicializado em 60.0"): return

	print("ENEMY_PATROL_OK: waypoints patrol, authentic sight tolerances, obstacle occlusion, alert trigger")
	quit(0)
