class_name RadioSystem
extends RefCounted

## Radio dialogue core, ported tick by tick from the English edition:
## - UpdateRadio/RadioFreqs (Banks0123.asm:2379-2461) and SetRadioArea (1060-1068) on every room setup
##   (NextRoomLogic 11847-11856, InitGame 11826-11832)
## - ChkRadioCalls (Banks0123.asm:1688-1745) and ChkIncomingCall (logic/incomingcall.asm:10-36, called from
##   PlayModeLogic 12162); antenna pickup forces a pending call (logic/items.asm:163-170)
## - RadioLogic states (Banks0123.asm:10676-10853): DrawRadio, RadioIdle, RadioSignalUp, SetupRadioReply,
##   RadioSignalOFF; ChgRadioFreq (10904-10953), ChkRadioReceiv/RadioAutoReply (10965-11039),
##   ChkRadioReply (11047-11165)
## Table, map zones, incoming-call rooms and texts come from tools/extractors/extract_radio_dialogue.py.

signal text_requested(text_id: int)
signal sfx_requested(sfx_id: int)

enum State { DRAW, IDLE, SIGNAL_UP, SETUP_REPLY, SIGNAL_OFF }

const CONTACT_BIG_BOSS: String = "BIG_BOSS"
const CONTACT_SCHNEIDER: String = "SCHNEIDER"
const CONTACT_DIANE: String = "DIANE"
const CONTACT_JENNIFER: String = "JENNIFER"
## Person IDs 1-7 of data/radiocalls.asm:13-20 (index 0 unused).
const PERSON_CONTACTS: Array[String] = ["", CONTACT_BIG_BOSS, CONTACT_SCHNEIDER, CONTACT_DIANE,
	CONTACT_SCHNEIDER, CONTACT_DIANE, CONTACT_JENNIFER, CONTACT_BIG_BOSS]

## RadioFreq is BCD (constants/Enums.asm:15-22).
const FREQ_BIGBOSS_PR1: int = 0x85
const FREQ_BIGBOSS_PR2: int = 0x13
const FREQ_SCHNEIDER_PR1: int = 0x79
const FREQ_SCHNEIDER_PR2: int = 0x26
const FREQ_DIANE_PR1: int = 0x33
const FREQ_DIANE_PR2: int = 0x91
const FREQ_JENNIFER: int = 0x48
const FREQ_MAX: int = 0x99

## RadioCallFlag: 0 = delay running, 1 = CALL in progress, 2 = stopped.
const CALL_PENDING: int = 0
const CALL_RINGING: int = 1
const CALL_STOPPED: int = 2
const INCOMING_CALL_BIT: int = 0x08
const CALL_DURATION: int = 0x58
const ANTENNA_CALL_DELAY: int = 0x10

const LED_COUNT: int = 12
const LED_FIRST_DELAY: int = 0x10
const LED_STEP_DELAY: int = 2
const FREQ_PRESS_DELAY: int = 8
const FREQ_REPEAT_DELAY: int = 2

const MAP_ZONE_NEEDS_ANTENNA: int = 5
const MAP_ZONE_BUILDING1_BASEMENT: int = 4
const CLASS_FOUR_STARS: int = 3

const SFX_INCOMING_CALL: int = 0x22
const SFX_RADIO_NOISE: int = 0x50
const SFX_MUTE: int = 0x5C
const TEXT_SEND: int = 0x0A
const TEXT_BUG_WARNING: int = 50
const TEXT_SWITCH_OFF_MSX: int = 136
const TEXT_MADNAR_CHECK: int = 15

const DATA_PATH: String = "radio/radio_dialogue.json"

var current_freq: int = FREQ_BIGBOSS_PR1
var is_send_mode: bool = false        # RadioCmd
var reply_requested: bool = false
var auto_reply_done: bool = false
var state: State = State.IDLE
var signal_leds: int = 0              # RadioLedCnt
var led_delay: int = 0
var hold_wait: int = 0                # ControlHoldWait
var reply_person: Dictionary = {}
var waiting_text: bool = false        # GAME_MODE_TEXT_BOX suspends RadioLogic
var persons: Array[Dictionary] = []   # RadioPersonsDat[0..NumRadioPersons-1]
var first_person_freq: int = 0        # RadioPersonsDat+0 is not cleared when a room has no radio
var radio_call_flag: int = CALL_STOPPED
var incoming_call_timer: int = 0
var map_zone: int = 0

