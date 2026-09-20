# elevator_cabin.gd
# Representação visual autêntica da cabine de elevador do MSX2 RC750.
# Acompanha a coordenada vertical elevator_y dentro do poço de elevador (salas 240-250).

class_name ElevatorCabin
extends Node2D

var elevator_y: float = 180.0:
	set(val):
		elevator_y = val
		queue_redraw()

func _ready() -> void:
	z_index = 1

func _draw() -> void:
	# A cabine é centrada horizontalmente em X=112 (ELEVATOR_CABIN_X)
	# Largura: 32px (de 96 a 128)
	# Altura: 36px (de elevator_y - 20 a elevator_y + 16)
	var left: float = ElevatorSystem.ELEVATOR_CABIN_X - 16.0 # 96.0
	var top: float = elevator_y - 20.0
	var width: float = 32.0
	var height: float = 36.0

	# Cabos do elevador subindo pelo poço até o topo da tela
	draw_line(Vector2(left + 8.0, 0.0), Vector2(left + 8.0, top), Color(0.2, 0.2, 0.2), 1.0)
	draw_line(Vector2(left + 24.0, 0.0), Vector2(left + 24.0, top), Color(0.2, 0.2, 0.2), 1.0)

	# Fundo da cabine (metálico escuro)
	draw_rect(Rect2(left, top, width, height), Color(0.12, 0.14, 0.16), true)

	# Teto e Piso da cabine (amarelo/alaranjado industrial MSX2)
	draw_rect(Rect2(left, top, width, 3.0), Color(0.85, 0.65, 0.15), true)
	draw_rect(Rect2(left, top + height - 3.0, width, 3.0), Color(0.85, 0.65, 0.15), true)

	# Parede esquerda da cabine (fechada)
	draw_rect(Rect2(left, top, 3.0, height), Color(0.35, 0.38, 0.42), true)

	# Painel de controle no fundo da cabine (botões iluminados)
	draw_rect(Rect2(left + 4.0, top + 10.0, 4.0, 10.0), Color(0.25, 0.28, 0.32), true)
	draw_circle(Vector2(left + 6.0, top + 13.0), 1.0, Color(0.9, 0.2, 0.2)) # Botão vermelho
	draw_circle(Vector2(left + 6.0, top + 17.0), 1.0, Color(0.2, 0.8, 0.3)) # Botão verde

	# Moldura externa preta
	draw_rect(Rect2(left, top, width, height), Color(0.0, 0.0, 0.0), false, 1.0)
