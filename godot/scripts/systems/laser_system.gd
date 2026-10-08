class_name LaserSystem
extends Node2D

## Sistema de Feixes Laser Infravermelhos autêntico do Metal Gear MSX2 RC750 (ID_LASER = 35).
## Lógica revertida de:
## - data/laserconfig.asm (LasersRoom24, LasersRoom25, LasersRoom72, idxLaserOnOff)
## - logic/laserbeams.asm (ChkTouchLaser, RemoveLaserBeans)
## - logic/drawlaserbeams.asm (DrawLaserBeams, DrawMovingLasers)
## - Banks0123.asm:5653-5847 (InitLaserRoom, DrawMovingLasers)

enum LaserOrientation {
	VERTICAL = 0,
	HORIZONTAL = 1
}

## Configurações canônicas de feixes por sala (data/laserconfig.asm)
## Formato: status, Y, X, length, orientation (0=Vertical, 1=Horizontal)
const LASERS_ROOM_24: Array[Dictionary] = [
	{"status": 1, "y": 16.0, "x": 111.0, "length": 48.0, "orientation": LaserOrientation.VERTICAL},
	{"status": 1, "y": 24.0, "x": 175.0, "length": 40.0, "orientation": LaserOrientation.VERTICAL},
	{"status": 1, "y": 80.0, "x": 64.0, "length": 32.0, "orientation": LaserOrientation.HORIZONTAL},
	{"status": 1, "y": 88.0, "x": 111.0, "length": 40.0, "orientation": LaserOrientation.VERTICAL},
	{"status": 1, "y": 80.0, "x": 128.0, "length": 32.0, "orientation": LaserOrientation.HORIZONTAL},
	{"status": 1, "y": 152.0, "x": 175.0, "length": 32.0, "orientation": LaserOrientation.VERTICAL},
]

const LASERS_ROOM_25: Array[Dictionary] = [
	{"status": 1, "y": 48.0, "x": 8.0, "length": 56.0, "orientation": LaserOrientation.HORIZONTAL},
	{"status": 1, "y": 56.0, "x": 79.0, "length": 40.0, "orientation": LaserOrientation.VERTICAL},
	{"status": 1, "y": 120.0, "x": 79.0, "length": 32.0, "orientation": LaserOrientation.VERTICAL},
	{"status": 1, "y": 80.0, "x": 224.0, "length": 24.0, "orientation": LaserOrientation.HORIZONTAL},
	{"status": 1, "y": 176.0, "x": 136.0, "length": 24.0, "orientation": LaserOrientation.HORIZONTAL},
]

const LASERS_ROOM_72: Array[Dictionary] = [
	{"status": 1, "y": 16.0, "x": 175.0, "length": 48.0, "orientation": LaserOrientation.VERTICAL},
	{"status": 0, "y": 80.0, "x": 8.0, "length": 24.0, "orientation": LaserOrientation.HORIZONTAL},
	{"status": 0, "y": 80.0, "x": 64.0, "length": 96.0, "orientation": LaserOrientation.HORIZONTAL},
	{"status": 1, "y": 88.0, "x": 47.0, "length": 40.0, "orientation": LaserOrientation.VERTICAL},
	{"status": 0, "y": 112.0, "x": 8.0, "length": 88.0, "orientation": LaserOrientation.HORIZONTAL},
	{"status": 0, "y": 88.0, "x": 175.0, "length": 40.0, "orientation": LaserOrientation.VERTICAL},
	{"status": 1, "y": 144.0, "x": 64.0, "length": 96.0, "orientation": LaserOrientation.HORIZONTAL},
	{"status": 0, "y": 144.0, "x": 192.0, "length": 56.0, "orientation": LaserOrientation.HORIZONTAL},
	{"status": 1, "y": 152.0, "x": 48.0, "length": 32.0, "orientation": LaserOrientation.VERTICAL},
	{"status": 0, "y": 152.0, "x": 176.0, "length": 32.0, "orientation": LaserOrientation.VERTICAL},
]

## Sequências dinâmicas da Sala 72 (idxLaserOnOff em laserconfig.asm:41-51)
const ROOM_72_SEQUENCES: Array[Array] = [
	[1, 0, 0, 1, 0, 0, 1, 0, 1, 0],
	[0, 1, 1, 0, 0, 0, 1, 0, 0, 1],
	[1, 0, 1, 0, 0, 1, 0, 0, 1, 1],
	[1, 1, 1, 0, 0, 0, 0, 1, 0, 0],
	[1, 0, 0, 0, 1, 1, 0, 0, 0, 1],
]

signal laser_triggered()

var room_id: int = 0
const ROOM_72_CYCLE_TICKS: int = 192 ## 0xC0 em Banks0123.asm:5797
const ROOM_72_CYCLE_SEC: float = 192.0 / 60.0

