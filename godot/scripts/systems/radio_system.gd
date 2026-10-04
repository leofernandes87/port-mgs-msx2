class_name RadioSystem
extends RefCounted

## Sistema de Rádio Transceptor (Codec) autêntico do Metal Gear MSX2 RC750 (Etapa 15).
## Lógica revertida de Banks0123.asm (DrawRadio, RadioIdle, ChgRadioFreq, RadioSignalUp, SetupRadioReply)
## e tabelas canônicas de data/radiocalls.asm (edição inglesa) e constants/Enums.asm.

# Identificadores de contatos da ROM (data/radiocalls.asm:15-22)
const CONTACT_BIG_BOSS: String = "BIG_BOSS"
const CONTACT_SCHNEIDER: String = "SCHNEIDER"
const CONTACT_DIANE: String = "DIANE"
const CONTACT_JENNIFER: String = "JENNIFER"

# Frequências canônicas da ROM (constants/Enums.asm:15-22 e Banks0123.asm:2455-2462)
# Frequência base: 120.XX MHz. Armazenamos as duas casas decimais (0 a 99).
const FREQ_BIGBOSS_PR1: int = 85        # 120.85 (0x85 em BCD)
const FREQ_BIGBOSS_PR2: int = 13        # 120.13 (0x13 em BCD)
const FREQ_SCHNEIDER_PR1: int = 79      # 120.79 (0x79 em BCD)
const FREQ_SCHNEIDER_PR2: int = 26      # 120.26 (0x26 em BCD)
const FREQ_DIANE_PR1: int = 33          # 120.33 (0x33 em BCD)
const FREQ_DIANE_PR2: int = 91          # 120.91 (0x91 em BCD)
const FREQ_JENNIFER: int = 48           # 120.48 (0x48 em BCD)

# Texto canônico de transmissão de Snake ao solicitar resposta (Text ID 10 em texts.asm:191)
const TXT_SNAKE_SEND: String = "THIS IS SOLID SNAKE... YOUR REPLY, PLEASE."

# Texto de estática quando não há sintonia
const TXT_NO_RESPONSE: String = "(...NO RESPONSE... ONLY RADIO STATIC...)"

# Estado atual do transceptor
var current_freq: int = FREQ_BIGBOSS_PR1 # Começa em 120.85 (Big Boss)
var is_send_mode: bool = false
var has_incoming_call: bool = false
var signal_leds: int = 0                # 0 a 12 LEDs de sinal
var answered_rooms: Array[int] = []     # Salas cujas chamadas autoreply já foram atendidas

