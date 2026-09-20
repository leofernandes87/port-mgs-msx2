extends SceneTree

## Suíte de testes headless para Máquina de Estados de Alerta Global, Evasão e Reforços Militares (Etapa 17).
## Valida:
## 1. Ciclo de 3 estados: NORMAL, ALERT e EVASION.
## 2. Contingente de reforços baseado no nível do cartão: NumRespawnGuards = CardLevel + 3.
## 3. Geração de reforços nas coordenadas canônicas da ROM (RespawnInfo offset 0xC445).
## 4. Transição automática ALERT -> EVASION quando Snake sai da linha de visão.
## 5. Temporizador regressivo da EVASÃO e reativação imediata para ALERTA ao ser reavistado.
## 6. Conclusão da Evasão e retorno ao modo NORMAL ao zerar o cronômetro.
## 7. Cancelamento imediato do alarme ao entrar em elevador (salas >= 240).

func _init() -> void:
	print("--- TESTE: MÁQUINA DE ESTADOS DE ALERTA GLOBAL, EVASÃO E REFORÇOS (ETAPA 17) ---")

	test_alert_initial_state()
	test_trigger_alert_and_card_quotas()
	test_reinforcement_respawn_cycle()
	test_alert_to_evasion_transition()
	test_evasion_countdown_and_realert()
	test_evasion_completion_to_normal()
	test_elevator_immediate_cancellation()

	print("ALERT_SYSTEM_OK: ciclo de 3 estados (Normal/Alerta/Evasao), cotas de cartao, respawn canonico da ROM, evasao regressiva e cancelamento por elevador validados")
	quit(0)

func test_alert_initial_state() -> void:
	var alert_sys := AlertSystem.new()
	assert(alert_sys.current_state == AlertSystem.AlertState.NORMAL, "Estado inicial deve ser NORMAL (0)")
	assert(not alert_sys.is_red_alert, "Alerta vermelho deve iniciar falso")
	assert(alert_sys.num_respawn_guards == 0, "Sem reforços pendentes no estado inicial")
	print("ALERT_INITIAL_OK: estado NORMAL e parâmetros limpos conferidos")

func test_trigger_alert_and_card_quotas() -> void:
	var alert_sys := AlertSystem.new()

	# Sem cartão (nível 0) -> mínimo 3 soldados (setalert.asm:36)
	alert_sys.trigger_alert(false, 0, 1)
	assert(alert_sys.current_state == AlertSystem.AlertState.ALERT, "Deve transitar para ALERT")
	assert(alert_sys.num_respawn_guards == 3, "Nível 0 deve gerar mínimo de 3 reforços (0 + 3)")
	assert(not alert_sys.is_red_alert, "Alerta regular não deve ser Red Alert")

	alert_sys.stop_alert()

	# Com Card 1 -> 4 soldados (1 + 3)
	alert_sys.trigger_alert(false, 1, 1)
	assert(alert_sys.num_respawn_guards == 4, "Card 1 deve conceder cota de 4 reforços (1 + 3)")

	alert_sys.stop_alert()

	# Com Card 4 e câmera/laser (Red Alert) -> 7 soldados (4 + 3)
	alert_sys.trigger_alert(true, 4, 1)
	assert(alert_sys.num_respawn_guards == 7, "Card 4 deve conceder cota de 7 reforços (4 + 3)")
	assert(alert_sys.is_red_alert, "Câmeras e lasers devem ativar Red Alert")

	print("ALERT_QUOTAS_OK: cotas de reforço baseadas em cartões (mínimo 3) e Red Alert validados")

func test_reinforcement_respawn_cycle() -> void:
	var alert_sys := AlertSystem.new()
	alert_sys.trigger_alert(false, 1, 1) # Sala 1, cota = 4

	var spawned_guards: Array[Dictionary] = []
	alert_sys.reinforcement_requested.connect(func(eid: int, pos: Vector2) -> void:
		spawned_guards.append({"enemy_id": eid, "pos": pos})
	)

	# Simular 20 ticks com visada ativa sobre Snake (espera o delay inicial de 20 ticks)
	for i in range(19):
		alert_sys.tick(true, 0, 1)
	assert(spawned_guards.is_empty(), "Não deve spawnar antes do término do delay de respawn")

	# Tick 20: Primeiro soldado convocado na Sala 1
	alert_sys.tick(true, 0, 1)
	assert(spawned_guards.size() == 1, "Deve convocar 1 soldado no tick 20")
	assert(spawned_guards[0]["enemy_id"] == 10, "Soldado da Sala 1 deve ser ID 10 (GUARD_ALERT)")
	assert(spawned_guards[0]["pos"] == Vector2(64.0, 16.0), "Ponto 1 da Sala 1 deve ser (64, 16)")
	assert(alert_sys.num_respawn_guards == 3, "Cota de reforços deve diminuir para 3")

	# Simular mais 24 ticks (intervalo canônico RESPAWN_INTERVAL)
	for i in range(24):
		alert_sys.tick(true, 1, 1)
	assert(spawned_guards.size() == 2, "Deve convocar 2º soldado após 24 ticks")
	assert(spawned_guards[1]["pos"] == Vector2(240.0, 144.0), "Ponto 2 da Sala 1 deve ser (240, 144)")
	assert(alert_sys.num_respawn_guards == 2, "Cota de reforços deve diminuir para 2")

	print("ALERT_RESPAWN_OK: ciclo de 24 ticks e pontos de borda da ROM validados")

