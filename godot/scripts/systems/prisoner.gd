class_name Prisoner
extends Node2D

## Entidade de Refém / Prisioneiro autêntica do Metal Gear MSX2 RC750.
## Lógica revertida de external/MetalGear/logic/actors/prisoner.asm.

signal rescued(prisoner: Prisoner)
signal killed(prisoner: Prisoner)

const TYPE_PRISONER: int = 49      # 0x31: Prisioneiro padrão
const TYPE_ELLEN: int = 50         # 0x32: Ellen Madnar
const TYPE_GREY_FOX: int = 51      # 0x33: Agente Grey Fox
const TYPE_MADNAR: int = 52        # 0x34: Dr. Pettrovich Madnar
const TYPE_FAKE_MADNAR: int = 55   # 0x37: Falso Madnar (Impostor)

const PRISONER_TEXTS: Dictionary = {
	129: "I'm saved! Dr. Pettrovich was moved to building 2. Building 2 is 10km north of here.",
	134: "I'm saved! The FOX HOUNDer called Grey Fox... is confined in an isolated cell.",
	136: "I'm saved! The best way to the isolated cell is to be caught by the enemy...",
	144: "I'm saved! Dr. Pettrovich is in a cell in the courtyard.",
	145: "Rescued! Keep up the good work, Snake.",
	146: "I'm saved! The FOX HOUNDer who infiltrated a few days ago is safe. They're holding him.",
	148: "I'm saved! Thank you, Snake!",
	152: "I'm saved! Watch out for infrared laser traps in the corridors.",
	159: "I'm saved! Diane of the Resistance supports you on frequency 120.33...",
	161: "I'm saved! Use a Parachute to dive between the fences.",
	164: "Glad you arrived, rookie... I'm Grey Fox... Metal Gear is an armored walking battle tank equipped with nuclear missiles... Only Dr. Pettrovich knows how to destroy it.",
	167: "Thank you. I'm the daughter of Dr. Pettrovich, Ellen. My father was forced to develop Metal Gear... please save him!",
	180: "I'm saved! The water channel goes to building 3.",
	182: "I'm Dr. Pettrovich... To destroy Metal Gear, attach plastic explosives to the right and left feet in sequence!",
	186: "I'm saved! Dr. Pettrovich is in an underground cell.",
	189: "Hehehe... I'm an impostor! The real Dr. Pettrovich is elsewhere!",
	190: "I'm saved! The only way off this floor is to use the north elevator!",
	193: "Rescued! I'm a brother of Jennifer. Climb the left ladder when escaping.",
	194: "I'm saved! The Boss of Outer Heaven is the commander-in-chief of FOX HOUND, Big Boss!...",
	195: "I'm saved! The only way to the courtyard is a Parachute dive from the rooftop.",
	198: "I'm saved! Call Jennifer of the Resistance on frequency 120.48...",
	202: "I'm saved! Use a Compass to cross the desert.",
	203: "Rescued! Thank you for saving me!"
}

var room_id: int = 0
var actor_type_id: int = TYPE_PRISONER
var prisoner_name: String = "PRISIONEIRO"
var message_text: String = "I'm saved!"
var is_rescued: bool = false
var is_dead: bool = false
var is_vital: bool = false # Grey Fox ou Ellen: morte causa falha crítica

func _ready() -> void:
	z_index = 3
	_configure_prisoner()

func setup(type_id: int, r_id: int, pos: Vector2 = Vector2.ZERO) -> void:
	actor_type_id = type_id
	room_id = r_id
	position = pos
	_configure_prisoner()

func _configure_prisoner() -> void:
	match actor_type_id:
		TYPE_ELLEN:
			prisoner_name = "ELLEN MADNAR"
			is_vital = true
		TYPE_GREY_FOX:
			prisoner_name = "GREY FOX"
			is_vital = true
		TYPE_MADNAR:
			prisoner_name = "DR. PETTROVICH MADNAR"
			is_vital = true
		TYPE_FAKE_MADNAR:
			prisoner_name = "FALSO MADNAR"
			is_vital = false
		_:
			prisoner_name = "PRISIONEIRO"
			is_vital = false

	message_text = PRISONER_TEXTS.get(room_id, "I'm saved! Thank you, Snake!")

