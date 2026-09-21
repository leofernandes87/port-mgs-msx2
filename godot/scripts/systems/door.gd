class_name RoomDoor
extends Node2D

## Porta interativa com trancas por cartão autêntica do Metal Gear MSX2 RC750.
## Lógica revertida de logic/doors/opendoor.asm, enterdoor.asm e data/doors.asm.

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
var is_entry_disabled: bool = false
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

# Tabela canônica DoorOpenEnterDat da ROM (external/MetalGear/data/doors.asm:15-35)
# Cada entrada contém as offsets e dimensões dos retângulos de abertura e entrada:
# open_oy, open_h, open_ox, open_w, enter_oy, enter_h, enter_ox, enter_w
const DOOR_OPEN_ENTER_DAT = {
	1: {"open_oy": 24.0, "open_h": 16.0, "open_ox": 0.0, "open_w": 32.0, "enter_oy": 12.0, "enter_h": 20.0, "enter_ox": 0.0, "enter_w": 32.0},  # Norte
	2: {"open_oy": -8.0, "open_h": 16.0, "open_ox": 0.0, "open_w": 32.0, "enter_oy": -4.0, "enter_h": 16.0, "enter_ox": 0.0, "enter_w": 32.0},  # Sul
	3: {"open_oy": 16.0, "open_h": 32.0, "open_ox": 0.0, "open_w": 20.0, "enter_oy": 24.0, "enter_h": 36.0, "enter_ox": -8.0, "enter_w": 20.0}, # Oeste
	4: {"open_oy": 16.0, "open_h": 32.0, "open_ox": -8.0, "open_w": 20.0, "enter_oy": 24.0, "enter_h": 36.0, "enter_ox": -4.0, "enter_w": 24.0}, # Leste (traseira caminhão)
	5: {"open_oy": 24.0, "open_h": 16.0, "open_ox": 0.0, "open_w": 32.0, "enter_oy": 12.0, "enter_h": 20.0, "enter_ox": 0.0, "enter_w": 32.0},  # Elevador
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

# Tiles ocupados na grade 32x24 quando a porta está fechada (colisão sólida 1)
var collision_tile_indices: Array[int] = []
# Tiles do vão de passagem desobstruídos quando a porta está aberta (colisão livre 0)
var clearance_tile_indices: Array[int] = []

func _ready() -> void:
	z_index = 6
	if is_lorry:
		is_open = true
	_calculate_collision_tiles()

func _calculate_collision_tiles() -> void:
	collision_tile_indices.clear()
	clearance_tile_indices.clear()

	var center_tx: int = int(position.x) / 8
	var center_ty: int = int(position.y) / 8

	match orientation:
		DoorOrientation.NORTH:
			# Bloqueio: soleira inferior da porta (4 tiles de largura)
			var row_y: int = center_ty + 3
			for offset_x: int in range(4):
				var tx: int = center_tx + offset_x
				if tx >= 0 and tx < 32 and row_y >= 0 and row_y < 24:
					collision_tile_indices.append(row_y * 32 + tx)
			# Desobstrução limpa quando aberta: todo o vão 4x4
			for offset_y: int in range(4):
				var ty: int = center_ty + offset_y
				for offset_x: int in range(4):
					var tx: int = center_tx + offset_x
					if tx >= 0 and tx < 32 and ty >= 0 and ty < 24:
						clearance_tile_indices.append(ty * 32 + tx)

		DoorOrientation.SOUTH:
			# Bloqueio: soleira sul
			var row_y: int = center_ty
			for offset_x: int in range(4):
				var tx: int = center_tx + offset_x
				if tx >= 0 and tx < 32 and row_y >= 0 and row_y < 24:
					collision_tile_indices.append(row_y * 32 + tx)
			# Desobstrução limpa quando aberta
			for offset_y: int in range(-1, 2):
				var ty: int = center_ty + offset_y
				for offset_x: int in range(4):
					var tx: int = center_tx + offset_x
					if tx >= 0 and tx < 32 and ty >= 0 and ty < 24:
						clearance_tile_indices.append(ty * 32 + tx)

		DoorOrientation.WEST:
			# Parede lateral oeste (ex: Door 128 na Sala 32):
			# Vão de passagem no chão: Y de position.y + 24 a position.y + 56 (ty = center_ty + 3 a center_ty + 6)
			# e colunas de passagem em torno de position.x (tx = center_tx - 1 a center_tx).
			for offset_y: int in range(3, 7):
				var ty: int = center_ty + offset_y
				for offset_x: int in range(-1, 1):
					var tx: int = center_tx + offset_x
					if tx >= 0 and tx < 32 and ty >= 0 and ty < 24:
						clearance_tile_indices.append(ty * 32 + tx)
			# Bloqueio quando fechada: soleira da porta
			for offset_y: int in range(3, 7):
				var ty: int = center_ty + offset_y
				var tx: int = center_tx
				if tx >= 0 and tx < 32 and ty >= 0 and ty < 24:
					collision_tile_indices.append(ty * 32 + tx)

		DoorOrientation.EAST:
			# Parede lateral leste (ex: Door 128 na Sala 153):
			# Vão de passagem no chão: Y de position.y + 24 a position.y + 56 (ty = center_ty + 3 a center_ty + 6)
			# e colunas de passagem a partir de position.x (tx = center_tx a center_tx + 1).
			for offset_y: int in range(3, 7):
				var ty: int = center_ty + offset_y
				for offset_x: int in range(0, 2):
					var tx: int = center_tx + offset_x
					if tx >= 0 and tx < 32 and ty >= 0 and ty < 24:
						clearance_tile_indices.append(ty * 32 + tx)
			# Bloqueio quando fechada: soleira da porta
			for offset_y: int in range(3, 7):
				var ty: int = center_ty + offset_y
				var tx: int = center_tx
				if tx >= 0 and tx < 32 and ty >= 0 and ty < 24:
					collision_tile_indices.append(ty * 32 + tx)

		DoorOrientation.LORRY_ENTER:
			# Traseira de caminhão (ex: Sala 5): desobstrui o vão de entrada
			for offset_y: int in range(1, 4):
				var ty: int = center_ty + offset_y
				for offset_x: int in range(1, 3):
					var tx: int = center_tx + offset_x
					if tx >= 0 and tx < 32 and ty >= 0 and ty < 24:
						clearance_tile_indices.append(ty * 32 + tx)

		DoorOrientation.LORRY_EXIT:
			# Saída de dentro do caminhão (ex: Sala 128, 127):
			# Remove as colunas de parede estática na borda direita
			for ty: int in range(11, 15):
				for tx: int in range(25, 32):
					clearance_tile_indices.append(ty * 32 + tx)

func inject_collision(collision_grid: Array) -> void:
	if collision_grid.is_empty():
		return
	if collision_tile_indices.is_empty() and clearance_tile_indices.is_empty():
		_calculate_collision_tiles()

	if is_open:
		# Quando a porta está ABERTA:
		# 1. Libera os tiles da soleira
		for idx: int in collision_tile_indices:
			if idx >= 0 and idx < collision_grid.size():
				collision_grid[idx] = 0
		# 2. Desobstrui todos os tiles do vão (eliminando blocos flutuantes e paredes no caminho)
		for idx: int in clearance_tile_indices:
			if idx >= 0 and idx < collision_grid.size():
				collision_grid[idx] = 0
	else:
		# Quando a porta está FECHADA: bloqueia fisicamente com 1
		for idx: int in collision_tile_indices:
			if idx >= 0 and idx < collision_grid.size():
				collision_grid[idx] = 1

## Retorna a caixa retangular onde Snake entra na porta aberta
func get_enter_trigger_rect() -> Rect2:
	if trigger_rect.size != Vector2.ZERO:
		return trigger_rect

	# Se for saída da traseira de caminhão móvel
	if orientation == DoorOrientation.LORRY_EXIT or (is_lorry and render_type_id == 4):
		return Rect2(204.0, 88.0, 36.0, 36.0)

	match orientation:
		DoorOrientation.NORTH:
			return Rect2(position.x + 4.0, position.y + 4.0, 24.0, 28.0)
		DoorOrientation.LORRY_ENTER:
			return Rect2(position.x + 4.0, position.y + 8.0, 24.0, 24.0)
		DoorOrientation.SOUTH:
			return Rect2(position.x + 4.0, position.y - 4.0, 24.0, 16.0)
		DoorOrientation.WEST:
			return Rect2(position.x - 16.0, position.y - 8.0, 28.0, 64.0)
		DoorOrientation.EAST:
			return Rect2(position.x - 4.0, position.y - 8.0, 28.0, 64.0)
		_:
			return Rect2(position.x, position.y, 32.0, 32.0)

## Retorna a caixa retangular onde Snake tenta abrir a porta fechada com cartão
func get_open_trigger_rect() -> Rect2:
	match orientation:
		DoorOrientation.NORTH:
			return Rect2(position.x, position.y + 20.0, 32.0, 20.0)
		DoorOrientation.SOUTH:
			return Rect2(position.x, position.y - 12.0, 32.0, 16.0)
		DoorOrientation.WEST:
			return Rect2(position.x - 8.0, position.y - 8.0, 28.0, 64.0)
		DoorOrientation.EAST:
			return Rect2(position.x - 20.0, position.y - 8.0, 28.0, 64.0)
		_:
			return Rect2(position.x, position.y, 32.0, 32.0)

## Verifica interação do jogador com a porta (logic/doors/opendoor.asm e enterdoor.asm)
## Retorna o ID da sala de destino se o jogador atravessar a porta aberta, ou -1 caso contrário.
func check_interaction(player: PlayerController, inventory: InventoryManager, collision_grid: Array) -> int:
	if player == null:
		return -1

	# Portas marcadas como apenas de retorno/spawn (fake doors de caminhão móvel da ROM)
	if is_entry_disabled:
		return -1

	# Lógica para portas de caminhão manuais com trigger_rect customizado
	if is_lorry and trigger_rect.size != Vector2.ZERO:
		if destination_room == -1:
			return -1
		if trigger_rect.has_point(player.position):
			var expected_dir: int = -1
			if orientation == DoorOrientation.LORRY_ENTER:
				expected_dir = PlayerController.Direction.UP
			elif orientation == DoorOrientation.LORRY_EXIT:
				expected_dir = PlayerController.Direction.RIGHT

			if expected_dir == -1 or player.current_direction == expected_dir:
				print("LORRY_DOOR_ENTER: Snake usou porta de caminhão %d para sala %d!" % [door_id, destination_room])
				return destination_room
		return -1

	var expected_dir: PlayerController.Direction = PlayerController.Direction.UP
	match orientation:
		DoorOrientation.NORTH, DoorOrientation.LORRY_ENTER:
			expected_dir = PlayerController.Direction.UP
		DoorOrientation.SOUTH:
			expected_dir = PlayerController.Direction.DOWN
		DoorOrientation.WEST:
			expected_dir = PlayerController.Direction.LEFT
		DoorOrientation.EAST, DoorOrientation.LORRY_EXIT:
			expected_dir = PlayerController.Direction.RIGHT

	# 1. Se a porta estiver fechada, verificar se Snake tenta abrir
	# Lógica fiel à ROM (logic/doors/opendoor.asm): apenas o retângulo canônico é usado,
	# sem fallback de distância que causaria abertura inadvertida de portas vizinhas.
	if not is_open:
		var open_box: Rect2 = get_open_trigger_rect()
		var in_open_zone: bool = open_box.has_point(player.position)
		if in_open_zone and player.current_direction == expected_dir:
			if not required_card.is_empty():
				# Fiel à ROM (CardLevelReg): basta *possuir* o cartão — não precisa selecioná-lo.
				if inventory.has_item(required_card):
					print("DOOR_CARD_OK: Porta %d aberta com %s!" % [door_id, required_card])
					open_door(collision_grid)
				else:
					print("DOOR_CARD_FAIL: Porta %d requer %s (não possui)." % [door_id, required_card])
			elif open_rule_id in [1, 10, 11]:
				open_door(collision_grid)
		return -1

	# 2. Se a porta já estiver aberta, verificar se Snake entrou no vão físico
	if is_open and destination_room != -1:
		var enter_box: Rect2 = get_enter_trigger_rect()
		if enter_box.has_point(player.position) and player.current_direction == expected_dir:
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
	# Toda a arte visual das salas, passagens e caminhões provém integralmente dos
	# snapshots de metatiles originais da ROM MSX2.
	# RoomDoor atua de forma limpa como entidade física de colisão e trigger de transição,
	# sem sobrepor caixas ou desenhos procedurais artificiais sobre o cenário autêntico.
	return
