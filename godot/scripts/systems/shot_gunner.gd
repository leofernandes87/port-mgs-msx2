class_name ShotGunner
extends Node2D

## Boss Shoot Gunner — Fiel à ROM MSX2 RC750 (Etapa 18)
## Fonte: logic/actors/shotgunner.asm, data/actorspriteattr.asm, data/weapondamage.asm
## ID_SHOT_GUNNER = 0x21 (33) — ActorsRoom057, spawn x=144, y=56
## Sala 57 é zona segura (ROOMS_SHOT_SECURE), tiros não ativam alerta.

# ---------------------------------------------------------------------------
# Constantes canônicas extraídas da ROM
# ---------------------------------------------------------------------------

## HP inicial: idxActorLife[33-1] = 0x14 (data/actorspriteattr.asm:129)
const BOSS_HP: int = 20

## Dano por bala de pistola: BulletDamage[33-1] = 2 (data/weapondamage.asm:18)
## Precisa de 10 tiros para matar.
const BULLET_DAMAGE: int = 2

## Velocidade de rolagem lateral: ±4 px/tick (shotgunner.asm:18-22) -> 4 * 60 = 240 px/s
const ROLL_SPEED: float = 4.0
const ROLL_SPEED_PX_PER_SEC: float = 240.0

## Duração máxima da rolagem: Wait = 0x0B = 11 ticks (shotgunner.asm:28, 148)
const ROLL_WAIT: int = 11
const ROLL_WAIT_SEC: float = 11.0 / 60.0

## Pausa após parar antes de atirar: Wait = 0x2D = 45 ticks (shotgunner.asm:100)
const SHOOT_WAIT: int = 45
const SHOOT_WAIT_SEC: float = 45.0 / 60.0

## Intervalo entre disparos: ANIM_CNT & 0x0F → 1 tiro a cada 16 ticks (shotgunner.asm:127)
const SHOT_INTERVAL: int = 16
const SHOT_INTERVAL_SEC: float = 16.0 / 60.0

## Delay de intro para refresh de sprites: IntroDelay = 2 ticks (shotgunner.asm:13)
const INTRO_DELAY: int = 2
const INTRO_DELAY_SEC: float = 2.0 / 60.0

# ---------------------------------------------------------------------------
# Máquina de estados — mapeamento direto das 3 fases de ShotGunnerLogic
# ---------------------------------------------------------------------------
enum SGunnerState {
	INTRO  = 0,  # ShotGunnerIntro: aguarda IntroDelay e exibe diálogo
	ROLL   = 1,  # ShotGunnerRoll: move lateralmente até colisão ou wait expirar
	SHOOT  = 2,  # SGunnerShotLogic: fica parado e atira a cada SHOT_INTERVAL ticks
}

# ---------------------------------------------------------------------------
# Estado do boss
# ---------------------------------------------------------------------------
var boss_hp: int = BOSS_HP
var is_dead: bool = false
var state: SGunnerState = SGunnerState.INTRO
var wait_timer: int = INTRO_DELAY
var anim_tick: int = 0       # ANIM_CNT geral
var intro_speech_done: bool = false

## Direção horizontal de rolagem: +1 = direita, -1 = esquerda (inicializada pelo spawn)
var roll_dir: int = 1
var speed_x: float = ROLL_SPEED  # SpeedX com sinal

## Grade de tiles 32×24 (768 ints) — passada pelo sandbox a cada tick
var collision_grid: Array = []

## Posição do player (usada para calcular direção de rolagem e ângulo de disparo)
var player_pos: Vector2 = Vector2.ZERO

## Cor do boss e estado visual
var flash_timer: int = 0  # Piscada branca ao ser atingido
var muzzle_flash_timer: int = 0  # Flash na ponta da escopeta ao atirar

## Disparo único por parada (estilo escopeta autêntico da Konami)
var has_fired_this_stop: bool = false

## Animação de rolagem — sprite IDs canônicos: 0x5E, 0x5F, 0x60, 0x5F
## (SGunnerRollSpr em shotgunner.asm:174-177; mapeado para índice de frame)
var roll_frame: int = 0  # 0-3 ciclando via ANIM_CNT & 6 >> 1

# ---------------------------------------------------------------------------
# Sinais
# ---------------------------------------------------------------------------

## Emitido quando o boss deve disparar um projétil em direção ao player
signal boss_shot_fired(origin: Vector2, target: Vector2)

