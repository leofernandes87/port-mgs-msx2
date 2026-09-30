class_name Bullet
extends Node2D

## Entidade de projétil balístico fiel à física e alcance do MSX2 RC750 (Etapa 13).
## Lógica revertida de logic/weapon/handgun.asm, logic/weaponuse.asm e logic/actors/bullethv.asm.

var is_enemy: bool = false
var direction: PlayerController.Direction = PlayerController.Direction.DOWN

# Constantes autênticas da ROM (ShootDirSpeeds em handgun.asm:86-90 e bullethv.asm:43-46)
var speed: float = 6.0          # Snake: 6 px/tick constante; Inimigo: 4.0 px/tick
var ticks_remaining: int = 16   # Alcance máximo da pistola: 16 ticks (10h) = 96 pixels
var damage: int = 2             # BulletDamage da ROM = 2 pontos (derrota soldados em 1 tiro)

func _ready() -> void:
	z_index = 12

func step_tick(collision_grid: Array, delta: float = 1.0 / 60.0) -> bool:
	var speed_px_per_sec: float = speed * 60.0
	var step_dist: float = speed_px_per_sec * delta
	var step_vec := Vector2.ZERO
	match direction:
		PlayerController.Direction.UP:
			step_vec = Vector2(0.0, -step_dist)
		PlayerController.Direction.DOWN:
			step_vec = Vector2(0.0, step_dist)
		PlayerController.Direction.LEFT:
			step_vec = Vector2(-step_dist, 0.0)
		PlayerController.Direction.RIGHT:
			step_vec = Vector2(step_dist, 0.0)

	position += step_vec
	ticks_remaining -= 1

	if ticks_remaining <= 0:
		return false

	# Limites de tela da ROM (ChkShotBoundaries em weaponuse.asm:366-376)
	# Y limit: 184; X right: 248; X left: 9
	if position.y < 0.0 or position.y >= 184.0 or position.x < 9.0 or position.x >= 248.0:
		return false

	# Colisão com o cenário (ChkShotCollision em weaponuse.asm:338)
	if not collision_grid.is_empty():
		var tx: int = int(position.x) / 8
		var ty: int = int(position.y) / 8
		if tx < 0 or tx >= 32 or ty < 0 or ty >= 24:
			return false
		var idx: int = ty * 32 + tx
		if idx >= 0 and idx < collision_grid.size() and int(collision_grid[idx]) == 1:
			return false

	queue_redraw()
	return true

func _draw() -> void:
	# Representação visual autêntica do projétil MSX2 (SprBullet / SprBulletAttr: 2x2 pixels)
	var color := Color("ff3322") if is_enemy else Color("ffff77")
	var bullet_rect := Rect2(-1.0, -1.0, 2.0, 2.0)
	draw_rect(bullet_rect, color)
	draw_rect(Rect2(-1.0, -1.0, 1.0, 1.0), Color.WHITE)
