extends SceneTree
## Suíte de testes headless — Míssil Teleguiado (Remote-Controlled Missile — Etapa 20)
## Valida as mecânicas canônicas extraídas de logic/weapon/missile.asm e logic/maxammo.asm
## Token de conclusão: REMOTE_MISSILE_OK

var _pass: int = 0
var _fail: int = 0

func _initialize() -> void:
	_run_all()
	var result: String = "REMOTE_MISSILE_OK: %d testes passaram, %d falharam" % [_pass, _fail]
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
	print("--- Remote-Controlled Missile Tests ---")
	_test_missile_setup_and_properties()
	_test_missile_steering()
	_test_wall_collision_causes_explosion()
	_test_boundaries_explosion()
	_test_explosion_timer_and_destruction()
	_test_enemy_hit_and_damage()
	_test_weapon_system_capacities_and_ammo()
	_test_rank_system_integration()
	_test_ammo_crate_refill()
	_test_canonical_room_147_and_collection()

## Teste 1: Configuração inicial, velocidade 4 px/tick e offsets da ROM
func _test_missile_setup_and_properties() -> void:
	var m: RemoteMissile = RemoteMissile.new()
	m.setup(Vector2(100.0, 100.0), PlayerController.Direction.UP)
	_assert(m.speed == 4.0, "Velocidade escalar = 4.0 px/tick (MissileIniSpeed)")
	_assert(m.damage == 5, "Dano = 5 HP (MissileDamage)")
	_assert(m.explosion_timer == 15, "Tempo de explosão = 15 ticks (0x0F)")
	_assert(m.position == Vector2(100.0, 88.0), "Spawn ligeiramente à frente/acima do jogador")
	_assert(m.velocity == Vector2(0.0, -4.0), "Velocidade inicial orientada para CIMA")
	_assert(m.state == RemoteMissile.MissileState.FLIGHT, "Estado inicial = FLIGHT")
	m.free()

## Teste 2: Manobra em voo em tempo real (steer nas 4 direções)
func _test_missile_steering() -> void:
	var m: RemoteMissile = RemoteMissile.new()
	m.setup(Vector2(100.0, 100.0), PlayerController.Direction.UP)

	m.steer(Vector2i(1, 0)) # Direita
	_assert(m.current_direction == PlayerController.Direction.RIGHT, "Curva para DIREITA")
	_assert(m.velocity == Vector2(4.0, 0.0), "Velocidade = (4, 0)")

	m.steer(Vector2i(0, 1)) # Baixo
	_assert(m.current_direction == PlayerController.Direction.DOWN, "Curva para BAIXO")
	_assert(m.velocity == Vector2(0.0, 4.0), "Velocidade = (0, 4)")

	m.steer(Vector2i(-1, 0)) # Esquerda
	_assert(m.current_direction == PlayerController.Direction.LEFT, "Curva para ESQUERDA")
	_assert(m.velocity == Vector2(-4.0, 0.0), "Velocidade = (-4, 0)")

	m.steer(Vector2i(0, -1)) # Cima
	_assert(m.current_direction == PlayerController.Direction.UP, "Curva para CIMA")
	_assert(m.velocity == Vector2(0.0, -4.0), "Velocidade = (0, -4)")
	m.free()

## Teste 3: Colisão com parede sólida da grade 32x24 aciona explosão
func _test_wall_collision_causes_explosion() -> void:
	var grid: Array = []
	for i in range(768):
		grid.append(0)
	# Cria bloco sólido na coluna 15, linha 10 (X: 120..127, Y: 80..87)
	grid[10 * 32 + 15] = 1

	var m: RemoteMissile = RemoteMissile.new()
	# Míssil apontado para a direita em (118, 84), avança 4px e atinge (122, 84) dentro do bloco sólido
	m.setup(Vector2(118.0, 96.0), PlayerController.Direction.RIGHT)
	m.position = Vector2(118.0, 84.0)
	m.velocity = Vector2(4.0, 0.0)

	var exploded_received: Array[bool] = [false]
	m.missile_exploded.connect(func(_p: Vector2) -> void: exploded_received[0] = true)

	var alive: bool = m.step_tick(grid)
	_assert(alive, "Permanece ativo no ciclo de explosão")
	_assert(m.state == RemoteMissile.MissileState.EXPLODING, "Transita para estado EXPLODING ao colidir com parede")
	_assert(exploded_received[0], "Sinal missile_exploded emitido")
	_assert(m.velocity == Vector2.ZERO, "Velocidade zerada durante explosão")
	m.free()