## Emitido quando o HP chega a 0
signal boss_defeated

## Emitido para exibir o diálogo de intro no HUD
signal intro_dialog(text: String)

# ---------------------------------------------------------------------------
# Inicialização
# ---------------------------------------------------------------------------

var _boss_texture: Texture2D = null

func _ready() -> void:
	z_index = 10
	if ResourceLoader.exists("res://assets/protected/sprites/shoot_gunner_msx.png"):
		_boss_texture = load("res://assets/protected/sprites/shoot_gunner_msx.png")

func setup(spawn_pos: Vector2, grid: Array, initial_player_pos: Vector2) -> void:
	position = spawn_pos
	collision_grid = grid
	player_pos = initial_player_pos
	# Decide direção inicial da rolagem: para o lado de Snake (shotgunner.asm:16-23)
	_decide_roll_direction()
	state = SGunnerState.INTRO
	wait_timer = INTRO_DELAY

# ---------------------------------------------------------------------------
# Lógica principal por tick — chamada pelo sandbox em _physics_process
# ---------------------------------------------------------------------------

func step_tick(p_pos: Vector2, grid: Array, delta: float = 1.0 / 60.0) -> void:
	if is_dead:
		return
	player_pos = p_pos
	collision_grid = grid
	anim_tick += 1

	# Animação de piscada (hit flash)
	if flash_timer > 0:
		flash_timer -= 1
	if muzzle_flash_timer > 0:
		muzzle_flash_timer -= 1

	match state:
		SGunnerState.INTRO:
			_tick_intro()
		SGunnerState.ROLL:
			_tick_roll(delta)
		SGunnerState.SHOOT:
			_tick_shoot()

# ---------------------------------------------------------------------------
# Fase INTRO — ShotGunnerIntro (shotgunner.asm:55-70)
# ---------------------------------------------------------------------------

func _tick_intro() -> void:
	wait_timer -= 1
	if wait_timer > 0:
		return  # ret nz — aguarda IntroDelay

	# IntroDelay expirou; verifica se o discurso já foi feito
	if not intro_speech_done:
		intro_speech_done = true
		# TEXT 61: "I'M SHOOT GUNNER! NOBODY HAS EVER BEEN ABLE TO ESCAPE FROM HERE."
		emit_signal("intro_dialog",
			"I'M SHOOT GUNNER!\nNOBODY HAS EVER BEEN\nABLE TO ESCAPE FROM HERE.")

	# Status = 1 → ROLL
	_transition_to_roll()

# ---------------------------------------------------------------------------
# Fase ROLL — ShotGunnerRoll (shotgunner.asm:80-103)
# ---------------------------------------------------------------------------

func _tick_roll(delta: float = 1.0 / 60.0) -> void:
	# Atualiza frame de animação: (ANIM_CNT & 6) >> 1 → 0,1,2,1 (shotgunner.asm:161-162)
	roll_frame = ((anim_tick & 6) >> 1)

	# Verifica colisão lateral antes de mover (ChkTileCollision, Shape 0)
	var blocked: bool = _check_tile_collision_horizontal(speed_x > 0.0)

	if not blocked:
		wait_timer -= 1
		var step_x: float = (speed_x * 60.0) * delta
		position.x += step_x
		position.x = clamp(position.x, 8.0, 248.0)

	# Para ao colidir ou ao wait expirar (ShotGunnerStop)
	if blocked or wait_timer <= 0:
		_transition_to_shoot()

# ---------------------------------------------------------------------------
# Fase SHOOT — SGunnerShotLogic (shotgunner.asm:113-148)
# ---------------------------------------------------------------------------

func _tick_shoot() -> void:
	wait_timer -= 1
	if wait_timer <= 0:
		# SGunnerThinkDir: decide nova direção e volta a rolar
		_decide_roll_direction()
		_transition_to_roll()
		return

	# Verifica abrigo do player (shotgunner.asm:117-123)
	# Se PlayerY >= 166 e PlayerX >= 170 → não atira (player atrás das caixas)
	if player_pos.y >= 166.0 and player_pos.x >= 170.0:
		return

	# Cadência canônica da ROM MSX2 (shotgunner.asm:126-131):
	# SGunnerShotLogic2: ANIM_CNT & 0x0F == 0 -> AddEnemyShot2
	if (anim_tick & 0x0F) == 0:
		var facing_dir: int = 1 if player_pos.x >= position.x else -1
		var spawn_offset := Vector2(facing_dir * 10.0, -10.0)
		muzzle_flash_timer = 5
		emit_signal("boss_shot_fired", position + spawn_offset, player_pos)

