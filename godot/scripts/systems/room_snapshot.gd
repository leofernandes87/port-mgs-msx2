class_name RoomSnapshot
extends RefCounted
## Diagnostic contract; no game logic or implicit protected-resource import.

const WIDTH: int = 256
const HEIGHT: int = 192
const MAX_FILE_BYTES: int = 2 * 1024 * 1024
var room_id: int = -1
var pixels: PackedByteArray = PackedByteArray()
var collision: PackedByteArray = PackedByteArray()
var colors: PackedColorArray = PackedColorArray()
var source: String = ""
var error_message: String = ""
var loaded: bool = false

func _reset() -> void:
	loaded = false
	room_id = -1
	pixels.clear()
	collision.clear()
	colors.clear()
	source = ""
	error_message = ""

func _fail(message: String) -> Error:
	error_message = message
	return ERR_INVALID_DATA

func load_path(path: String) -> Error:
	_reset()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("Não foi possível abrir o arquivo.")
	if file.get_length() > MAX_FILE_BYTES:
		return _fail("Arquivo excede o limite de 2 MiB.")
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return _fail("JSON inválido; selecione um snapshot de sala.")
	return decode(parser.data as Dictionary)

func _integer_in(value: Variant, low: int, high: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number: float = float(value)
	return is_finite(number) and number == floor(number) and number >= low and number <= high

func decode(data: Dictionary) -> Error:
	_reset()
	if data.get("format_version") != "1.0.0" or data.get("width") != WIDTH or data.get("height") != HEIGHT:
		return _fail("Versão ou dimensões de snapshot incompatíveis.")
	if not _integer_in(data.get("room_id"), 0, 250):
		return _fail("ID de sala inválido.")
	if not data.get("pixels") is Array or not data.get("collision") is Array or not data.get("palette_rgb") is Array:
		return _fail("Pixels, paleta ou colisão ausentes.")
	var raw_pixels: Array = data["pixels"]
	var raw_collision: Array = data["collision"]
	var palette: Array = data["palette_rgb"]
	if raw_pixels.size() != WIDTH * HEIGHT or raw_collision.size() != 768 or palette.size() != 18:
		return _fail("Quantidade de pixels, cores ou células incorreta.")
	for pixel: Variant in raw_pixels:
		if not _integer_in(pixel, 0, 17):
			return _fail("Índice de paleta inválido.")
	for flag: Variant in raw_collision:
		if not _integer_in(flag, 0, 1):
			return _fail("Indicador de colisão inválido.")
	for row: Variant in palette:
		if not row is Array or (row as Array).size() != 3:
			return _fail("Cor RGB inválida.")
		for channel: Variant in row:
			if not _integer_in(channel, 0, 255):
				return _fail("Canal RGB fora da faixa.")
	if not data.get("source") is String or not data.get("input_sha256") is String:
		return _fail("Proveniência ausente.")
	var hash_pattern: RegEx = RegEx.new()
	hash_pattern.compile("^[0-9a-f]{64}$")
	if hash_pattern.search(data["input_sha256"]) == null:
		return _fail("Hash de origem inválido.")
	room_id = int(data["room_id"])
	pixels = PackedByteArray(raw_pixels)
	collision = PackedByteArray(raw_collision)
	for row: Array in palette:
		colors.append(Color8(int(row[0]), int(row[1]), int(row[2])))
	source = data["source"]
	loaded = true
	return OK

func make_image() -> Image:
	if not loaded:
		return null
	var image: Image = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGB8)
	for y: int in range(HEIGHT):
		for x: int in range(WIDTH):
			image.set_pixel(x, y, colors[pixels[y * WIDTH + x]])
	return image
