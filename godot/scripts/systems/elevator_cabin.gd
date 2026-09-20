# elevator_cabin.gd
# Representação visual autêntica da cabine de elevador do MSX2 RC750.
# Acompanha a coordenada vertical elevator_y dentro do poço de elevador (salas 240-250).
# Baseado na estrutura SprElevatorDat da ROM (logic/elevatorroom.asm:227-241).

class_name ElevatorCabin
extends Node2D

var elevator_y: float = 180.0:
	set(val):
		elevator_y = val
		queue_redraw()

func _ready() -> void:
	z_index = 1

func _draw() -> void:
	# Coordenadas autênticas da ROM (SprElevatorDat):
	# ElevatorX = 112. Sprites cobrem X de 96 a 128 (largura: 32px).
	# ElevatorY base = elevator_y. Sprites cobrem Y de (elevator_y - 48) até (elevator_y + 16) (altura: 64px).
	var left: float = 96.0
	var top: float = elevator_y - 48.0
	var width: float = 32.0
	var height: float = 64.0

	# 1. Cabos de sustentação do elevador estendendo-se até o topo do poço
	draw_line(Vector2(left + 8.0, 0.0), Vector2(left + 8.0, top), Color(0.25, 0.28, 0.3), 1.0)
	draw_line(Vector2(left + 24.0, 0.0), Vector2(left + 24.0, top), Color(0.25, 0.28, 0.3), 1.0)

	# 2. Fundo interno da cabine (metálico escuro com sombra)
	draw_rect(Rect2(left, top, width, height), Color(0.1, 0.12, 0.14), true)

	# 3. Teto da cabine (viga reforçada amarela/cinza MSX2)
	draw_rect(Rect2(left, top, width, 4.0), Color(0.85, 0.65, 0.15), true)
	draw_rect(Rect2(left, top + 4.0, width, 2.0), Color(0.4, 0.3, 0.1), true)

	# 4. Piso da cabine (plataforma onde Snake se apoia, Y=elevator_y até elevator_y + 8)
	draw_rect(Rect2(left, elevator_y + 4.0, width, 4.0), Color(0.85, 0.65, 0.15), true)
	draw_rect(Rect2(left, elevator_y + 8.0, width, 8.0), Color(0.3, 0.32, 0.35), true)

	# 5. Parede esquerda sólida da cabine
	draw_rect(Rect2(left, top, 4.0, height), Color(0.35, 0.38, 0.42), true)
	draw_line(Vector2(left + 4.0, top), Vector2(left + 4.0, top + height), Color(0.15, 0.18, 0.2), 1.0)

	# 6. Painel de controle no interior esquerdo da cabine
	draw_rect(Rect2(left + 5.0, elevator_y - 24.0, 4.0, 14.0), Color(0.2, 0.22, 0.25), true)
	draw_circle(Vector2(left + 7.0, elevator_y - 20.0), 1.5, Color(0.95, 0.2, 0.2)) # Botão indicador
	draw_circle(Vector2(left + 7.0, elevator_y - 14.0), 1.5, Color(0.2, 0.85, 0.3)) # Botão andar

	# 7. Moldura externa e detalhes de reforço
	draw_rect(Rect2(left, top, width, height), Color(0.0, 0.0, 0.0), false, 1.0)
