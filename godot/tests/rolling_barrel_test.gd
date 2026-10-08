extends SceneTree

## Rolling barrel (ID 0Fh) against logic/actors/rollingbarrels.asm:8-132, Banks0123.asm:6358-6402,
## 7277-7332, 12612-12672, 12875-12919, data/shapes.asm, data/weapondamage.asm:18-58.
## Expected values are hand-computed from the routines, not produced by the implementation.

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
	print("\n--- Rolling Barrel (logic/actors/rollingbarrels.asm) ---")
	var barrel: RollingBarrel = RollingBarrel.new()

	# InitRollingBarrel: speed from PlayerX only; Direction stays 0 from the erased EnemyList.
	barrel.setup(128, 8, 60, 141)
	if not require(barrel.x_fixed == 0x8000 and barrel.pixel_y() == 8, "Spawn em X=128,Y=8 com Xdec=0"): return
	if not require(barrel.speed_x == 0x0080, "PlayerX < 80h: velocidade inicial +80h"): return
	if not require(barrel.direction == 0, "Direction inicial 0 (InitRollingBarrel não a define)"): return
	if not require(barrel.sprite_id == 0x36 and barrel.moving, "SpriteId 36h e MOVING=1"): return
	if not require(barrel.life == 2 and barrel.start_x == 60, "LIFE=2 e START_X=PlayerX"): return
	barrel.setup(128, 8, 0x80, 141)
	if not require(barrel.speed_x == 0xFF80 and barrel.direction == 0, "PlayerX >= 80h: velocidade -80h, Direction 0"): return

	# Direction 0 -> rra carry 0 -> -8 per tick even while moving right.
	barrel.setup(128, 8, 60, 141)
	for _i in range(16):
		barrel.step_tick()
	if not require(barrel.speed_x == 0, "16 ticks de -8 zeram a velocidade +80h"): return
	if not require(barrel.x_fixed == 0x83C0 and barrel.pixel_x() == 131, "X 8.8 = 8000h + 960 = 83C0h"): return
	barrel.step_tick()
	if not require(barrel.signed_speed_x() == -8 and barrel.x_fixed == 0x83B8, "Reverte para a esquerda no tick 17"): return

	# Anim2FramesActor mask 3: ANIM_CNT is incremented before the logic.
	barrel.setup(128, 8, 60, 141)
	var frames: Array[int] = []
	for _i in range(8):
		barrel.step_tick()
		frames.append(barrel.sprite_id)
	if not require(frames == [0x36, 0x36, 0x36, 0x37, 0x37, 0x37, 0x37, 0x36], "SpriteId alterna 36h/37h nos ticks 4 e 8"): return

	# ChkBarrelBounce, right wall: X=199 keeps Xdec, DIR_DOWN, -80h, then -8 and MoveActor.
	var bounces: Array[int] = []
	var sfx: Array[int] = []
	barrel.barrel_bounced.connect(func(d: int) -> void: bounces.append(d))
	barrel.sfx_requested.connect(func(s: int) -> void: sfx.append(s))
	barrel.setup(128, 8, 60, 141)
	barrel.x_fixed = (210 << 8) | 0x40
	barrel.step_tick()
	if not require(barrel.direction == RollingBarrel.DIR_DOWN and barrel.speed_x == 0xFF78, "Parede direita: DIR_DOWN e -80h-8"): return
	if not require(barrel.x_fixed == 0xC6B8, "X = (199<<8|40h) - 88h = C6B8h (Xdec preservado)"): return
	if not require(bounces == [2] and sfx == [0x1D], "Sinal de ricochete e SFX 1Dh"): return

	# Left wall: X=57 keeps Xdec, DIR_LEFT, +80h, then +8.
	bounces.clear()
	sfx.clear()
	barrel.x_fixed = (55 << 8) | 0x10
	barrel.direction = RollingBarrel.DIR_DOWN
	barrel.speed_x = 0xFF00
	barrel.step_tick()
	if not require(barrel.direction == RollingBarrel.DIR_LEFT and barrel.speed_x == 0x0088, "Parede esquerda: DIR_LEFT e +80h+8"): return
	if not require(barrel.x_fixed == 0x3998, "X = (57<<8|10h) + 88h = 3998h"): return
	if not require(bounces == [3] and sfx == [0x1D], "Ricochete esquerdo emite DIR_LEFT e SFX 1Dh"): return
	barrel.step_tick()
	if not require(barrel.speed_x == 0x0090, "DIR_LEFT (bit0=1) acelera +8"): return

	# Long run: the walls keep the barrel inside 56..200 and ChkActorExitRoom never fires.
	barrel.setup(128, 8, 60, 141)
	bounces.clear()
	var min_x: int = 255
	var max_x: int = 0
	for _i in range(6000):
		barrel.step_tick()
		min_x = mini(min_x, barrel.pixel_x())
		max_x = maxi(max_x, barrel.pixel_x())
	if not require(not barrel.is_dismissed and bounces.size() >= 10, "Oscila entre paredes sem sair da sala"): return
	if not require(min_x >= 50 and max_x <= 205, "X permanece perto de [56, 200] (%d..%d)" % [min_x, max_x]): return
	if not require(barrel.pixel_y() == 8, "SpeedY = 0: Y fixo"): return

	# ChkActorExitRoom: Y >= 193 dismisses.
	var dismissed: Array[bool] = []
	barrel.dismissed.connect(func() -> void: dismissed.append(true))
	barrel.y_fixed = 193 << 8
	barrel.step_tick()
	if not require(barrel.is_dismissed and dismissed.size() == 1, "Y >= 193 dispensa o ator"): return

	# ChkArea with ActorsShapeTouch 10h; `inc a` before GetShapeInfo -> ImpactAreasInfo row 10h = (48h, 48h, 0, 0Ch).
	barrel.setup(128, 8, 0x90, 141)
	if not require(barrel.touches_player(Vector2(128, 100)), "Snake no meio da coluna é tocado"): return
	if not require(barrel.touches_player(Vector2(139, 9)) and barrel.touches_player(Vector2(117, 151)), "Bordas internas da coluna tocam"): return
	if not require(not barrel.touches_player(Vector2(128, 152)) and not barrel.touches_player(Vector2(128, 8)), "|Y-80| = 72 não toca"): return
	if not require(not barrel.touches_player(Vector2(140, 80)) and not barrel.touches_player(Vector2(116, 80)), "|X-128| = 12 não toca"): return
	if not require(RollingBarrel.TOUCH_DAMAGE == 0xFF, "ActorTouchDamage[14] = FFh"): return

	# ActorShapeProject 11h -> ImpactAreasInfo row 11h = (48h, 48h, 0, 10h).
	if not require(barrel.shot_hits(Vector2(128, 150)) and barrel.shot_hits(Vector2(143, 80)), "Tiro atinge a coluna inteira"): return
	if not require(not barrel.shot_hits(Vector2(128, 152)) and not barrel.shot_hits(Vector2(144, 80)), "Tiro fora da coluna"): return
	if not require(barrel.explosive_hits(Vector2(128, 100)), "ActorShapeExpl usa a mesma área"): return

	# Weapon damage tables: 0 for all, FFh for grenades -> LIFE never decreases.
	for weapon: int in [RollingBarrel.Weapon.HAND_GUN, RollingBarrel.Weapon.SMG, RollingBarrel.Weapon.ROCKET_LAUNCHER,
			RollingBarrel.Weapon.PLASTIC_BOMB, RollingBarrel.Weapon.LAND_MINE, RollingBarrel.Weapon.MISSILE]:
		barrel.apply_weapon_hit(weapon as RollingBarrel.Weapon)
	if not require(barrel.apply_weapon_hit(RollingBarrel.Weapon.GRENADE_LAUNCHER) == RollingBarrel.NO_DAMAGE, "Granada: FFh sem dano"): return
	if not require(barrel.life == 2 and not barrel.is_dismissed, "Barril é indestrutível"): return
	barrel.free()

	# Canonical extraction, when present locally, must agree with the constants above.
	var data: Dictionary = RollingBarrel.extracted_data()
	if data.is_empty():
		print("  SKIP: data/extracted/en-eu-rc750/rolling-barrel ausente (rode tools/extractors/extract_rolling_barrel.py)")
	else:
		var damage: Dictionary = data["weapon_damage"]
		var behaviour: Dictionary = data["behaviour"]
		var touch: Dictionary = data["touch_area"]
		var shot: Dictionary = data["shot_area"]
		var sprite: Dictionary = data["sprite"]
		if not require(int(data["life"]) == RollingBarrel.INITIAL_LIFE and int(data["touch_damage"]) == RollingBarrel.TOUCH_DAMAGE, "ROM: LIFE e dano de toque"): return
		if not require([int(touch["offset_y"]), int(touch["radius_y"]), int(touch["offset_x"]), int(touch["radius_x"])] == RollingBarrel.TOUCH_AREA, "ROM: área de toque"): return
		if not require([int(shot["offset_y"]), int(shot["radius_y"]), int(shot["offset_x"]), int(shot["radius_x"])] == RollingBarrel.SHOT_AREA, "ROM: área de tiro"): return
		if not require(damage["GRENADE_LAUNCHER"] == null and int(damage["HAND_GUN"]) == 0 and int(damage["PLASTIC_BOMB"]) == 0, "ROM: tabela de dano"): return
		if not require(int(behaviour["right_limit_x"]) == RollingBarrel.RIGHT_LIMIT_X and int(behaviour["left_reset_x"]) == RollingBarrel.LEFT_RESET_X and int(behaviour["acceleration_x"]) == RollingBarrel.ACCELERATION_X, "ROM: constantes de ChkBarrelBounce/RB_IncrementSpeed"): return
		if not require(int(sprite["frame_height"]) == int(RollingBarrel.FRAME_SIZE.y) and int(sprite["origin"][0]) == int(RollingBarrel.SPRITE_ORIGIN.x), "ROM: coluna 16x144 com origem (8,0)"): return
		var texture: Texture2D = RollingBarrel.texture_for_room(205)
		if not require(texture != null and texture.get_width() == 32 and texture.get_height() == 144, "Spritesheet canônico 32x144 carregado"): return

	# Sandbox integration: rooms 141, 153, 191 and 205 (actorsinrooms.asm:860-866, idxActorsRooms 1167-1231).
	var sandbox: Node = preload("res://scenes/sandbox_gameplay.tscn").instantiate()
	root.add_child(sandbox)
	for room: int in [141, 153, 191, 205]:
		if not data.is_empty():
			if not require(RollingBarrel.texture_for_room(room) != null, "Sala %d tem spritesheet canônico" % room): return
		sandbox.call("_spawn_room_enemies", room)
		var spawned: Array = sandbox.get("rolling_barrels") as Array
		if not require(spawned.size() == 1, "Sala %d spawna 1 barril" % room): return
		var rb: RollingBarrel = spawned[0] as RollingBarrel
		if not require(rb.pixel_x() == 128 and rb.pixel_y() == 8 and rb.room_id == room, "Sala %d: barril em (128,8)" % room): return
	# TouchPlayer: Snake in the middle of the column loses all life (ActorTouchDamage FFh).
	var snake: PlayerController = sandbox.get("player") as PlayerController
	snake.infinite_life = false
	snake.invulnerable_timer_sec = 0.0
	snake.can_control = true
	snake.position = Vector2(128, 100)
	sandbox.call("_physics_process", 1.0 / 60.0)
	if not require(snake.life == 0 and snake.is_dead, "Contato com a coluna mata Snake"): return
	sandbox.call("_spawn_room_enemies", 1)
	if not require((sandbox.get("rolling_barrels") as Array).is_empty(), "Sala 1 sem barris"): return
	sandbox.free()

	print("ROLLING_BARREL_TEST_OK: comportamento e sprites do barril rolante conferem com a ROM")
	quit(0)