## Teste 4: Limites de tela do MSX2 (X < 9 ou X > 248 ou Y > 184)
func _test_boundaries_explosion() -> void:
	var m: RemoteMissile = RemoteMissile.new()
	m.setup(Vector2(10.0, 100.0), PlayerController.Direction.LEFT)
	m.position = Vector2(10.0, 100.0)
	m.velocity = Vector2(-4.0, 0.0)

	# Ao avançar, posição torna-se 6.0 (< MIN_X = 9.0)
	m.step_tick([])
	_assert(m.state == RemoteMissile.MissileState.EXPLODING, "Explode ao cruzar borda esquerda da tela")
	m.free()

## Teste 5: Contagem de 15 ticks de explosão e sinal missile_destroyed
func _test_explosion_timer_and_destruction() -> void:
	var m: RemoteMissile = RemoteMissile.new()
	m.setup(Vector2(100.0, 100.0), PlayerController.Direction.UP)
	m.explode()

	var destroyed_signal: Array[bool] = [false]
	m.missile_destroyed.connect(func() -> void: destroyed_signal[0] = true)

	# 14 ticks em explosão
	for i in range(14):
		var alive: bool = m.step_tick([])
		_assert(alive, "Tick %d: explosão ainda em andamento" % (i + 1))

	# 15º tick: encerra
	var still_alive: bool = m.step_tick([])
	_assert(not still_alive, "Tick 15: míssil concluído")
	_assert(m.state == RemoteMissile.MissileState.FINISHED, "Estado final = FINISHED")
	_assert(destroyed_signal[0], "Sinal missile_destroyed emitido")
	m.free()

## Teste 6: Detecção de colisão com inimigo e aplicação de 5 HP de dano
func _test_enemy_hit_and_damage() -> void:
	var m: RemoteMissile = RemoteMissile.new()
	m.setup(Vector2(100.0, 100.0), PlayerController.Direction.UP)
	m.position = Vector2(100.0, 80.0)

	var enemy_pos := Vector2(104.0, 82.0)
	_assert(m.check_actor_hit(enemy_pos, 12.0), "check_actor_hit retorna true dentro do raio de 12px")
	_assert(not m.check_actor_hit(Vector2(200.0, 82.0), 12.0), "check_actor_hit retorna false fora do raio")

	# Simula acerto no soldado (dano de míssil é 5 HP)
	var enemy_guard: EnemyGuard = EnemyGuard.new()
	var killed: bool = enemy_guard.take_bullet_hit(m.damage)
	_assert(killed, "take_bullet_hit retorna true com impacto do míssil")
	_assert(enemy_guard.is_dead, "Dano de 5 HP do míssil elimina o soldado instantaneamente")
	m.free()
	enemy_guard.free()

## Teste 7: WeaponSystem com WEAPON_MISSILE e limites por patente
func _test_weapon_system_capacities_and_ammo() -> void:
	var ws: WeaponSystem = WeaponSystem.new()
	_assert(ws.add_weapon(WeaponSystem.WEAPON_MISSILE, 5), "Arma MISSILE adicionada com sucesso")
	_assert(ws.has_weapon(WeaponSystem.WEAPON_MISSILE), "has_weapon retorna true")
	_assert(ws.ammo[WeaponSystem.WEAPON_MISSILE] == 5, "Munição inicial = 5")
	_assert(ws.max_ammo[WeaponSystem.WEAPON_MISSILE] == 5, "Capacidade Rank 1 = 5")

	ws.update_rank_capacities(2)
	_assert(ws.max_ammo[WeaponSystem.WEAPON_MISSILE] == 10, "Capacidade Rank 2 = 10")

	ws.update_rank_capacities(3)
	_assert(ws.max_ammo[WeaponSystem.WEAPON_MISSILE] == 15, "Capacidade Rank 3 = 15")

	ws.update_rank_capacities(4)
	_assert(ws.max_ammo[WeaponSystem.WEAPON_MISSILE] == 20, "Capacidade Rank 4 = 20")

	# Consumo de munição
	ws.select_weapon(WeaponSystem.WEAPON_MISSILE)
	_assert(ws.can_fire(), "can_fire retorna true com munição")
	_assert(ws.consume_ammo(), "consume_ammo consome 1 unidade")
	_assert(ws.ammo[WeaponSystem.WEAPON_MISSILE] == 4, "Munição reduzida para 4")

