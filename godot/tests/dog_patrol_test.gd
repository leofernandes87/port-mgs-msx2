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
	print("\n--- Guard Dog (ID_DOG = 25) Canonical Behavior & Sprite Tests ---")

	# 1. Testes de Inicialização do Cão de Guarda (logic/actors/dog.asm:7-22)
	var dog: EnemyGuard = EnemyGuard.new()
	dog.actor_type_id = 25
	dog.init_dog()
	if not require(dog.is_dog, "is_dog deve ser true após init_dog()"): return
	if not require(dog.actor_type_id == 25, "actor_type_id deve ser 25 (ID_DOG)"): return
	if not require(is_equal_approx(dog.speed, EnemyGuard.DOG_SPEED), "Velocidade do cão deve ser exatamente DOG_SPEED (1.3 px/tick)"): return
	if not require(dog.touch_damage == 2, "Dano de mordida/contato do cão deve ser 2 HP (shapes.asm:37)"): return
	if not require(dog.dog_state == EnemyGuard.DogState.SLEEP, "Cão deve iniciar no estado SLEEP (Status 0)"): return
	if not require(dog.dog_wait_timer >= 32 and dog.dog_wait_timer <= 56, "Tempo de sono inicial deve ser entre 32 e 56 ticks"): return
	if not require(not dog.is_dead, "Cão deve iniciar vivo"): return

	# 2. Ciclo de Sono e Escuta (dog.asm:45-83)
	dog.dog_wait_timer = 1
	dog.step_tick([], Vector2(200.0, 200.0))
	if not require(dog.dog_state == EnemyGuard.DogState.LISTEN, "Ao expirar dog_wait_timer, cão deve passar para LISTEN (Status 1)"): return
	if not require(dog.dog_listen_timer >= 20 and dog.dog_listen_timer <= 32, "Tempo de escuta deve ser entre 20 e 32 ticks"): return

	# 3. Despertar Imediato por Proximidade (<= 48 px)
	dog.dog_state = EnemyGuard.DogState.SLEEP
	dog.position = Vector2(100.0, 100.0)
	# Jogador a 40 px de distância (proximidade de faro/ouvido)
	dog.step_tick([], Vector2(100.0, 140.0))
	if not require(dog.dog_state == EnemyGuard.DogState.CHASE, "Aproximação de Snake a <= 48 px deve acordar o cão para CHASE imediatamente"): return
	if not require(is_equal_approx(dog.speed, EnemyGuard.DOG_SPEED), "Velocidade em perseguição ativa deve ser DOG_SPEED (1.3 px/tick)"): return

	# 4. Despertar Explícito / Disparo de Arma
	dog.dog_state = EnemyGuard.DogState.SLEEP
	dog.wake_up_to_chase()
	if not require(dog.dog_state == EnemyGuard.DogState.CHASE, "wake_up_to_chase() deve colocar o cão em CHASE"): return
	if not require(dog.dog_bark_timer > 0, "Despertar com wake_up_to_chase() deve emitir latido inicial"): return

	# 5. Perseguição em Velocidade Canônica e Orientação pelo Eixo Dominante (dog.asm:88-103)
	dog.position = Vector2(100.0, 100.0)
	dog.current_direction = PlayerController.Direction.RIGHT
	dog.dog_wait_timer = 20
	# Jogador à direita e ligeiramente abaixo (+60 X, +10 Y -> dominante é X/RIGHT)
	var prev_x: float = dog.position.x
	dog.step_tick([], Vector2(160.0, 110.0))
	if not require(dog.position.x > prev_x, "Cão deve avançar em X na direção de Snake"): return
	if not require(is_equal_approx(dog.position.x - prev_x, EnemyGuard.DOG_SPEED), "Passo de perseguição deve ser de exatamente DOG_SPEED (1.3 px)"): return
	if not require(dog.current_direction == PlayerController.Direction.RIGHT, "Direção dominante deve ser RIGHT"): return

	# 6. Dano por Contato com Snake (2 HP)
	var dummy_player: PlayerController = PlayerController.new()
	dummy_player.life = 24
	dog.position = Vector2(100.0, 100.0)
	dog.step_tick([], Vector2(105.0, 100.0), false, PlayerController.Direction.DOWN, dummy_player)
	if not require(dummy_player.life == 22, "Contato do cão deve infligir 2 HP de dano a Snake"): return
	dummy_player.queue_free()

	# 7. Combate: Socos e Disparos contra o Cão
	# 1º soco: atordoa e deixa com 1 HP
	dog.punches_received = 0
	dog.is_dead = false
	dog.receive_punch()
	if not require(dog.punches_received == 1, "Cão deve registrar 1 soco recebido"): return
	if not require(not dog.is_dead, "Cão com 2 HP não morre com apenas 1 soco"): return
	if not require(dog.stunned_timer == 32, "Cão deve ficar atordoado por 32 ticks"): return
	if not require(dog.dog_state == EnemyGuard.DogState.CHASE, "Cão atingido por soco acorda em CHASE"): return

	# 2º soco: elimina o cão
	dog.stunned_timer = 0
	dog.receive_punch()
	if not require(dog.punches_received == 2, "Cão deve registrar 2 socos"): return
	if not require(dog.is_dead, "2 socos eliminam o cão de guarda"): return

	# Disparo balístico: elimina o cão com 1 único tiro
	var dog2: EnemyGuard = EnemyGuard.new()
	dog2.init_dog()
	var hit_ok: bool = dog2.take_bullet_hit(2)
	if not require(hit_ok, "take_bullet_hit deve retornar true"): return
	if not require(dog2.is_dead, "1 tiro elimina o cão de guarda com 2 HP"): return
	dog.queue_free()
	dog2.queue_free()

	# 8. Integração completa na Sala 006 com SandboxGameplay
	var sandbox_scene: PackedScene = preload("res://scenes/sandbox_gameplay.tscn")
	var sandbox: Control = sandbox_scene.instantiate() as Control
	root.add_child(sandbox)
	await process_frame
	await process_frame

	var room_ok: bool = sandbox.call("change_to_room", 6, Vector2(128.0, 180.0), PlayerController.Direction.UP)
	if not require(room_ok, "Sala 6 deve carregar com sucesso no Sandbox"): return
	if not require(sandbox.get("snapshot").room_id == 6, "Sala ativa deve ser a Sala 6"): return

	var enemies: Array = sandbox.get("enemies") as Array
	if not require(enemies.size() == 2, "Sala 6 deve ter exatamente 2 cães de guarda da ROM"): return

	var dog_count: int = 0
	var found_pos1: bool = false
	var found_pos2: bool = false
	for e in enemies:
		if e is EnemyGuard and e.is_dog:
			dog_count += 1
			if is_equal_approx(e.position.x, 160.0) and is_equal_approx(e.position.y, 64.0):
				found_pos1 = true
			elif is_equal_approx(e.position.x, 112.0) and is_equal_approx(e.position.y, 48.0):
				found_pos2 = true

	if not require(dog_count == 2, "Ambos os inimigos na Sala 6 devem ser cães (is_dog = true)"): return
	if not require(found_pos1, "Cão 1 da Sala 6 deve spawnar em (160, 64) conforme actorsinrooms.asm"): return
	if not require(found_pos2, "Cão 2 da Sala 6 deve spawnar em (112, 48) conforme actorsinrooms.asm"): return

	# Verificar que cães não disparam a sirene de rádio da guarnição humana ao spawnar
	var alert_sys: AlertSystem = sandbox.get("alert_system") as AlertSystem
	if not require(alert_sys.current_state == AlertSystem.AlertState.NORMAL, "Cães dormindo não devem acionar alerta de guarnição humana"): return

	# 9. Teste do Sistema de Binóculos com Cães de Guarda
	# Ao ativar binóculo e retornar, cães de guarda devem ser preservados
	sandbox.call("_backup_home_enemies")
	var backup: Array = sandbox.get("home_enemies_backup") as Array
	if not require(backup.size() == 2, "Backup de inimigos deve conter os 2 cães"): return
	if not require(bool(backup[0].get("is_dog", false)), "Cão 1 deve estar registrado como cão no backup"): return
	if not require(bool(backup[1].get("is_dog", false)), "Cão 2 deve estar registrado como cão no backup"): return

	sandbox.call("_restore_home_enemies")
	var restored_enemies: Array = sandbox.get("enemies") as Array
	if not require(restored_enemies.size() == 2, "Restauração deve conter exatamente 2 cães"): return
	if not require(restored_enemies[0].is_dog and restored_enemies[1].is_dog, "Inimigos restaurados devem ser cães válidos"): return
	if not require(is_equal_approx(restored_enemies[0].speed, EnemyGuard.DOG_SPEED), "Velocidade de DOG_SPEED (1.3 px/tick) deve ser restaurada"): return

	sandbox.queue_free()
	await process_frame

	print("DOG_PATROL_TEST_OK: Todos os testes de comportamento canônico e sprite dos cães passaram!")
	quit(0)
