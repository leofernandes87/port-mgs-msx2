class_name ItemMenu
extends Control

## Menu modal de seleção de equipamentos e itens estilo Metal Gear MSX2.
## Congela a ação e permite escolher itens com WASD/Setas e confirmar com J/Z/Enter/Clique.

signal item_selected(item_id: String)
signal menu_closed

var inventory: InventoryManager = null
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
	panel.custom_minimum_size = Vector2(280, 220)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	style.border_color = Color(0.3, 0.6, 0.9)
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
	title_label.text = "== EQUIPMENT =="
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(title_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 4)
	vbox.add_child(list_container)

	footer_label = Label.new()
	footer_label.text = "CIMA/BAIXO: Navegar · ENTER/J/Z/Clique: Equipar · E/ESC: Sair"
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", 11)
	footer_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	vbox.add_child(footer_label)

func open_menu(inv: InventoryManager) -> void:
	inventory = inv
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

	# Opção 0: Nenhum equipado
	available_options.append({"id": "", "label": "[NENHUM]"})

	if inventory != null:
		for item in inventory.items:
			var label_str: String = item
			if item == InventoryManager.ITEM_RATION:
				label_str = "RATION (x%d/%d)" % [inventory.rations_count, inventory.max_rations]
			elif item == InventoryManager.ITEM_BOX:
				label_str = "CARDBOARD BOX"
			elif item == InventoryManager.ITEM_GOGGLES:
				label_str = "INFRARED GOGGLES"
			elif item == InventoryManager.ITEM_SILENCER:
				label_str = "SILENCER"
			available_options.append({
				"id": item,
				"label": label_str
			})

	# Encontrar índice atualmente selecionado
	current_selection_idx = 0
	if inventory != null:
		var cur_sel: String = inventory.get_selected_item()
		for i in range(available_options.size()):
			if available_options[i]["id"] == cur_sel:
				current_selection_idx = i
				break

	_render_items()

func _render_items() -> void:
	for child in list_container.get_children():
		child.queue_free()

	var equipped_item: String = inventory.get_selected_item() if inventory != null else ""

	for i in range(available_options.size()):
		var opt := available_options[i]
		var btn := Button.new()
		var is_selected: bool = (i == current_selection_idx)
		var is_equipped: bool = (opt["id"] != "" and opt["id"] == equipped_item) or (opt["id"] == "" and equipped_item == "")
		var prefix: String = "> " if is_selected else "  "
		var suffix: String = " (EQUIPADO)" if is_equipped else ""
		btn.text = prefix + opt["label"] + suffix
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE

		var style := StyleBoxFlat.new()
		if is_selected:
			style.bg_color = Color(0.15, 0.25, 0.4, 0.9)
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
		else:
			style.bg_color = Color(0.08, 0.12, 0.18, 0.5)
			btn.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
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
		if inventory != null:
			if chosen == "":
				inventory.selected_index = -1
			else:
				inventory.selected_index = inventory.items.find(chosen)
		emit_signal("item_selected", chosen)
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
		elif event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			close_menu()
			return true

	# Se for release de Ctrl ou Alt
	if event is InputEventKey and not event.pressed:
		if event.keycode == KEY_CTRL or event.keycode == KEY_ALT:
			close_menu()
			return true

	return true
