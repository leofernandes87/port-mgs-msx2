class_name ItemBox
extends Node2D

## Caixa de item coletável do Metal Gear MSX2 RC750 (Etapa 9).
## Posições e identidades autênticas revertidas de data/itemsinrooms.asm.

static var collected_boxes: Dictionary = {}

var item_id: String = ""
var room_id: int = 0
var box_unique_id: String = ""
var collected: bool = false

func _ready() -> void:
	z_index = 5
	box_unique_id = "%d_%s_%d_%d" % [room_id, item_id, int(position.x), int(position.y)]
	if collected_boxes.has(box_unique_id):
		collected = true

func step_tick(player_pos: Vector2, inventory: InventoryManager) -> bool:
	if collected:
		return false

	var dist: float = position.distance_to(player_pos)
	if dist <= 12.0:
		if inventory.collect_item(item_id):
			collected = true
			collected_boxes[box_unique_id] = true
			queue_redraw()
			return true

	return false

func _draw() -> void:
	if collected:
		return

	# Caixa militar clássica de suprimentos do Metal Gear (12x12 pixels)
	var box_rect := Rect2(-6, -6, 12, 12)
	var box_color := Color("889098") # Cinza metálico claro
	var border_color := Color("283038") # Borda escura
	var strap_color := Color("404850") # Cinta escura central

	draw_rect(box_rect, box_color)
	draw_rect(box_rect, border_color, false, 1.0)
	
	# Cinta horizontal
	draw_rect(Rect2(-6, -1, 12, 2), strap_color)
	
	# Letra / Identificador sutil
	if item_id.begins_with("CARD"):
		# Desenho do cartão em miniatura
		draw_rect(Rect2(-2, -4, 4, 3), Color.WHITE)
		draw_rect(Rect2(-1, -3, 2, 1), Color.RED)
	elif item_id == InventoryManager.ITEM_RATION:
		# Cruz médica vermelha na ração
		draw_rect(Rect2(-3, -4, 6, 2), Color("d02020"))
		draw_rect(Rect2(-1, -6, 2, 6), Color("d02020"))
	else:
		# Ícone de suprimento
		draw_rect(Rect2(-2, -4, 4, 2), Color.YELLOW)
