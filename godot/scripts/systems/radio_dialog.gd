class_name RadioDialog
extends Control

## Interface Gráfica autêntica do Transceptor / Codec do MSX2 RC750 (1987).
## Baseada na desmontagem Z80 de Banks0123.asm:10695-10730 (DrawRadio, DrawRadioFreq, DrawRadioLeds),
## RadioTilesMap (18x9 tiles em 48, 24), SnakeTilesMap (4x4 tiles em 200, 40), display digital de 7 segmentos
## vermelho em (120, 33), 12 barras de sinal LED em (64, 32) e caixa de texto autêntica de 5 linhas.

signal radio_closed

var radio_system: RadioSystem = null
var current_room_id: int = 0
var is_active: bool = false

# Efeito de máquina de escrever (typewriter)
var target_full_text: String = ""
var displayed_text: String = ""
var char_index: int = 0
var typewriter_speed: float = 0.045
var typewriter_timer: float = 0.0
var text_finished: bool = true

# Dados da transmissão atual
var current_contact: String = ""
var current_contact_name: String = ""
var current_text: String = ""
var has_signal: bool = false

# Animação dos 12 LEDs de sinal (Banks0123.asm:10787)
var target_leds: int = 0
var current_leds: int = 0
var led_anim_timer: float = 0.0

# Suporte a transmissões com múltiplas páginas (ex: briefing Operação Intrude N313)
var dialog_pages: Array[String] = []
var current_page_index: int = 0
var is_tuning_locked: bool = false

# Ícone clássico de ENTER do MSX2 (Banks0123.asm:8201-8219 DrawEnterIcon / PromptXY em 212, 168)
const ENTER_ICON_BITS: Array[int] = [
	0b00000100, # .....#..
	0b00000100, # .....#..
	0b00000100, # .....#..
	0b00100100, # ..#..#..
	0b01000100, # .#...#..
	0b11111100, # ######..
	0b01000000, # .#......
	0b00100000, # ..#.....
]

# Temporizador para animação de fala e piscar de olhos
var anim_timer: float = 0.0

# Texturas autênticas extraídas do MSX2 Screen 5
var texture_chassis: Texture2D = null
var texture_snake_portrait: Texture2D = null
var texture_digits: Texture2D = null
var texture_120: Texture2D = null
var texture_leds: Texture2D = null
var texture_msx_font: Texture2D = null

func _ready() -> void:
	visible = false
	z_index = 50
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	_load_textures()

func _load_textures() -> void:
	texture_chassis = _load_texture("res://assets/protected/sprites/transceiver/transceiver_chassis.png")
	texture_snake_portrait = _load_texture("res://assets/protected/sprites/transceiver/transceiver_snake_portrait.png")
	texture_digits = _load_texture("res://assets/protected/sprites/transceiver/transceiver_digits.png")
	texture_120 = _load_texture("res://assets/protected/sprites/transceiver/transceiver_120.png")
	texture_leds = _load_texture("res://assets/protected/sprites/transceiver/transceiver_leds.png")
	texture_msx_font = _load_texture("res://assets/protected/sprites/transceiver/msx_font.png")

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var global_path: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_path):
		var img := Image.load_from_file(global_path)
		if img:
			return ImageTexture.create_from_image(img)
	return null

func start_briefing(contact: String, contact_name: String, pages: Array[String], system: RadioSystem = null) -> void:
	if system:
		radio_system = system
	elif not radio_system:
		radio_system = RadioSystem.new()
	is_active = true
	visible = true
	is_tuning_locked = true # Trava sintonia durante a cutscene (MSX2 logic/introscene.asm)
	var all_pages: Array[String] = []
	for p: String in pages:
		all_pages.append_array(_paginate_text(p, 184.0, 4))
	dialog_pages = all_pages
	current_page_index = 0
	current_contact = contact
	current_contact_name = contact_name
	has_signal = true
	target_leds = 12
	current_leds = 12 # No MSX2 (introscene.asm:196-203), RadioSignalUp atinge 12 antes do texto abrir
	if radio_system:
		radio_system.is_send_mode = false
		radio_system.set_frequency(RadioSystem.FREQ_BIGBOSS_PR1)
	if dialog_pages.size() > 0:
		_display_current_page()
	queue_redraw()
	print("RADIO_BRIEFING: Iniciado briefing de %s (%d páginas)" % [contact_name, dialog_pages.size()])

