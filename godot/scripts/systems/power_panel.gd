class_name PowerPanel
extends Node2D

## Painel de Força / Disjuntor Elétrico (Etapa 22).
## Lógica revertida de logic/actors/powerswitch.asm (InitPowerSwitch, PowerSwitchLogic, gfxPowSwitch)
## e logic/damagetoenemy.asm (imunidade a balas, destruição por Míssil Teleguiado com dano 5 HP).

const PANEL_WIDTH: float = 16.0
const PANEL_HEIGHT: float = 16.0
const MAX_HP: int = 2

signal panel_destroyed(room_id: int)
signal hit_absorbed(weapon_type: String)

var room_id: int = -1
var hp: int = MAX_HP
var is_destroyed: bool = false
var anim_tick: int = 0

func _ready() -> void:
	z_index = 3

func setup(p_room_id: int, p_pos: Vector2, p_is_destroyed: bool = false) -> void:
	room_id = p_room_id
	position = p_pos
	is_destroyed = p_is_destroyed
	hp = 0 if is_destroyed else MAX_HP
	queue_redraw()

func get_bounds() -> Rect2:
	return Rect2(position.x - 8.0, position.y - 8.0, PANEL_WIDTH, PANEL_HEIGHT)

func collides_with_point(p: Vector2, radius: float = 8.0) -> bool:
	return get_bounds().grow(radius).has_point(p)

## Aplica dano ao painel de força baseado na arma.
## Retorna true se o painel foi destruído pelo disparo.
func take_hit(weapon_type: String, damage: int) -> bool:
	if is_destroyed:
		return false

	if weapon_type == "MISSILE":
		hp = max(0, hp - damage)
		if hp <= 0:
			is_destroyed = true
			panel_destroyed.emit(room_id)
			queue_redraw()
			return true
		return false
	else:
		# Handgun, SMG ou tiros normais são absorvidos pela carcaça blindada (0xFF no MSX2)
		hit_absorbed.emit(weapon_type)
		return false

func tick() -> void:
	anim_tick += 1
	if not is_destroyed and (anim_tick % 15 == 0):
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(-8.0, -8.0, PANEL_WIDTH, PANEL_HEIGHT)

	if not is_destroyed:
		# 1. Carcaça de metal blindado cinza escuro
		draw_rect(rect, Color(0.18, 0.22, 0.25))
		draw_rect(rect, Color(0.45, 0.52, 0.58), false, 1.0) # Borda metálica

		# 2. Parafusos nos cantos
		var screw_col := Color(0.7, 0.75, 0.8)
		draw_rect(Rect2(-7.0, -7.0, 1.0, 1.0), screw_col)
		draw_rect(Rect2(6.0, -7.0, 1.0, 1.0), screw_col)
		draw_rect(Rect2(-7.0, 6.0, 1.0, 1.0), screw_col)
		draw_rect(Rect2(6.0, 6.0, 1.0, 1.0), screw_col)

		# 3. Placa de aviso de alta voltagem (triângulo amarelo e raio)
		var triangle := PackedVector2Array([
			Vector2(0.0, -5.0),
			Vector2(-5.0, 3.0),
			Vector2(5.0, 3.0)
		])
		draw_colored_polygon(triangle, Color(0.95, 0.80, 0.10))

		# Raio elétrico preto no centro do triângulo
		var bolt := PackedVector2Array([
			Vector2(1.0, -4.0),
			Vector2(-2.0, -1.0),
			Vector2(0.0, -1.0),
			Vector2(-1.0, 2.0),
			Vector2(2.0, -1.0),
			Vector2(0.0, -1.0)
		])
		draw_colored_polygon(bolt, Color(0.1, 0.1, 0.1))

		# 4. LED indicador de energia ativa (pisca sutilmente verde/amarelo)
		var is_blink_on: bool = (anim_tick / 20) % 2 == 0
		var led_col := Color(0.2, 0.95, 0.2) if is_blink_on else Color(0.1, 0.5, 0.1)
		draw_rect(Rect2(-2.0, 4.0, 4.0, 2.0), led_col)

		# 5. Conduíte inferior de cabos elétricos
		draw_rect(Rect2(-3.0, 7.0, 6.0, 3.0), Color(0.3, 0.35, 0.38))
	else:
		# Estado Destruído / Chamuscado
		# 1. Carcaça queimada de preto carvão
		draw_rect(rect, Color(0.08, 0.08, 0.09))
		draw_rect(rect, Color(0.25, 0.18, 0.15), false, 1.0) # Borda chamuscada

		# 2. Rachaduras e buraco de impacto central
		draw_rect(Rect2(-4.0, -4.0, 8.0, 8.0), Color(0.02, 0.02, 0.02))
		draw_line(Vector2(-6.0, -6.0), Vector2(-2.0, -2.0), Color(0.35, 0.15, 0.1), 1.0)
		draw_line(Vector2(5.0, -5.0), Vector2(1.0, -1.0), Color(0.35, 0.15, 0.1), 1.0)
		draw_line(Vector2(-3.0, 4.0), Vector2(2.0, 1.0), Color(0.35, 0.15, 0.1), 1.0)

		# 3. Fios rompidos e faíscas residuais apagadas
		draw_line(Vector2(-2.0, 4.0), Vector2(-4.0, 7.0), Color(0.6, 0.3, 0.1), 1.0)
		draw_line(Vector2(2.0, 4.0), Vector2(4.0, 6.0), Color(0.4, 0.4, 0.7), 1.0)
