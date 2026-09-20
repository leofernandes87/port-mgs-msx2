class_name RoomDoor
extends Node2D

## Porta interativa com trancas por cartão autêntica do Metal Gear MSX2 RC750 (Etapa 9).
## Lógica revertida de logic/doors/opendoor.asm e data/doors.asm.

enum DoorOrientation {
	NORTH = 1,
	SOUTH = 2,
	WEST = 3,
	EAST = 4,
	LORRY_ENTER = 5,
	LORRY_EXIT = 6,
}

var door_id: int = 0
var room_id: int = 0
var render_type_id: int = 1
var open_rule_id: int = 1
var required_card: String = ""
var destination_room: int = -1
var entry_position: Vector2 = Vector2.ZERO
var destination_direction: int = -1
var orientation: DoorOrientation = DoorOrientation.NORTH
var is_open: bool = false
var is_lorry: bool = false
var trigger_rect: Rect2 = Rect2()

# Tabela canônica de posicionamento de Snake ao entrar/sair de portas (logic/nextroom.asm:457-480)
# Offset Y, Offset X, Direção (1: UP, 2: DOWN, 3: LEFT, 4: RIGHT)
const PLAYER_IN_DOOR_DAT = {
	1: {"offset_y": 40.0, "offset_x": 12.0, "direction": PlayerController.Direction.DOWN},  # Porta Norte (Parede Superior)
	2: {"offset_y": -8.0, "offset_x": 16.0, "direction": PlayerController.Direction.UP},    # Porta Sul (Parede Inferior)
	3: {"offset_y": 48.0, "offset_x": 16.0, "direction": PlayerController.Direction.RIGHT}, # Porta Oeste (Parede Esquerda)
	4: {"offset_y": 48.0, "offset_x": -10.0, "direction": PlayerController.Direction.LEFT}, # Porta Leste (Parede Direita)
	5: {"offset_y": 40.0, "offset_x": 12.0, "direction": PlayerController.Direction.DOWN},  # Elevador
	6: {"offset_y": 40.0, "offset_x": 12.0, "direction": PlayerController.Direction.DOWN},  # Elevador Saída
}

static func get_door_spawn(draw_xy: Vector2, render_type: int) -> Dictionary:
	var info: Dictionary = PLAYER_IN_DOOR_DAT.get(render_type, {
		"offset_y": 40.0, "offset_x": 12.0, "direction": PlayerController.Direction.DOWN
	})
	var spawn_pos := Vector2(draw_xy.x + float(info.offset_x), draw_xy.y + float(info.offset_y))
	var spawn_dir: int = int(info.direction)
	return {"pos": spawn_pos, "dir": spawn_dir}

static func get_card_for_rule(rule_id: int) -> String:
	match rule_id:
		2: return InventoryManager.ITEM_CARD1
		3: return InventoryManager.ITEM_CARD2
		4: return InventoryManager.ITEM_CARD3
		5: return InventoryManager.ITEM_CARD4
		6: return InventoryManager.ITEM_CARD5
		7: return InventoryManager.ITEM_CARD6
		8: return InventoryManager.ITEM_CARD7
		9: return InventoryManager.ITEM_CARD8
		_: return ""

# Tiles ocupados na grade 32x24 (onde a colisão é injetada/removida)
var collision_tile_indices: Array[int] = []

func _ready() -> void:
	z_index = 6
	if is_lorry:
		is_open = true
	_calculate_collision_tiles()

func _calculate_collision_tiles() -> void:
	collision_tile_indices.clear()
	if is_lorry:
		return
	var center_tx: int = int(position.x) / 8
	var center_ty: int = int(position.y) / 8

	# Portas normais cobrem 2 tiles (16 pixels) de largura ou altura
	match orientation:
		DoorOrientation.NORTH, DoorOrientation.SOUTH:
			var t1: int = center_ty * 32 + center_tx
			var t2: int = center_ty * 32 + (center_tx + 1)
			collision_tile_indices = [t1, t2]
		DoorOrientation.WEST, DoorOrientation.EAST:
			var t1: int = center_ty * 32 + center_tx
			var t2: int = (center_ty + 1) * 32 + center_tx
			collision_tile_indices = [t1, t2]

func inject_collision(collision_grid: Array) -> void:
	if is_lorry or collision_grid.is_empty():
		return
	for idx: int in collision_tile_indices:
		if idx >= 0 and idx < collision_grid.size():
			collision_grid[idx] = 0 if is_open else 1

