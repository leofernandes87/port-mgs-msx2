class_name ElectrifiedFloorTest
extends SceneTree

## Teste automatizado para Pisos Eletrificados e Painéis de Força (Etapa 22).
## Verifica fidelidade à lógica de logic/damageelectric.asm, logic/actors/powerswitch.asm,
## e logic/damagetoenemy.asm no MSX2 RC750.

var total_passed: int = 0
var total_failed: int = 0

func _init() -> void:
	print("\n--- Electrified Floors & Power Panels Tests ---")
	_run_all_tests()
	_print_summary()
	quit(0 if total_failed == 0 else 1)

func _assert_true(condition: bool, message: String) -> void:
	if condition:
		total_passed += 1
		print("  PASS: %s" % message)
	else:
		total_failed += 1
		printerr("  FAIL: %s" % message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		total_passed += 1
		print("  PASS: %s" % message)
	else:
		total_failed += 1
		printerr("  FAIL: %s — esperado '%s', obtido '%s'" % [message, str(expected), str(actual)])

func _run_all_tests() -> void:
	_test_rooms_configuration()
	_test_hazard_tiles_detection()
	_test_damage_cadence_and_delay()
	_test_safe_tiles_no_damage()
	_test_power_panel_bullet_immunity()
	_test_power_panel_missile_destruction()
	_test_floor_deactivation_after_panel_destruction()
	_test_reset_state()
	_test_room37_end_to_end_simulation()

func _test_rooms_configuration() -> void:
	var efs := ElectrifiedFloorSystem.new()
	_assert_true(efs.is_room_electrified(16), "Sala 16 possui piso eletrificado")
	_assert_true(efs.is_room_electrified(37), "Sala 37 possui piso eletrificado")
	_assert_true(efs.is_room_electrified(40), "Sala 40 possui piso eletrificado")
	_assert_true(efs.is_room_electrified(110), "Sala 110 possui piso eletrificado")
	_assert_true(efs.is_room_electrified(116), "Sala 116 possui piso eletrificado")

	_assert_true(not efs.is_room_electrified(0), "Sala 0 não é eletrificada")
	_assert_true(not efs.is_room_electrified(8), "Sala 8 não é eletrificada")
	_assert_true(not efs.is_room_electrified(121), "Sala 121 não é eletrificada")
	_assert_true(not efs.is_room_electrified(211), "Sala 211 não é eletrificada")

	_assert_eq(ElectrifiedFloorSystem.DAMAGE_PER_SHOCK, 2, "Dano por choque é exatamente 2 HP")
	_assert_eq(ElectrifiedFloorSystem.SHOCK_DELAY_TICKS, 8, "Intervalo de choque é de 8 ticks")
	_assert_eq(ElectrifiedFloorSystem.SFX_ID, 24, "SFX ID de choque elétrico é 0x18 (24)")

func _test_hazard_tiles_detection() -> void:
	var efs := ElectrifiedFloorSystem.new()
	# Injeta tiles sintéticos conhecidos na sala 37
	efs.set_custom_hazard_tiles(37, [Vector2i(10, 5), Vector2i(11, 5), Vector2i(12, 5)])

	_assert_true(efs.is_tile_electrified(37, 10, 5), "Tile (10, 5) da Sala 37 é eletrificado")
	_assert_true(efs.is_tile_electrified(37, 11, 5), "Tile (11, 5) da Sala 37 é eletrificado")
	_assert_true(not efs.is_tile_electrified(37, 0, 0), "Tile (0, 0) da Sala 37 não é eletrificado")
	_assert_true(not efs.is_tile_electrified(8, 10, 5), "Sala não-eletrificada retorna false")

func _test_damage_cadence_and_delay() -> void:
	var efs := ElectrifiedFloorSystem.new()
	efs.setup_room(37)
	efs.set_custom_hazard_tiles(37, [Vector2i(5, 5)])

	# Posição do jogador sobre o tile (5, 5): X = 5 * 8 + 4 = 44, Y = 5 * 8 + 4 = 44
	var pos := Vector2(44.0, 44.0)

	# 1º tick: choque imediato de 2 HP
	var dmg0: int = efs.check_player_hazard(pos, 37)
	_assert_eq(dmg0, 2, "1º contato com piso causa 2 HP de dano")
	_assert_eq(efs.damage_delay_timer, 8, "Timer de delay ajustado para 8 ticks")

	# Ticks 1 a 8: dano deve ser 0 enquanto o delay de 8 frames é consumido
	for i in range(1, 9):
		var dmg_wait: int = efs.check_player_hazard(pos, 37)
		_assert_eq(dmg_wait, 0, "Tick de espera %d não causa dano contínuo" % i)

	# 9º tick: delay esgotou (timer == 0), novo choque de 2 HP ocorre
	var dmg_repeat: int = efs.check_player_hazard(pos, 37)
	_assert_eq(dmg_repeat, 2, "Após 8 ticks de delay, novo choque de 2 HP ocorre")

func _test_safe_tiles_no_damage() -> void:
	var efs := ElectrifiedFloorSystem.new()
	efs.setup_room(37)
	efs.set_custom_hazard_tiles(37, [Vector2i(10, 10)])

	# Jogador na entrada (X=16.0, Y=100.0) longe do piso eletrificado
	var safe_pos := Vector2(16.0, 100.0)
	var dmg: int = efs.check_player_hazard(safe_pos, 37)
	_assert_eq(dmg, 0, "Pisar em área segura não causa dano")

func _test_power_panel_bullet_immunity() -> void:
	var panel := PowerPanel.new()
	panel.setup(37, Vector2(100.0, 16.0), false)

	_assert_eq(panel.hp, 2, "Painel de força inicializa com 2 HP")
	_assert_true(not panel.is_destroyed, "Painel não está destruído inicialmente")

	# Tiros de pistola e metralhadora causam 0 de dano (0xFF no MSX2 BulletDamage)
	var hit1: bool = panel.take_hit("BULLET", 2)
	_assert_true(not hit1, "take_hit com BULLET retorna false (imune)")
	_assert_eq(panel.hp, 2, "HP do painel permanece 2 após tiro de bala")
	_assert_true(not panel.is_destroyed, "Painel permanece intacto contra balas")
	panel.free()

func _test_power_panel_missile_destruction() -> void:
	var panel := PowerPanel.new()
	panel.setup(37, Vector2(100.0, 16.0), false)

	var signal_emitted: Array[bool] = [false]
	panel.panel_destroyed.connect(func(_rid: int) -> void: signal_emitted[0] = true)

	# Míssil causa 5 de dano (MissileDamage no MSX2), destruindo com 1 impacto
	var hit: bool = panel.take_hit("MISSILE", 5)
	_assert_true(hit, "take_hit com MISSILE retorna true")
	_assert_eq(panel.hp, 0, "HP do painel reduzido a 0")
	_assert_true(panel.is_destroyed, "Painel marcado como destruído")
	_assert_true(signal_emitted[0], "Sinal panel_destroyed emitido")

	# Tentativa de danificar painel já destruído
	var hit_again: bool = panel.take_hit("MISSILE", 5)
	_assert_true(not hit_again, "Painel já destruído não processa novos acertos")
	panel.free()


func _test_floor_deactivation_after_panel_destruction() -> void:
	var efs := ElectrifiedFloorSystem.new()
	efs.setup_room(37)
	efs.set_custom_hazard_tiles(37, [Vector2i(5, 5)])

	var hazard_pos := Vector2(44.0, 44.0)

	# Confirma choque inicial
	var dmg1: int = efs.check_player_hazard(hazard_pos, 37)
	_assert_eq(dmg1, 2, "Choque ativo antes de desligar painel")

	# Desliga o painel de força da sala 37
	efs.set_power(37, false)
	_assert_true(not efs.is_power_on(37), "Força da sala 37 desligada")

	# Pisar no mesmo piso agora não deve dar choque
	efs.damage_delay_timer = 0
	var dmg2: int = efs.check_player_hazard(hazard_pos, 37)
	_assert_eq(dmg2, 0, "Piso eletrificado inofensivo após desligamento do painel")

func _test_reset_state() -> void:
	var efs := ElectrifiedFloorSystem.new()
	efs.set_power(37, false)
	efs.set_power(110, false)
	_assert_true(not efs.is_power_on(37), "Sala 37 desligada")
	_assert_true(not efs.is_power_on(110), "Sala 110 desligada")

	efs.reset_state()
	_assert_true(efs.is_power_on(37), "Reset restaura força na Sala 37")
	_assert_true(efs.is_power_on(110), "Reset restaura força na Sala 110")
	_assert_eq(efs.damage_delay_timer, 0, "Reset zera damage_delay_timer")

func _test_room37_end_to_end_simulation() -> void:
	var efs := ElectrifiedFloorSystem.new()
	efs.setup_room(37)

	# Se os dados reais de room 37 foram carregados do JSON, verifica contagem
	var coords: Array[Vector2i] = efs.get_hazard_coords(37)
	if coords.size() > 0:
		_assert_true(coords.size() >= 300, "Sala 37 possui mais de 300 tiles eletrificados extraídos (%d)" % coords.size())
	else:
		efs.set_custom_hazard_tiles(37, [Vector2i(10, 5)])

	var panel := PowerPanel.new()
	panel.setup(37, Vector2(100.0, 16.0), false)
	panel.panel_destroyed.connect(func(rid: int) -> void: efs.set_power(rid, false))

	# 1. Colisão do míssil com o painel em (100, 16)
	_assert_true(panel.collides_with_point(Vector2(100.0, 16.0)), "Míssil em (100, 16) colide com painel")
	_assert_true(panel.collides_with_point(Vector2(96.0, 18.0)), "Míssil dentro do raio colide com painel")
	_assert_true(not panel.collides_with_point(Vector2(20.0, 20.0)), "Míssil longe não colide com painel")

	# 2. Destruição do painel pelo míssil
	var destroyed: bool = panel.take_hit("MISSILE", 5)
	_assert_true(destroyed, "Míssil destrói painel da sala 37")
	_assert_true(not efs.is_power_on(37), "Piso da Sala 37 é desativado imediatamente")
	panel.free()

func _print_summary() -> void:
	print("ELECTRIFIED_FLOOR_TEST_OK: %d testes passaram, %d falharam" % [total_passed, total_failed])
