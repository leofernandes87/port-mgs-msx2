class_name RadioDialog
extends Control

## Interface Gráfica autêntica do Transceptor / Codec do MSX2 RC750 (Etapa 15).
## Estilo visual militar autêntico com display de frequência, 12 LEDs de sinal, retratos e texto digitado.

signal radio_closed

var radio_system: RadioSystem = null
var current_room_id: int = 0
var is_active: bool = false

# Efeito de máquina de escrever (typewriter)
var target_full_text: String = ""
var displayed_text: String = ""
var char_index: int = 0
var typewriter_speed: float = 0.02
var typewriter_timer: float = 0.0
var text_finished: bool = true

# Dados da transmissão atual
var current_contact: String = ""
var current_contact_name: String = ""
var current_text: String = ""
var has_signal: bool = false

# Animação dos 12 LEDs de sinal
var target_leds: int = 0
var current_leds: int = 0
var led_anim_timer: float = 0.0

# Suporte a transmissões com múltiplas páginas (ex: briefing Operação Intrude N313)
var dialog_pages: Array[String] = []
var current_page_index: int = 0

func _ready() -> void:
	visible = false
	z_index = 20
	custom_minimum_size = Vector2(256.0, 192.0)
	size = Vector2(256.0, 192.0)

func start_briefing(contact: String, contact_name: String, pages: Array[String], system: RadioSystem = null) -> void:
	if system:
		radio_system = system
	elif not radio_system:
		radio_system = RadioSystem.new()
	is_active = true
	visible = true
	dialog_pages = pages.duplicate()
	current_page_index = 0
	current_contact = contact
	current_contact_name = contact_name
	has_signal = true
	target_leds = 12
	current_leds = 0
	if radio_system:
		radio_system.is_send_mode = false
		radio_system.set_frequency(RadioSystem.FREQ_BIGBOSS_PR1)
	if dialog_pages.size() > 0:
		_set_text(dialog_pages[0])
	queue_redraw()
	print("RADIO_BRIEFING: Iniciado briefing de %s (%d páginas)" % [contact_name, dialog_pages.size()])

func open_radio(system: RadioSystem, room_id: int, auto_answer: bool = false) -> void:
	radio_system = system
	current_room_id = room_id
	is_active = true
	visible = true

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
	dialog_pages.clear()
	current_page_index = 0
	radio_closed.emit()
	print("RADIO_CLOSED: Transceptor desligado.")


func _process(delta: float) -> void:
	if not is_active:
		return

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
		if led_anim_timer >= 0.04:
			led_anim_timer = 0.0
			if current_leds < target_leds:
				current_leds += 1
			else:
				current_leds -= 1
			queue_redraw()

func handle_input(event: InputEvent) -> bool:
	if not is_active:
		return false

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_F4 or event.keycode == KEY_T or event.keycode == KEY_ESCAPE)):
		close_radio()
		return true

	# Avançar texto imediatamente se pressionar Espaço ou Enter
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		if not text_finished:
			# Pula digitação e exibe tudo
			displayed_text = target_full_text
			char_index = target_full_text.length()
			text_finished = true
			queue_redraw()
			return true
		else:
			# Texto já completo: verifica se há mais páginas
			if current_page_index + 1 < dialog_pages.size():
				current_page_index += 1
				_set_text(dialog_pages[current_page_index])
				queue_redraw()
				return true
			elif dialog_pages.size() > 0:
				close_radio()
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
	target_full_text = text
	displayed_text = ""
	char_index = 0
	typewriter_timer = 0.0
	text_finished = false

