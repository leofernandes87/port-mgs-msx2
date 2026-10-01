class_name CaptureCutscene
extends Node2D

## Sistema da Cutscene Canônica de Captura de Solid Snake na Sala 8 (Outer Heaven).
## Fundamentado na engenharia reversa da ROM original MSX2 RC750:
## - logic/common.asm:26-47 (Gatilho da emboscada em Room 8, PlayerX em [0xC0, 0xD0])
## - logic/capturescene.asm:1-280 (Máquina de estados, movimento dos guardas, temporizadores e desfecho)
## - data/texts.asm:189-190 (Diálogos autênticos: TextId 6 "DON'T MOVE!", TextId 7 "YOU ARE CAPTURED!")
## - Banks0123.asm:8345, 8387 (Janela de mensagem Type 4 em 48, 8 de 160x41 px)
## - Banks0123.asm:11672-11743 (FadeOutLogic com decremento de paleta a cada 4 frames)

signal cutscene_started
signal message_displayed(text: String)
signal teleport_requested
signal cutscene_finished

enum State {
	INACTIVE = 0,
	SPAWN_GUARD_A = 1,       # AddCaptureGuard (InitCaptureScene: wait 2 frames)
	GUARD_A_SPEAK = 2,       # SetTextUnskippable 6: "DON'T MOVE!"
	GUARD_B_WALK_X = 3,      # Guard B marcha para a esquerda a 120 px/s até X <= 184 (0xB8)
	GUARD_B_WALK_Y = 4,      # Guard B marcha em Y até alinhar com Snake
	GUARD_B_ARRIVED = 5,     # Guard B vira para esquerda e aguarda 2 frames
	GUARD_B_SPEAK = 6,       # SetTextUnskippable 7: "YOU ARE CAPTURED!"
	POST_SPEAK_PAUSE = 7,    # CaptureWaitText (30 frames = 0.5s)
	WAIT_BEFORE_FADE = 8,    # CaptureSetup / CaptureWait (60 frames = 1.0s, áudio mutado)
	FADE_OUT = 9,            # CaptureFadeOut (60 frames = 1.0s de fade gradual)
	IN_DARKNESS = 10,        # PutInPrison: espera 16 frames no preto e transporta para a Cela 211
	FADE_IN = 11,            # Clareia a tela na Cela 211 (30 frames = 0.5s)
	FINISHED = 12            # Restabelece controles de Snake e finaliza cutscene
}

# Velocidade de marcha dos guardas: SetWalkSpeedFast = 2 px/frame no MSX2 -> 120 px/s na Godot
const GUARD_WALK_SPEED_PX_PER_SEC: float = 120.0

# Coordenadas canônicas de parada do Guarda B (CaptureGuardBX: CP 0B8h)
const GUARD_B_STOP_X: float = 184.0 # 0xB8

# Temporizadores calibrados no padrão 60 FPS (NTSC MSX2):
const DURATION_SPEAK_A_SEC: float = 1.6        # Exibição do "DON'T MOVE!"
const DURATION_SPEAK_B_SEC: float = 1.8        # Exibição do "YOU ARE CAPTURED!"
const DURATION_POST_SPEAK_SEC: float = 0.5     # 30 frames (0x1E)
const DURATION_PRE_FADE_SEC: float = 1.0       # 60 frames (0x3C)
const DURATION_FADE_OUT_SEC: float = 1.0       # Fade out progressivo
const DURATION_DARKNESS_SEC: float = 0.27      # 16 frames (0x10)
const DURATION_FADE_IN_SEC: float = 0.5        # Transição suave para a Cela 211

var current_state: State = State.INACTIVE
var is_active: bool = false
var state_timer: float = 0.0

# Posições e orientações dos guardas de captura
var guard_a_pos: Vector2 = Vector2.ZERO
var guard_a_dir: PlayerController.Direction = PlayerController.Direction.LEFT
var guard_a_visible: bool = false