func open_radio(system: RadioSystem, room_id: int, auto_answer: bool = false) -> void:
	radio_system = system
	current_room_id = room_id
	is_active = true
	visible = true
	is_tuning_locked = false

	if auto_answer and radio_system and radio_system.has_incoming_call:
		var result: Dictionary = radio_system.answer_call(room_id)
		_start_dialog(result)
	else:
		# Entra em modo RECV na frequência atual
		if radio_system:
			radio_system.is_send_mode = false
		_update_status_display()
		_set_text("TRANSCEIVER ONLINE. TUNE FREQUENCY (LEFT/RIGHT) AND PRESS UP TO TRANSMIT.")

	queue_redraw()
	var freq_msg: String = radio_system.get_frequency_string() if radio_system else "120.85"
	print("RADIO_OPENED: Transceptor ativado na sala %d (Freq: %s)" % [room_id, freq_msg])

func close_radio() -> void:
	if not is_active:
		return
	is_active = false
	visible = false
	is_tuning_locked = false
	dialog_pages.clear()
	current_page_index = 0
	radio_closed.emit()
	print("RADIO_CLOSED: Transceptor desligado.")

func _process(delta: float) -> void:
	if not is_active:
		return

	anim_timer += delta

	# Animação de digitação do texto
	if not text_finished:
		typewriter_timer += delta
		while typewriter_timer >= typewriter_speed and char_index < target_full_text.length():
			typewriter_timer -= typewriter_speed
			char_index += 1
			displayed_text = target_full_text.substr(0, char_index)
			queue_redraw()
		if char_index >= target_full_text.length():
			text_finished = true
			queue_redraw()

	# Animação progressiva dos LEDs de sinal (Banks0123.asm:10787)
	if current_leds != target_leds:
		led_anim_timer += delta
		if led_anim_timer >= 0.033: # ~2 frames no MSX2
			led_anim_timer = 0.0
			if current_leds < target_leds:
				current_leds += 1
			else:
				current_leds -= 1
			queue_redraw()

	# Redesenho contínuo para animação da boca/olhos e prompt piscante
	queue_redraw()

func handle_input(event: InputEvent) -> bool:
	if not is_active:
		return false

	# Durante cutscene / briefing com Big Boss, a sintonia e o modo SEND ficam desativados
	if is_tuning_locked:
		# Ignora cancelamento prematuro durante o briefing obrigatório
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode in [KEY_F4, KEY_T, KEY_ESCAPE])):
			return true

		# Avançar ou acelerar texto com Espaço / Enter / Botão A
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])):
			if not text_finished:
				# Acelera digitação e exibe texto completo da página atual
				displayed_text = target_full_text
				char_index = target_full_text.length()
				text_finished = true
				queue_redraw()
				return true
			else:
				# Página concluída: avança para a próxima ou encerra briefing
				if current_page_index + 1 < dialog_pages.size():
					current_page_index += 1
					_display_current_page()
					queue_redraw()
					return true
				else:
					close_radio()
					return true

		# Consome qualquer comando direcional para impedir desvio de sintonia
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") \
		   or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			return true
		if event is InputEventKey and event.pressed and (event.keycode in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]):
			return true

		return false

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_F4 or event.keycode == KEY_T or event.keycode == KEY_ESCAPE)):
		close_radio()
		return true

	# Avançar texto imediatamente se pressionar Espaço ou Enter
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])):
		if not text_finished:
			# Pula digitação e exibe tudo da página atual
			displayed_text = target_full_text
			char_index = target_full_text.length()
			text_finished = true
			queue_redraw()
			return true
		else:
			# Texto já completo: verifica se há mais páginas
			if current_page_index + 1 < dialog_pages.size():
				current_page_index += 1
				_display_current_page()
				queue_redraw()
				return true
			else:
				close_radio()
				return true

	# Sintonia: Esquerda / Direita
	if event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and event.keycode == KEY_A):
		if radio_system:
			radio_system.tune_down()
			radio_system.is_send_mode = false
		_on_frequency_changed()
		return true
	elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and event.keycode == KEY_D):
		if radio_system:
			radio_system.tune_up()
			radio_system.is_send_mode = false
		_on_frequency_changed()
		return true

	# Transmissão (SEND): Cima / W
	if event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_W):
		_trigger_send()
		return true

	# Modo Recepção (RECV): Baixo / S
	if event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_S):
		if radio_system:
			radio_system.is_send_mode = false
		_update_status_display()
		_set_text("RECEIVER MODE. WAITING FOR TRANSMISSION.")
		return true

	return false