func _draw() -> void:
	if not is_active:
		return

	# Fundo escuro semitransparente que cobre a tela inteira (256x192)
	draw_rect(Rect2(0, 0, 256, 192), Color(0.04, 0.06, 0.08, 0.95))

	# Moldura metálica militar principal
	var panel_rect := Rect2(8, 6, 240, 180)
	draw_rect(panel_rect, Color("141c24"))
	draw_rect(panel_rect, Color("485c6c"), false, 2.0)
	draw_rect(Rect2(10, 8, 236, 176), Color("243444"), false, 1.0)

	# 1. Barra de Cabeçalho: Título "TRANSCEIVER" e Modos [RECV] / [SEND]
	draw_rect(Rect2(12, 10, 232, 16), Color("182430"))
	draw_string(ThemeDB.fallback_font, Vector2(16, 22), "TRANSCEIVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("50e080"))

	var is_send: bool = radio_system.is_send_mode if radio_system else false
	var recv_color := Color("40e060") if not is_send else Color("405060")
	var send_color := Color("ff5050") if is_send else Color("405060")
	draw_string(ThemeDB.fallback_font, Vector2(150, 22), "[RECV]", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, recv_color)
	draw_string(ThemeDB.fallback_font, Vector2(195, 22), "[SEND]", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, send_color)

	# 2. Display Digital de Frequência
	var freq_box := Rect2(16, 30, 130, 24)
	draw_rect(freq_box, Color("081014"))
	draw_rect(freq_box, Color("304858"), false, 1.0)
	var freq_val: String = radio_system.get_frequency_string() if radio_system else "120.85"
	var freq_str: String = "< %s MHz >" % freq_val
	draw_string(ThemeDB.fallback_font, Vector2(24, 46), freq_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("60ff80"))

	# 3. Medidor de Sinal (12 LEDs de sinal - Banks0123.asm:10798)
	var meter_x: float = 154.0
	var meter_y: float = 34.0
	draw_string(ThemeDB.fallback_font, Vector2(meter_x, 42), "SIGNAL:", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("8098a8"))
	for i: int in range(12):
		var led_rect := Rect2(meter_x + float(i * 6), meter_y + 10, 5, 8)
		var led_on: bool = (i < current_leds)
		var led_color: Color
		if i < 8:
			led_color = Color("30e040") if led_on else Color("143018")
		elif i < 10:
			led_color = Color("e0d020") if led_on else Color("302c08")
		else:
			led_color = Color("e03030") if led_on else Color("300c0c")
		draw_rect(led_rect, led_color)
		draw_rect(led_rect, Color("081014"), false, 0.5)

	# 4. Moldura do Retrato do Interlocutor (60x60 px)
	var portrait_rect := Rect2(16, 60, 56, 56)
	draw_rect(portrait_rect, Color("0c141c"))
	draw_rect(portrait_rect, Color("486078"), false, 1.0)
	_draw_portrait(portrait_rect)

	# 5. Caixa de Mensagem / Diálogo
	var dialog_rect := Rect2(78, 60, 162, 100)
	draw_rect(dialog_rect, Color("081018"))
	draw_rect(dialog_rect, Color("384858"), false, 1.0)

	# Nome do Interlocutor
	var header_name: String = current_contact_name if not current_contact_name.is_empty() else "RADIO"
	draw_string(ThemeDB.fallback_font, Vector2(84, 73), header_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e0d040"))
	draw_line(Vector2(84, 76), Vector2(234, 76), Color("283848"), 1.0)

	# Texto da Mensagem quebrando em linhas
	_draw_multiline_text(displayed_text, Vector2(84, 88), 150.0, 11.0, Color("e0e8f0"))

	# Indicador de páginas para briefings longos
	if dialog_pages.size() > 1:
		var page_str := "[ %d / %d ]" % [current_page_index + 1, dialog_pages.size()]
		draw_string(ThemeDB.fallback_font, Vector2(195, 155), page_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("60a080"))

	# 6. Rodapé com Instruções de Controle
	var help_str: String = "A/D: SINTONIZAR  W: TRANSMITIR  ESPAÇO: AVANÇAR  T/F4: SAIR"
	draw_string(ThemeDB.fallback_font, Vector2(16, 176), help_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("708898"))

func _draw_portrait(rect: Rect2) -> void:
	var cx: float = rect.position.x
	var cy: float = rect.position.y

	if (radio_system and radio_system.is_send_mode) or current_contact.is_empty():
		# Retrato do Solid Snake (MSX2 style)
		# Rosto
		draw_rect(Rect2(cx + 16, cy + 14, 24, 28), Color("d8a078"))
		# Bandana verde/azul militar
		draw_rect(Rect2(cx + 14, cy + 10, 28, 8), Color("284850"))
		# Cabelo castanho
		draw_rect(Rect2(cx + 14, cy + 4, 28, 8), Color("382014"))
		draw_rect(Rect2(cx + 12, cy + 8, 4, 20), Color("382014"))
		draw_rect(Rect2(cx + 40, cy + 8, 4, 20), Color("382014"))
		# Olhos
		draw_rect(Rect2(cx + 20, cy + 22, 5, 2), Color("181820"))
		draw_rect(Rect2(cx + 31, cy + 22, 5, 2), Color("181820"))
		# Traje militar (ombros)
		draw_rect(Rect2(cx + 8, cy + 42, 40, 14), Color("304838"))
	elif current_contact == RadioSystem.CONTACT_BIG_BOSS:
		# Retrato do Big Boss (tapa-olho direito, barba e boina/cabelo grisalho)
		draw_rect(Rect2(cx + 16, cy + 14, 24, 28), Color("c89068"))
		# Cabelo / boina
		draw_rect(Rect2(cx + 14, cy + 4, 28, 10), Color("404848"))
		# Tapa-olho (olho direito de Big Boss = lado esquerdo do sprite)
		draw_rect(Rect2(cx + 19, cy + 20, 7, 6), Color("101018"))
		draw_line(Vector2(cx + 14, cy + 16), Vector2(cx + 26, cy + 26), Color("101018"), 1.5)
		# Olho esquerdo visível
		draw_rect(Rect2(cx + 31, cy + 22, 5, 2), Color("181820"))
		# Barba/bigode grisalho
		draw_rect(Rect2(cx + 18, cy + 34, 20, 8), Color("686868"))
		# Uniforme com gola alta
		draw_rect(Rect2(cx + 8, cy + 42, 40, 14), Color("384030"))
	elif current_contact == RadioSystem.CONTACT_SCHNEIDER:
		# Retrato de Schneider (cabelo escuro espetado, expressão séria)
		draw_rect(Rect2(cx + 16, cy + 14, 24, 28), Color("d09870"))
		draw_rect(Rect2(cx + 12, cy + 4, 32, 12), Color("201824"))
		draw_rect(Rect2(cx + 20, cy + 22, 5, 2), Color("181820"))
		draw_rect(Rect2(cx + 31, cy + 22, 5, 2), Color("181820"))
		draw_rect(Rect2(cx + 8, cy + 42, 40, 14), Color("504030"))
	elif current_contact == RadioSystem.CONTACT_DIANE:
		# Retrato de Diane (cabelo loiro comprido)
		draw_rect(Rect2(cx + 16, cy + 14, 24, 28), Color("e0a880"))
		draw_rect(Rect2(cx + 12, cy + 4, 32, 12), Color("d8b040"))
		draw_rect(Rect2(cx + 10, cy + 14, 6, 30), Color("d8b040"))
		draw_rect(Rect2(cx + 40, cy + 14, 6, 30), Color("d8b040"))
		draw_rect(Rect2(cx + 20, cy + 22, 5, 2), Color("203050"))
		draw_rect(Rect2(cx + 31, cy + 22, 5, 2), Color("203050"))
		draw_rect(Rect2(cx + 8, cy + 42, 40, 14), Color("603040"))

func _draw_multiline_text(text: String, start_pos: Vector2, max_w: float, line_h: float, color: Color) -> void:
	var raw_lines: PackedStringArray = text.split("\n")
	var y: float = start_pos.y

	for rline: String in raw_lines:
		var words: PackedStringArray = rline.split(" ")
		var cur_line: String = ""

		for word: String in words:
			var test_line: String = cur_line + (" " if not cur_line.is_empty() else "") + word
			var line_w: float = ThemeDB.fallback_font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			if line_w > max_w and not cur_line.is_empty():
				draw_string(ThemeDB.fallback_font, Vector2(start_pos.x, y), cur_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
				y += line_h
				cur_line = word
			else:
				cur_line = test_line

		if not cur_line.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(start_pos.x, y), cur_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
			y += line_h
