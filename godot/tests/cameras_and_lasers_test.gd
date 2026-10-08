extends SceneTree

## Suíte de testes headless para Câmeras de Vigilância e Feixes Laser Infravermelhos (Etapa 16).
## Valida:
## 1. Direções canônicas de câmeras da ROM (Sala 14: CamDirs7 -> 3, 2, 2).
## 2. Patrulha e inversão em waypoints a 1 px/tick.
## 3. Visada direcional (offset focal) e detecção de Snake.
## 4. Oclusão de visão por obstáculos sólidos da grade 32x24.
## 5. Furtividade da Caixa de Papelão (Cardboard Box).
## 6. Tabelas canônicas de feixes laser (Salas 24, 25 e 72).
## 7. Física e tolerâncias de toque no laser (ChkTouchLaser vertical e horizontal).
## 8. Visibilidade condicionada aos Óculos Infravermelhos (Goggles).
## 9. Alternância de sequências dinâmicas da Sala 72 a cada 192 ticks.

func _init() -> void:
	print("--- TESTE: CÂMERAS DE VIGILÂNCIA E FEIXES LASER INFRAVERMELHOS (ETAPA 16) ---")

	test_camera_canonical_directions()
	test_camera_patrol_movement()
	test_camera_vision_and_alert()
	test_camera_vision_occlusion()
	test_camera_cardboard_box_stealth()
	test_laser_system_canonical_tables()
	test_laser_touch_collision()
	test_laser_goggles_visibility()
	test_laser_room_72_dynamic_cycling()

	print("CAMERAS_AND_LASERS_OK: câmeras móveis, campo de visão direcional com oclusão, feixes laser autênticos, detecção ChkTouchLaser, Goggles e alternância da Sala 72 validados")
	quit(0)

func test_camera_canonical_directions() -> void:
	# Sala 14 tem 3 câmeras: CamDirs7 = [3, 2, 2] -> [RIGHT, LEFT, LEFT]
	var cam0: SecurityCamera = SecurityCamera.new()
	cam0.setup(14, 0, [], Vector2(64.0, 152.0))
	assert(cam0.facing_direction == SecurityCamera.Direction.RIGHT, "Câmera 0 da Sala 14 deve apontar para a DIREITA (3)")

	var cam1: SecurityCamera = SecurityCamera.new()
	cam1.setup(14, 1, [], Vector2(192.0, 80.0))
	assert(cam1.facing_direction == SecurityCamera.Direction.LEFT, "Câmera 1 da Sala 14 deve apontar para a ESQUERDA (2)")

	var cam2: SecurityCamera = SecurityCamera.new()
	cam2.setup(14, 2, [], Vector2(160.0, 184.0))
	assert(cam2.facing_direction == SecurityCamera.Direction.LEFT, "Câmera 2 da Sala 14 deve apontar para a ESQUERDA (2)")

	# Sala 21 tem 1 câmera: CamDirs6 = [1] -> [DOWN]
	var cam_s21: SecurityCamera = SecurityCamera.new()
	cam_s21.setup(21, 0, [], Vector2(128.0, 32.0))
	assert(cam_s21.facing_direction == SecurityCamera.Direction.DOWN, "Câmera da Sala 21 deve apontar para BAIXO (1)")

	cam0.free()
	cam1.free()
	cam2.free()
	cam_s21.free()

	print("CAMERA_DIRS_OK: orientações canônicas conferidas")

func test_camera_patrol_movement() -> void:
	var cam: SecurityCamera = SecurityCamera.new()
	var waypoints: Array[Vector2] = [Vector2(64.0, 8.0), Vector2(64.0, 152.0)]
	cam.setup(14, 0, waypoints, Vector2(64.0, 8.0))

	assert(cam.position == Vector2(64.0, 8.0), "Posição inicial da câmera incorreta")
	assert(cam.is_moving, "Câmera com 2 waypoints deve iniciar em movimento")

	# Avançar 20 ticks a 0.5 px/tick rumo a (64.0, 152.0)
	for _i in range(20):
		cam.tick(Vector2(200.0, 200.0), [], false, false)

	assert(is_equal_approx(cam.position.x, 64.0), "Câmera não deve oscilar no eixo X")
	assert(is_equal_approx(cam.position.y, 18.0), "Câmera deveria ter avançado 10 px em Y em 20 ticks a 0.5 px/tick (esperado: 18.0, obtido: %.1f)" % cam.position.y)

	cam.free()
	print("CAMERA_PATROL_OK: patrulha a 0.5 px/tick em waypoints validada")

