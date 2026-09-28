class_name BinocularOverlay
extends Control

## Overlay visual autêntico do modo Binóculo / Telescópio do Metal Gear MSX2 RC750.
## Lógica revertida de Banks0123.asm:12572-12604 e logic/menuequipment.asm:338-361.

var is_active: bool = false
var state: BinocularSystem.State = BinocularSystem.State.INACTIVE
var looking_direction: int = -1
var preview_room_id: int = -1
var home_room_id: int = -1

var title_label: Label
var subtitle_label: Label

func _init() -> void:
	custom_minimum_size = Vector2(256.0, 192.0)
	size = Vector2(256.0, 192.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 25
	visible = false

	# Título "TELESCOPE MODE" (MSX: txtTelescope)
	title_label = Label.new()
	title_label.text = "TELESCOPE MODE"
	title_label.position = Vector2(0.0, 8.0)
	title_label.size = Vector2(256.0, 16.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 10)
	title_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 0.95))

	# Subtítulo com instrução / sala observada
	subtitle_label = Label.new()
	subtitle_label.text = ""
	subtitle_label.position = Vector2(0.0, 172.0)
	subtitle_label.size = Vector2(256.0, 16.0)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 9)
	subtitle_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))

	add_child(title_label)
	add_child(subtitle_label)

func update_state(active: bool, cur_state: BinocularSystem.State, dir: int, p_room: int, h_room: int) -> void:
	is_active = active
	state = cur_state
	looking_direction = dir
	preview_room_id = p_room
	home_room_id = h_room
	visible = is_active

	if subtitle_label:
		if state == BinocularSystem.State.LOOKING:
			var dir_name: String = ""
			match looking_direction:
				PlayerController.Direction.UP: dir_name = "NORTE"
				PlayerController.Direction.DOWN: dir_name = "SUL"
				PlayerController.Direction.LEFT: dir_name = "OESTE"
				PlayerController.Direction.RIGHT: dir_name = "LESTE"
			subtitle_label.text = "[OBSERVANDO: %s · SALA %03d]" % [dir_name, preview_room_id]
			subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 0.95))
		else:
			subtitle_label.text = "[SETAS / WASD]: OBSERVAR  ·  [E / ESC]: SAIR"
			subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 0.85))

	queue_redraw()

func _draw() -> void:
	if not is_active:
		return

	var center := Vector2(128.0, 96.0)

	# 1. Mira / Retículo Central MSX (BinocularSprAtt em logic/menuequipment.asm:355)
	var reticle_col := Color(1.0, 1.0, 1.0, 0.9)
	var accent_col := Color(0.3, 1.0, 0.4, 0.95)

	# Círculo central pequeno
	draw_arc(center, 4.0, 0.0, TAU, 16, reticle_col, 1.0)
	# Círculo externo
	draw_arc(center, 24.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.35), 1.0)

	# Ticks de mira em cruz
	draw_line(Vector2(center.x - 26.0, center.y), Vector2(center.x - 7.0, center.y), reticle_col, 1.0)
	draw_line(Vector2(center.x + 7.0, center.y), Vector2(center.x + 26.0, center.y), reticle_col, 1.0)
	draw_line(Vector2(center.x, center.y - 22.0), Vector2(center.x, center.y - 7.0), reticle_col, 1.0)
	draw_line(Vector2(center.x, center.y + 7.0), Vector2(center.x, center.y + 22.0), reticle_col, 1.0)

	# Colchetes táticos [ ]
	# Superior esquerdo
	draw_line(Vector2(center.x - 18.0, center.y - 15.0), Vector2(center.x - 12.0, center.y - 15.0), accent_col, 1.0)
	draw_line(Vector2(center.x - 18.0, center.y - 15.0), Vector2(center.x - 18.0, center.y - 9.0), accent_col, 1.0)
	# Superior direito
	draw_line(Vector2(center.x + 18.0, center.y - 15.0), Vector2(center.x + 12.0, center.y - 15.0), accent_col, 1.0)
	draw_line(Vector2(center.x + 18.0, center.y - 15.0), Vector2(center.x + 18.0, center.y - 9.0), accent_col, 1.0)
	# Inferior esquerdo
	draw_line(Vector2(center.x - 18.0, center.y + 15.0), Vector2(center.x - 12.0, center.y + 15.0), accent_col, 1.0)
	draw_line(Vector2(center.x - 18.0, center.y + 15.0), Vector2(center.x - 18.0, center.y + 9.0), accent_col, 1.0)
	# Inferior direito
	draw_line(Vector2(center.x + 18.0, center.y + 15.0), Vector2(center.x + 12.0, center.y + 15.0), accent_col, 1.0)
	draw_line(Vector2(center.x + 18.0, center.y + 15.0), Vector2(center.x + 18.0, center.y + 9.0), accent_col, 1.0)

	# 2. Seta de Direção Canônica MSX (ArrowsChars em Banks0123.asm:12599)
	if state == BinocularSystem.State.LOOKING and looking_direction != -1:
		var arrow_col := Color(1.0, 0.9, 0.2, 0.95)
		match looking_direction:
			PlayerController.Direction.UP:
				draw_colored_polygon([
					Vector2(128.0, 24.0), Vector2(120.0, 36.0), Vector2(136.0, 36.0)
				], arrow_col)
			PlayerController.Direction.DOWN:
				draw_colored_polygon([
					Vector2(128.0, 168.0), Vector2(120.0, 156.0), Vector2(136.0, 156.0)
				], arrow_col)
			PlayerController.Direction.LEFT:
				draw_colored_polygon([
					Vector2(16.0, 96.0), Vector2(28.0, 88.0), Vector2(28.0, 104.0)
				], arrow_col)
			PlayerController.Direction.RIGHT:
				draw_colored_polygon([
					Vector2(240.0, 96.0), Vector2(228.0, 88.0), Vector2(228.0, 104.0)
				], arrow_col)
