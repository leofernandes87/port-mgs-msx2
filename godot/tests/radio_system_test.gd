# radio_system_test.gd
# Radio dialogue core, tick by tick against the English edition:
# - ChkIncomingCall (logic/incomingcall.asm:10-36): 32-tick delay, then 88-tick CALL
# - RadioLogic (Banks0123.asm:10676-10853): auto reply, WAIT-CALL after SEND, 12 LEDs (first delay 10h, step 2)
# - ChgRadioFreq (Banks0123.asm:10904-10953): BCD tuning, press delay 8, repeat every 2 ticks
# - ChkRadioReply (Banks0123.asm:11047-11165): antenna, transmitter, Schneider, Jennifer, Madnar conditions
# Synthetic persons; the extracted table is only cross-checked when data/extracted exists.

extends SceneTree

var _texts: Array[int] = []

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error("FALHA: " + message)
		printerr("FALHA: " + message)
		quit(1)
		return false
	return true

func _init() -> void:
	call_deferred("_run")

func _person(person_id: int, freq: int, wait_call: bool, text_id: int) -> Dictionary:
	return {"person": person_id, "freq": freq, "wait_call": wait_call, "auto_tune": false, "text_id": text_id}

func _new_radio(persons: Array[Dictionary], freq: int) -> RadioSystem:
	var rs := RadioSystem.new()
	rs.persons = persons
	rs.current_freq = freq
	rs.text_requested.connect(func(text_id: int) -> void: _texts.append(text_id))
	_texts.clear()
	rs.open_radio()
	return rs

func _idle(rs: RadioSystem, ticks: int) -> void:
	for i: int in range(ticks):
		rs.radio_tick(false, false, false, false, false)

