# radio_system_test.gd
# Validação automatizada do sistema de rádio transceptor (Codec) do MSX2 RC750 (Etapa 15).
# Cobre:
# 1. Frequências canônicas da ROM (Big Boss 120.85, Schneider 120.79, Diane 120.33, Jennifer 120.48).
# 2. Sintonia decimal BCD, formatação e limites (120.00 a 120.99).
# 3. Transmissão SEND por Snake (Text ID 10: "THIS IS SOLID SNAKE... YOUR REPLY, PLEASE.").
# 4. Banco de diálogos canônicos por sala (Salas 0, 1, 5, 29, 37, 50, etc.).
# 5. Sistema de chamadas recebidas (RADIO_AUTOREPLY, flag CALL, auto-sintonia e 12 LEDs de sinal).
# 6. Integração completa do RadioDialog no SandboxGameplay (abertura, congelamento de física e fechamento).

extends SceneTree

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error("FALHA: " + message)
		printerr("FALHA: " + message)
		quit(1)
		return false
	return true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# --------------------------------------------------------------------------
	# 1. Teste de Frequências e Sintonia BCD (Banks0123.asm:10906-10958)
	# --------------------------------------------------------------------------
	var rs: RadioSystem = RadioSystem.new()
	if not require(rs.current_freq == 85, "Frequência inicial deve ser 85 (120.85)"): return
	if not require(rs.get_frequency_string() == "120.85", "String inicial deve ser '120.85'"): return
	if not require(rs.get_contact_name_for_freq(85) == "BIG BOSS", "120.85 deve mapear para BIG BOSS"): return

	# Sintonizar para cima (+0.01)
	rs.tune_up()
	if not require(rs.current_freq == 86 and rs.get_frequency_string() == "120.86", "tune_up deve ir para 120.86"): return

	# Sintonizar para baixo (-0.01)
	rs.tune_down()
	if not require(rs.current_freq == 85 and rs.get_frequency_string() == "120.85", "tune_down deve retornar para 120.85"): return

	# Limite superior (120.99)
	rs.set_frequency(99)
	rs.tune_up()
	if not require(rs.current_freq == 99, "tune_up no limite de 99 não deve ultrapassar 120.99"): return

	# Limite inferior (120.00)
	rs.set_frequency(0)
	rs.tune_down()
	if not require(rs.current_freq == 0 and rs.get_frequency_string() == "120.00", "tune_down no piso não deve descer abaixo de 120.00"): return

	# Mapeamento de nomes de contatos
	if not require(rs.get_contact_name_for_freq(79) == "SCHNEIDER", "120.79 deve mapear para SCHNEIDER"): return
	if not require(rs.get_contact_name_for_freq(33) == "DIANE", "120.33 deve mapear para DIANE"): return
	if not require(rs.get_contact_name_for_freq(48) == "JENNIFER", "120.48 deve mapear para JENNIFER"): return
	if not require(rs.get_contact_name_for_freq(50) == "", "Frequência sem contato deve retornar vazio"): return

	# --------------------------------------------------------------------------
	# 2. Teste de Transmissão SEND de Snake (Text ID 10 em texts.asm:191)
	# --------------------------------------------------------------------------
	rs.set_frequency(85) # Sintonizado em Big Boss
	var send_res: Dictionary = rs.send_transmission(0)
	if not require(rs.is_send_mode, "send_transmission deve ativar is_send_mode"): return
	if not require(bool(send_res.has_signal), "Transmissão para Big Boss na Sala 0 deve ter sinal"): return
	if not require(String(send_res.contact) == RadioSystem.CONTACT_BIG_BOSS, "Contato deve ser BIG BOSS"): return
	if not require(String(send_res.text).contains("THIS IS BIG BOSS"), "Resposta deve ser do Big Boss"): return
	if not require(rs.signal_leds == 12, "Sinal sintonizado deve ativar 12 LEDs"): return

	# --------------------------------------------------------------------------
	# 3. Teste do Banco Canônico de Diálogos por Sala (data/radiocalls.asm)
	# --------------------------------------------------------------------------
	# Sala 1: Big Boss em 120.85 e Schneider em 120.79
	rs.set_frequency(85)
	var r1_bb: Dictionary = rs.get_transmission_result(1)
	if not require(String(r1_bb.contact) == RadioSystem.CONTACT_BIG_BOSS, "Sala 1: 120.85 deve contatar Big Boss"): return
	if not require(String(r1_bb.text).contains("GAIN ACCESS TO THE ENEMY'S FORTRESS"), "Sala 1: texto de Big Boss incorreto"): return

	rs.set_frequency(79)
	var r1_sch: Dictionary = rs.get_transmission_result(1)
	if not require(String(r1_sch.contact) == RadioSystem.CONTACT_SCHNEIDER, "Sala 1: 120.79 deve contatar Schneider"): return
	if not require(String(r1_sch.text).contains("THIS IS THE RESISTANCE LEADER, MR. SCHNEIDER"), "Sala 1: texto de Schneider incorreto"): return
	if not require(String(r1_sch.text).contains("12079"), "Sala 1: texto de Schneider deve informar frequência 12079"): return

	# Sala 29 (Sala de Gás): Dica da máscara de gás de Big Boss e localização de Schneider
	rs.set_frequency(85)
	var r29_bb: Dictionary = rs.get_transmission_result(29)
	if not require(String(r29_bb.text).contains("PUT ON A GAS MASK IN THE GAS ROOM"), "Sala 29: Big Boss deve alertar sobre Gas Mask"): return

	rs.set_frequency(79)
	var r29_sch: Dictionary = rs.get_transmission_result(29)
	if not require(String(r29_sch.text).contains("GO TO THE SOUTH PART OF THE 1ST FLOOR TO GET YOUR MASK"), "Sala 29: Schneider deve dar a localização"): return

	# Frequência incorreta / Sem contato
	rs.set_frequency(55)
	var r29_empty: Dictionary = rs.get_transmission_result(29)
	if not require(not bool(r29_empty.has_signal), "Frequência não cadastrada deve ter has_signal = false"): return
	if not require(String(r29_empty.text) == RadioSystem.TXT_NO_RESPONSE, "Frequência sem contato deve retornar estática"): return
	if not require(rs.signal_leds == 0, "Sem sinal os LEDs de sinal devem ser 0"): return

	# --------------------------------------------------------------------------
	# 4. Teste de Chamada Recebida Automática (RADIO_AUTOREPLY / Indicador CALL)
	# --------------------------------------------------------------------------
	rs.answered_rooms.clear()
	var incoming: bool = rs.check_incoming_call(0)
	if not require(incoming and rs.has_incoming_call, "Sala 0 deve disparar chamada recebida automática"): return

	# Atendimento automático (auto-sintoniza e marca como atendida)
	rs.set_frequency(0) # Desintonizado
	var answered: Dictionary = rs.answer_call(0)
	if not require(bool(answered.has_signal), "Chamada atendida deve ter sinal"): return
	if not require(rs.current_freq == 85, "Atender chamada na Sala 0 deve auto-sintonizar em 120.85"): return
	if not require(not rs.has_incoming_call, "has_incoming_call deve ser false após atendimento"): return
	if not require(rs.signal_leds == 12, "Chamada atendida deve ter 12 LEDs de sinal"): return

	# Segunda checagem na mesma sala não deve redisparar chamada atendida
	var repeat_call: bool = rs.check_incoming_call(0)
	if not require(not repeat_call and not rs.has_incoming_call, "Sala já atendida não deve gerar nova chamada"): return

	# --------------------------------------------------------------------------
	# 5. Teste de Integração no SandboxGameplay
	# --------------------------------------------------------------------------
	var sandbox_scene: PackedScene = preload("res://scenes/sandbox_gameplay.tscn")
	var sandbox: Control = sandbox_scene.instantiate() as Control
	root.add_child(sandbox)
	await process_frame
	await process_frame

	if not require(sandbox.radio_dialog != null, "Sandbox deve instanciar radio_dialog"): return
	if not require(not sandbox.radio_dialog.is_active, "RadioDialog inicial deve estar inativo"): return
	if not require(not sandbox.radio_dialog.visible, "RadioDialog inicial deve estar invisível"): return

	# Carregar Sala 0 no Sandbox (deve ativar CALL)
	sandbox.radio_system.answered_rooms.clear()
	var loaded_0: bool = sandbox.change_to_room(0, Vector2(128.0, 100.0), PlayerController.Direction.UP)
	if not require(loaded_0, "Sala 0 deve carregar no sandbox"): return
	if not require(sandbox.radio_system.has_incoming_call, "Entrar na Sala 0 deve ativar has_incoming_call"): return

	# Simular pressionamento da tecla T / F4 para abrir o rádio
	var key_t := InputEventKey.new()
	key_t.keycode = KEY_T
	key_t.pressed = true
	sandbox._input(key_t)

	if not require(sandbox.radio_dialog.is_active, "Pressionar T deve ativar radio_dialog"): return
	if not require(sandbox.radio_dialog.visible, "RadioDialog deve ficar visível"): return
	if not require(not sandbox.radio_system.has_incoming_call, "Abrir o rádio com CALL deve consumir a chamada"): return
	if not require(sandbox.radio_system.current_freq == 85, "Rádio deve estar auto-sintonizado em 120.85"): return

	# Validar paginação canônica de no máximo 4 linhas (Banks0123.asm:8344, 8377)
	if not require(sandbox.radio_dialog.dialog_pages.size() >= 2, "Mensagem longa de Big Boss deve ser auto-paginada em pelo menos 2 páginas"): return
	for p_idx: int in range(sandbox.radio_dialog.dialog_pages.size()):
		var page_str: String = sandbox.radio_dialog.dialog_pages[p_idx]
		var line_count: int = page_str.split("\n").size()
		if not require(line_count <= 4, "Cada página de rádio deve ter no máximo 4 linhas (Página %d tem %d linhas)" % [p_idx, line_count]): return

	# Testar avanço de página com Enter/Espaço
	var key_enter := InputEventKey.new()
	key_enter.keycode = KEY_ENTER
	key_enter.pressed = true
	# 1º Enter: conclui digitação da página 0
	sandbox._input(key_enter)
	if not require(sandbox.radio_dialog.text_finished, "1º Enter deve concluir digitação da página atual"): return
	# 2º Enter: avança para a página 1
	sandbox._input(key_enter)
	if not require(sandbox.radio_dialog.current_page_index == 1, "2º Enter deve avançar para a próxima página"): return

	# Testar congelamento da física durante o rádio
	var player_initial_y: float = sandbox.player.position.y
	sandbox._physics_process(0.016)
	if not require(is_equal_approx(sandbox.player.position.y, player_initial_y), "Física do jogador deve ficar pausada enquanto o rádio estiver ativo"): return

	# Simular sintonia no diálogo (tecla D -> tune_up)
	var key_d := InputEventKey.new()
	key_d.keycode = KEY_D
	key_d.pressed = true
	sandbox._input(key_d)
	if not require(sandbox.radio_system.current_freq == 86, "Tecla D no rádio deve sintonizar para 120.86"): return

	# Simular transmissão SEND no diálogo (tecla W -> send)
	var key_w := InputEventKey.new()
	key_w.keycode = KEY_W
	key_w.pressed = true
	sandbox._input(key_w)
	if not require(sandbox.radio_system.is_send_mode, "Tecla W no rádio deve ativar modo SEND"): return

	# Fechar rádio com T
	sandbox._input(key_t)
	if not require(not sandbox.radio_dialog.is_active, "Pressionar T novamente deve fechar o rádio"): return
	if not require(not sandbox.radio_dialog.visible, "RadioDialog deve ficar invisível após fechar"): return

	sandbox.queue_free()

	print("RADIO_SYSTEM_OK: frequências canônicas, sintonia BCD, transmissão SEND, banco de diálogos por sala, chamadas autoreply e integração SandboxGameplay validados")
	quit(0)