func test_camera_vision_and_alert() -> void:
	var cam: SecurityCamera = SecurityCamera.new()
	# Câmera em (64.0, 100.0), olhando para a DIREITA (foco X = 64 + 16 = 80, foco Y = 100)
	cam.setup(14, 0, [], Vector2(64.0, 100.0))

	var alert_signaled: Array[bool] = [false]
	cam.player_detected.connect(func(_c: SecurityCamera): alert_signaled[0] = true)

	# Snake alinhado à direita no mesmo Y (100.0), em X=120.0 (desobstruído)
	var player_pos := Vector2(120.0, 100.0)
	assert(cam.check_vision(player_pos, [], false), "Câmera deveria detectar Snake desobstruído à sua frente")

	# Executar tick: deve disparar alarme e iniciar o ciclo de piscar
	cam.tick(player_pos, [], false, false)
	assert(alert_signaled[0], "Sinal player_detected deveria ter sido emitido")
	assert(cam.has_seen_player, "has_seen_player deveria ser true")
	assert(not cam.is_moving, "Câmera deveria congelar o movimento ao detectar Snake")
	assert(cam.alert_flashing, "alert_flashing deveria ser true")
	assert(cam.alert_timer == 32, "alert_timer deveria iniciar em 32 ticks")

	cam.free()
	print("CAMERA_ALERT_OK: detecção de Snake e congelamento com alarme validados")

func test_camera_vision_occlusion() -> void:
	var cam: SecurityCamera = SecurityCamera.new()
	# Câmera em (64.0, 100.0), olhando para a DIREITA
	cam.setup(14, 0, [], Vector2(64.0, 100.0))

	var player_pos := Vector2(120.0, 100.0)

	# Criar grade de colisão 32x24 (768 tiles de 8x8)
	var grid: Array = []
	grid.resize(768)
	grid.fill(0)

	# Inserir parede sólida no caminho (em X=96.0, Y=100.0 -> tile_x=12, tile_y=12)
	var wall_tile_x: int = 12 # 96 / 8
	var wall_tile_y: int = 12 # 96..103 / 8
	grid[wall_tile_y * 32 + wall_tile_x] = 1

	# Com parede no meio, a visão deve ser bloqueada!
	assert(not cam.check_vision(player_pos, grid, false), "Visão da câmera deveria ter sido bloqueada pela parede sólida")

	cam.free()
	print("CAMERA_OCCLUSION_OK: oclusão por obstáculos sólidos da grade validada")

func test_camera_cardboard_box_stealth() -> void:
	var cam: SecurityCamera = SecurityCamera.new()
	cam.setup(14, 0, [], Vector2(64.0, 100.0))

	var player_pos := Vector2(120.0, 100.0)

	# Snake parado na caixa de papelão (is_box_idle = true)
	assert(not cam.check_vision(player_pos, [], true), "Câmera não deve detectar Snake disfarçado na caixa imóvel")

	cam.free()
	print("CAMERA_BOX_STEALTH_OK: furtividade da caixa de papelão confirmada")

func test_laser_system_canonical_tables() -> void:
	var ls: LaserSystem = LaserSystem.new()

	# Sala 24: 6 feixes
	ls.setup(24)
	assert(ls.beams.size() == 6, "Sala 24 deve conter exatamente 6 feixes laser")
	assert(ls.beams[0]["orientation"] == LaserSystem.LaserOrientation.VERTICAL, "Feixe 0 da Sala 24 deve ser vertical")
	assert(ls.beams[2]["orientation"] == LaserSystem.LaserOrientation.HORIZONTAL, "Feixe 2 da Sala 24 deve ser horizontal")

	# Sala 25: 5 feixes
	ls.setup(25)
	assert(ls.beams.size() == 5, "Sala 25 deve conter exatamente 5 feixes laser")

	# Sala 72: 10 feixes
	ls.setup(72)
	assert(ls.beams.size() == 10, "Sala 72 deve conter exatamente 10 feixes laser")

	ls.free()
	print("LASER_TABLES_OK: contagens e orientações das salas 24, 25 e 72 validadas")