## Teste 8: Integração com RankSystem (get_max_ammo)
func _test_rank_system_integration() -> void:
	var rs: RankSystem = RankSystem.new()
	rs.current_rank = 1
	_assert(rs.get_max_ammo("MISSILE") == 5, "Rank 1: 5 mísseis")
	rs.current_rank = 2
	_assert(rs.get_max_ammo("MISSILE") == 10, "Rank 2: 10 mísseis")
	rs.current_rank = 3
	_assert(rs.get_max_ammo("MISSILE") == 15, "Rank 3: 15 mísseis")
	rs.current_rank = 4
	_assert(rs.get_max_ammo("MISSILE") == 20, "Rank 4: 20 mísseis")

## Teste 9: Recarga de mísseis via caixa de munição
func _test_ammo_crate_refill() -> void:
	var ws: WeaponSystem = WeaponSystem.new()
	ws.add_weapon(WeaponSystem.WEAPON_MISSILE, 2)
	ws.update_rank_capacities(2) # Capacidade = 10
	ws.add_ammo_crate()
	_assert(ws.ammo[WeaponSystem.WEAPON_MISSILE] == 7, "Caixa de munição recarrega +5 mísseis (2 + 5 = 7)")

## Teste 10: Localização canônica na Sala 147 e coleta de ItemBox
func _test_canonical_room_147_and_collection() -> void:
	var rm: RoomManager = RoomManager.new()
	var room_data: Dictionary = rm.load_room_actors(147)
	_assert(not room_data.is_empty(), "Sala 147 carregada pelo RoomManager")
	var items: Array = room_data.get("items", [])
	_assert(items.size() == 1, "Sala 147 possui exatamente 1 item canônico")
	var item_info: Dictionary = items[0] as Dictionary
	_assert(int(item_info.get("item_type_id", 0)) == 7, "Item da Sala 147 é MISSILE (tipo 7)")
	_assert(int(item_info.get("x", 0)) == 72 and int(item_info.get("y", 0)) == 32, "Posição canônica na Sala 147 é (72, 32)")

	# Coleta da ItemBox na Sala 147
	ItemBox.collected_boxes.erase("147_MISSILE_72_32")
	var inv: InventoryManager = InventoryManager.new()
	var ws: WeaponSystem = WeaponSystem.new()
	var box: ItemBox = ItemBox.new()
	box.room_id = 147
	box.item_id = WeaponSystem.WEAPON_MISSILE
	box.position = Vector2(72.0, 32.0)

	# Snake longe (distância 50px)
	var touched_far: bool = box.step_tick(Vector2(20.0, 32.0), inv, ws)
	_assert(not touched_far and not box.collected, "ItemBox não coletada quando longe")
	_assert(not ws.has_weapon(WeaponSystem.WEAPON_MISSILE), "Snake não possui míssil antes de tocar na caixa")

	# Snake aproxima (distância 10px)
	var touched_near: bool = box.step_tick(Vector2(70.0, 32.0), inv, ws)
	_assert(touched_near and box.collected, "ItemBox do míssil coletada ao aproximar")
	_assert(ws.has_weapon(WeaponSystem.WEAPON_MISSILE), "Snake adquire WEAPON_MISSILE")
	_assert(ws.ammo[WeaponSystem.WEAPON_MISSILE] == 5, "Munição inicial adquirida é 5")

	box.free()