## Verifica toque do jogador desarmado ou soco.
func check_touch(player_pos: Vector2, is_punching: bool) -> bool:
	if is_dead or is_rescued:
		return false

	var touch_box := Rect2(position.x - 12.0, position.y - 12.0, 24.0, 24.0)
	if not touch_box.has_point(player_pos):
		return false

	if is_punching:
		# Soco atinge o prisioneiro e o mata
		kill_prisoner()
		return false

	# Resgate bem-sucedido
	rescue_prisoner()
	return true

## Aplica tiro de arma de fogo no prisioneiro.
func apply_bullet_hit() -> bool:
	if is_dead or is_rescued:
		return false
	kill_prisoner()
	return true

func rescue_prisoner() -> void:
	if is_rescued or is_dead:
		return
	is_rescued = true
	queue_redraw()
	rescued.emit(self)

func kill_prisoner() -> void:
	if is_dead:
		return
	is_dead = true
	queue_redraw()
	killed.emit(self)

func _draw() -> void:
	if is_dead:
		# Prisioneiro eliminado no chão
		draw_circle(Vector2(0, 4), 6, Color(0.6, 0.1, 0.1, 0.8))
		draw_rect(Rect2(-8, 6, 16, 6), Color(0.4, 0.05, 0.05))
		return

	# Paleta MSX2 autêntica
	var c_skin := Color(0.91, 0.63, 0.50) # Pele #E8A080
	var c_hair := Color(0.19, 0.13, 0.06) # Cabelo castanho/preto
	var c_cloth := Color(0.85, 0.85, 0.85) # Roupa padrão cáqui/clara
	var c_ropes := Color(0.55, 0.27, 0.07) # Cordas marrons

	if actor_type_id == TYPE_ELLEN:
		c_cloth = Color(0.85, 0.25, 0.38) # Vestido rosa/magenta
		c_hair = Color(0.44, 0.19, 0.06)  # Cabelo castanho comprido
	elif actor_type_id == TYPE_GREY_FOX:
		c_cloth = Color(0.25, 0.31, 0.44) # Traje de infiltrador azulado
		c_hair = Color(0.88, 0.75, 0.13)  # Bandana/cabelo amarelado
	elif actor_type_id == TYPE_MADNAR or actor_type_id == TYPE_FAKE_MADNAR:
		c_cloth = Color(0.95, 0.95, 0.95) # Jaleco branco de cientista
		c_hair = Color(0.65, 0.65, 0.65)  # Cabelo grisalho

	# Cabeça
	draw_circle(Vector2(0, -6), 5, c_skin)
	draw_arc(Vector2(0, -7), 5, -PI, 0, 8, c_hair, 2.0)

	if not is_rescued:
		# Prisioneiro amarrado (joelhos dobrados, cordas no peito e braços)
		draw_rect(Rect2(-5, -1, 10, 10), c_cloth)
		draw_line(Vector2(-5, 2), Vector2(5, 2), c_ropes, 1.5)
		draw_line(Vector2(-5, 5), Vector2(5, 5), c_ropes, 1.5)
		draw_line(Vector2(-5, 8), Vector2(5, 8), c_ropes, 1.5)
		draw_rect(Rect2(-4, 9, 8, 4), Color(0.2, 0.2, 0.2)) # Pés amarrados
	else:
		# Prisioneiro libertado (braços abertos agradecendo)
		draw_rect(Rect2(-5, -1, 10, 11), c_cloth)
		# Braços abertos
		draw_line(Vector2(-5, 1), Vector2(-9, -2), c_skin, 2.0)
		draw_line(Vector2(5, 1), Vector2(9, -2), c_skin, 2.0)
		# Pernas em pé
		draw_rect(Rect2(-4, 10, 3, 5), Color(0.25, 0.25, 0.25))
		draw_rect(Rect2(1, 10, 3, 5), Color(0.25, 0.25, 0.25))