# ---------------------------------------------------------------------------
# Transições de estado
# ---------------------------------------------------------------------------

func _transition_to_roll() -> void:
	state = SGunnerState.ROLL
	wait_timer = ROLL_WAIT
	has_fired_this_stop = false
	# COLLISION_CFG = 0 durante rolagem (colisão com player desativada) (shotgunner.asm:29, 149)
	# (controlado pelo sandbox: enquanto em ROLL, não aplica dano de contato)

func _transition_to_shoot() -> void:
	speed_x = 0.0
	state = SGunnerState.SHOOT
	wait_timer = SHOOT_WAIT
	has_fired_this_stop = false
	# COLLISION_CFG = 3 ao parar (colisão com player e tiros ativada) (shotgunner.asm:102)

# ---------------------------------------------------------------------------
# Colisão horizontal com tiles — ChkTileCollision Shape 0 adaptada para eixo X
# (ShapeSize_0 de logic/collisions.asm: LEFT=(-8,-4),(-8,3); RIGHT=(7,-4),(7,3))
# ---------------------------------------------------------------------------

func _check_tile_collision_horizontal(going_right: bool) -> bool:
	if collision_grid.is_empty():
		return false
	var cx: float = position.x
	var cy: float = position.y
	# Pontos de amostragem LEFT: (-8,-4) e (-8,3)
	# Pontos de amostragem RIGHT: (7,-4) e (7,3)
	var ox: float = 7.0 if going_right else -8.0
	var ny: int = int(cy + (-4.0))
	var py: int = int(cy + 3.0)
	var px: int = int(cx + ox + speed_x)
	for ty: int in [ny, py]:
		if ty < 0 or ty >= 192:
			return true
		if px < 0 or px >= 256:
			return true
		var col: int = (ty / 8) * 32 + (px / 8)
		if col >= 0 and col < collision_grid.size() and int(collision_grid[col]) == 1:
			return true
	return false

# ---------------------------------------------------------------------------
# Decide direção de rolagem olhando para Snake (shotgunner.asm:135-146)
# ---------------------------------------------------------------------------

func _decide_roll_direction() -> void:
	if player_pos.x >= position.x:
		speed_x = ROLL_SPEED   # Vai para a direita
		roll_dir = 1
	else:
		speed_x = -ROLL_SPEED  # Vai para a esquerda
		roll_dir = -1

# ---------------------------------------------------------------------------
# Recebe hit de bala do player (BulletDamage[33-1] = 2)
# Retorna true se boss morre
# ---------------------------------------------------------------------------

func apply_bullet_hit() -> bool:
	if is_dead:
		return false
	# Durante ROLL, colisões com tiros são desativadas (COLLISION_CFG bit1 = 0)
	# (shotgunner.asm:29: COLLISION_CFG = 0 durante ROLL)
	if state == SGunnerState.ROLL:
		return false

	boss_hp -= BULLET_DAMAGE
	flash_timer = 4  # Piscada visual breve ao ser atingido
	if boss_hp <= 0:
		boss_hp = 0
		_on_defeat()
		return true
	return false

# ---------------------------------------------------------------------------
# Derrota — DismissActor6 (Banks0123.asm:12996-13003)
# Seta ShotGunnerStat bit0 = Dead; restaura música; sem drop de item.
# ---------------------------------------------------------------------------

func _on_defeat() -> void:
	is_dead = true
	visible = false
	queue_redraw()
	emit_signal("boss_defeated")

## Obtém a região retangular exata no spritesheet MSX2 (64x64 px).
## Linha 0 = Facing Right, Linha 1 = Facing Left (espelhado).
## Colunas: 0 = Stand (0x5D), 1..3 = Roll 1, 2, 3 (0x5E, 0x5F, 0x60).
func _get_sprite_rect() -> Rect2:
	var facing_right: bool = (player_pos.x >= position.x) if state == SGunnerState.SHOOT else (roll_dir >= 0)
	var row: int = 0 if facing_right else 1
	var col: int = 0
	if state == SGunnerState.ROLL:
		# SGunnerRollSpr: 5Eh, 5Fh, 60h, 5Fh -> colunas 1, 2, 3, 2
		const ROLL_COLS: Array[int] = [1, 2, 3, 2]
		col = ROLL_COLS[roll_frame % 4]
	else:
		col = 0  # Stand
	return Rect2(col * 16.0, row * 32.0, 16.0, 32.0)

