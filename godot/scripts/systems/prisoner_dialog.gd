class_name PrisonerDialog
extends Node2D

## English text box type 1, SetText mode 0. Text/assets remain private.
## Banks0123.asm:7798-8303; geometry tables:8365-8387.
signal closed

enum State { CLOSED, INIT, APPEAR, DECODE, PRINT, WAIT, END }
const DATA_FILE: String = "dialogues/grey-fox-en.json"
const FONT_PATH: String = "res://assets/protected/sprites/transceiver/msx_font.png"
const BOX: Rect2 = Rect2(48, 8, 160, 41)
const TEXT_ORIGIN: Vector2 = Vector2(52, 12)
const PROMPT_ORIGIN: Vector2 = Vector2(196, 36)
## The box is drawn into VRAM page 0 like room tiles, items and doors (z <= 6); hardware
## sprites (enemies, Snake, shots: z >= 8) stay above it. textboxappear.asm:51-62,
## Banks0123.asm:4741-4744; sprites over bitmap: hudspritemask.asm:37-41, nextroom.asm:90.
const BITMAP_LAYER_Z: int = 7

var is_active: bool = false
var state: State = State.CLOSED
var pages: Array = []
var page_index: int = -1
var tick_counter: int = 0
var glyphs: Array[Dictionary] = []
var font_texture: Texture2D
var last_error: String = ""
var _cursor: Vector2 = TEXT_ORIGIN
var _code_index: int = 0
var _appear_remaining: int = 19
var _frame_rect: Rect2 = Rect2(120, 26, 16, 5)
var _elapsed: float = 0.0
var _advance_requested: bool = false
var _wait_ticks: int = 0

func _init() -> void:
	visible = false
	z_index = BITMAP_LAYER_Z
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func atlas_cell(code: int) -> int:
	if (code >= 0x30 and code <= 0x39) or (code >= 0x41 and code <= 0x5a):
		return code
	# DrawChar raw codes; gfx/font.asm:29-35,63-67 (English branch).
	return int({0: 32, 0x3f: 35, 0x5c: 46, 0x5f: 44, 0x97: 96}.get(code, -1))

func open_grey_fox() -> bool:
	last_error = ""
	if not FileAccess.file_exists(RomProvenance.canonical_path(DATA_FILE)) or not FileAccess.file_exists(FONT_PATH):
		last_error = "Execute python3 -m tools.extractors.extract_grey_fox_dialogue"
		return false
	var data: Dictionary = RomProvenance.load_canonical_json(DATA_FILE)
	if data.is_empty():
		last_error = "Invalid or non-canonical private dialogue data"
		return false
	if data.get("schema") != "msx-english-dialogue-1" or data.get("text_id") != 59 or data.get("box_type") != 0x11:
		last_error = "Expected English text 59, box 0x11"
		return false
	if FileAccess.get_sha256(FONT_PATH) != data.get("font_sha256", ""):
		last_error = "Font changed; re-extract Grey Fox dialogue and font"
		return false
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(FONT_PATH))
	if img == null or img.get_size() != Vector2i(128, 64):
		last_error = "Invalid MSX font atlas"
		return false
	if not data.get("pages") is Array:
		last_error = "Missing pages"
		return false
	if not open_pages(data["pages"], ImageTexture.create_from_image(img)):
		last_error = "Invalid English pages or dialogue already open"
		return false
	return true

func open_pages(message_pages: Array, font: Texture2D) -> bool:
	if is_active or message_pages.is_empty():
		return false
	# Reject malformed data and overflow rather than silently repaginating it.
	for page: Variant in message_pages:
		if not page is Array:
			return false
		var cursor: Vector2 = TEXT_ORIGIN
		for value: Variant in page:
			if not (value is int or value is float) or float(value) != float(int(value)):
				return false
			var code: int = int(value)
			if code == 0xfe:
				cursor = Vector2(TEXT_ORIGIN.x, cursor.y + 12)
				continue
			if atlas_cell(code) < 0:
				return false
			if cursor.x > 196:
				cursor = Vector2(TEXT_ORIGIN.x, cursor.y + 12)
			if cursor.y > 36:
				return false
			cursor.x += 4 if code == 0x97 else 8
	pages = message_pages.duplicate(true)
	font_texture = font
	page_index = -1
	tick_counter = Engine.get_physics_frames() & 0xff
	_appear_remaining = 19
	_frame_rect = Rect2(120, 26, 16, 5)
	_elapsed = 0.0
	_advance_requested = false
	glyphs.clear()
	state = State.INIT
	is_active = true
	visible = true
	queue_redraw()
	return true

