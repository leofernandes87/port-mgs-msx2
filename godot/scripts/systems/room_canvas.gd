class_name RoomCanvas
extends Control

var snapshot: RoomSnapshot
var texture: ImageTexture
var show_collision: bool = false

func show_snapshot(value: RoomSnapshot) -> void:
	snapshot = value
	texture = ImageTexture.create_from_image(value.make_image()) if value.loaded else null
	queue_redraw()

func _draw() -> void:
	if texture == null:
		return
	var zoom: float = maxf(1.0, floorf(minf(size.x / 256.0, size.y / 192.0)))
	var origin: Vector2 = (size - Vector2(256, 192) * zoom) / 2.0
	draw_texture_rect(texture, Rect2(origin, Vector2(256, 192) * zoom), false)
	if show_collision:
		for index: int in range(768):
			if snapshot.collision[index] == 1:
				var cell: Vector2 = Vector2(index % 32, index / 32) * 8.0
				draw_rect(Rect2(origin + cell * zoom, Vector2(8, 8) * zoom), Color(1, 0.15, 0.1, 0.4))