var antenna_taken: bool = false
var transmitter_taken: bool = false
var schneider_captured: bool = false
var jennifer_brother_dead: bool = false
var madnar_moved: bool = false
var switch_off_msx: bool = false
var class_rank: int = 0

var has_incoming_call: bool:
	get:
		return radio_call_flag == CALL_RINGING
	set(value):
		radio_call_flag = CALL_RINGING if value else CALL_STOPPED

static var _data: Dictionary = {}
static var _data_loaded: bool = false

static func data() -> Dictionary:
	if not _data_loaded:
		_data_loaded = true
		_data = RomProvenance.load_canonical_json(DATA_PATH)
		if _data.is_empty():
			push_warning("RadioSystem: rode tools/extractors/extract_radio_dialogue.py para gerar %s" % DATA_PATH)
	return _data

## Pages of a text ID, each page with its FE line breaks as "\n" (DecodeText, Banks0123.asm:5305-5340).
static func text_pages(text_id: int) -> Array[String]:
	var pages: Array[String] = []
	var entry: Dictionary = data().get("texts", {}).get(str(text_id), {})
	for page: Variant in entry.get("pages", []):
		pages.append("\n".join(PackedStringArray(page as Array)))
	return pages

static func room_persons(room_id: int) -> Array:
	var rooms: Array = data().get("rooms", [])
	return rooms[room_id] if room_id >= 0 and room_id < rooms.size() else []

static func room_has_incoming_call(room_id: int) -> bool:
	for room: Variant in data().get("incoming_call_rooms", []):
		if int(room) == room_id:
			return true
	return false

static func room_map_zone(room_id: int) -> int:
	var zones: Array = data().get("map_zones", [])
	return int(zones[room_id]) if room_id >= 0 and room_id < zones.size() else 0

static func bcd_increment(freq: int) -> int:
	if freq == FREQ_MAX:
		return freq
	return freq + 7 if (freq & 0x0F) == 9 else freq + 1

static func bcd_decrement(freq: int) -> int:
	if freq == 0:
		return freq
	return freq - 7 if (freq & 0x0F) == 0 else freq - 1

func get_frequency_string() -> String:
	return "120.%02X" % current_freq

func set_frequency(freq: int) -> void:
	current_freq = clampi(freq, 0, FREQ_MAX)

func get_contact_name_for_freq(freq: int) -> String:
	for person: Dictionary in persons:
		if int(person["freq"]) == freq:
			return String(PERSON_CONTACTS[int(person["person"])]).replace("_", " ")
	return ""

func reply_contact() -> String:
	return PERSON_CONTACTS[int(reply_person.get("person", 0))]

## NextRoomLogic: SetRadioArea + UpdateRadio, then SetAreaMusic2 -> ChkRadioCalls.
func enter_room(room_id: int) -> void:
	update_radio(room_id)
	check_radio_calls(room_id)

func update_radio(room_id: int) -> void:
	map_zone = room_map_zone(room_id)
	persons.clear()
	for entry: Variant in room_persons(room_id):
		var person: Dictionary = (entry as Dictionary).duplicate()
		persons.append(person)
		if bool(person["auto_tune"]):
			current_freq = int(person["freq"])
	if not persons.is_empty():
		first_person_freq = int(persons[0]["freq"])

func check_radio_calls(room_id: int) -> void:
	var flag: int = CALL_STOPPED
	var blocked: bool = false
	if schneider_captured and first_person_freq in [FREQ_SCHNEIDER_PR1, FREQ_SCHNEIDER_PR2]:
		blocked = true
	elif first_person_freq == FREQ_JENNIFER and (class_rank != CLASS_FOUR_STARS or jennifer_brother_dead):
		blocked = true
	elif map_zone >= MAP_ZONE_NEEDS_ANTENNA and not antenna_taken:
		blocked = true
	if not blocked and room_has_incoming_call(room_id):
		incoming_call_timer = INCOMING_CALL_BIT * 4
		flag = CALL_PENDING
	radio_call_flag = flag

func tick_incoming_call() -> void:
	if incoming_call_timer == 0 or radio_call_flag == CALL_STOPPED:
		return
	if radio_call_flag == CALL_PENDING:
		incoming_call_timer -= 1
		if incoming_call_timer != 0:
			return
		incoming_call_timer = CALL_DURATION
		radio_call_flag = CALL_RINGING
	incoming_call_timer -= 1
	if incoming_call_timer == 0:
		radio_call_flag = CALL_STOPPED

