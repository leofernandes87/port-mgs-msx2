class_name IntroCutscene
extends Node

## Sequência da abertura baseada em external/MetalGear/logic/introscene.asm.
## Contadores são chamadas de lógica, não frames do renderizador.
## Cadência nominal local de 30 Hz medida no openMSX: docs/reverse_engineering/intro-fence-timing.md.
## Posições de espera resultam da colisão da sala, não de teleporte para a grade.

signal intro_started
signal intro_finished
signal radio_requested(pages: Array[String])

enum State {
	INACTIVE = 0,
	SCENE_1_DIVE_LEFT = 1,
	SCENE_2_EMERGE_WAIT = 2,
	SCENE_3_DIVE_LEFT = 3,
	SCENE_4_DIVE_NORTH = 4,
	SCENE_5_EMERGE_WAIT = 5,
	SCENE_6_RADIO_WAIT = 6,
	SCENE_7_RADIO_READING = 7,
	SCENE_8_RADIO_CLOSED = 8,
	SCENE_9_SWIM_RIGHT = 9,
	SCENE_10_SWIM_NORTH = 10,
	SCENE_11_CLIMB = 11,
	SCENE_12_BOUNCE = 12,
	FINISHED = 13,
}

const BRIEFING_PAGES: Array[String] = [
	"THIS IS BIG BOSS...\nOPERATION INTRUDE N313.",
	"PENETRATE THE ENEMY'S\nOUTER HEAVEN AND\nDESTROY THE ULTIMATE\nWEAPON METAL GEAR!",
	"FIRST,\nCONTACT MISSING\nGREY FOX AND SEARCH FOR\nMETAL GEAR!",
	"CONTACT IN THE BAND OF\n120.85 FROM NOW ON...\nOVER!"
]

# Offsets de salto do MSX2 (logic/introscene.asm:380)
const BOUNCE_OFFSETS: Array[int] = [2, 1, 0, -2, -2, -2, -3, -5, -7, -5, -3, -2]

# Aproxima a cadência observada nesta intro NTSC, sem mudar o relógio do gameplay.
# Banks0123.asm:440-466 permite pular interrupções; não é uma regra universal do MSX.
const LOGIC_STEP_SEC: float = 1.0 / 30.0
var current_state: State = State.INACTIVE
var state_counter: int = 0
var is_active: bool = false
var radio_answered: bool = false
var _accumulator: float = 0.0
var _animation_wait: int = 0
var _animation_frame: int = 0

func start_intro(player: PlayerController) -> void:
	if not player:
		return
	# external/MetalGear/Banks0123.asm:8422-8438.
	is_active = true
	radio_answered = false
	_accumulator = 0.0
	_animation_wait = 0
	_animation_frame = 0
	current_state = State.SCENE_1_DIVE_LEFT
	state_counter = 0x40
	player.can_control = false
	player.is_moving = false
	player.position = Vector2(192.0, 184.0)
	player.current_direction = PlayerController.Direction.LEFT
	player.anim_mode = PlayerController.AnimMode.DEEP_WATER
	player.water_frame = 0
	player.climb_frame = 0
	player.queue_redraw()
	intro_started.emit()

func skip_intro(player: PlayerController) -> void:
	if not is_active and current_state == State.FINISHED:
		return
	# Skip é conveniência local; usa a posição final medida, sem afetar o fim natural.
	if player:
		player.position = Vector2(128.0, 87.0)
	_finish_intro(player)

func tick(player: PlayerController, delta: float = 1.0 / 60.0) -> void:
	if not is_active or not player or not is_finite(delta) or delta <= 0.0:
		return
	if current_state in [State.SCENE_6_RADIO_WAIT, State.SCENE_7_RADIO_READING]:
		_accumulator = 0.0
		return
	_accumulator += delta
	while is_active and _accumulator + 0.000000001 >= LOGIC_STEP_SEC:
		_accumulator = maxf(0.0, _accumulator - LOGIC_STEP_SEC)
		_step(player)
		if current_state in [State.SCENE_6_RADIO_WAIT, State.SCENE_7_RADIO_READING]:
			_accumulator = 0.0
			break

func _move(player: PlayerController, direction: PlayerController.Direction, amount: float, collide: bool = true) -> void:
	# logic/introscene.asm:255-261; Banks0123.asm:8972-8997.
	player.current_direction = direction
	var movement := Vector2.ZERO
	match direction:
		PlayerController.Direction.UP: movement.y = -amount
		PlayerController.Direction.RIGHT: movement.x = amount
		PlayerController.Direction.LEFT: movement.x = -amount
	var next_position: Vector2 = player.position + movement
	# Banks0123.asm:8840-8842,8956-8962: colisão zera velocidade, não StopPlayerFlag.
	player.is_moving = true
	if not collide or not player.is_colliding_at(next_position, direction):
		player.position = next_position