# ---------------------------------------------------------------------------
# Desenho autêntico MSX2 com fallback procedural
# ---------------------------------------------------------------------------

func _draw() -> void:
	# Fiel ao MSX2 (Banks0123.asm:12996-13003, 13079-13080):
	# Ao ser derrotado, DismissActor6 chama RemoveActor_ liberando a estrutura do ator.
	# Não existe sprite de corpo no chão; o ator simplesmente é removido e desaparece.
	if is_dead:
		return

	var base_color: Color = Color(0.85, 0.2, 0.1)    # Vermelho: uniforme de boss
	var shadow_color: Color = Color(0.4, 0.1, 0.05)
	var highlight: Color = Color(1.0, 1.0, 1.0, 0.7) if flash_timer > 0 else Color.TRANSPARENT

	# 1. Renderização autêntica com spritesheet MSX2
	# Stand: SprOffsets1 (-8, -27); Roll: SprOffsets10 (-8, -32)
	if _boss_texture != null:
		var src_rect := _get_sprite_rect()
		var dest_offset_y: float = -32.0 if state == SGunnerState.ROLL else -27.0
		var dest_rect := Rect2(-8.0, dest_offset_y, 16.0, 32.0)
		draw_texture_rect_region(_boss_texture, dest_rect, src_rect)

		# Muzzle flash na ponta do cano da escopeta
		if muzzle_flash_timer > 0 and state != SGunnerState.ROLL:
			var facing_right: bool = player_pos.x >= position.x
			var m_tip: float = 8.0 if facing_right else -8.0
			draw_rect(Rect2(m_tip - 2.0, -13.0, 5.0, 8.0), Color(1.0, 0.9, 0.2))
			draw_rect(Rect2(m_tip - 3.0, -12.0, 7.0, 6.0), Color.WHITE)

		# Flash de hit
		if flash_timer > 0:
			draw_rect(dest_rect, highlight)

		queue_redraw()
		return

	match state:
		SGunnerState.INTRO, SGunnerState.SHOOT:
			var facing_dir: int = (1 if player_pos.x >= position.x else -1) if state == SGunnerState.SHOOT else roll_dir
			# Posição em pé — corpo retangular + capacete
			draw_rect(Rect2(-6.0, -14.0, 12.0, 16.0), shadow_color)  # Sombra
			draw_rect(Rect2(-5.0, -15.0, 12.0, 16.0), base_color)    # Corpo
			draw_rect(Rect2(-5.0, -22.0, 12.0, 8.0), Color(0.2, 0.2, 0.2))  # Capacete
			var face_ox: float = -1.0 if facing_dir >= 0 else -3.0
			draw_rect(Rect2(face_ox, -18.0, 4.0, 4.0), Color(1.0, 0.8, 0.6))  # Rosto
			# Escopeta apontando na direção de disparo
			var gun_ox: float = 6.0 if facing_dir >= 0 else -14.0
			draw_rect(Rect2(gun_ox, -10.0, 8.0, 3.0), Color(0.15, 0.15, 0.15))
			# Muzzle flash autêntico na ponta do cano
			if muzzle_flash_timer > 0:
				var m_tip: float = gun_ox + (9.0 if facing_dir >= 0 else -1.0)
				draw_rect(Rect2(m_tip - 2.0, -13.0, 5.0, 8.0), Color(1.0, 0.9, 0.2))
				draw_rect(Rect2(m_tip - 3.0, -12.0, 7.0, 6.0), Color.WHITE)
		SGunnerState.ROLL:
			# Animação de rolagem: losango que gira
			var r: float = 7.0 + float(roll_frame) * 0.5
			var pts: PackedVector2Array = PackedVector2Array([
				Vector2(0.0, -r), Vector2(r, 0.0), Vector2(0.0, r), Vector2(-r, 0.0)
			])
			draw_colored_polygon(pts, shadow_color)
			var pts2: PackedVector2Array = PackedVector2Array([
				Vector2(0.0, -r + 1.0), Vector2(r - 1.0, 0.0), Vector2(0.0, r - 1.0), Vector2(-r + 1.0, 0.0)
			])
			draw_colored_polygon(pts2, base_color)

	# Flash de hit
	if flash_timer > 0:
		draw_rect(Rect2(-7.0, -23.0, 14.0, 24.0), highlight)

	queue_redraw()
