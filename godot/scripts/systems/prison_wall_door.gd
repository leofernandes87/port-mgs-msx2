class_name PrisonWallDoor
extends RoomDoor
## Doors 103 (Snake) and 12 (Grey Fox south wall), with independent life.
## data/doors.asm:26-29,427,724-728,992-1031; drawdoors.asm:262-319.

var wall_texture: Texture2D
var closed_collision: Array = []
var background_collision: Dictionary = {}
var tiles_w: int = 0
var tiles_h: int = 0

func _ready() -> void:
	z_index = 6
	if wall_texture == null:
		var data: Dictionary = RomProvenance.load_canonical_json("prison-walls/wall-%d.json" % render_type_id)
		if not data.is_empty():
			configure_visual(data)
		if wall_texture == null:
			push_warning("Parede da prisão ausente/inválida: execute tools/extractors/extract_prison_wall.py")

func configure_visual(data: Dictionary) -> bool:
	var w: int = int(data.get("width", 0))
	var h: int = int(data.get("height", 0))
	var expected: Vector2i = Vector2i(24, 104) if render_type_id == 14 else Vector2i(16, 96)
	if render_type_id in [12, 13]:
		expected = Vector2i(32, 8)
	if Vector2i(w, h) != expected:
		return false
	var pixels: Array = data.get("pixels", [])
	var palette: Array = data.get("palette_rgb", [])
	var flags: Array = data.get("collision", [])
	if pixels.size() != w * h or flags.size() != w * h / 64 or palette.is_empty():
		return false
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for i: int in range(pixels.size()):
		var index: int = int(pixels[i])
		if index < 0 or index >= palette.size():
			return false
		var rgb: Array = palette[index]
		if rgb.size() != 3:
			return false
		# TIMP skips color index zero (Banks0123.asm:4806-4809).
		img.set_pixel(i % w, i / w, Color8(int(rgb[0]), int(rgb[1]), int(rgb[2]), 0 if index == 0 else 255))
	for flag: Variant in flags:
		if flag != 0 and flag != 1:
			return false
	tiles_w = w / 8
	tiles_h = h / 8
	closed_collision = flags.duplicate()
	wall_texture = ImageTexture.create_from_image(img)
	queue_redraw()
	return true

func inject_collision(collision_grid: Array) -> void:
	# Restore the saved background, not a rectangle of zeroes:
	# erasedoor.asm:25,365-367,399-414.
	for y: int in range(tiles_h):
		for x: int in range(tiles_w):
			var index: int = (int(position.y) / 8 + y) * 32 + int(position.x) / 8 + x
			if index < 0 or index >= collision_grid.size():
				continue
			if not background_collision.has(index):
				background_collision[index] = collision_grid[index]
			collision_grid[index] = background_collision[index] if is_open else closed_collision[y * tiles_w + x]

func get_open_trigger_rect() -> Rect2:
	# DoorOpenEnterDat: data/doors.asm:26-29.
	if render_type_id == 12:
		return Rect2(position + Vector2(8, 32), Vector2(16, 8))
	if render_type_id == 13:
		return Rect2(position + Vector2(8, -10), Vector2(16, 18))
	return Rect2(position + Vector2(0 if render_type_id == 14 else -10, 32), Vector2(26, 16))

func get_enter_trigger_rect() -> Rect2:
	if render_type_id == 12:
		return Rect2(position + Vector2(0, 16), Vector2(32, 16))
	if render_type_id == 13:
		return Rect2(position, Vector2(32, 8))
	return Rect2(position + Vector2(8 if render_type_id == 14 else 0, 32), Vector2(8, 32))

func check_interaction(player: PlayerController, _inventory: InventoryManager, _grid: Array) -> int:
	# ChkEnterDoor does not require facing once open: enterdoor.asm:64-88.
	if is_open and get_enter_trigger_rect().has_point(player.position):
		return destination_room
	return -1

func _draw() -> void:
	if not is_open and wall_texture != null:
		draw_texture(wall_texture, Vector2.ZERO)