var beams: Array[Dictionary] = []
var goggles_equipped: bool = false
var in_alert_mode: bool = false
var room_72_timer_sec: float = 0.0
var room_72_timer: int:
	get:
		return int(ceil(room_72_timer_sec * 60.0 - 0.0001))
	set(v):
		room_72_timer_sec = float(v) / 60.0
var room_72_seq_idx: int = 0

func setup(p_room_id: int) -> void:
	room_id = p_room_id
	beams.clear()
	room_72_timer_sec = 0.0
	room_72_seq_idx = 0

	var template: Array[Dictionary] = []
	match room_id:
		24:
			template = LASERS_ROOM_24
		25:
			template = LASERS_ROOM_25
		72:
			template = LASERS_ROOM_72
		_:
			template = []

	for b: Dictionary in template:
		beams.append(b.duplicate())

	queue_redraw()

func tick(player_pos: Vector2, p_goggles_equipped: bool, p_in_alert_mode: bool, delta: float = 1.0 / 60.0) -> void:
	goggles_equipped = p_goggles_equipped
	in_alert_mode = p_in_alert_mode

	# No MSX2, feixes são desligados durante o modo de alerta (InitLaserRoom / DrawLaserBeams)
	if in_alert_mode or beams.is_empty():
		queue_redraw()
		return

	# Sala 72: cicla as 5 sequências dinâmicas a cada 192 ticks (0xC0 em Banks0123.asm:5797, 3.2s a 60fps)
	if room_id == 72:
		room_72_timer_sec += delta
		while room_72_timer_sec >= ROOM_72_CYCLE_SEC - 0.0001:
			room_72_timer_sec = maxf(0.0, room_72_timer_sec - ROOM_72_CYCLE_SEC)
			room_72_seq_idx = (room_72_seq_idx + 1) % ROOM_72_SEQUENCES.size()
			var seq: Array = ROOM_72_SEQUENCES[room_72_seq_idx]
			for i in range(mini(beams.size(), seq.size())):
				beams[i]["status"] = int(seq[i])

	# Teste de colisão de Snake com feixes ativos
	if check_touch(player_pos):
		laser_triggered.emit()

	queue_redraw()

func check_touch(player_pos: Vector2) -> bool:
	if in_alert_mode:
		return false

	for b: Dictionary in beams:
		if int(b.get("status", 0)) == 0:
			continue

		var orientation: int = int(b.get("orientation", LaserOrientation.VERTICAL))
		var bx: float = float(b.get("x", 0.0))
		var by: float = float(b.get("y", 0.0))
		var blen: float = float(b.get("length", 0.0))

		# Verificação fiel a ChkTouchLaser (laserbeams.asm:11-68)
		if orientation == LaserOrientation.VERTICAL:
			# Vertical: tolerância X < 4; tolerância Y centrada em (Y + 8 + length/2) < length/2
			if absf(player_pos.x - bx) < 4.0:
				var center_y: float = by + 8.0 + blen * 0.5
				if absf(player_pos.y - center_y) < blen * 0.5:
					return true
		else:
			# Horizontal: tolerância Y < 4; tolerância X centrada em (X + length/2) < length/2
			if absf(player_pos.y - by) < 4.0:
				var center_x: float = bx + blen * 0.5
				if absf(player_pos.x - center_x) < blen * 0.5:
					return true

	return false

func _draw() -> void:
	# No MSX2, lasers são invisíveis a olho nu sem GOGGLES (drawlaserbeams.asm:8-10)
	# E são desligados durante o alerta
	if not goggles_equipped or in_alert_mode or beams.is_empty():
		return

	var laser_color: Color = Color("ff2020")
	var glow_color: Color = Color(1.0, 0.1, 0.1, 0.3)
	var emitter_color: Color = Color("8090a0")

	for b: Dictionary in beams:
		if int(b.get("status", 0)) == 0:
			continue

		var orientation: int = int(b.get("orientation", LaserOrientation.VERTICAL))
		var bx: float = float(b.get("x", 0.0))
		var by: float = float(b.get("y", 0.0))
		var blen: float = float(b.get("length", 0.0))

		var start_pt: Vector2
		var end_pt: Vector2

		if orientation == LaserOrientation.VERTICAL:
			start_pt = Vector2(bx, by)
			end_pt = Vector2(bx, by + blen)
			# Nódulos emissores nas pontas
			draw_rect(Rect2(bx - 2, by - 1, 4, 3), emitter_color)
			draw_rect(Rect2(bx - 2, by + blen - 2, 4, 3), emitter_color)
		else:
			start_pt = Vector2(bx, by)
			end_pt = Vector2(bx + blen, by)
			# Nódulos emissores nas pontas
			draw_rect(Rect2(bx - 1, by - 2, 3, 4), emitter_color)
			draw_rect(Rect2(bx + blen - 2, by - 2, 3, 4), emitter_color)

		# Feixe laser infravermelho revelado pelos óculos térmicos
		draw_line(start_pt, end_pt, glow_color, 4.0)
		draw_line(start_pt, end_pt, laser_color, 1.5)
