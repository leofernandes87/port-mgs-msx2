class_name RoomManager
extends RefCounted

## Gerenciador de conexões entre salas e transições fiéis ao MSX2 RC750 (Etapa 6).
## Lógica revertida de Banks0123.asm (GetNextRoomNum, ChkExitRoom) e logic/nextroom.asm (SetRoomEntryXY).

const NO_ROOM: int = 255

# Limites exatos de disparo de saída da tela (ChkExitRoom em Banks0123.asm:9418)
const EXIT_LEFT_X: float = 12.0
const EXIT_RIGHT_X: float = 244.0
const EXIT_UP_Y: float = 16.0
const EXIT_DOWN_Y: float = 186.0

# Coordenadas exatas de reentrada na nova sala (EntryRoomXY em logic/nextroom.asm:362)
const ENTRY_Y_FROM_UP: float = 184.0
const ENTRY_Y_FROM_DOWN: float = 18.0
const ENTRY_X_FROM_LEFT: float = 242.0
const ENTRY_X_FROM_RIGHT: float = 12.0

# Tabela completa de conexões (156 entradas extraídas de data/roomsconnections.asm)
const CONNECTIONS_TABLE: Array = [
	[  1, 121, 255,   4], # 0
	[  2,   0, 255,   5], # 1
	[  3,   1, 255,   6], # 2
	[255,   2, 255,   7], # 3
	[  5, 255,   0,   8], # 4
	[  6,   4,   1,   9], # 5
	[  7,   5,   2,  10], # 6
	[255,   6,   3,  11], # 7
	[  9, 255,   4,  12], # 8
	[ 10,   8,   5,  13], # 9
	[ 11,   9,   6,  14], # 10
	[ 64,  10,   7,  15], # 11
	[ 13, 255,   8, 255], # 12
	[ 14,  12,   9, 255], # 13
	[ 15,  13,  10, 255], # 14
	[255,  14,  11, 255], # 15
	[ 17, 255, 255,  20], # 16
	[ 18,  16, 255, 255], # 17
	[ 19,  17, 255, 255], # 18
	[255,  18, 255,  21], # 19
	[255, 255,  16,  22], # 20
	[255, 255,  19,  23], # 21
	[255, 255,  20,  24], # 22
	[255, 255,  21,  27], # 23
	[ 25, 255,  22, 255], # 24
	[ 26,  24, 255, 255], # 25
	[ 27,  25, 255, 255], # 26
	[255,  26,  23, 255], # 27
	[ 29, 255, 255,  32], # 28
	[ 30,  28, 255, 255], # 29
	[ 31,  29, 255, 255], # 30
	[255,  30, 255,  33], # 31
	[255, 255,  28,  34], # 32
	[255, 255,  31,  35], # 33
	[255, 255,  32,  36], # 34
	[255, 255,  33,  39], # 35
	[ 37, 255,  34, 255], # 36
	[ 38,  36, 255, 255], # 37
	[ 39,  37, 255, 255], # 38
	[255,  38,  35, 255], # 39
	[ 41, 255, 255,  44], # 40
	[ 42,  40, 255,  45], # 41
	[ 43,  41, 255,  46], # 42
	[255,  42, 255,  47], # 43
	[ 45, 255,  40,  48], # 44
	[ 46,  44,  41, 117], # 45
	[ 47,  45,  42, 255], # 46
	[255,  46,  43,  49], # 47
	[117, 255,  44,  50], # 48
	[255, 255,  47,  53], # 49
	[ 51, 255,  48, 255], # 50
	[ 52,  50, 117, 255], # 51
	[ 53,  51, 255, 255], # 52
	[255,  52,  49, 255], # 53
	[ 55, 255, 255,  57], # 54
	[ 56,  54, 255, 255], # 55
	[123,  55, 255, 255], # 56
	[255, 255,  54,  58], # 57
	[ 59, 255,  57,  61], # 58
	[ 60,  58, 255,  62], # 59
	[255,  59, 255,  63], # 60
	[ 62, 255,  58, 255], # 61
	[ 63,  61,  59, 255], # 62
	[255,  62,  60, 255], # 63
	[120,  11,  64,  64], # 64
	[ 66, 120,  65,  65], # 65
	[ 67,  65,  66,  66], # 66
	[ 68,  66,  67,  67], # 67
	[ 69,  67,  68,  68], # 68
	[ 73,  68,  69,  69], # 69
	[ 71, 255, 255,  73], # 70
	[ 72,  70, 255,  74], # 71
	[255,  71, 255,  75], # 72
	[ 74,  69,  70,  76], # 73
	[ 75,  73,  71,  77], # 74
	[102,  74,  72,  78], # 75
	[ 77, 255,  73, 255], # 76
	[ 78,  76,  74, 255], # 77
	[105,  77,  75, 255], # 78
	[ 80, 255, 255,  82], # 79
	[ 81,  79, 255,  83], # 80
	[255,  80, 255,  84], # 81
	[ 83, 255,  79,  85], # 82
	[ 84,  82,  80,  86], # 83
	[255,  83,  81,  87], # 84
	[ 86, 255,  82, 255], # 85
	[ 87,  85,  83, 255], # 86
	[255,  86,  84, 255], # 87
	[255, 255, 255,  91], # 88
	[ 90, 255, 255,  92], # 89
	[ 91,  89, 255, 255], # 90
	[255,  90,  88, 255], # 91
	[255, 255,  89, 255], # 92
	[ 94, 125, 255,  96], # 93
	[ 95,  93, 255,  97], # 94
	[255,  94, 255,  98], # 95
	[ 97, 255,  93,  99], # 96
	[ 98,  96,  94, 100], # 97
	[255,  97,  95, 101], # 98
	[100, 255,  96, 255], # 99
	[101,  99,  97, 255], # 100
	[255, 100,  98, 255], # 101
	[103,  75, 102, 102], # 102
	[208, 102, 103, 103], # 103
	[108, 210, 104, 104], # 104
	[106,  78, 255, 255], # 105
	[211, 105, 255, 255], # 106
	[110, 212, 108, 255], # 107
	[109, 104, 255, 107], # 108
	[255, 108, 255, 110], # 109
	[255, 107, 109, 255], # 110
	[112, 255, 255, 115], # 111
	[113, 111, 255, 255], # 112
	[114, 112, 255, 255], # 113
	[116, 113, 255, 255], # 114
	[255, 255, 111, 255], # 115
	[118, 114, 255, 255], # 116
	[255,  48,  45,  51], # 117
	[255, 116, 119, 255], # 118
	[255, 255, 255, 118], # 119
	[ 65,  64, 120, 120], # 120
	[  0, 255, 255, 255], # 121
	[255, 255, 255, 255], # 122
	[221,  56, 255, 255], # 123
	[125, 220, 255, 255], # 124
	[ 93, 124, 255, 255], # 125
	[209, 103, 208, 208], # 126
	[210, 208, 209, 209], # 127
	[104, 209, 210, 210], # 128
	[212, 106, 255, 255], # 129
	[107, 211, 255, 255], # 130
	[255, 255, 255, 255], # 131
	[255, 255, 255, 255], # 132
	[255, 255, 255, 255], # 133
	[255, 255, 255, 255], # 134
	[255, 255, 255, 255], # 135
	[255, 255, 255, 255], # 136
	[255, 255, 255, 255], # 137
	[124, 221, 255, 255], # 138
	[220, 123, 255, 255], # 139
	[221, 124, 255, 255], # 140
	[255, 255, 255, 255], # 141
	[225, 255, 255, 255], # 142
	[226, 224, 255, 255], # 143
	[227, 225, 255, 255], # 144
	[228, 226, 255, 255], # 145
	[242, 255, 255, 255], # 146
	[255, 241, 255, 255], # 147
	[244, 255, 255, 255], # 148
	[255, 243, 255, 255], # 149
	[246, 255, 255, 255], # 150
	[255, 245, 255, 255], # 151
	[255, 248, 255, 255], # 152
	[247, 249, 255, 255], # 153
	[248, 250, 255, 255], # 154
	[249, 255, 255, 255], # 155
]