var guard_b_pos: Vector2 = Vector2.ZERO
var guard_b_dir: PlayerController.Direction = PlayerController.Direction.LEFT
var guard_b_visible: bool = false
var guard_b_moving: bool = false
var guard_b_target_y: float = 0.0

# Animação de passadas dos guardas
var anim_tick: float = 0.0
var anim_frame: int = 0

# Janela de diálogo estilo MSX2 Type 4
var show_message_box: bool = false
var current_message_text: String = ""

# Efeito de Fade para preto (0.0 = transparente, 1.0 = 100% escuro)
var fade_alpha: float = 0.0

# Referência ao jogador
var target_player: PlayerController = null

# Texturas autênticas MSX2 extraídas da ROM RC750
var guard_texture: Texture2D = null
var font_texture: Texture2D = null

func _ready() -> void:
	z_index = 60 # Sobre o cenário e atores, abaixo do HUD quando necessário
	load_msx_textures()

func load_msx_textures() -> void:
	var guard_path := "res://assets/protected/sprites/guard_msx.png"
	var abs_guard := ProjectSettings.globalize_path(guard_path)
	if FileAccess.file_exists(abs_guard):
		var img_g := Image.load_from_file(abs_guard)
		if img_g != null and not img_g.is_empty():
			guard_texture = ImageTexture.create_from_image(img_g)

	var font_path := "res://assets/protected/sprites/transceiver/msx_font.png"
	var abs_font := ProjectSettings.globalize_path(font_path)
	if FileAccess.file_exists(abs_font):
		var img_f := Image.load_from_file(abs_font)
		if img_f != null and not img_f.is_empty():
			font_texture = ImageTexture.create_from_image(img_f)

## Inicia a sequência de captura na Sala 8
func start_cutscene(player: PlayerController) -> void:
	target_player = player
	is_active = true
	anim_tick = 0.0
	anim_frame = 0
	fade_alpha = 0.0
	show_message_box = false
	current_message_text = ""

	# Trava controles de Snake imediatamente (logic/common.asm:43)
	if target_player != null:
		target_player.can_control = false
		target_player.is_punching = false

	# 1. Spawna Guarda A em (240, PlayerY) encarando a esquerda (logic/capturescene.asm:27-36)
	var py: float = target_player.position.y if target_player != null else 96.0
	guard_a_pos = Vector2(240.0, py)
	guard_a_dir = PlayerController.Direction.LEFT
	guard_a_visible = true

	# 2. Configura ponto de spawn e destino do Guarda B (logic/capturescene.asm:177-184)
	var spawn_b_y: float = 176.0 if py < 152.0 else 136.0 # 0xB0 se PlayerY < 0x98, senão 0x88
	guard_b_pos = Vector2(240.0, spawn_b_y)
	guard_b_dir = PlayerController.Direction.LEFT
	guard_b_visible = false
	guard_b_moving = false
	guard_b_target_y = py

	current_state = State.SPAWN_GUARD_A
	state_timer = 2.0 / 60.0 # 2 frames de delay inicial (InitCaptureScene:129)
	cutscene_started.emit()
	queue_redraw()