func handle_input(event: InputEvent) -> void:
	# ControlsTrigger / FKeysTrigger, not held keys. Banks0123.asm:7952-7968,8150-8156.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_M, KEY_N] and state in [State.PRINT, State.WAIT]:
			_advance_requested = true

func step_tick(delta: float) -> void:
	_elapsed += delta
	while is_active and _elapsed + 0.0000001 >= 1.0 / 60.0:
		_elapsed -= 1.0 / 60.0
		tick_counter = (tick_counter + 1) & 0xff
		_step()
	queue_redraw()

func _step() -> void:
	match state:
		State.INIT:
			state = State.APPEAR
		State.APPEAR:
			# logic/textboxappear.asm:10-62: predecrement, 18 growing rectangles.
			_appear_remaining -= 1
			if _appear_remaining == 0:
				state = State.DECODE
			else:
				_frame_rect.position -= Vector2(4, 1)
				_frame_rect.size += Vector2(8, 2)
		State.DECODE:
			page_index += 1
			if page_index >= pages.size():
				state = State.END
			else:
				_code_index = 0
				_cursor = TEXT_ORIGIN
				_wait_ticks = 0
				state = State.PRINT
		State.PRINT, State.WAIT:
			if _advance_requested:
				# SkipText discards the rest of the current page; it does not fill it.
				# Banks0123.asm:8130-8136,8192-8198.
				glyphs.clear()
				state = State.DECODE
			elif state == State.PRINT and (tick_counter & 3) == 0:
				_print_one()
			elif state == State.WAIT:
				_wait_ticks += 1
		State.END:
			close()
	_advance_requested = false

func _print_one() -> void:
	var page: Array = pages[page_index]
	while _code_index < page.size():
		var code: int = int(page[_code_index])
		_code_index += 1
		if code == 0xfe:
			_cursor = Vector2(TEXT_ORIGIN.x, _cursor.y + 12)
			continue
		# Banks0123.asm:8010-8033,8113-8124: wrap by pixels; apostrophe advances 4.
		if _cursor.x > 196:
			_cursor = Vector2(TEXT_ORIGIN.x, _cursor.y + 12)
		glyphs.append({"code": code, "position": _cursor})
		_cursor.x += 4 if code == 0x97 else 8
		return
	state = State.WAIT

## DrawEnterIcon runs from the first TW_Wait tick after TW_TextEnd, only while another
## page is pending; the final page waits without it. Banks0123.asm:8102-8107,8179-8185,8207-8218.
func prompt_active() -> bool:
	return state == State.WAIT and _wait_ticks > 0 and page_index < pages.size() - 1

func prompt_visible() -> bool:
	return prompt_active() and (tick_counter & 16) != 0

func close() -> void:
	var was_active: bool = is_active
	is_active = false
	visible = false
	state = State.CLOSED
	_advance_requested = false
	glyphs.clear()
	queue_redraw()
	if was_active:
		closed.emit()

func _draw() -> void:
	if not is_active or state == State.INIT or (state == State.APPEAR and _appear_remaining == 19):
		return
	# DrawRect at Banks0123.asm:4148-4170, palette index 14 (white).
	draw_rect(_frame_rect, Color.WHITE)
	draw_rect(_frame_rect.grow(-1), Color.BLACK)
	for glyph: Dictionary in glyphs:
		_draw_glyph(int(glyph["code"]), glyph["position"])
	if prompt_visible():
		_draw_glyph(0x3f, PROMPT_ORIGIN)
	elif prompt_active():
		# DrawChar with C=0 copies the blank page-1 cell over (196,36), erasing any
		# glyph printed there. Banks0123.asm:4726-4744,8210-8211.
		draw_rect(Rect2(PROMPT_ORIGIN, Vector2(8, 8)), Color.BLACK)

func _draw_glyph(code: int, at: Vector2) -> void:
	if font_texture == null:
		return
	var cell: int = atlas_cell(code)
	var src: Rect2 = Rect2((cell % 16) * 8, (cell / 16) * 8, 8, 8)
	# Opaque 8x8 copy, including spaces and the overlap after a narrow apostrophe.
	draw_rect(Rect2(at, Vector2(8, 8)), Color.BLACK)
	draw_texture_rect_region(font_texture, Rect2(at, Vector2(8, 8)), src)
