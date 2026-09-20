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
	if not require(moved_now and player.position.x == 102.0, "Snake deve voltar a se mover normalmente após o soco"): return

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

	print("COMBAT_AND_HEALTH_OK: punch 8-ticks, 4-direction impact boxes, 64-tick stun, 3-punch kill, touch damage and 32-tick invulnerability")
	quit(0)
