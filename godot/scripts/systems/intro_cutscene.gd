class_name IntroCutscene
extends Node

## Sistema da Cutscene de Introdução / Infiltração na Água e Escalada da Grade.
## Fiel à máquina de estados do MSX2 RC750 (logic/introscene.asm e Banks0123.asm:8420-8440).
##
## Sequência canônica:
## 1. Mergulho sob a água (SprWaterShadow) partindo de (192, 184) até (128, 184).
## 2. Superfície (SprSnakeWaterU) encarando a base ao Norte.
## 3. Submerge novamente rumo a Oeste (48, 184) e Norte (48, 168).
## 4. Superfície virado a Leste (SprSnakeWaterR).
## 5. Chime e chamada do Transceptor (120.85): Briefing da Operação Intrude N313 por Big Boss.
## 6. Caminha pela água na superfície (SprSnakeWaterR/U, SWIM_SURFACE) até o centro (128, 168) e à grade (128, 136).
## 7. Escala a grade de arame (SprSnakeClimb1/2) até Y = 102.
## 8. Salto/ricochete sobre a cerca até terra firme (128, 80).
## 9. Controles liberados para o jogador.

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

var current_state: State = State.INACTIVE
var state_timer_sec: float = 0.0
var state_counter: int:
	get:
		return int(ceil(state_timer_sec * 60.0 - 0.0001))
	set(v):
		state_timer_sec = float(v) / 60.0

var is_active: bool = false
var radio_answered: bool = false

func start_intro(player: PlayerController) -> void:
	if not player:
		return
	is_active = true
	radio_answered = false
	current_state = State.SCENE_1_DIVE_LEFT
	state_counter = 0x40 # 64 frames (1.067s)

	player.can_control = false
	player.is_moving = false
	player.position = Vector2(192.0, 184.0)
	player.current_direction = PlayerController.Direction.LEFT
	player.anim_mode = PlayerController.AnimMode.DEEP_WATER
	player.water_frame = 0
	player.climb_frame = 0
	player.queue_redraw()

	intro_started.emit()
	print("INTRO_CUTSCENE: Iniciada infiltração na água em (192, 184) - Modo DEEP_WATER")

func skip_intro(player: PlayerController) -> void:
	if not is_active and current_state == State.FINISHED:
		return
	print("INTRO_CUTSCENE: Skip acionado pelo jogador. Teleportando para terra firme.")
	_finish_intro(player)