func _process(delta: float) -> void:
	if not is_active:
		return

	# Snake permanece rigorosamente estático e sem controle durante toda a cutscene
	if target_player != null:
		target_player.can_control = false

	# Animação de passadas (alterna a cada ~8 frames = 0.133s)
	anim_tick += delta
	anim_frame = 1 if int(anim_tick * 7.5) % 2 == 1 else 0

	match current_state:
		State.SPAWN_GUARD_A:
			state_timer -= delta
			if state_timer <= 0.0:
				# Guarda A fala "DON'T MOVE!" e spawna Guarda B (logic/capturescene.asm:170-186)
				current_state = State.GUARD_A_SPEAK
				state_timer = DURATION_SPEAK_A_SEC
				show_message_box = true
				current_message_text = "DON'T MOVE!"
				guard_b_visible = true
				message_displayed.emit(current_message_text)

		State.GUARD_A_SPEAK:
			state_timer -= delta
			if state_timer <= 0.0:
				# Fecha a primeira caixa e inicia a marcha do Guarda B em X
				show_message_box = false
				current_state = State.GUARD_B_WALK_X
				guard_b_moving = true
				guard_b_dir = PlayerController.Direction.LEFT

		State.GUARD_B_WALK_X:
			# Guarda B anda para a esquerda a 120 px/s até atingir X = 184 (logic/capturescene.asm:208-213)
			guard_b_pos.x -= GUARD_WALK_SPEED_PX_PER_SEC * delta
			if guard_b_pos.x <= GUARD_B_STOP_X:
				guard_b_pos.x = GUARD_B_STOP_X
				# Decide a direção vertical rumo a Snake (logic/capturescene.asm:216-225)
				if guard_b_pos.y < guard_b_target_y:
					guard_b_dir = PlayerController.Direction.DOWN
				else:
					guard_b_dir = PlayerController.Direction.UP
				current_state = State.GUARD_B_WALK_Y

		State.GUARD_B_WALK_Y:
			# Guarda B caminha na vertical até alinhar com o Y de Snake (logic/capturescene.asm:232-239)
			var dy: float = guard_b_target_y - guard_b_pos.y
			var step: float = GUARD_WALK_SPEED_PX_PER_SEC * delta
			if abs(dy) <= step or abs(dy) < 2.0:
				guard_b_pos.y = guard_b_target_y
				guard_b_moving = false
				guard_b_dir = PlayerController.Direction.LEFT # Vira para Snake (logic/capturescene.asm:242)
				current_state = State.GUARD_B_ARRIVED
				state_timer = 2.0 / 60.0 # 2 frames de pausa
			else:
				guard_b_pos.y += sign(dy) * step

		State.GUARD_B_ARRIVED:
			state_timer -= delta
			if state_timer <= 0.0:
				# Guarda B fala "YOU ARE CAPTURED!" (logic/capturescene.asm:251-260)
				current_state = State.GUARD_B_SPEAK
				state_timer = DURATION_SPEAK_B_SEC
				show_message_box = true
				current_message_text = "YOU ARE CAPTURED!"
				message_displayed.emit(current_message_text)

		State.GUARD_B_SPEAK:
			state_timer -= delta
			if state_timer <= 0.0:
				# Fecha a caixa de diálogo e aguarda pausa pós-fala (logic/capturescene.asm:266)
				show_message_box = false
				current_state = State.POST_SPEAK_PAUSE
				state_timer = DURATION_POST_SPEAK_SEC

		State.POST_SPEAK_PAUSE:
			state_timer -= delta
			if state_timer <= 0.0:
				# Transita para o preparo de captura e mudo (logic/capturescene.asm:38-47)
				current_state = State.WAIT_BEFORE_FADE
				state_timer = DURATION_PRE_FADE_SEC

		State.WAIT_BEFORE_FADE:
			state_timer -= delta
			if state_timer <= 0.0:
				# Inicia o Fade Out gradativo para preto (logic/capturescene.asm:69-72)
				current_state = State.FADE_OUT
				state_timer = DURATION_FADE_OUT_SEC

		State.FADE_OUT:
			state_timer -= delta
			var progress: float = clamp(1.0 - (state_timer / DURATION_FADE_OUT_SEC), 0.0, 1.0)
			fade_alpha = progress
			if state_timer <= 0.0:
				fade_alpha = 1.0
				current_state = State.IN_DARKNESS
				state_timer = DURATION_DARKNESS_SEC
				# No ápice da escuridão, solicita transporte para a Cela 211 e confisco de itens
				teleport_requested.emit()

		State.IN_DARKNESS:
			fade_alpha = 1.0
			state_timer -= delta
			if state_timer <= 0.0:
				# Inicia o clareamento suave da tela na Cela 211
				current_state = State.FADE_IN
				state_timer = DURATION_FADE_IN_SEC
				guard_a_visible = false
				guard_b_visible = false

		State.FADE_IN:
			state_timer -= delta
			var progress: float = clamp(state_timer / DURATION_FADE_IN_SEC, 0.0, 1.0)
			fade_alpha = progress
			if state_timer <= 0.0:
				fade_alpha = 0.0
				current_state = State.FINISHED
				is_active = false
				# Destrava os controles do jogador ao despertar na cela (logic/capturescene.asm:115-118)
				if target_player != null:
					target_player.can_control = true
				cutscene_finished.emit()

	queue_redraw()