func force_pending_call() -> void:
	incoming_call_timer = ANTENNA_CALL_DELAY
	radio_call_flag = CALL_PENDING

## DrawRadio: stops the CALL and erases RadioCmd..RadioCmd+10h (AutoReplyDone and ReplyRequested included).
func open_radio() -> void:
	radio_call_flag = CALL_STOPPED
	is_send_mode = false
	signal_leds = 0
	led_delay = 0
	reply_person = {}
	auto_reply_done = false
	reply_requested = false
	waiting_text = false
	state = State.IDLE
	sfx_requested.emit(SFX_RADIO_NOISE)

## One RadioLogic iteration. Triggers are new presses; holds are keys kept down (ControlsTrigger/Hold).
func radio_tick(up_trigger: bool, left_trigger: bool, right_trigger: bool, left_hold: bool, right_hold: bool) -> void:
	if waiting_text:
		return
	match state:
		State.IDLE:
			if is_send_mode:
				sfx_requested.emit(SFX_RADIO_NOISE)
			if up_trigger:
				is_send_mode = true
				reply_requested = true
				sfx_requested.emit(SFX_MUTE)
				_request_text(TEXT_SEND)
				return
			is_send_mode = false
			_change_frequency(left_trigger, right_trigger, left_hold, right_hold)
			_check_receive()
		State.SIGNAL_UP:
			led_delay -= 1
			if led_delay != 0:
				return
			led_delay = LED_STEP_DELAY
			signal_leds += 1
			if signal_leds == LED_COUNT:
				state = State.SETUP_REPLY
		State.SETUP_REPLY:
			state = State.SIGNAL_OFF
			sfx_requested.emit(SFX_MUTE)
			_request_text(int(reply_person["text_id"]))
		State.SIGNAL_OFF:
			reply_requested = false
			signal_leds = 0
			auto_reply_done = true
			state = State.IDLE
			sfx_requested.emit(SFX_RADIO_NOISE)

func text_closed() -> void:
	waiting_text = false

func _request_text(text_id: int) -> void:
	waiting_text = true
	text_requested.emit(text_id)

func _change_frequency(left_trigger: bool, right_trigger: bool, left_hold: bool, right_hold: bool) -> void:
	var left: bool
	if left_trigger or right_trigger:
		auto_reply_done = false
		reply_requested = false
		hold_wait = FREQ_PRESS_DELAY
		left = left_trigger
	elif left_hold or right_hold:
		hold_wait = (hold_wait - 1) & 0xFF
		if hold_wait != 0:
			return
		hold_wait = FREQ_REPEAT_DELAY
		left = left_hold
	else:
		return
	current_freq = bcd_decrement(current_freq) if left else bcd_increment(current_freq)

func _check_receive() -> void:
	for person: Dictionary in persons:
		if int(person["freq"]) != current_freq:
			continue
		if not bool(person["wait_call"]):
			if auto_reply_done:
				return
		elif not reply_requested:
			continue
		if not _reply_allowed(person):
			return
		reply_person = person
		state = State.SIGNAL_UP
		led_delay = LED_FIRST_DELAY
		return

func _reply_allowed(person: Dictionary) -> bool:
	var text_id: int = int(person["text_id"])
	var freq: int = int(person["freq"])
	if map_zone >= MAP_ZONE_NEEDS_ANTENNA and not antenna_taken:
		return false
	var big_boss: bool = freq in [FREQ_BIGBOSS_PR1, FREQ_BIGBOSS_PR2]
	if big_boss and switch_off_msx:
		person["text_id"] = TEXT_SWITCH_OFF_MSX
		return true
	if big_boss and transmitter_taken and map_zone != MAP_ZONE_BUILDING1_BASEMENT:
		person["text_id"] = TEXT_BUG_WARNING
		return true
	if freq in [FREQ_SCHNEIDER_PR1, FREQ_SCHNEIDER_PR2]:
		return not schneider_captured
	if freq == FREQ_JENNIFER:
		return class_rank == CLASS_FOUR_STARS and not jennifer_brother_dead
	if text_id == TEXT_MADNAR_CHECK:
		return not madnar_moved
	return true