func tick(player: PlayerController, delta: float = 1.0 / 60.0) -> void:
	if not is_active or not player:
		return

	match current_state:
		State.SCENE_1_DIVE_LEFT:
			state_timer_sec = maxf(0.0, state_timer_sec - delta)
			player.position.x -= 60.0 * delta # 1.0 px/frame * 60 = 60 px/s (192 -> 128)
			player.water_frame = (state_counter / 8) % 2
			player.queue_redraw()
			if state_timer_sec <= 0.0001:
				state_timer_sec = 0.0
				current_state = State.SCENE_2_EMERGE_WAIT
				state_counter = 0x30 # 48 frames (0.800s)
				player.anim_mode = PlayerController.AnimMode.SWIM_SURFACE
				player.current_direction = PlayerController.Direction.UP
				player.queue_redraw()
				print("INTRO_CUTSCENE: Snake emergiu em (128, 184) encarando o complexo")

		State.SCENE_2_EMERGE_WAIT:
			state_timer_sec = maxf(0.0, state_timer_sec - delta)
			if state_timer_sec <= 0.0001:
				state_timer_sec = 0.0
				current_state = State.SCENE_3_DIVE_LEFT
				state_counter = 0x50 # 80 frames (1.333s)
				player.anim_mode = PlayerController.AnimMode.DEEP_WATER
				player.current_direction = PlayerController.Direction.LEFT
				player.queue_redraw()
				print("INTRO_CUTSCENE: Snake submergiu novamente rumo a Oeste")

		State.SCENE_3_DIVE_LEFT:
			state_timer_sec = maxf(0.0, state_timer_sec - delta)
			player.position.x -= 60.0 * delta # 1.0 px/frame * 60 = 60 px/s (128 -> 48)
			player.water_frame = (state_counter / 8) % 2
			player.queue_redraw()
			if state_timer_sec <= 0.0001:
				state_timer_sec = 0.0
				current_state = State.SCENE_4_DIVE_NORTH
				state_counter = 0x10 # 16 frames (0.267s)
				player.current_direction = PlayerController.Direction.UP
				player.queue_redraw()

		State.SCENE_4_DIVE_NORTH:
			state_timer_sec = maxf(0.0, state_timer_sec - delta)
			player.position.y -= 60.0 * delta # 1.0 px/frame * 60 = 60 px/s (184 -> 168)
			player.water_frame = (state_counter / 8) % 2
			player.queue_redraw()
			if state_timer_sec <= 0.0001:
				state_timer_sec = 0.0
				player.position = Vector2(48.0, 168.0)
				current_state = State.SCENE_5_EMERGE_WAIT
				state_counter = 0x40 # 64 frames (1.067s)
				player.anim_mode = PlayerController.AnimMode.SWIM_SURFACE
				player.current_direction = PlayerController.Direction.RIGHT
				player.queue_redraw()
				print("INTRO_CUTSCENE: Snake emergiu em (48, 168) virado para a direita")

		State.SCENE_5_EMERGE_WAIT:
			state_timer_sec = maxf(0.0, state_timer_sec - delta)
			if state_counter == 0x20:
				# Toca chime de chamada do rádio (SFX 0x22 no MSX2)
				print("INTRO_CUTSCENE: Transceptor recebendo chamada de Big Boss (120.85)!")
			if state_timer_sec <= 0.0001:
				state_timer_sec = 0.0
				current_state = State.SCENE_6_RADIO_WAIT
				radio_requested.emit(BRIEFING_PAGES)

		State.SCENE_6_RADIO_WAIT:
			# Aguardando transceptor ser atendido/aberto
			pass

		State.SCENE_7_RADIO_READING:
			# Aguardando término das 4 páginas do briefing
			pass

		State.SCENE_8_RADIO_CLOSED:
			current_state = State.SCENE_9_SWIM_RIGHT
			state_counter = 0x28 # 40 frames
			player.anim_mode = PlayerController.AnimMode.SWIM_SURFACE
			player.current_direction = PlayerController.Direction.RIGHT
			player.queue_redraw()
			print("INTRO_CUTSCENE: Briefing encerrado. Caminhando pela água rumo ao centro da sala (128, 168)")

		State.SCENE_9_SWIM_RIGHT:
			state_timer_sec = maxf(0.0, state_timer_sec - delta)
			player.position.x += 120.0 * delta # 80 px: 48 -> 128 (velocidade canônica 2.0 px/frame * 60 = 120 px/s)
			player.water_frame = (state_counter / 8) % 2
			player.queue_redraw()
			if state_timer_sec <= 0.0001:
				state_timer_sec = 0.0
				player.position = Vector2(128.0, 168.0)
				current_state = State.SCENE_10_SWIM_NORTH
				state_counter = 32 # 32 frames (0.533s)
				player.anim_mode = PlayerController.AnimMode.SWIM_SURFACE
				player.current_direction = PlayerController.Direction.UP
				player.queue_redraw()
				print("INTRO_CUTSCENE: Snake alcançou o centro (128, 168). Caminhando pela água rumo à grade ao norte")

		State.SCENE_10_SWIM_NORTH:
			state_timer_sec = maxf(0.0, state_timer_sec - delta)
			if player.position.y > 136.0:
				player.position.y -= 60.0 * delta # 32 px: 168 -> 136 a 1.0 px/frame * 60 = 60 px/s
			player.water_frame = (state_counter / 8) % 2
			player.queue_redraw()
			if state_timer_sec <= 0.0001:
				state_timer_sec = 0.0
				player.position = Vector2(128.0, 136.0)
				current_state = State.SCENE_11_CLIMB
				state_counter = 0x1C # 28 frames (0.467s)
				player.anim_mode = PlayerController.AnimMode.CLIMB
				player.current_direction = PlayerController.Direction.UP
				player.queue_redraw()
				print("INTRO_CUTSCENE: Snake alcançou a grade em (128, 136) e começou a escalar!")

		State.SCENE_11_CLIMB:
			state_timer_sec = maxf(0.0, state_timer_sec - delta)
			player.position.x = 128.0 # Mantém estritamente no centro horizontal
			player.position.y -= (34.0 / 28.0) * 60.0 * delta # 34 px: 136 -> 102
			player.climb_frame = (state_counter / 6) % 2
			player.queue_redraw()
			if state_timer_sec <= 0.0001:
				state_timer_sec = 0.0
				player.position = Vector2(128.0, 102.0)
				current_state = State.SCENE_12_BOUNCE
				state_counter = 12 # 12 frames (0.200s)
				player.anim_mode = PlayerController.AnimMode.NORMAL
				player.current_direction = PlayerController.Direction.UP
				player.queue_redraw()
				print("INTRO_CUTSCENE: Snake no topo da grade. Saltando para terra firme!")

		State.SCENE_12_BOUNCE:
			state_timer_sec = maxf(0.0, state_timer_sec - delta)
			var progress := 1.0 - (state_timer_sec / (12.0 / 60.0))
			var arc: float = sin(progress * PI) * 6.0
			player.position.x = 128.0 # Estritamente vertical, sem desvio diagonal
			player.position.y = lerpf(102.0, 80.0, progress) - arc
			player.queue_redraw()
			if state_timer_sec <= 0.0001:
				state_timer_sec = 0.0
				_finish_intro(player)

func on_radio_finished() -> void:
	if current_state in [State.SCENE_6_RADIO_WAIT, State.SCENE_7_RADIO_READING]:
		current_state = State.SCENE_8_RADIO_CLOSED

func _finish_intro(player: PlayerController) -> void:
	current_state = State.FINISHED
	is_active = false
	if player:
		player.position = Vector2(128.0, 80.0)
		player.anim_mode = PlayerController.AnimMode.NORMAL
		player.current_direction = PlayerController.Direction.UP
		player.is_moving = false
		player.can_control = true
		player.queue_redraw()
	intro_finished.emit()
	print("INTRO_CUTSCENE_FINISHED: Snake em terra firme (128, 80). Controle total entregue ao jogador!")