func _draw() -> void:
	if not is_active and fade_alpha <= 0.0:
		return

	# 1. Renderização dos guardas da emboscada
	if guard_a_visible:
		_draw_guard_soldier(guard_a_pos, guard_a_dir, false)

	if guard_b_visible:
		_draw_guard_soldier(guard_b_pos, guard_b_dir, guard_b_moving)

	# 2. Janela de Mensagem clássica do MSX2 Type 4 em (48, 8, 160, 41)
	if show_message_box and current_message_text != "":
		_draw_msx_message_box(current_message_text)

	# 3. Overlay de Fade Out / Escuridão (256x192)
	if fade_alpha > 0.0:
		draw_rect(Rect2(0.0, 0.0, 256.0, 192.0), Color(0.0, 0.0, 0.0, fade_alpha))

## Obtém a região de corte no spritesheet autêntico MSX2 guard_msx.png (64x128 px, células 16x32)
func _get_guard_sprite_rect(dir: PlayerController.Direction, moving: bool) -> Rect2:
	var row: int = 0
	match dir:
		PlayerController.Direction.DOWN:
			row = 0
		PlayerController.Direction.UP:
			row = 1
		PlayerController.Direction.RIGHT:
			row = 2
		PlayerController.Direction.LEFT:
			row = 3

	var col: int = 0
	if moving:
		col = 1 if anim_frame == 0 else 2
	else:
		col = 0 # Stand

	return Rect2(float(col * 16), float(row * 32), 16.0, 32.0)

## Desenha um soldado inimigo de Outer Heaven com fidelidade à paleta e silhueta MSX2
func _draw_guard_soldier(pos: Vector2, dir: PlayerController.Direction, moving: bool) -> void:
	# 1. Renderização autêntica com spritesheet MSX2 extraído (guard_msx.png)
	if guard_texture != null:
		var src_rect := _get_guard_sprite_rect(dir, moving)
		var dest_rect := Rect2(pos.x - 8.0, pos.y - 26.0, 16.0, 32.0)
		draw_texture_rect_region(guard_texture, dest_rect, src_rect)
		return

	# 2. Fallback procedural preservado caso a textura protegida não esteja presente
	var c_helmet := Color("4b692f")       # Verde oliva capacete
	var c_helmet_rim := Color("2d401c")   # Borda escura do capacete
	var c_skin := Color("d8a080")         # Tom de pele
	var c_suit := Color("3c5426")         # Farda militar
	var c_vest := Color("273719")         # Colete tático
	var c_boots := Color("141c0d")        # Botas de combate
	var c_rifle := Color("181820")        # Fuzil de assalto

	var x: float = pos.x
	var y: float = pos.y

	var leg_offset_l: float = 0.0
	var leg_offset_r: float = 0.0
	if moving:
		if anim_frame == 0:
			leg_offset_l = -2.0
			leg_offset_r = 2.0
		else:
			leg_offset_l = 2.0
			leg_offset_r = -2.0

	draw_rect(Rect2(x - 5.0, y - 5.0 + leg_offset_l, 4.0, 5.0), c_boots)
	draw_rect(Rect2(x + 1.0, y - 5.0 + leg_offset_r, 4.0, 5.0), c_boots)
	draw_rect(Rect2(x - 6.0, y - 16.0, 12.0, 11.0), c_suit)
	draw_rect(Rect2(x - 5.0, y - 15.0, 10.0, 9.0), c_vest)
	draw_rect(Rect2(x - 5.0, y - 24.0, 10.0, 8.0), c_helmet)
	draw_rect(Rect2(x - 6.0, y - 20.0, 12.0, 2.0), c_helmet_rim)

	match dir:
		PlayerController.Direction.LEFT:
			draw_rect(Rect2(x - 5.0, y - 20.0, 3.0, 3.0), c_skin)
			draw_rect(Rect2(x - 14.0, y - 14.0, 10.0, 3.0), c_rifle)
			draw_rect(Rect2(x - 8.0, y - 11.0, 3.0, 4.0), c_rifle)
			draw_rect(Rect2(x - 6.0, y - 14.0, 3.0, 3.0), c_skin)
		PlayerController.Direction.RIGHT:
			draw_rect(Rect2(x + 2.0, y - 20.0, 3.0, 3.0), c_skin)
			draw_rect(Rect2(x + 4.0, y - 14.0, 10.0, 3.0), c_rifle)
			draw_rect(Rect2(x + 5.0, y - 11.0, 3.0, 4.0), c_rifle)
			draw_rect(Rect2(x + 3.0, y - 14.0, 3.0, 3.0), c_skin)
		PlayerController.Direction.UP:
			draw_rect(Rect2(x - 4.0, y - 23.0, 8.0, 5.0), c_helmet_rim)
			draw_rect(Rect2(x + 3.0, y - 18.0, 3.0, 12.0), c_rifle)
		PlayerController.Direction.DOWN:
			draw_rect(Rect2(x - 4.0, y - 20.0, 8.0, 3.0), c_skin)
			draw_rect(Rect2(x - 2.0, y - 19.0, 1.0, 1.0), Color.BLACK)
			draw_rect(Rect2(x + 1.0, y - 19.0, 1.0, 1.0), Color.BLACK)
			draw_rect(Rect2(x - 2.0, y - 13.0, 4.0, 12.0), c_rifle)