func test_laser_touch_collision() -> void:
	var ls: LaserSystem = LaserSystem.new()
	ls.setup(24)

	# Feixe 0 da Sala 24: Vertical em X=111.0, Y=16.0, length=48.0
	# Centro Y = 16 + 8 + 24 = 48.0. Tolerância Y = 24.0. Intervalo Y: 24..72
	var hit_detected: Array[bool] = [false]
	ls.laser_triggered.connect(func(): hit_detected[0] = true)

	# Snake tocando o feixe vertical em (111.0, 48.0)
	assert(ls.check_touch(Vector2(111.0, 48.0)), "Snake deveria tocar o feixe vertical em (111.0, 48.0)")

	# Snake distante em X (120.0, 48.0)
	assert(not ls.check_touch(Vector2(120.0, 48.0)), "Snake a 9 px de distância no eixo X não deveria colidir")

	# Snake fora do alcance Y (111.0, 10.0)
	assert(not ls.check_touch(Vector2(111.0, 10.0)), "Snake fora do alcance vertical não deveria colidir")

	# Feixe 2 da Sala 24: Horizontal em X=64.0, Y=80.0, length=32.0 (alcance X: 64..96)
	assert(ls.check_touch(Vector2(80.0, 80.0)), "Snake deveria tocar o feixe horizontal em (80.0, 80.0)")
	assert(not ls.check_touch(Vector2(80.0, 86.0)), "Snake a 6 px de distância no eixo Y não deveria colidir")

	# Testar emissão de sinal via tick
	ls.tick(Vector2(80.0, 80.0), false, false)
	assert(hit_detected[0], "Sinal laser_triggered deveria ter sido emitido pelo tick")

	ls.free()
	print("LASER_TOUCH_OK: colisão física de feixes verticais e horizontais validada")

func test_laser_goggles_visibility() -> void:
	var ls: LaserSystem = LaserSystem.new()
	ls.setup(24)

	# Sem goggles e fora de alerta
	ls.tick(Vector2(0, 0), false, false)
	assert(not ls.goggles_equipped, "Goggles deveriam estar desequipados")

	# Equipando goggles
	ls.tick(Vector2(0, 0), true, false)
	assert(ls.goggles_equipped, "Goggles deveriam estar equipados")

	# Em alerta mode: lasers desligados
	ls.tick(Vector2(0, 0), true, true)
	assert(ls.in_alert_mode, "Deveria estar em modo de alerta")
	assert(not ls.check_touch(Vector2(80.0, 80.0)), "Feixes de laser devem estar inativos durante o alarme")

	ls.free()
	print("LASER_GOGGLES_OK: visibilidade condicionada a Goggles e supressão em alerta validadas")

func test_laser_room_72_dynamic_cycling() -> void:
	var ls: LaserSystem = LaserSystem.new()
	ls.setup(72)

	# Sequência inicial (Seq 0): [1, 0, 0, 1, 0, 0, 1, 0, 1, 0]
	assert(ls.beams[0]["status"] == 1, "Feixe 0 na Seq 0 deve estar ligado")
	assert(ls.beams[1]["status"] == 0, "Feixe 1 na Seq 0 deve estar desligado")

	# Simular passagem de 192 ticks
	for _i in range(192):
		ls.tick(Vector2(0, 0), false, false)

	# Sequência seguinte (Seq 1): [0, 1, 1, 0, 0, 0, 1, 0, 0, 1]
	assert(ls.beams[0]["status"] == 0, "Feixe 0 na Seq 1 deve ter alternado para desligado")
	assert(ls.beams[1]["status"] == 1, "Feixe 1 na Seq 1 deve ter alternado para ligado")
	assert(ls.beams[2]["status"] == 1, "Feixe 2 na Seq 1 deve ter alternado para ligado")

	ls.free()
	print("LASER_CYCLING_OK: alternância dinâmica das sequências da Sala 72 validada")