func _on_frequency_changed() -> void:
	target_leds = 0
	current_contact = ""
	current_contact_name = ""
	has_signal = false
	var freq_text: String = radio_system.get_frequency_string() if radio_system else "120.85"
	_set_text("TUNING: %s MHz..." % freq_text)
	queue_redraw()

func _trigger_send() -> void:
	if not radio_system:
		radio_system = RadioSystem.new()
	radio_system.is_send_mode = true
	var result: Dictionary = radio_system.send_transmission(current_room_id)
	_start_dialog(result)

func _start_dialog(result: Dictionary) -> void:
	has_signal = bool(result.get("has_signal", false))
	current_contact = String(result.get("contact", ""))
	var is_send: bool = radio_system.is_send_mode if radio_system else false
	current_contact_name = String(result.get("contact_name", "SOLID SNAKE" if is_send else "RADIO"))
	target_leds = 12 if has_signal else 0
	_set_text(String(result.get("text", "")))
	queue_redraw()

func _update_status_display() -> void:
	if radio_system:
		current_contact_name = radio_system.get_contact_name_for_freq(radio_system.current_freq)
	target_leds = 0
	queue_redraw()

func _set_text(text: String) -> void:
	dialog_pages = _paginate_text(text, 184.0, 4)
	current_page_index = 0
	_display_current_page()

func _display_current_page() -> void:
	if current_page_index >= 0 and current_page_index < dialog_pages.size():
		target_full_text = dialog_pages[current_page_index]
	else:
		target_full_text = ""
	displayed_text = ""
	char_index = 0
	typewriter_timer = 0.0
	text_finished = false

## Divide um texto em páginas de no máximo max_lines_per_page linhas (cada linha com até max_w pixels)
static func _paginate_text(text: String, max_w: float = 184.0, max_lines_per_page: int = 4) -> Array[String]:
	if text.strip_edges().is_empty():
		return [""]

	var raw_lines: PackedStringArray = text.split("\n")
	var wrapped_lines: Array[String] = []

	for rline: String in raw_lines:
		var words: PackedStringArray = rline.split(" ")
		var cur_words: Array[String] = []
		var cur_w: float = 0.0

		for word: String in words:
			if word.is_empty() and cur_words.size() > 0:
				continue
			var word_w: float = 0.0
			for i in range(word.length()):
				var c: int = word.unicode_at(i)
				word_w += 4.0 if (c == 39 or c == 96) else 8.0

			var space_w: float = 8.0 if cur_words.size() > 0 else 0.0
			if cur_w + space_w + word_w > max_w and cur_words.size() > 0:
				wrapped_lines.append(" ".join(cur_words))
				cur_words = [word]
				cur_w = word_w
			else:
				cur_words.append(word)
				cur_w += space_w + word_w

		if cur_words.size() > 0:
			wrapped_lines.append(" ".join(cur_words))

	var pages: Array[String] = []
	var cur_page_lines: Array[String] = []
	for line: String in wrapped_lines:
		cur_page_lines.append(line)
		if cur_page_lines.size() >= max_lines_per_page:
			pages.append("\n".join(cur_page_lines))
			cur_page_lines = []

	if cur_page_lines.size() > 0:
		pages.append("\n".join(cur_page_lines))

	return pages if pages.size() > 0 else [""]

