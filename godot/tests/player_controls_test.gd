extends SceneTree
## StoreControls, GetPlayerDir, ChkControlPlayer and 8.8 movement (CORE-002).

const U: int = PlayerControls.UP
const D: int = PlayerControls.DOWN
const L: int = PlayerControls.LEFT
const R: int = PlayerControls.RIGHT


func _initialize() -> void:
	call_deferred("_run")


func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
		return false
	return true


func _press(c: PlayerControls, raw: int) -> int:
	c.store(raw)
	return c.get_player_dir()


func _run() -> void:
	# 1. StoreControls: trigger = bits newly pressed.
	var c := PlayerControls.new()
	c.store(U)
	if not require(c.hold == U and c.trigger == U, "Primeira leitura: UP em hold e trigger"): return
	c.store(U)
	if not require(c.hold == U and c.trigger == 0, "UP mantido não gera trigger"): return
	c.store(U | L)
	if not require(c.hold == U | L and c.trigger == L, "Só LEFT é novo"): return
	c.store(L)
	if not require(c.trigger == 0, "Soltar não gera trigger"): return

	# 2. GetPlayerDir: new direction wins, the old one returns when the new is released.
	c = PlayerControls.new()
	if not require(_press(c, U) == 1 and c.direction_mask == U and c.direction_mask_old == 0, "UP novo: dir 1, máscara UP"): return
	if not require(_press(c, U) == 1, "UP mantido continua UP"): return
	if not require(_press(c, U | L) == 3 and c.direction_mask == L and c.direction_mask_old == U, "LEFT novo vence UP mantido"): return
	if not require(_press(c, U | L) == 0, "Duas direções mantidas: IdsDirection[5] = 0 mantém a direção"): return
	if not require(_press(c, U) == 1 and c.direction_mask == U and c.direction_mask_old == 0, "Soltar LEFT volta ao UP antigo"): return
	if not require(_press(c, 0) == 0, "Nada pressionado: 0"): return

	# Simultaneous new presses: fixed priority Up, Down, Left, Right (Banks0123.asm:8734-8749).
	c = PlayerControls.new()
	if not require(_press(c, U | R) == 1, "UP+RIGHT juntos: UP"): return
	c = PlayerControls.new()
	if not require(_press(c, D | L) == 2, "DOWN+LEFT juntos: DOWN"): return
	c = PlayerControls.new()
	if not require(_press(c, L | R) == 3, "LEFT+RIGHT juntos: LEFT"): return
	c = PlayerControls.new()
	if not require(_press(c, R) == 4, "RIGHT sozinho: 4"): return

	# Held direction outside both masks is used as is (DisableControls leaves masks at 0).
	c = PlayerControls.new()
	_press(c, D)
	c.disable()
	if not require(c.direction_mask == 0 and c.direction_mask_old == 0, "DisableControls zera as máscaras"): return
	if not require(_press(c, D) == 2, "DOWN mantido após DisableControls: IdsDirection[2]"): return
	if not require(_press(c, D | R) == 4, "RIGHT novo após DisableControls"): return
	if not require(_press(c, D) == 2 and c.direction_mask == R, "Soltar RIGHT com máscara antiga zerada: usa o hold, máscara intacta"): return

	# 3. ChkControlPlayer + MovePlayerX/Y in 8.8.
	var player: PlayerController = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	root.add_child(player)
	await process_frame
	if not require(PlayerController.MOV_SPEED_NORMAL == 0x200 and is_equal_approx(PlayerController.SPEED_NORMAL, 2.0), "PlayerMovSpeed = 200h"): return
	player.set_grid_position(100.5, 100.0)
	player.current_direction = PlayerController.Direction.RIGHT
	if not require(player.step_control(R, 4) and player.position == Vector2(102.5, 100.0), "+200h preserva a fração 8.8"): return
	if not require(player.step_control(U | R, 0) and player.position == Vector2(104.5, 100.0), "Direção nova 0 mantém PlayerDirection"): return
	if not require(player.step_control(U, 1) and player.position == Vector2(104.5, 98.0), "Velocidade só no eixo da direção"): return
	if not require(not player.step_control(0, 0) and not player.is_moving and player.position == Vector2(104.5, 98.0), "Parada imediata sem direção mantida"): return
	if not require(player.current_direction == PlayerController.Direction.UP, "Parar não muda a direção"): return
	player.step_control(L, 3, 0.25)
	if not require(player.position == Vector2(102.5, 98.0), "Deslocamento por tick independe do delta"): return
	player.anim_mode = PlayerController.AnimMode.SWIM_SURFACE
	player.step_control(L, 3)
	if not require(player.position == Vector2(101.5, 98.0), "Velocidade 100h = 1 px por tick"): return
	player.queue_free()
	await process_frame

	# 4. Sandbox: UpdateControls each iteration, GetPlayerDir on the walk path.
	var sandbox: SandboxGameplay = (load("res://scenes/sandbox_gameplay.tscn") as PackedScene).instantiate()
	root.add_child(sandbox)
	sandbox.set_physics_process(false)
	await process_frame
	if sandbox.intro_cutscene and sandbox.intro_cutscene.is_active:
		sandbox.intro_cutscene.is_active = false
	var p: PlayerController = sandbox.player
	p.can_control = true
	p.anim_mode = PlayerController.AnimMode.NORMAL
	var open_grid: Array = []
	open_grid.resize(768)
	open_grid.fill(0)
	p.set_collision_grid(open_grid)
	p.set_grid_position(128.0, 100.0)
	sandbox.player_controls.reset()

	sandbox.controls_override = U
	sandbox.game_tick()
	if not require(p.position == Vector2(128.0, 98.0) and p.current_direction == PlayerController.Direction.UP, "Sandbox: UP move 2 px"): return
	sandbox.controls_override = U | L
	sandbox.game_tick()
	if not require(p.position == Vector2(126.0, 98.0) and p.current_direction == PlayerController.Direction.LEFT, "Sandbox: LEFT novo vence UP mantido"): return
	sandbox.game_tick()
	if not require(p.position == Vector2(124.0, 98.0) and p.current_direction == PlayerController.Direction.LEFT, "Sandbox: dois mantidos conservam LEFT"): return
	sandbox.controls_override = U
	sandbox.game_tick()
	if not require(p.position == Vector2(124.0, 96.0) and p.current_direction == PlayerController.Direction.UP, "Sandbox: soltar LEFT volta a UP"): return
	sandbox.controls_override = 0
	sandbox.game_tick()
	if not require(p.position == Vector2(124.0, 96.0) and not p.is_moving, "Sandbox: parada imediata"): return
	sandbox.queue_free()
	await process_frame

	print("PLAYER_CONTROLS_OK: StoreControls, GetPlayerDir com DirectionMask/Old, ChkControlPlayer e 8.8 por tick")
	quit(0)