func _step(player: PlayerController) -> void:
	# Decremento precede movimento: no zero, só ocorre transição.
	# external/MetalGear/logic/introscene.asm:32-166,243-364.
	if current_state not in [State.SCENE_8_RADIO_CLOSED, State.FINISHED]:
		state_counter -= 1
	match current_state:
		State.SCENE_1_DIVE_LEFT:
			if state_counter == 0:
				current_state = State.SCENE_2_EMERGE_WAIT
				state_counter = 0x30
				player.anim_mode = PlayerController.AnimMode.SWIM_SURFACE
				player.current_direction = PlayerController.Direction.UP
			else:
				_move(player, PlayerController.Direction.LEFT, 1.0)
		State.SCENE_2_EMERGE_WAIT:
			player.is_moving = false
			if state_counter == 0:
				current_state = State.SCENE_3_DIVE_LEFT
				state_counter = 0x50
				player.anim_mode = PlayerController.AnimMode.DEEP_WATER
				player.current_direction = PlayerController.Direction.LEFT
		State.SCENE_3_DIVE_LEFT:
			if state_counter == 0:
				current_state = State.SCENE_4_DIVE_NORTH
				state_counter = 0x20
			else:
				_move(player, PlayerController.Direction.LEFT, 1.0)
		State.SCENE_4_DIVE_NORTH:
			if state_counter == 0:
				current_state = State.SCENE_5_EMERGE_WAIT
				state_counter = 0x40
				player.anim_mode = PlayerController.AnimMode.SWIM_SURFACE
				player.current_direction = PlayerController.Direction.RIGHT
			else:
				_move(player, PlayerController.Direction.UP, 1.0)
		State.SCENE_5_EMERGE_WAIT:
			if state_counter == 0x20:
				print("INTRO_CUTSCENE: Transceptor recebendo chamada de Big Boss (120.85)!")
			if state_counter == 0:
				current_state = State.SCENE_6_RADIO_WAIT
				radio_requested.emit(BRIEFING_PAGES)
			return # IntroScene5 does not call SetPlayerSpr while waiting.
		State.SCENE_8_RADIO_CLOSED:
			# logic/introscene.asm:224-235. ExitRadio já foi fechado pela UI.
			# 0x28 é o contador de movimento, nunca uma segunda pausa.
			current_state = State.SCENE_9_SWIM_RIGHT
			state_counter = 0x28
		State.SCENE_9_SWIM_RIGHT:
			if state_counter == 0:
				current_state = State.SCENE_10_SWIM_NORTH
				state_counter = 0x30
			else:
				_move(player, PlayerController.Direction.RIGHT, 2.0)
		State.SCENE_10_SWIM_NORTH:
			if state_counter == 0:
				# logic/introscene.asm:288-299. Só Y é reposicionado.
				player.position.y = 136.0
				player.anim_mode = PlayerController.AnimMode.CLIMB
				player.current_direction = PlayerController.Direction.UP
				current_state = State.SCENE_11_CLIMB
				state_counter = 0x1C
			else:
				_move(player, PlayerController.Direction.UP, 2.0)
		State.SCENE_11_CLIMB:
			if state_counter == 0:
				# logic/introscene.asm:321-333.
				player.position.y = 102.0
				player.anim_mode = PlayerController.AnimMode.NORMAL
				player.is_moving = false
				current_state = State.SCENE_12_BOUNCE
				state_counter = 0x0C
			else:
				# logic/introscene.asm:312-318: movimento vertical sem ChkPlayerColl.
				_move(player, PlayerController.Direction.UP, 1.0, false)
		State.SCENE_12_BOUNCE:
			# logic/introscene.asm:341-364,380-391: aplicar somente contadores ímpares.
			if state_counter == 0:
				current_state = State.FINISHED
			elif (state_counter & 1) != 0:
				player.position.y += BOUNCE_OFFSETS[state_counter]
		State.FINISHED:
			# logic/introscene.asm:372-378: liberar controle sem teleporte final.
			_finish_intro(player)
	_animate(player)
	player.queue_redraw()

func _animate(player: PlayerController) -> void:
	# external/MetalGear/Banks0123.asm:9827-9843,9851-9877.
	var interval: int = 0
	if player.anim_mode == PlayerController.AnimMode.DEEP_WATER:
		interval = 4
	elif player.anim_mode == PlayerController.AnimMode.CLIMB:
		if not player.is_moving:
			_animation_wait = 0
		else:
			interval = 6
	if interval > 0:
		_animation_wait += 1
		if _animation_wait == interval:
			_animation_wait = 0
			_animation_frame += 1
	if player.anim_mode == PlayerController.AnimMode.DEEP_WATER:
		player.water_frame = _animation_frame & 1
	elif player.anim_mode == PlayerController.AnimMode.CLIMB:
		player.climb_frame = _animation_frame & 1

func on_radio_finished() -> void:
	if current_state in [State.SCENE_6_RADIO_WAIT, State.SCENE_7_RADIO_READING]:
		current_state = State.SCENE_8_RADIO_CLOSED
		_accumulator = 0.0

func _finish_intro(player: PlayerController) -> void:
	current_state = State.FINISHED
	is_active = false
	_accumulator = 0.0
	if player:
		player.anim_mode = PlayerController.AnimMode.NORMAL
		player.current_direction = PlayerController.Direction.UP
		player.is_moving = false
		player.can_control = true
		player.queue_redraw()
	intro_finished.emit()
