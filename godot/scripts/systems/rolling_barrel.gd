class_name RollingBarrel
extends Node2D

## Rolling barrel column (ID_ROLLING_BARREL = 0Fh), rooms 141, 153, 191 and 205 (data/actorsinrooms.asm:860-866;
## idxActorsRooms reuses ActorsRoom141 for 153 and 191 at actorsinrooms.asm:1167-1231).
## - logic/actors/rollingbarrels.asm:8-132 (RollingBarrelLogic, RB_IncrementSpeed, ChkBarrelBounce, InitRollingBarrel)
## - Banks0123.asm:6358-6402 SetupActor (EnemyList erased at 12558-12562, so Direction starts at 0),
##   12612-12672 EnemiesLogic/RunEnemyLogic order,
##   7277-7332 AddActorSpeedX/Anim2FramesActor, 12875-12919 MoveActor/ChkActorExitRoom
## - data/shapes.asm (ImpactAreasInfo, ActorsShapeTouch 10h, ActorShapeProject/Expl 11h, ActorTouchDamage FFh);
##   the `inc a` before GetShapeInfo (touchenemy.asm:87-93, damagetoenemy.asm:98-102) makes the row = shape
## - Snake uses sprite layer 0 (SprAttRAM, Banks0123.asm:5414-5424): he is drawn in front of actors
## - data/weapondamage.asm:18-58 (index 14: 0 for every weapon, FFh for grenades): the barrel cannot be destroyed
## - logic/punchenemy.asm:6-17 (not punchable)
## Sprites come from tools/extractors/extract_rolling_barrel.py (canonical ROM only).

signal barrel_bounced(new_direction: int)
signal sfx_requested(sfx_id: int)
signal dismissed

enum Weapon { HAND_GUN, SMG, GRENADE_LAUNCHER, ROCKET_LAUNCHER, PLASTIC_BOMB, LAND_MINE, MISSILE }

const ACTOR_ID: int = 0x0F
const SPRITE_ID_FIRST: int = 0x36
const INITIAL_LIFE: int = 2
const TOUCH_DAMAGE: int = 0xFF
const NO_DAMAGE: int = -1
const WEAPON_DAMAGE: Array[int] = [0, 0, NO_DAMAGE, 0, 0, 0, 0]

const RIGHT_LIMIT_X: int = 200
const RIGHT_RESET_X: int = 199
const LEFT_LIMIT_X: int = 56
const LEFT_RESET_X: int = 57
const SPEED_X: int = 0x80
const PLAYER_X_SPLIT: int = 0x80
const ACCELERATION_X: int = 8
const ANIM_MASK: int = 3
const SFX_HIT_WALL: int = 0x1D
const DIR_DOWN: int = 2
const DIR_LEFT: int = 3

const EXIT_Y: int = 193
const EXIT_RIGHT_X: int = 255
const EXIT_LEFT_X: int = 7

## [offset Y, radius Y, offset X, radius X]
const TOUCH_AREA: Array[int] = [0x48, 0x48, 0x00, 0x0C]
const SHOT_AREA: Array[int] = [0x48, 0x48, 0x00, 0x10]
const EXPLOSIVE_AREA: Array[int] = [0x48, 0x48, 0x00, 0x10]

const DATA_DIR: String = "rolling-barrel"
const SPRITE_ORIGIN: Vector2 = Vector2(8.0, 0.0)
const FRAME_SIZE: Vector2 = Vector2(16.0, 144.0)

static var _textures: Dictionary = {}
static var _data_checked: bool = false
static var _data: Dictionary = {}

var x_fixed: int = 0
var y_fixed: int = 0
var speed_x: int = 0
var speed_y: int = 0
var direction: int = 0
var sprite_id: int = SPRITE_ID_FIRST
var anim_cnt: int = 0
var life: int = INITIAL_LIFE
var start_x: int = 0
var moving: bool = false
var is_dismissed: bool = false
var room_id: int = -1

func _init() -> void:
	z_index = 5

## SetupActor (Banks0123.asm:6359-6402) followed by InitRollingBarrel (rollingbarrels.asm:115-132).
func setup(spawn_x: int, spawn_y: int, player_x: int, spawn_room: int = -1) -> void:
	x_fixed = (spawn_x & 0xFF) << 8
	y_fixed = (spawn_y & 0xFF) << 8
	anim_cnt = 0
	life = INITIAL_LIFE
	direction = 0
	speed_y = 0
	is_dismissed = false
	room_id = spawn_room
	start_x = player_x & 0xFF
	speed_x = SPEED_X if start_x < PLAYER_X_SPLIT else (-SPEED_X) & 0xFFFF
	moving = true
	sprite_id = SPRITE_ID_FIRST
	_sync_position()

## One EnemiesLogic iteration (Banks0123.asm:12635-12638): RunEnemyLogic, MoveActor, ChkActorExitRoom.
func step_tick(_delta: float = 1.0 / 60.0) -> void:
	if is_dismissed:
		return
	anim_cnt = (anim_cnt + 1) & 0xFF
	_rolling_barrel_logic()
	_move_actor()
	_check_exit_room()
	_sync_position()
	queue_redraw()

