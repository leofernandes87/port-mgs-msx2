extends Control
## Cena de Abertura e Tela de Título Autêntica do Metal Gear MSX2 RC750 (Konami 1987).
##
## Reproduz a máquina de estados exata do jogo original:
## 1. Logo da Konami: tela branca, revelação em cortina de cima para baixo da fita
##    e da marca KONAMI (168x49 px, 49 linhas, 1 linha a cada 2 frames / ~1.6s).
## 2. Pausa curta no logo completo (~1.0s).
## 3. Tela de Título: subida do logotipo "METAL GEAR" cromado com frisos vermelhos (MGLogoYpos).
## 4. Espera de comando: "(C) KONAMI 1987" fixo e "PRESS START" piscando a cada 30 frames.
## 5. Play Start: piscar rápido do comando de início por 80 frames e transição para o gameplay.

enum State {
	KONAMI_WIPE,
	KONAMI_HOLD,
	LOGO_SCROLL,
	TITLE_IDLE,
	PLAY_START
}

const VIRTUAL_WIDTH: int = 256
const VIRTUAL_HEIGHT: int = 192

# Tabela original de scroll Y do logo Metal Gear (external/MetalGear/logic/mainmenu.asm:240)
# MGLogoYpos: db 20h, 30h, 40h, 50h, 60h, 70h, 80h, 90h, 0A0h, 0B0h, 0C0h
const MG_LOGO_Y_POSITIONS: Array[int] = [192, 176, 160, 144, 128, 112, 96, 80, 64, 48, 32]

var current_state: State = State.KONAMI_WIPE
var state_timer: float = 0.0

# Controles de animação
var wipe_line: int = 0
var wipe_frame_counter: int = 0
var scroll_step_index: int = 0
var scroll_frame_counter: int = 0
var blink_counter: int = 0
var blink_visible: bool = true
var flash_counter: int = 0
var flash_visible: bool = true

# Texturas protegidas autênticas
var tex_konami_ribbon: Texture2D = null
var tex_metalgear_logo: Texture2D = null
var tex_copyright: Texture2D = null
var tex_press_start: Texture2D = null
var tex_push_space: Texture2D = null
var tex_play_start: Texture2D = null

# Configurações de exibição
var use_press_start_prompt: bool = true
var current_logo_y: int = 192

func _ready() -> void:
	_load_textures()
	current_state = State.KONAMI_WIPE
	wipe_line = 0
	wipe_frame_counter = 0
	print("BOOT_OK: cena principal pronta")
	queue_redraw()

func _load_textures() -> void:
	const PATH_RIBBON := "res://assets/protected/sprites/intro_konami_ribbon.png"
	const PATH_LOGO := "res://assets/protected/sprites/intro_metalgear_logo.png"
	const PATH_COPY := "res://assets/protected/sprites/intro_copyright.png"
	const PATH_START := "res://assets/protected/sprites/intro_press_start.png"
	const PATH_SPACE := "res://assets/protected/sprites/intro_push_space.png"
	const PATH_PLAY := "res://assets/protected/sprites/intro_play_start.png"

	if ResourceLoader.exists(PATH_RIBBON):
		tex_konami_ribbon = load(PATH_RIBBON)
	if ResourceLoader.exists(PATH_LOGO):
		tex_metalgear_logo = load(PATH_LOGO)
	if ResourceLoader.exists(PATH_COPY):
		tex_copyright = load(PATH_COPY)
	if ResourceLoader.exists(PATH_START):
		tex_press_start = load(PATH_START)
	if ResourceLoader.exists(PATH_SPACE):
		tex_push_space = load(PATH_SPACE)
	if ResourceLoader.exists(PATH_PLAY):
		tex_play_start = load(PATH_PLAY)

func _process(delta: float) -> void:
	state_timer += delta

	match current_state:
		State.KONAMI_WIPE:
			# Revela 1 linha da cortina a cada 2 frames (~30 linhas/segundo em 60fps)
			wipe_frame_counter += 1
			if wipe_frame_counter >= 2:
				wipe_frame_counter = 0
				wipe_line += 1
				if wipe_line >= 49:
					wipe_line = 49
					current_state = State.KONAMI_HOLD
					state_timer = 0.0
			queue_redraw()

		State.KONAMI_HOLD:
			# Segura a imagem por ~1.2 segundos e inicia o scroll do título
			if state_timer >= 1.2:
				_go_to_logo_scroll()

		State.LOGO_SCROLL:
			# Avança os passos de scroll do logotipo Metal Gear
			scroll_frame_counter += 1
			if scroll_frame_counter >= 3:
				scroll_frame_counter = 0
				scroll_step_index += 1
				if scroll_step_index < MG_LOGO_Y_POSITIONS.size():
					current_logo_y = MG_LOGO_Y_POSITIONS[scroll_step_index]
				else:
					_go_to_title_idle()
			queue_redraw()

		State.TITLE_IDLE:
			# Pisca o texto a cada 32 frames (~0.5s)
			blink_counter += 1
			if blink_counter >= 30:
				blink_counter = 0
				blink_visible = !blink_visible
				queue_redraw()

		State.PLAY_START:
			# Efeito de confirmação (piscar rápido por 80 frames = ~1.3s)
			flash_counter += 1
			# Alterna visibilidade a cada 4 frames
			flash_visible = ((flash_counter / 4) % 2) == 0
			queue_redraw()

			if flash_counter >= 80:
				_start_game()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key_event := event as InputEventKey
		# Tecla T permite alternar entre 'PRESS START' e 'PUSH SPACE KEY'
		if key_event.keycode == KEY_T and current_state == State.TITLE_IDLE:
			use_press_start_prompt = !use_press_start_prompt
			queue_redraw()
			return

		_handle_action_press()
		return

	if event is InputEventJoypadButton and event.is_pressed():
		_handle_action_press()
		return

	if event is InputEventMouseButton and event.is_pressed():
		_handle_action_press()
		return