var _snapshot_cache: Dictionary = {}
var _actors_cache: Dictionary = {}

## Consulta o ID da próxima sala com base na direção de saída (GetNextRoomNum em Banks0123.asm:889).
static func get_next_room(room_id: int, dir: PlayerController.Direction) -> int:
	# Conexões da Cela e Sala Adjacente de Prisão (Salas 211 e 212)
	if room_id == 211:
		if dir == PlayerController.Direction.LEFT:
			return 212
		return NO_ROOM
	elif room_id == 212:
		if dir == PlayerController.Direction.RIGHT:
			return 211
		return NO_ROOM

	var index: int = -1
	if room_id < 126:
		index = room_id
	elif room_id < 208:
		return NO_ROOM
	elif room_id < 228:
		index = room_id - 82
	elif room_id < 241:
		return NO_ROOM
	elif room_id <= 250:
		index = room_id - 95
	else:
		return NO_ROOM

	if index < 0 or index >= CONNECTIONS_TABLE.size():
		return NO_ROOM

	var conns: Array = CONNECTIONS_TABLE[index]
	match dir:
		PlayerController.Direction.UP:
			return int(conns[0])
		PlayerController.Direction.DOWN:
			return int(conns[1])
		PlayerController.Direction.LEFT:
			return int(conns[2])
		PlayerController.Direction.RIGHT:
			return int(conns[3])
		_:
			return NO_ROOM