func test_alert_to_evasion_transition() -> void:
	var alert_sys := AlertSystem.new()
	alert_sys.trigger_alert(false, 1, 1)

	var transitions: Array[Dictionary] = []
	alert_sys.state_changed.connect(func(old_s: AlertSystem.AlertState, new_s: AlertSystem.AlertState) -> void:
		transitions.append({"old": old_s, "new": new_s})
	)

	# Soldados perdem linha de visão de Snake (ex: Snake se escondeu atrás de obstáculo)
	alert_sys.tick(false, 1, 1)
	assert(alert_sys.current_state == AlertSystem.AlertState.EVASION, "Deve transitar imediatamente para EVASION quando Snake sai de vista")
	assert(alert_sys.evasion_timer == AlertSystem.EVASION_COUNTDOWN_TICKS, "Temporizador de evasão deve iniciar em 99")
	assert(transitions.size() == 1 and transitions[0]["new"] == AlertSystem.AlertState.EVASION, "Sinal state_changed deve ser emitido para EVASION")

	print("ALERT_TO_EVASION_OK: transição instantânea para Evasão ao perder visada validada")

func test_evasion_countdown_and_realert() -> void:
	var alert_sys := AlertSystem.new()
	alert_sys.trigger_alert(false, 1, 1)
	alert_sys.tick(false, 1, 1) # Entra em EVASION

	# 10 ticks em evasão sem visada -> decrementa o timer
	for i in range(10):
		alert_sys.tick(false, 1, 1)
	assert(alert_sys.evasion_timer == 89, "Temporizador deve decrementar a cada tick em evasão (99 -> 89)")

	# Snake é reavistado por um soldado durante a busca!
	alert_sys.tick(true, 1, 1)
	assert(alert_sys.current_state == AlertSystem.AlertState.ALERT, "Deve retornar imediatamente para ALERT ao ser reavistado")
	assert(alert_sys.evasion_timer == AlertSystem.EVASION_COUNTDOWN_TICKS, "Temporizador de evasão deve ser restaurado para 99")

	print("EVASION_REALERT_OK: contagem regressiva e reativação imediata do alerta validadas")

func test_evasion_completion_to_normal() -> void:
	var alert_sys := AlertSystem.new()
	alert_sys.trigger_alert(false, 1, 1)
	alert_sys.tick(false, 1, 1) # Entra em EVASION

	# Simular até o cronômetro esgotar completamente (89 + 10 = 99 ticks)
	for i in range(99):
		alert_sys.tick(false, 1, 1)

	assert(alert_sys.current_state == AlertSystem.AlertState.NORMAL, "Após zerar cronômetro de evasão, deve retornar ao estado NORMAL")
	assert(not alert_sys.is_red_alert, "Alerta vermelho deve ser desativado")
	assert(alert_sys.num_respawn_guards == 0, "Cota de reforços deve ser zerada")

	print("EVASION_COMPLETION_OK: retorno limpo ao estado NORMAL após esgotar contagem validado")

func test_elevator_immediate_cancellation() -> void:
	var alert_sys := AlertSystem.new()
	alert_sys.trigger_alert(true, 4, 3) # Alerta na Sala 3
	assert(alert_sys.current_state == AlertSystem.AlertState.ALERT, "Deve estar em alerta")

	# Snake entra no elevador (Sala 240) -> StopAlert na ROM (Banks0123.asm:6646 cp 0F0h; jr nc, StopAlert)
	alert_sys.on_room_transition(240)
	assert(alert_sys.current_state == AlertSystem.AlertState.NORMAL, "Entrar em elevador (sala >= 240) deve cancelar imediatamente o alarme")
	assert(not alert_sys.is_red_alert, "Red alert deve ser cancelado")

	print("ELEVATOR_CANCEL_OK: cancelamento imediato de alarme ao entrar em elevadores validado")