func _handle_action_press() -> void:
	match current_state:
		State.KONAMI_WIPE, State.KONAMI_HOLD:
			# Qualquer tecla pula direto para o menu (comportamento de ChkAnykeyStart no MSX)
			_go_to_title_idle()
		State.LOGO_SCROLL:
			_go_to_title_idle()
		State.TITLE_IDLE:
			# Confirma início do jogo
			current_state = State.PLAY_START
			flash_counter = 0
			flash_visible = true
			state_timer = 0.0
			queue_redraw()

func _go_to_logo_scroll() -> void:
	current_state = State.LOGO_SCROLL
	scroll_step_index = 0
	scroll_frame_counter = 0
	current_logo_y = MG_LOGO_Y_POSITIONS[0]
	state_timer = 0.0
	queue_redraw()

func _go_to_title_idle() -> void:
	current_state = State.TITLE_IDLE
	current_logo_y = 32
	blink_counter = 0
	blink_visible = true
	state_timer = 0.0
	queue_redraw()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/sandbox_gameplay.tscn")

func _draw() -> void:
	var viewport_sz: Vector2 = size
	var zoom_factor: float = max(1.0, floor(min(viewport_sz.x / float(VIRTUAL_WIDTH), viewport_sz.y / float(VIRTUAL_HEIGHT))))
	var screen_sz := Vector2(VIRTUAL_WIDTH, VIRTUAL_HEIGHT) * zoom_factor
	var origin: Vector2 = ((viewport_sz - screen_sz) / 2.0).floor()

	# Fundo da tela virtual
	if current_state == State.KONAMI_WIPE or current_state == State.KONAMI_HOLD:
		# Konami screen: fundo branco puro (VDP reg 7 = 0x0F)
		draw_rect(Rect2(origin, screen_sz), Color(1.0, 1.0, 1.0, 1.0), true)

		# Desenha fita e texto da Konami com revelação de cortina
		if tex_konami_ribbon != null and wipe_line > 0:
			var ribbon_dest := Rect2(
				origin + Vector2(40, 64) * zoom_factor,
				Vector2(168, wipe_line) * zoom_factor
			)
			var ribbon_src := Rect2(0, 0, 168, wipe_line)
			draw_texture_rect_region(tex_konami_ribbon, ribbon_dest, ribbon_src)
	else:
		# Title screen: fundo preto puro
		draw_rect(Rect2(origin, screen_sz), Color(0.0, 0.0, 0.0, 1.0), true)

		# Logotipo Metal Gear
		if tex_metalgear_logo != null:
			var logo_dest := Rect2(
				origin + Vector2(32, current_logo_y) * zoom_factor,
				Vector2(176, 40) * zoom_factor
			)
			draw_texture_rect(tex_metalgear_logo, logo_dest, false)

		# Elementos adicionais aparecem quando o scroll termina
		if current_state == State.TITLE_IDLE or current_state == State.PLAY_START:
			# (C) KONAMI 1987 em (78, 96)
			if tex_copyright != null:
				var copy_dest := Rect2(
					origin + Vector2(78, 96) * zoom_factor,
					Vector2(104, 8) * zoom_factor
				)
				draw_texture_rect(tex_copyright, copy_dest, false)

			# Prompt piscante / Play Start em Y=136
			if current_state == State.TITLE_IDLE:
				if blink_visible:
					if use_press_start_prompt and tex_press_start != null:
						# PRESS START centralizado em X=84, Y=136
						var start_dest := Rect2(
							origin + Vector2(84, 136) * zoom_factor,
							Vector2(88, 8) * zoom_factor
						)
						draw_texture_rect(tex_press_start, start_dest, false)
					elif tex_push_space != null:
						# PUSH SPACE KEY autêntico do MSX2 em X=72, Y=136
						var space_dest := Rect2(
							origin + Vector2(72, 136) * zoom_factor,
							Vector2(112, 8) * zoom_factor
						)
						draw_texture_rect(tex_push_space, space_dest, false)
			elif current_state == State.PLAY_START:
				if flash_visible:
					if tex_play_start != null:
						# PLAY START autêntico em X=88, Y=136
						var play_dest := Rect2(
							origin + Vector2(88, 136) * zoom_factor,
							Vector2(80, 8) * zoom_factor
						)
						draw_texture_rect(tex_play_start, play_dest, false)
					elif tex_press_start != null:
						var start_dest := Rect2(
							origin + Vector2(84, 136) * zoom_factor,
							Vector2(88, 8) * zoom_factor
						)
						draw_texture_rect(tex_press_start, start_dest, false)
