class_name WeaponMenu
extends Control

## Menu modal de seleção de armas estilo Metal Gear MSX2.
## Congela a ação e permite escolher armas com WASD/Setas e confirmar com J/Z/Enter/Clique.

signal weapon_selected(weapon_name: String)
signal menu_closed

var weapon_system: WeaponSystem = null
var current_selection_idx: int = 0
var available_options: Array[Dictionary] = [] # {"id": String, "label": String}

var panel: PanelContainer
var list_container: VBoxContainer
var title_label: Label
var footer_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	z_index = 100

	# Fundo escuro semi-transparente
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	add_child(bg)

	# Painel central
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 200)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.1, 0.08, 0.95)
	style.border_color = Color(0.3, 0.8, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_bottom = 12
	style.content_margin_top = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	title_label = Label.new()
	title_label.text = "== WEAPONS =="
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	vbox.add_child(title_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 4)
	vbox.add_child(list_container)

	footer_label = Label.new()
	footer_label.text = "CIMA/BAIXO: Navegar · ENTER/J/Z/Clique: Equipar · Q/ESC: Sair"
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", 11)
	footer_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.6))
	vbox.add_child(footer_label)

func open_menu(ws: WeaponSystem) -> void:
	weapon_system = ws
	_rebuild_list()
	visible = true
	grab_focus()

func close_menu() -> void:
	visible = false
	emit_signal("menu_closed")

func _rebuild_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	available_options.clear()

	# Opção 0: Desarmado
	available_options.append({"id": WeaponSystem.WEAPON_NONE, "label": "[DESARMADO]"})

	if weapon_system != null:
		for w_id in weapon_system.owned_weapons:
			var cur_ammo: int = int(weapon_system.ammo.get(w_id, 0))
			var max_ammo: int = int(weapon_system.max_ammo.get(w_id, 50))
			var silencer_tag: String = " [SILENCIADOR]" if (w_id == WeaponSystem.WEAPON_HANDGUN and weapon_system.has_silencer) else ""
			available_options.append({
				"id": w_id,
				"label": "%-16s %02d/%02d%s" % [w_id, cur_ammo, max_ammo, silencer_tag]
			})

	# Encontrar índice atualmente equipado
	current_selection_idx = 0
	if weapon_system != null:
		for i in range(available_options.size()):
			if available_options[i]["id"] == weapon_system.selected_weapon:
				current_selection_idx = i
				break

	_render_items()

func _render_items() -> void:
	for child in list_container.get_children():
		child.queue_free()

	for i in range(available_options.size()):
		var opt := available_options[i]
		var btn := Button.new()
		var is_selected: bool = (i == current_selection_idx)
		var is_equipped: bool = (weapon_system != null and weapon_system.selected_weapon == opt["id"])
		var prefix: String = "> " if is_selected else "  "
		var suffix: String = " (EQUIPADA)" if is_equipped else ""
		btn.text = prefix + opt["label"] + suffix
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE

		var style := StyleBoxFlat.new()
		if is_selected:
			style.bg_color = Color(0.15, 0.35, 0.2, 0.9)
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
		else:
			style.bg_color = Color(0.08, 0.15, 0.1, 0.5)
			btn.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

		var captured_idx: int = i
		btn.pressed.connect(func() -> void:
			current_selection_idx = captured_idx
			_confirm_selection()
		)
		list_container.add_child(btn)

func _confirm_selection() -> void:
	if current_selection_idx >= 0 and current_selection_idx < available_options.size():
		var chosen: String = str(available_options[current_selection_idx]["id"])
		if weapon_system != null:
			weapon_system.selected_weapon = chosen
		emit_signal("weapon_selected", chosen)
	close_menu()

func handle_input(event: InputEvent) -> bool:
	if not visible:
		return false

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP or event.keycode == KEY_W:
			current_selection_idx = (current_selection_idx - 1 + available_options.size()) % maxi(1, available_options.size())
			_render_items()
			return true
		elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
			current_selection_idx = (current_selection_idx + 1) % maxi(1, available_options.size())
			_render_items()
			return true
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_J, KEY_Z]:
			_confirm_selection()
			return true
		elif event.keycode == KEY_ESCAPE or event.keycode == KEY_Q:
			close_menu()
			return true

	# Se for release da tecla Shift enquanto o menu foi aberto por segurar Shift
	if event is InputEventKey and not event.pressed:
		if event.keycode == KEY_SHIFT:
			close_menu()
			return true

	return true
