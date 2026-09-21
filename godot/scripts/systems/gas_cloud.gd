class_name GasCloud
extends Node2D

## Ator visual de nuvem de gás animada (ID_GAS = 8 na ROM MSX2).
## Lógica revertida de logic/actors/gas.asm (InitGas, GasWait, GasShow, ciclos de 32 ticks).

var timer: int = 20
var is_visible_phase: bool = false
var anim_tick: int = 0
var anim_frame: int = 0

func _init(start_visible: bool = false) -> void:
	z_index = 8
	is_visible_phase = start_visible
	timer = 32 if start_visible else randi_range(10, 40)

func step_tick() -> void:
	timer -= 1
	if timer <= 0:
		is_visible_phase = not is_visible_phase
		if is_visible_phase:
			timer = 32 # 0x20 ticks visível (gas.asm:34)
		else:
			timer = randi_range(20, 60) # Intervalo oculto (gas.asm:11)
		queue_redraw()

	if is_visible_phase:
		anim_tick = (anim_tick + 1) % 8
		if anim_tick == 0:
			anim_frame = (anim_frame + 1) % 2
			queue_redraw()

func _draw() -> void:
	if not is_visible_phase:
		return

	# Paleta autêntica MSX: verde escuro e verde claro (SetSprColor 2 e 4Dh em gas.asm:36-37)
	var col_outer := Color(0.2, 0.65, 0.25, 0.45)
	var col_inner := Color(0.4, 0.85, 0.35, 0.60)

	var puff_offsets: Array[Vector2] = []
	if anim_frame == 0:
		puff_offsets = [
			Vector2(-6, -4), Vector2(4, -5), Vector2(-2, 3), Vector2(6, 2)
		]
	else:
		puff_offsets = [
			Vector2(-5, -6), Vector2(5, -3), Vector2(-4, 4), Vector2(3, 4)
		]

	for off in puff_offsets:
		draw_circle(off, 6.0, col_outer)
		draw_circle(off, 3.5, col_inner)