func _draw() -> void:
	if not is_active:
		return

	# Fundo preto cobrindo a tela inteira da janela (Fullscreen)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 1.0))

	# Cálculo de zoom proporcional e centralização canônica (4:3)
	var zoom_factor: float = maxf(1.0, floorf(minf(size.x / 256.0, size.y / 192.0)))
	var screen_sz := Vector2(256.0, 192.0) * zoom_factor
	var origin: Vector2 = ((size - screen_sz) / 2.0).floor()

	draw_set_transform(origin, 0.0, Vector2(zoom_factor, zoom_factor))

	# Fundo preto canônico do MSX2 Screen 5 (ClearPage0)
	draw_rect(Rect2(0, 0, 256, 192), Color(0.0, 0.0, 0.0, 1.0))

	var is_send: bool = radio_system.is_send_mode if radio_system else false

	if texture_chassis:
		# Renderização autêntica com sprites extraídos do MSX2

		# 1. Título "TRANSCEIVER" em (80, 8) conforme data/menuradiotexts.asm:7 (dw 850h)
		_draw_msx_line("TRANSCEIVER", Vector2(80.0, 8.0), Color("ffffff"))

		# 2. Chassi do Transmissor em (48, 24) - desenhado ANTES para não cobrir o texto RECV
		draw_texture(texture_chassis, Vector2(48.0, 24.0))

		# 3. Indicador de modo RECV / SEND desenhado SOBRE o chassi em (56, 64) conforme data/menuradiotexts.asm:11 (dw 4038h)
		if is_send:
			_draw_msx_line("SEND", Vector2(56.0, 64.0), Color("ff4040"))
		else:
			_draw_msx_line("RECV", Vector2(56.0, 64.0), Color("ffffff"))

		# 4. Medidor de 12 LEDs de sinal em (64, 32) e (64, 40)
		if texture_leds:
			for pair_idx: int in range(6):
				var tile_idx: int = 0
				if current_leds >= (pair_idx + 1) * 2:
					tile_idx = 2  # Ambos acesos (tile 0x43)
				elif current_leds == pair_idx * 2 + 1:
					tile_idx = 1  # Esquerdo aceso, direito apagado (tile 0x42)
				else:
					tile_idx = 0  # Ambos apagados (tile 0x41)

				var src_rect := Rect2(float(tile_idx * 8), 0.0, 8.0, 8.0)
				var lx: float = 64.0 + float(pair_idx * 8)
				draw_texture_rect_region(texture_leds, Rect2(lx, 32.0, 8.0, 8.0), src_rect)
				draw_texture_rect_region(texture_leds, Rect2(lx, 40.0, 8.0, 8.0), src_rect)

		# 5. Display Digital da Frequência em (120, 33)
		if texture_120:
			draw_texture(texture_120, Vector2(120.0, 33.0))

		if texture_digits:
			var freq_val: int = radio_system.current_freq if radio_system else 85
			var d1: int = (freq_val / 10) % 10
			var d2: int = freq_val % 10
			var src_d1 := Rect2(float(d1 * 8), 0.0, 8.0, 16.0)
			var src_d2 := Rect2(float(d2 * 8), 0.0, 8.0, 16.0)
			draw_texture_rect_region(texture_digits, Rect2(152.0, 33.0, 8.0, 16.0), src_d1)
			draw_texture_rect_region(texture_digits, Rect2(160.0, 33.0, 8.0, 16.0), src_d2)

		# 6. Retrato do Solid Snake em (200, 40) com animação canônica (Banks0123.asm:8072)
		if texture_snake_portrait:
			var frame_idx: int = 0
			var is_snake_talking: bool = is_send or current_contact == "SOLID SNAKE"
			if is_snake_talking and not text_finished:
				var step: int = int(anim_timer * 60.0) & 0x1C
				if step == 0:
					frame_idx = 1 # piscar de olhos (SnakePicture1)
				elif (step & 4) != 0:
					frame_idx = 2 # falar/boca aberta (SnakePicture2)
				else:
					frame_idx = 0 # normal (SnakePicture0)
			else:
				# Piscar periódico de olhos a cada ~3 segundos (180 frames) por 8 frames
				var blink_tick: int = int(anim_timer * 60.0) % 180
				frame_idx = 1 if (blink_tick < 8) else 0

			var src_portrait := Rect2(float(frame_idx * 32), 0.0, 32.0, 32.0)
			draw_texture_rect_region(texture_snake_portrait, Rect2(200.0, 40.0, 32.0, 32.0), src_portrait)

		# 7. Moldura da Caixa de Diálogo em (32, 116, 200, 72)
		var box_rect := Rect2(32.0, 116.0, 200.0, 72.0)
		draw_rect(box_rect, Color(0.0, 0.0, 0.0, 1.0))
		draw_rect(box_rect, Color(1.0, 1.0, 1.0, 1.0), false, 1.0)

		# Texto da Mensagem em (36, 120) com espaçamento de linha canônico de 12px (Banks0123.asm:8118)
		_draw_msx_multiline(displayed_text, Vector2(36.0, 120.0), 184.0, 12.0, Color(1.0, 1.0, 1.0, 1.0))

		# Prompt piscante de ENTER do MSX2 em (212, 168) (Banks0123.asm:8201-8219 DrawEnterIcon / TextXYSize)
		if text_finished and ((int(anim_timer * 60.0) & 16) == 0):
			if texture_msx_font:
				_draw_msx_char(13, Vector2(212.0, 168.0), Color(1.0, 1.0, 1.0, 1.0))
			else:
				_draw_enter_icon(Vector2(212.0, 168.0), Color(1.0, 1.0, 1.0, 1.0))

	else:
		# Fallback procedural mantido se os arquivos protegidos não existirem
		_draw_fallback(is_send)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_msx_char(ch: int, pos: Vector2, color: Color) -> int:
	if ch < 0 or ch >= 128:
		return 8
	if ch == 32: # Espaço
		return 8
	if texture_msx_font:
		var col: int = ch % 16
		var row: int = ch / 16
		var src := Rect2(float(col * 8), float(row * 8), 8.0, 8.0)
		draw_texture_rect_region(texture_msx_font, Rect2(pos, Vector2(8.0, 8.0)), src, color)
	else:
		draw_string(ThemeDB.fallback_font, pos + Vector2(0.0, 8.0), String.chr(ch), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
	if ch == 39 or ch == 96: # Apóstrofo ocupa 4 pixels (Banks0123.asm:4703)
		return 4
	return 8

func _draw_msx_line(line_str: String, pos: Vector2, color: Color) -> float:
	var cx: float = pos.x
	for i in range(line_str.length()):
		var code: int = line_str.unicode_at(i)
		var w: int = _draw_msx_char(code, Vector2(cx, pos.y), color)
		cx += float(w)
	return cx - pos.x

func _draw_msx_multiline(text: String, start_pos: Vector2, max_w: float, line_h: float, color: Color) -> void:
	var raw_lines: PackedStringArray = text.split("\n")
	var y: float = start_pos.y
	# Limite canônico MSX2: a moldura termina em Y=188. A última linha de texto suportada fica em Y=168 (168 + 8 = 176).
	var max_y: float = start_pos.y + 4.0 * line_h

	for rline: String in raw_lines:
		if y > max_y:
			break
		var words: PackedStringArray = rline.split(" ")
		var cur_words: Array[String] = []
		var cur_w: float = 0.0

		for word: String in words:
			var word_w: float = 0.0
			for i in range(word.length()):
				var c: int = word.unicode_at(i)
				word_w += 4.0 if (c == 39 or c == 96) else 8.0

			var space_w: float = 8.0 if cur_words.size() > 0 else 0.0
			if cur_w + space_w + word_w > max_w and cur_words.size() > 0:
				if y > max_y:
					break
				_draw_msx_line(" ".join(cur_words), Vector2(start_pos.x, y), color)
				y += line_h
				cur_words = [word]
				cur_w = word_w
			else:
				cur_words.append(word)
				cur_w += space_w + word_w

		if cur_words.size() > 0 and y <= max_y:
			_draw_msx_line(" ".join(cur_words), Vector2(start_pos.x, y), color)
			y += line_h

func _draw_fallback(is_send: bool) -> void:
	var panel_rect := Rect2(8, 6, 240, 180)
	draw_rect(panel_rect, Color("141c24"))
	draw_rect(panel_rect, Color("485c6c"), false, 2.0)
	draw_rect(Rect2(10, 8, 236, 176), Color("243444"), false, 1.0)

	draw_rect(Rect2(12, 10, 232, 16), Color("182430"))
	draw_string(ThemeDB.fallback_font, Vector2(16, 22), "TRANSCEIVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("50e080"))

	var recv_color := Color("40e060") if not is_send else Color("405060")
	var send_color := Color("ff5050") if is_send else Color("405060")
	draw_string(ThemeDB.fallback_font, Vector2(150, 22), "[RECV]", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, recv_color)
	draw_string(ThemeDB.fallback_font, Vector2(195, 22), "[SEND]", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, send_color)

	var freq_box := Rect2(16, 30, 130, 24)
	draw_rect(freq_box, Color("081014"))
	draw_rect(freq_box, Color("304858"), false, 1.0)
	var freq_val: String = radio_system.get_frequency_string() if radio_system else "120.85"
	var freq_str: String = "< %s MHz >" % freq_val
	draw_string(ThemeDB.fallback_font, Vector2(24, 46), freq_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("60ff80"))

	var meter_x: float = 154.0
	var meter_y: float = 34.0
	draw_string(ThemeDB.fallback_font, Vector2(meter_x, 42), "SIGNAL:", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("8098a8"))
	for i: int in range(12):
		var led_rect := Rect2(meter_x + float(i * 6), meter_y + 10, 5, 8)
		var led_on: bool = (i < current_leds)
		var led_color := Color("30e040") if led_on else Color("143018")
		draw_rect(led_rect, led_color)
		draw_rect(led_rect, Color("081014"), false, 0.5)

	var dialog_rect := Rect2(16, 60, 224, 100)
	draw_rect(dialog_rect, Color("081018"))
	draw_rect(dialog_rect, Color("384858"), false, 1.0)
	var header_name: String = current_contact_name if not current_contact_name.is_empty() else "RADIO"
	draw_string(ThemeDB.fallback_font, Vector2(22, 73), header_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e0d040"))
	draw_line(Vector2(22, 76), Vector2(234, 76), Color("283848"), 1.0)
	_draw_msx_multiline(displayed_text, Vector2(22, 88), 212.0, 11.0, Color("e0e8f0"))

func _draw_enter_icon(pos: Vector2, color: Color) -> void:
	for y in range(8):
		var row_bits: int = ENTER_ICON_BITS[y]
		for x in range(8):
			if (row_bits & (1 << (7 - x))) != 0:
				draw_rect(Rect2(pos.x + float(x), pos.y + float(y), 1.0, 1.0), color)