func _run() -> void:
	# 1. BCD tuning (DAA): 0x89 + 1 = 0x90, 0x90 - 1 = 0x89, limits 0x00 and 0x99.
	if not require(RadioSystem.bcd_increment(0x89) == 0x90, "0x89 + 1 deve ser 0x90"): return
	if not require(RadioSystem.bcd_decrement(0x90) == 0x89, "0x90 - 1 deve ser 0x89"): return
	if not require(RadioSystem.bcd_increment(0x99) == 0x99, "0x99 é o limite superior"): return
	if not require(RadioSystem.bcd_decrement(0x00) == 0x00, "0x00 é o limite inferior"): return
	var tuner := _new_radio([], 0x85)
	if not require(tuner.get_frequency_string() == "120.85", "Frequência exibida 120.85"): return
	tuner.radio_tick(false, false, true, false, true)
	if not require(tuner.current_freq == 0x86, "Pressionar direita sobe imediatamente"): return
	for i: int in range(7):
		tuner.radio_tick(false, false, false, false, true)
	if not require(tuner.current_freq == 0x86, "Segurar não repete antes de 8 ticks"): return
	tuner.radio_tick(false, false, false, false, true)
	if not require(tuner.current_freq == 0x87, "8º tick segurando repete"): return
	tuner.radio_tick(false, false, false, false, true)
	tuner.radio_tick(false, false, false, false, true)
	if not require(tuner.current_freq == 0x88, "Repetição a cada 2 ticks"): return
	tuner.radio_tick(false, true, true, true, true)
	if not require(tuner.current_freq == 0x87, "Esquerda tem prioridade"): return

	# 2. Incoming call: flag 0 for 32 ticks, CALL from tick 32 to tick 118, stopped at tick 119.
	var caller := RadioSystem.new()
	caller.radio_call_flag = RadioSystem.CALL_PENDING
	caller.incoming_call_timer = RadioSystem.INCOMING_CALL_BIT * 4
	for i: int in range(31):
		caller.tick_incoming_call()
	if not require(not caller.has_incoming_call and caller.incoming_call_timer == 1, "Atraso de 32 ticks antes do CALL"): return
	caller.tick_incoming_call()
	if not require(caller.has_incoming_call and caller.incoming_call_timer == 0x57, "CALL começa com 58h e decrementa no mesmo tick"): return
	for i: int in range(86):
		caller.tick_incoming_call()
	if not require(caller.has_incoming_call, "CALL ainda ativo no tick 118"): return
	caller.tick_incoming_call()
	if not require(caller.radio_call_flag == RadioSystem.CALL_STOPPED, "CALL termina no tick 119"): return
	caller.force_pending_call()
	if not require(caller.radio_call_flag == RadioSystem.CALL_PENDING and caller.incoming_call_timer == 0x10, "Antena força chamada com atraso 10h"): return
	caller.has_incoming_call = true
	caller.open_radio()
	if not require(caller.radio_call_flag == RadioSystem.CALL_STOPPED, "DrawRadio para o CALL"): return

	# 3. Auto reply: 1 tick to detect, 16 ticks to the first LED, 22 more ticks to 12 LEDs, then the text.
	var auto := _new_radio([_person(1, 0x85, false, 3)], 0x85)
	auto.radio_tick(false, false, false, false, false)
	if not require(auto.state == RadioSystem.State.SIGNAL_UP and auto.signal_leds == 0, "Auto reply detectado no primeiro tick"): return
	_idle(auto, 16)
	if not require(auto.signal_leds == 1, "Primeiro LED após 10h ticks"): return
	_idle(auto, 22)
	if not require(auto.signal_leds == 12 and auto.state == RadioSystem.State.SETUP_REPLY, "12 LEDs com passo de 2 ticks"): return
	if not require(_texts.is_empty(), "Texto só abre no SetupRadioReply"): return
	_idle(auto, 1)
	if not require(_texts == [3] and auto.waiting_text, "Resposta abre o texto da pessoa"): return
	_idle(auto, 10)
	if not require(auto.state == RadioSystem.State.SIGNAL_OFF, "Janela de texto suspende o RadioLogic"): return
	auto.text_closed()
	_idle(auto, 1)
	if not require(auto.auto_reply_done and auto.signal_leds == 0 and auto.state == RadioSystem.State.IDLE, "RadioSignalOFF marca AutoReplyDone"): return
	_idle(auto, 30)
	if not require(_texts == [3], "Auto reply não se repete sem mudar frequência"): return
	auto.radio_tick(false, true, false, true, false)
	auto.radio_tick(false, false, true, false, true)
	if not require(not auto.auto_reply_done and auto.state == RadioSystem.State.SIGNAL_UP, "Ressintonizar reabilita o auto reply"): return

	# 4. WAIT-CALL: silent until SEND (text 0Ah), then replies.
	var wait := _new_radio([_person(2, 0x79, true, 23)], 0x79)
	_idle(wait, 5)
	if not require(wait.state == RadioSystem.State.IDLE and _texts.is_empty(), "WAIT-CALL não responde sem SEND"): return
	wait.radio_tick(true, false, false, false, false)
	if not require(_texts == [RadioSystem.TEXT_SEND] and wait.is_send_mode and wait.reply_requested, "SEND abre o texto 0Ah"): return
	wait.text_closed()
	_idle(wait, 1)
	if not require(wait.state == RadioSystem.State.SIGNAL_UP and not wait.is_send_mode, "Resposta após SEND"): return
	_idle(wait, 39)
	if not require(_texts == [RadioSystem.TEXT_SEND, 23] and wait.reply_contact() == RadioSystem.CONTACT_SCHNEIDER, "Schneider responde após SEND"): return

	# 5. ChkRadioReply conditions.
	var zone := _new_radio([_person(1, 0x85, false, 3)], 0x85)
	zone.map_zone = 5
	_idle(zone, 1)
	if not require(zone.state == RadioSystem.State.IDLE, "Zona >= 5 sem antena não responde"): return
	zone.antenna_taken = true
	_idle(zone, 1)
	if not require(zone.state == RadioSystem.State.SIGNAL_UP, "Zona >= 5 com antena responde"): return
	var bug := _new_radio([_person(1, 0x85, false, 3)], 0x85)
	bug.transmitter_taken = true
	_idle(bug, 41)
	if not require(_texts == [RadioSystem.TEXT_BUG_WARNING], "Big Boss avisa do transmissor fora da zona 4"): return
	var msx := _new_radio([_person(1, 0x85, false, 3)], 0x85)
	msx.switch_off_msx = true
	msx.transmitter_taken = true
	_idle(msx, 41)
	if not require(_texts == [RadioSystem.TEXT_SWITCH_OFF_MSX], "SwitchOffMSXF tem prioridade"): return
	var captured := _new_radio([_person(2, 0x79, false, 23)], 0x79)
	captured.schneider_captured = true
	_idle(captured, 1)
	if not require(captured.state == RadioSystem.State.IDLE, "Schneider capturado não responde"): return
	var jennifer := _new_radio([_person(6, 0x48, false, 40)], 0x48)
	jennifer.class_rank = 2
	_idle(jennifer, 1)
	if not require(jennifer.state == RadioSystem.State.IDLE, "Jennifer exige classe 4 estrelas"): return
	jennifer.class_rank = RadioSystem.CLASS_FOUR_STARS
	_idle(jennifer, 1)
	if not require(jennifer.state == RadioSystem.State.SIGNAL_UP, "Jennifer responde com 4 estrelas"): return
	var madnar := _new_radio([_person(3, 0x33, false, RadioSystem.TEXT_MADNAR_CHECK)], 0x33)
	madnar.madnar_moved = true
	_idle(madnar, 1)
	if not require(madnar.state == RadioSystem.State.IDLE, "Texto 15 some após Madnar ser movido"): return

	# 6. Extracted table and sandbox integration (only with data/extracted present).
	if RadioSystem.data().is_empty():
		print("RADIO_SYSTEM_OK: núcleo validado (radio_dialogue.json ausente; integração ignorada)")
		quit(0)
		return
	var room0 := RadioSystem.new()
	room0.current_freq = 0x00
	room0.enter_room(0)
	if not require(room0.current_freq == RadioSystem.FREQ_BIGBOSS_PR1, "Sala 0 auto-sintoniza Big Boss"): return
	if not require(room0.radio_call_flag == RadioSystem.CALL_PENDING and room0.incoming_call_timer == 32, "Sala 0 tem chamada recebida"): return
	if not require(not RadioSystem.text_pages(int(room0.persons[0]["text_id"])).is_empty(), "Texto da sala 0 extraído"): return

	var sandbox: Control = (preload("res://scenes/sandbox_gameplay.tscn") as PackedScene).instantiate() as Control
	root.add_child(sandbox)
	await process_frame
	await process_frame
	if not require(sandbox.change_to_room(0, Vector2(128.0, 100.0), PlayerController.Direction.UP), "Sala 0 deve carregar"): return
	if not require(sandbox.radio_system.radio_call_flag == RadioSystem.CALL_PENDING, "Entrar na sala 0 arma o CALL"): return
	var key_t := InputEventKey.new()
	key_t.keycode = KEY_T
	key_t.pressed = true
	sandbox._input(key_t)
	var dialog: RadioDialog = sandbox.radio_dialog
	if not require(dialog.is_active and sandbox.radio_system.radio_call_flag == RadioSystem.CALL_STOPPED, "Abrir o rádio para o CALL"): return
	for i: int in range(40):
		dialog._physics_process(1.0 / 60.0)
	if not require(dialog.is_showing_text() and not dialog.dialog_pages.is_empty(), "Auto reply abre o texto no diálogo"): return
	var key_enter := InputEventKey.new()
	key_enter.keycode = KEY_ENTER
	key_enter.pressed = true
	for i: int in range(dialog.dialog_pages.size() * 2):
		sandbox._input(key_enter)
	if not require(not dialog.is_showing_text() and dialog.is_active, "Última página devolve ao RadioLogic"): return
	sandbox._input(key_t)
	if not require(not dialog.is_active, "T fecha o rádio"): return
	sandbox.queue_free()

	print("RADIO_SYSTEM_OK: CALL 32/88 ticks, BCD, auto reply, WAIT-CALL, condições e integração validados")
	quit(0)
