class_name PauseMenu
extends Control

## Tela de Pause com menu de opções e configurações do Sandbox estilo MSX2.
## Congela a ação e permite alternar God Mode, receber armas, toggles de debug e reset.

signal continue_requested
signal god_mode_toggled(enabled: bool)
signal give_arsenal_requested
signal collision_toggled(enabled: bool)
signal enemy_vision_toggled(enabled: bool)
signal colliders_toggled(enabled: bool)
signal reset_room_requested
signal title_screen_requested
signal map_mode_toggled(use_remaster: bool)

var is_god_mode: bool = false
var show_collision: bool = false
var show_enemy_vision: bool = false
var show_colliders: bool = false
var use_remastered_maps: bool = false

var panel: PanelContainer
var god_mode_btn: Button
var collision_btn: Button
var vision_btn: Button
var colliders_btn: Button
var map_mode_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	z_index = 100

	# Fundo escuro semi-transparente
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 310)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.06, 0.98)
	style.border_color = Color(0.8, 0.7, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_bottom = 14
	style.content_margin_top = 14
	style.content_margin_left = 18
	style.content_margin_right = 18
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "== PAUSE / OPÇÕES =="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# 1. Continuar Jogo
	var resume_btn := _create_option_button("▶ Continuar Jogo (ESC)", Color(0.3, 0.8, 0.4))
	resume_btn.pressed.connect(func() -> void:
		emit_signal("continue_requested")
		close_menu()
	)
	vbox.add_child(resume_btn)

	# 2. Invencibilidade (God Mode)
	god_mode_btn = _create_option_button("", Color(0.9, 0.9, 0.9))
	god_mode_btn.pressed.connect(func() -> void:
		is_god_mode = not is_god_mode
		_update_buttons_text()
		emit_signal("god_mode_toggled", is_god_mode)
	)
	vbox.add_child(god_mode_btn)

	# 3. Receber Arsenal Completo
	var arsenal_btn := _create_option_button("★ Receber Arsenal Completo (Kit)", Color(0.9, 0.7, 0.2))
	arsenal_btn.pressed.connect(func() -> void:
		emit_signal("give_arsenal_requested")
	)
	vbox.add_child(arsenal_btn)

	# 4. Mostrar Grade de Colisão
	collision_btn = _create_option_button("", Color(0.9, 0.9, 0.9))
	collision_btn.pressed.connect(func() -> void:
		show_collision = not show_collision
		_update_buttons_text()
		emit_signal("collision_toggled", show_collision)
	)
	vbox.add_child(collision_btn)

	# 5. Mostrar Visão dos Inimigos
	vision_btn = _create_option_button("", Color(0.9, 0.9, 0.9))
	vision_btn.pressed.connect(func() -> void:
		show_enemy_vision = not show_enemy_vision
		_update_buttons_text()
		emit_signal("enemy_vision_toggled", show_enemy_vision)
	)
	vbox.add_child(vision_btn)

	# 6. Mostrar Hitbox de Snake
	colliders_btn = _create_option_button("", Color(0.9, 0.9, 0.9))
	colliders_btn.pressed.connect(func() -> void:
		show_colliders = not show_colliders
		_update_buttons_text()
		emit_signal("colliders_toggled", show_colliders)
	)
	vbox.add_child(colliders_btn)

	# 7. Alternar Modo de Mapa (Original MSX2 vs Remaster HD)
	map_mode_btn = _create_option_button("", Color(0.9, 0.9, 0.9))
	map_mode_btn.pressed.connect(func() -> void:
		use_remastered_maps = not use_remastered_maps
		_update_buttons_text()
		emit_signal("map_mode_toggled", use_remastered_maps)
	)
	vbox.add_child(map_mode_btn)

	# 7. Reiniciar Sala Atual
	var reset_btn := _create_option_button("⟲ Reiniciar Snake na Sala Atual", Color(1.0, 0.4, 0.4))
	reset_btn.pressed.connect(func() -> void:
		emit_signal("reset_room_requested")
		close_menu()
	)
	vbox.add_child(reset_btn)

	# 8. Voltar à Tela de Título
	var title_btn := _create_option_button("⌂ Voltar à Tela de Título", Color(0.7, 0.8, 1.0))
	title_btn.pressed.connect(func() -> void:
		emit_signal("title_screen_requested")
		close_menu()
	)
	vbox.add_child(title_btn)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Guia de controles
	var controls_help := Label.new()
	controls_help.text = "Comandos: WASD/Setas: Mover · J/Z/Clique: Atirar/Socar · K/X: Soco\nQ/Shift: Menu Armas · E/Ctrl: Menu Itens · R/Tab: Rádio · ESC: Pause"
	controls_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_help.add_theme_font_size_override("font_size", 10)
	controls_help.add_theme_color_override("font_color", Color(0.65, 0.75, 0.7))
	vbox.add_child(controls_help)

	_update_buttons_text()

func _create_option_button(label_text: String, text_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.12, 0.8)
	style.border_color = Color(0.2, 0.4, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", text_color)
	return btn

func open_menu(god_mode: bool, col: bool, vis: bool, colliders: bool, use_remaster: bool = false) -> void:
	is_god_mode = god_mode
	show_collision = col
	show_enemy_vision = vis
	show_colliders = colliders
	use_remastered_maps = use_remaster
	_update_buttons_text()
	visible = true
	grab_focus()

func close_menu() -> void:
	visible = false

func _update_buttons_text() -> void:
	if god_mode_btn:
		god_mode_btn.text = "⚡ Invencibilidade (God Mode): " + ("[ LIGADO ]" if is_god_mode else "[ DESLIGADO ]")
		god_mode_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2) if is_god_mode else Color(0.8, 0.8, 0.8))
	if collision_btn:
		collision_btn.text = "▦ Grade de Colisão do Mapa: " + ("[ LIGADA ]" if show_collision else "[ DESLIGADA ]")
		collision_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4) if show_collision else Color(0.8, 0.8, 0.8))
	if vision_btn:
		vision_btn.text = "👁 Campo de Visão Inimigo: " + ("[ LIGADO ]" if show_enemy_vision else "[ DESLIGADO ]")
		vision_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4) if show_enemy_vision else Color(0.8, 0.8, 0.8))
	if colliders_btn:
		colliders_btn.text = "● Hitbox / Pontos de Snake: " + ("[ LIGADOS ]" if show_colliders else "[ DESLIGADOS ]")
		colliders_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4) if show_colliders else Color(0.8, 0.8, 0.8))
	if map_mode_btn:
		map_mode_btn.text = "🎨 Mapa de Fundo: " + ("[ REMASTER HD ]" if use_remastered_maps else "[ ORIGINAL MSX2 ]")
		map_mode_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0) if use_remastered_maps else Color(0.3, 1.0, 0.4))

func handle_input(event: InputEvent) -> bool:
	if not visible:
		return false
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			emit_signal("continue_requested")
			close_menu()
			return true
	return true