## Verifica se a posição de Snake cruzou um dos 4 limites de tela (ChkExitRoom em Banks0123.asm:9418).
## Retorna a Direction de saída, ou 0 se ainda estiver dentro da sala.
static func check_room_exit(pos: Vector2) -> int:
	if pos.x < EXIT_LEFT_X:
		return PlayerController.Direction.LEFT
	elif pos.x >= EXIT_RIGHT_X:
		return PlayerController.Direction.RIGHT
	elif pos.y < EXIT_UP_Y:
		return PlayerController.Direction.UP
	elif pos.y >= EXIT_DOWN_Y:
		return PlayerController.Direction.DOWN
	return 0

## Calcula a posição exata de Snake na nova sala (SetRoomEntryXY / EntryRoomXY em logic/nextroom.asm:342).
static func get_entry_position(exit_dir: int, current_pos: Vector2) -> Vector2:
	match exit_dir:
		PlayerController.Direction.UP:
			return Vector2(current_pos.x, ENTRY_Y_FROM_UP)
		PlayerController.Direction.DOWN:
			return Vector2(current_pos.x, ENTRY_Y_FROM_DOWN)
		PlayerController.Direction.LEFT:
			return Vector2(ENTRY_X_FROM_LEFT, current_pos.y)
		PlayerController.Direction.RIGHT:
			return Vector2(ENTRY_X_FROM_RIGHT, current_pos.y)
		_:
			return current_pos

## Carrega um RoomSnapshot a partir dos caminhos locais validados.
func load_room_snapshot(room_id: int) -> RoomSnapshot:
	if _snapshot_cache.has(room_id):
		return _snapshot_cache[room_id] as RoomSnapshot

	var candidate_paths: Array[String] = [
		ProjectSettings.globalize_path("res://../data/extracted/stage5-batch/room-%03d.json" % room_id),
		ProjectSettings.globalize_path("res://../data/extracted/stage5-item-rooms/room-%03d.json" % room_id),
		ProjectSettings.globalize_path("res://../data/extracted/stage5-lorries/room-%03d.json" % room_id),
		ProjectSettings.globalize_path("res://../data/extracted/stage5-elevators/room-%03d.json" % room_id),
		ProjectSettings.globalize_path("res://../data/extracted/stage4c-validated/room-%03d.json" % room_id),
		ProjectSettings.globalize_path("res://../data/extracted/stage4b-validated/room-%03d.json" % room_id),
		ProjectSettings.globalize_path("res://../data/extracted/stage4-validated/room-%03d.json" % room_id)
	]

	for path: String in candidate_paths:
		if FileAccess.file_exists(path):
			var snap := RoomSnapshot.new()
			if snap.load_path(path) == OK:
				_snapshot_cache[room_id] = snap
				return snap

	# Salas de caminhão (126, 127, 128) compartilham o mesmo layout de VRAM/tiles (layout_1b780 / metatiles 5)
	if room_id in [126, 128]:
		var lorry_snap: RoomSnapshot = load_room_snapshot(127)
		if lorry_snap != null:
			var copy_snap := RoomSnapshot.new()
			copy_snap.room_id = room_id
			copy_snap.pixels = lorry_snap.pixels.duplicate()
			copy_snap.collision = lorry_snap.collision.duplicate()
			copy_snap.colors = lorry_snap.colors.duplicate()
			copy_snap.source = lorry_snap.source
			copy_snap.loaded = true
			_snapshot_cache[room_id] = copy_snap
			return copy_snap

	return null

## Carrega metadados de atores, itens e portas canônicas da sala a partir de stage5-batch, stage5-lorries ou stage5-elevators.
func load_room_actors(room_id: int) -> Dictionary:
	if _actors_cache.has(room_id):
		return _actors_cache[room_id] as Dictionary

	var candidate_paths: Array[String] = [
		ProjectSettings.globalize_path("res://../data/extracted/stage5-batch/room-%03d-actors.json" % room_id),
		ProjectSettings.globalize_path("res://../data/extracted/stage5-item-rooms/room-%03d-actors.json" % room_id),
		ProjectSettings.globalize_path("res://../data/extracted/stage5-lorries/room-%03d-actors.json" % room_id),
		ProjectSettings.globalize_path("res://../data/extracted/stage5-elevators/room-%03d-actors.json" % room_id)
	]
	for path: String in candidate_paths:
		if FileAccess.file_exists(path):
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			if file != null:
				var parser: JSON = JSON.new()
				if parser.parse(file.get_as_text()) == OK and parser.data is Dictionary:
					var data: Dictionary = parser.data as Dictionary
					_actors_cache[room_id] = data
					return data
	return {}