# Banco de dados de chamadas canônicas por sala (data/radiocalls.asm)
# Cada entrada contém: contact, freq, is_autoreply, text, text_id
# Porte parcial de idxRoomRadio: salas ausentes ainda não foram portadas. is_autoreply só pode
# ser true onde RoomsMusic tem o bit 3 (chamada recebida; musicradioconfig.asm:9, Banks0123.asm:1729-1739).
const ROOM_CALLS: Dictionary = {
	0: [
		{
			"contact": CONTACT_BIG_BOSS,
			"freq": FREQ_BIGBOSS_PR1,
			"is_autoreply": true,
			"text_id": 3,
			"text": "THIS IS BIG BOSS... MISSION! GAIN ACCESS TO THE ENEMY'S FORTRESS, OUTER HEAVEN. TAKE ACTION NOT TO BE DISCOVERED BY THE ENEMY. ...OVER"
		}
	],
	1: [
		{
			"contact": CONTACT_BIG_BOSS,
			"freq": FREQ_BIGBOSS_PR1,
			"is_autoreply": false,
			"text_id": 3,
			"text": "THIS IS BIG BOSS... MISSION! GAIN ACCESS TO THE ENEMY'S FORTRESS, OUTER HEAVEN. TAKE ACTION NOT TO BE DISCOVERED BY THE ENEMY. ...OVER"
		},
		{
			"contact": CONTACT_SCHNEIDER,
			"freq": FREQ_SCHNEIDER_PR1,
			"is_autoreply": false,
			"text_id": 23,
			"text": "THIS IS THE RESISTANCE LEADER, MR. SCHNEIDER... I WILL BRIEF YOU ON THE FORTRESS DETAILS. PLEASE CONTACT ON WAVEBAND 12079. ...OVER"
		}
	],
	4: [
		{
			"contact": CONTACT_BIG_BOSS,
			"freq": FREQ_BIGBOSS_PR1,
			"is_autoreply": false,
			"text_id": 3,
			"text": "THIS IS BIG BOSS... MISSION! GAIN ACCESS TO THE ENEMY'S FORTRESS, OUTER HEAVEN. TAKE ACTION NOT TO BE DISCOVERED BY THE ENEMY. ...OVER"
		}
	],
	5: [
		{
			"contact": CONTACT_BIG_BOSS,
			"freq": FREQ_BIGBOSS_PR1,
			"is_autoreply": false,
			"text_id": 4,
			"text": "THIS IS BIG BOSS... TAKE THE WEAPONS AND EQUIPMENTS FROM THE ENEMY'S LORRY!! YOU SHOULD HAVE AN I.D.CARD TO OPEN THE DOOR. ...OVER"
		}
	],
	20: [
		{
			"contact": CONTACT_DIANE,
			"freq": FREQ_DIANE_PR1,
			"is_autoreply": false,
			"text_id": 80,
			"text": "HELLO THIS IS DIANE... MACHINEGUN KID MUST BE KILLED BY REMOTE-CONTROL MISSILE. ...OVER"
		}
	],
	28: [
		{
			"contact": CONTACT_BIG_BOSS,
			"freq": FREQ_BIGBOSS_PR1,
			"is_autoreply": false,
			"text_id": 20,
			"text": "THIS IS BIG BOSS... THERE MUST BE SOME RESISTANCE. TRY TO CONTACT WITH THE TRANSCEIVER! ...OVER"
		}
	],
	29: [
		{
			"contact": CONTACT_BIG_BOSS,
			"freq": FREQ_BIGBOSS_PR1,
			"is_autoreply": true,
			"text_id": 25,
			"text": "THIS IS BIG BOSS... PUT ON A GAS MASK IN THE GAS ROOM. ...OVER"
		},
		{
			"contact": CONTACT_SCHNEIDER,
			"freq": FREQ_SCHNEIDER_PR1,
			"is_autoreply": false,
			"text_id": 26,
			"text": "THIS IS THE RESISTANCE LEADER, MR. SCHNEIDER... GO TO THE SOUTH PART OF THE 1ST FLOOR TO GET YOUR MASK. ...OVER"
		}
	],
	30: [
		{
			"contact": CONTACT_BIG_BOSS,
			"freq": FREQ_BIGBOSS_PR1,
			"is_autoreply": false,
			"text_id": 20,
			"text": "THIS IS BIG BOSS... THERE MUST BE SOME RESISTANCE. TRY TO CONTACT WITH THE TRANSCEIVER! ...OVER"
		},
		{
			"contact": CONTACT_SCHNEIDER,
			"freq": FREQ_SCHNEIDER_PR1,
			"is_autoreply": false,
			"text_id": 23,
			"text": "THIS IS THE RESISTANCE LEADER, MR. SCHNEIDER... I WILL BRIEF YOU ON THE FORTRESS DETAILS. PLEASE CONTACT ON WAVEBAND 12079. ...OVER"
		}
	],
	31: [
		{
			"contact": CONTACT_SCHNEIDER,
			"freq": FREQ_SCHNEIDER_PR1,
			"is_autoreply": false,
			"text_id": 23,
			"text": "THIS IS THE RESISTANCE LEADER, MR. SCHNEIDER... I WILL BRIEF YOU ON THE FORTRESS DETAILS. PLEASE CONTACT ON WAVEBAND 12079. ...OVER"
		}
	],
	37: [
		{
			"contact": CONTACT_BIG_BOSS,
			"freq": FREQ_BIGBOSS_PR1,
			"is_autoreply": true,
			"text_id": 38,
			"text": "THIS IS BIG BOSS... BREAK DOWN THE POWER SUPPLY BOX WITH THE REMOTE-CONTROL MISSILE TO GET RID OF THE HIGH-VOLTAGE. ...OVER"
		},
		{
			"contact": CONTACT_SCHNEIDER,
			"freq": FREQ_SCHNEIDER_PR1,
			"is_autoreply": false,
			"text_id": 39,
			"text": "THIS IS MR. SCHNEIDER... THE REMOTE-CONTROL MISSILE IS AVAILABLE IN THE SOUTHEASTERN AREA. ...OVER"
		}
	],
	50: [
		{
			"contact": CONTACT_DIANE,
			"freq": FREQ_DIANE_PR1,
			"is_autoreply": false,
			"text_id": 88,
			"text": "HI. THIS IS DIANE... BEAT HIND-D WITH A GRENADE LAUNCHER. ...BYE"
		}
	],
	53: [
		{
			"contact": CONTACT_BIG_BOSS,
			"freq": FREQ_BIGBOSS_PR1,
			"is_autoreply": true,
			"text_id": 42,
			"text": "THIS IS BIG BOSS... WIND BARRIER IS EXTENDED ON THE ROOFTOP. LOOK FOR THE BOMBBLASTSUIT TO BE INTO THE BARRIER. ...OVER"
		},
		{
			"contact": CONTACT_SCHNEIDER,
			"freq": FREQ_SCHNEIDER_PR1,
			"is_autoreply": false,
			"text_id": 51,
			"text": "THIS IS MR. SCHNEIDER... THE BOMBBLASTSUIT CAN BE FOUND IN THE BASEMENT. ...OVER"
		}
	],
	54: [
		{
			"contact": CONTACT_BIG_BOSS,
			"freq": FREQ_BIGBOSS_PR1,
			"is_autoreply": false,
			"text_id": 60,
			"text": "THIS IS BIG BOSS... TAKE BACK YOUR GEAR AND ESCAPE! IT'S HIDDEN IN ONE OF THE ROOMS. PUNCH AROUND TO FIND IT! ...OVER"
		}
	],
	58: [
		{
			"contact": CONTACT_SCHNEIDER,
			"freq": FREQ_SCHNEIDER_PR1,
			"is_autoreply": false,
			"text_id": 64,
			"text": "THIS IS SCHNEIDER... PUNCH THE WALLS AND BOMB AREAS THAT SOUND HOLLOW. ...OVER"
		}
	],
	67: [
		{
			"contact": CONTACT_DIANE,
			"freq": FREQ_DIANE_PR1,
			"is_autoreply": false,
			"text_id": 92,
			"text": "HI. THIS IS DIANE... BEAT THE TANK WITH MINES. ...BYE"
		}
	]
}