## Desenha a caixa de texto clássica do MSX2 Type 4 (Banks0123.asm:8345, 8387)
## X = 48, Y = 8, NX = 160, NY = 41
func _draw_msx_message_box(text: String) -> void:
	var box_rect := Rect2(48.0, 8.0, 160.0, 41.0)

	# Fundo preto sólido do MSX2 Screen 5 (FillRect cor 0)
	draw_rect(box_rect, Color(0.0, 0.0, 0.0, 1.0))
	# Borda branca de 1 pixel (DrawRect cor 14)
	draw_rect(box_rect, Color(1.0, 1.0, 1.0, 1.0), false, 1.0)

	# Renderiza o texto com a fonte original MSX2
	_draw_msx_text_centered(text, box_rect)

## Renderiza string centralizada usando o spritesheet da fonte MSX2 (msx_font.png)
func _draw_msx_text_centered(text: String, box: Rect2) -> void:
	var text_w: float = float(text.length() * 8)
	var start_x: float = floor(box.position.x + (box.size.x - text_w) * 0.5)
	var start_y: float = floor(box.position.y + (box.size.y - 8.0) * 0.5)

	for i in range(text.length()):
		var ch_code: int = text.unicode_at(i)
		var dest_pos := Vector2(start_x + float(i * 8), start_y)
		_draw_msx_glyph(ch_code, dest_pos)

## Renderiza glifo ASCII 8x8 individual com msx_font.png
func _draw_msx_glyph(ascii_code: int, pos: Vector2, color: Color = Color.WHITE) -> void:
	if ascii_code == 32: # Espaço
		return

	if font_texture != null:
		var code: int = clampi(ascii_code, 0, 127)
		var col: int = code % 16
		var row: int = code / 16
		var src_rect := Rect2(float(col * 8), float(row * 8), 8.0, 8.0)
		var dest_rect := Rect2(pos, Vector2(8.0, 8.0))
		draw_texture_rect_region(font_texture, dest_rect, src_rect, color)
	else:
		# Fallback com fonte do sistema caso o asset protegido não esteja presente
		var ch: String = String.chr(ascii_code)
		draw_string(ThemeDB.fallback_font, pos + Vector2(0.0, 7.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
