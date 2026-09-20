extends Control
## Explicit local snapshot viewer. Default project boot remains ROM independent.

var snapshot: RoomSnapshot = RoomSnapshot.new()
var canvas: RoomCanvas
var status: Label
var picker: FileDialog
var overlay_button: CheckButton

func _ready() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	margin.add_child(column)
	var bar: HBoxContainer = HBoxContainer.new()
	column.add_child(bar)
	var title: Label = Label.new()
	title.text = "Laboratório MSX2 · Salas"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title)
	var open_button: Button = Button.new()
	open_button.text = "Abrir snapshot local"
	open_button.pressed.connect(func() -> void: picker.popup_centered_ratio(0.8))
	bar.add_child(open_button)
	overlay_button = CheckButton.new()
	overlay_button.text = "Colisão estática"
	overlay_button.toggled.connect(_toggle_collision)
	bar.add_child(overlay_button)
	status = Label.new()
	status.text = "Selecione um snapshot exportado. Nenhuma ROM é carregada pelo Godot."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	canvas = RoomCanvas.new()
	canvas.custom_minimum_size = Vector2(512, 384)
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(canvas)
	canvas.resized.connect(canvas.queue_redraw)
	var note: Label = Label.new()
	note.text = "Fundo estático · paleta nominal · sem portas, entidades ou movimentação"
	column.add_child(note)
	picker = FileDialog.new()
	picker.access = FileDialog.ACCESS_FILESYSTEM
	picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	picker.filters = PackedStringArray(["*.json ; Snapshot de sala"])
	picker.file_selected.connect(load_snapshot)
	add_child(picker)
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	for index: int in range(arguments.size() - 1):
		if arguments[index] == "--snapshot":
			load_snapshot(arguments[index + 1])

func load_snapshot(path: String) -> void:
	if snapshot.load_path(path) != OK:
		status.text = snapshot.error_message
		canvas.show_snapshot(snapshot)
		return
	canvas.show_snapshot(snapshot)
	status.text = "Sala %03d · 256×192 pixels · %s" % [snapshot.room_id, path.get_file()]
	print("ROOM_LOADED: %d" % snapshot.room_id)

func _toggle_collision(enabled: bool) -> void:
	overlay_button.set_pressed_no_signal(enabled)
	canvas.show_collision = enabled
	canvas.queue_redraw()
