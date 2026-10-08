class_name PlayerControls
extends RefCounted
## ControlsHold/ControlsTrigger and the direction memory of NormalCtrl.
## StoreControls: logic/controls.asm:8-30 (trigger = bits newly pressed this iteration).
## GetPlayerDir: Banks0123.asm:8702-8759; IdsDirection: Banks0123.asm:8767-8782.
## DisableControls: logic/nextroom.asm:380-384.

# Bits de ControlsHold/ControlsTrigger (logic/controls.asm:35-43).
const UP: int = 0x01
const DOWN: int = 0x02
const LEFT: int = 0x04
const RIGHT: int = 0x08
const DIRECTIONS: int = 0x0F

# Índice = máscara de direções; 0 = nenhuma direção nova (1=Up, 2=Down, 3=Left, 4=Right).
const IDS_DIRECTION: Array[int] = [0, 1, 2, 0, 3, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0]

var hold: int = 0
var trigger: int = 0
var direction_mask: int = 0
var direction_mask_old: int = 0


## StoreControls: one call per game iteration (UpdateControls in GameLogic).
func store(raw: int) -> void:
	trigger = (hold ^ raw) & raw
	hold = raw


## GetPlayerDir: returns PlayerDirectionNew (0 keeps the current direction).
func get_player_dir() -> int:
	var a: int
	var new_dirs: int = trigger & DIRECTIONS
	if new_dirs != 0:
		direction_mask_old = direction_mask
		if new_dirs & UP:
			a = UP
		elif new_dirs & DOWN:
			a = DOWN
		elif new_dirs & LEFT:
			a = LEFT
		else:
			a = new_dirs & RIGHT
		direction_mask = a
	else:
		var held: int = hold & DIRECTIONS
		a = held
		if held & direction_mask == 0 and held & direction_mask_old != 0:
			a = direction_mask_old
			direction_mask_old = 0
			direction_mask = a
	return IDS_DIRECTION[a]


func disable() -> void:
	direction_mask = 0
	direction_mask_old = 0


func reset() -> void:
	hold = 0
	trigger = 0
	disable()


## Cursor keys or WASD mapped to the direction bits of ReadControls.
static func read_keyboard() -> int:
	var raw: int = 0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		raw |= UP
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		raw |= DOWN
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		raw |= LEFT
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		raw |= RIGHT
	return raw