## Verifica interação do jogador com a porta (logic/doors/opendoor.asm:125-135)
## Retorna o ID da sala de destino se o jogador atravessar a porta aberta, ou -1 caso contrário.
func check_interaction(player: PlayerController, inventory: InventoryManager, collision_grid: Array) -> int:
	if player == null:
		return -1

	# Lógica para portas de caminhão (lorries)
	if is_lorry:
		if destination_room == -1:
			return -1
		var in_zone: bool = false
		if trigger_rect.size != Vector2.ZERO:
			in_zone = trigger_rect.has_point(player.position)
		else:
			in_zone = position.distance_to(player.position) <= 12.0

		if in_zone:
			var expected_dir: int = -1
			if orientation == DoorOrientation.LORRY_ENTER:
				expected_dir = PlayerController.Direction.UP
			elif orientation == DoorOrientation.LORRY_EXIT:
				expected_dir = PlayerController.Direction.RIGHT

			if expected_dir == -1 or player.current_direction == expected_dir:
				print("LORRY_DOOR_ENTER: Snake usou porta de caminhão %d para sala %d!" % [door_id, destination_room])
				return destination_room
		return -1

	# Lógica padrão de portas normais de prédios
	var door_w: float = 16.0 if (orientation == DoorOrientation.NORTH or orientation == DoorOrientation.SOUTH) else 8.0
	var door_h: float = 8.0 if (orientation == DoorOrientation.NORTH or orientation == DoorOrientation.SOUTH) else 16.0
	var center_pos: Vector2 = position + Vector2(door_w / 2.0, door_h / 2.0)
	var dist: float = center_pos.distance_to(player.position)

	# 1. Se a porta estiver fechada, verificar se Snake tenta abrir
	if not is_open:
		if dist <= 24.0:
			var expected_dir: PlayerController.Direction
			match orientation:
				DoorOrientation.NORTH: expected_dir = PlayerController.Direction.UP
				DoorOrientation.SOUTH: expected_dir = PlayerController.Direction.DOWN
				DoorOrientation.WEST:  expected_dir = PlayerController.Direction.LEFT
				DoorOrientation.EAST:  expected_dir = PlayerController.Direction.RIGHT

			if player.current_direction == expected_dir:
				if required_card.is_empty() or inventory.get_selected_item() == required_card:
					open_door(collision_grid)
				else:
					# Porta trancada
					pass
		return -1

	# 2. Se a porta já estiver aberta, verificar se Snake entrou no vão
	if is_open and destination_room != -1:
		if dist <= 14.0:
			print("DOOR_ENTER: Snake entrou na porta %d rumo à sala %d!" % [door_id, destination_room])
			return destination_room

	return -1

func open_door(collision_grid: Array) -> void:
	if is_open:
		return
	is_open = true
	inject_collision(collision_grid)
	queue_redraw()
	print("DOOR_OPENED: Porta %d aberta com sucesso!" % door_id)

func close_door(collision_grid: Array) -> void:
	if not is_open:
		return
	is_open = false
	inject_collision(collision_grid)
	queue_redraw()

func _draw() -> void:
	if is_lorry:
		return

	var door_w: float = 16.0 if (orientation == DoorOrientation.NORTH or orientation == DoorOrientation.SOUTH) else 8.0
	var door_h: float = 8.0 if (orientation == DoorOrientation.NORTH or orientation == DoorOrientation.SOUTH) else 16.0
	var door_rect := Rect2(0, 0, door_w, door_h)

	if is_open:
		# Vão aberto escuro da passagem
		draw_rect(door_rect, Color("101418"))
		draw_rect(door_rect, Color("202830"), false, 1.0)
		return

	# Porta metálica fechada clássica do MSX2
	var panel_color := Color("586878")
	var border_color := Color("283038")
	var detail_color := Color("788898")

	draw_rect(door_rect, panel_color)
	draw_rect(door_rect, border_color, false, 1.0)

	# Ranhuras metálicas ou leitor de cartão
	if door_w >= 16.0:
		draw_rect(Rect2(7, 1, 2, 6), border_color) # Divisão central
		if not required_card.is_empty():
			draw_rect(Rect2(11, 2, 3, 3), Color("c03030")) # Leitor de cartão vermelho
			draw_rect(Rect2(12, 3, 1, 1), Color.YELLOW)
	else:
		draw_rect(Rect2(1, 7, 6, 2), border_color)
		if not required_card.is_empty():
			draw_rect(Rect2(2, 11, 3, 3), Color("c03030"))