func _rolling_barrel_logic() -> void:
	if (anim_cnt & ANIM_MASK) == 0:
		sprite_id ^= 1
	_check_bounce()
	# Status stays 0: NextActorStatus is only reachable from the Status 1 branch (rollingbarrels.asm:14-56).
	var accel: int = ACCELERATION_X if (direction & 1) == 1 else -ACCELERATION_X
	speed_x = (speed_x + accel) & 0xFFFF

func _check_bounce() -> void:
	var x: int = x_fixed >> 8
	if x >= RIGHT_LIMIT_X:
		_change_direction(RIGHT_RESET_X, DIR_DOWN, (-SPEED_X) & 0xFFFF)
	elif x < LEFT_LIMIT_X:
		_change_direction(LEFT_RESET_X, DIR_LEFT, SPEED_X)

## ChangeBarrelDir writes only the integer X byte; Xdec is kept (rollingbarrels.asm:101-107).
func _change_direction(new_x: int, new_direction: int, new_speed: int) -> void:
	x_fixed = (new_x << 8) | (x_fixed & 0xFF)
	direction = new_direction
	speed_x = new_speed
	barrel_bounced.emit(new_direction)
	sfx_requested.emit(SFX_HIT_WALL)

func _move_actor() -> void:
	if not moving:
		return
	y_fixed = (y_fixed + speed_y) & 0xFFFF
	x_fixed = (x_fixed + speed_x) & 0xFFFF

func _check_exit_room() -> void:
	var x: int = x_fixed >> 8
	if (y_fixed >> 8) >= EXIT_Y or x >= EXIT_RIGHT_X or x < EXIT_LEFT_X:
		is_dismissed = true
		dismissed.emit()

func _sync_position() -> void:
	position = Vector2(float(x_fixed >> 8), float(y_fixed >> 8))

func pixel_x() -> int:
	return x_fixed >> 8

func pixel_y() -> int:
	return y_fixed >> 8

func signed_speed_x() -> int:
	return speed_x - 0x10000 if speed_x >= 0x8000 else speed_x

func frame_index() -> int:
	return sprite_id - SPRITE_ID_FIRST

## ChkArea (logic/punchenemy.asm:101-126): 8-bit sums, absolute difference strictly below each radius.
func _in_area(area: Array[int], point: Vector2) -> bool:
	if is_dismissed:
		return false
	var dy: int = absi(((pixel_y() + area[0]) & 0xFF) - (int(point.y) & 0xFF))
	if dy >= area[1]:
		return false
	var dx: int = absi(((pixel_x() + area[2]) & 0xFF) - (int(point.x) & 0xFF))
	return dx < area[3]

## ChkTouchEnemy (logic/touchenemy.asm:83-107).
func touches_player(player_pos: Vector2) -> bool:
	return _in_area(TOUCH_AREA, player_pos)

## ChkEneHitByShot (logic/damagetoenemy.asm:92-131): hand gun, SMG, rocket and missile.
func shot_hits(shot_pos: Vector2) -> bool:
	return _in_area(SHOT_AREA, shot_pos)

## Same routine with ActorShapeExpl: grenade, land mine and plastic bomb.
func explosive_hits(shot_pos: Vector2) -> bool:
	return _in_area(EXPLOSIVE_AREA, shot_pos)

## DecEnemyLife (logic/damagetoenemy.asm:159-223). Every table entry is 0 or FFh, so LIFE never changes.
func apply_weapon_hit(weapon: Weapon) -> int:
	var damage: int = WEAPON_DAMAGE[weapon]
	if damage != NO_DAMAGE:
		life = maxi(0, life - damage)
	return damage

static func _load_data() -> void:
	if _data_checked:
		return
	_data_checked = true
	_data = RomProvenance.load_canonical_json(DATA_DIR.path_join("rolling_barrel.json"))

static func extracted_data() -> Dictionary:
	_load_data()
	return _data

static func texture_for_room(target_room: int) -> Texture2D:
	if _textures.has(target_room):
		return _textures[target_room]
	var texture: Texture2D = null
	_load_data()
	for entry: Variant in _data.get("rooms", []):
		var room: Dictionary = entry as Dictionary
		if int(room.get("room_id", -1)) != target_room:
			continue
		var path: String = RomProvenance.canonical_path(DATA_DIR.path_join(String(room.get("png", ""))))
		if FileAccess.file_exists(path):
			var img: Image = Image.load_from_file(path)
			if img != null and not img.is_empty():
				texture = ImageTexture.create_from_image(img)
	if texture == null:
		push_warning("RollingBarrel: sem spritesheet extraído para a sala %d (rode tools/extractors/extract_rolling_barrel.py)" % target_room)
	_textures[target_room] = texture
	return texture

func _draw() -> void:
	if is_dismissed:
		return
	var dest := Rect2(-SPRITE_ORIGIN, FRAME_SIZE)
	var texture: Texture2D = texture_for_room(room_id)
	if texture != null:
		draw_texture_rect_region(texture, dest, Rect2(Vector2(FRAME_SIZE.x * frame_index(), 0.0), FRAME_SIZE))
		return
	# Placeholder with the original footprint when the private extraction is absent.
	draw_rect(dest, Color(0.57, 0.57, 0.57))
	draw_rect(dest, Color.BLACK, false, 1.0)