## Sintoniza para cima em +0.01 (Banks0123.asm:10938-10945)
func tune_up() -> void:
	if current_freq < 99:
		current_freq += 1

## Sintoniza para baixo em -0.01 (Banks0123.asm:10948-10957)
func tune_down() -> void:
	if current_freq > 0:
		current_freq -= 1

## Define uma frequência diretamente (0 a 99)
func set_frequency(freq: int) -> void:
	current_freq = clampi(freq, 0, 99)

## Retorna a string formatada da frequência (ex: "120.85")
func get_frequency_string() -> String:
	return "120.%02d" % current_freq

## Retorna o nome amigável do contato sintonizado atualmente, se houver
func get_contact_name_for_freq(freq: int) -> String:
	match freq:
		FREQ_BIGBOSS_PR1, FREQ_BIGBOSS_PR2: return "BIG BOSS"
		FREQ_SCHNEIDER_PR1, FREQ_SCHNEIDER_PR2: return "SCHNEIDER"
		FREQ_DIANE_PR1, FREQ_DIANE_PR2: return "DIANE"
		FREQ_JENNIFER: return "JENNIFER"
		_: return ""

## Verifica se Snake ao entrar em uma sala recebe uma chamada automática (RADIO_AUTOREPLY)
func check_incoming_call(room_id: int) -> bool:
	if answered_rooms.has(room_id):
		return false

	var calls: Array = ROOM_CALLS.get(room_id, [])
	for call_info: Dictionary in calls:
		if bool(call_info.get("is_autoreply", false)):
			has_incoming_call = true
			print("RADIO_INCOMING_CALL: Chamada recebida na sala %d! Indicador CALL ativado." % room_id)
			return true
	return false

## Atende uma chamada recebida automática, sintoniza na frequência correta e retorna os dados do diálogo
func answer_call(room_id: int) -> Dictionary:
	has_incoming_call = false
	if not answered_rooms.has(room_id):
		answered_rooms.append(room_id)

	var calls: Array = ROOM_CALLS.get(room_id, [])
	for call_info: Dictionary in calls:
		if bool(call_info.get("is_autoreply", false)):
			current_freq = int(call_info.get("freq", FREQ_BIGBOSS_PR1))
			signal_leds = 12
			is_send_mode = false
			return {
				"has_signal": true,
				"contact": String(call_info.get("contact", CONTACT_BIG_BOSS)),
				"contact_name": get_contact_name_for_freq(current_freq),
				"freq_str": get_frequency_string(),
				"text": String(call_info.get("text", "")),
				"is_incoming": true
			}

	# Fallback
	return get_transmission_result(room_id)

## Snake solicita resposta na frequência sintonizada (modo SEND / ChkRadioReceiv em Banks0123.asm:10968)
func send_transmission(room_id: int) -> Dictionary:
	is_send_mode = true
	var result: Dictionary = get_transmission_result(room_id)
	return result

## Verifica e retorna o resultado da transmissão na sala e frequência atuais
func get_transmission_result(room_id: int) -> Dictionary:
	var calls: Array = ROOM_CALLS.get(room_id, [])
	for call_info: Dictionary in calls:
		if int(call_info.get("freq", -1)) == current_freq:
			signal_leds = 12
			return {
				"has_signal": true,
				"contact": String(call_info.get("contact", CONTACT_BIG_BOSS)),
				"contact_name": get_contact_name_for_freq(current_freq),
				"freq_str": get_frequency_string(),
				"text": String(call_info.get("text", "")),
				"is_incoming": false
			}

	# Sem ninguém na frequência não há resposta, nem do Big Boss (ChkRadioReceiv, Banks0123.asm:10971-10990)
	signal_leds = 0
	return {
		"has_signal": false,
		"contact": "",
		"contact_name": "",
		"freq_str": get_frequency_string(),
		"text": TXT_NO_RESPONSE,
		"is_incoming": false
	}
