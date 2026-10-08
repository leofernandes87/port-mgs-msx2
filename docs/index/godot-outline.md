# Esboço dos scripts Godot grandes

Gerado por `tools/context/build_index.py` para .gd com 300+ linhas; não editar.
Leia por faixa (`Read offset/limit` ou `python3 -m tools.context.lookup gd ARQUIVO FUNC`),
nunca o arquivo inteiro. Formato: `- início-fim assinatura`; `nome@linha` em sinais/constantes.

## godot/scripts/scenes/sandbox_gameplay.gd (3179 linhas)
class_name SandboxGameplay · extends Control
const/enum: ROOMS_SHOT_SECURE@91, ELEVATOR_STATE_IDLE@105, ELEVATOR_STATE_MOVING@106, INITIAL_ROOM_ID@134, DEFAULT_SPAWN_X@135, DEFAULT_SPAWN_Y@136
var: intro_cutscene@16, play_intro_cutscene@17, snapshot@19, player@20, room_manager@21, enemies@22, inventory@23, weapon_system@24, radio_system@25, game_clock@26, player_controls@27, controls_override@28, radio_dialog@29, cameras@30, laser_system@31, bullets@32, hud@33, silencer_dropped_room_150@34, item_boxes@35, room_doors@36, runtime_collision@37, room_texture@38, use_remastered_maps@44, show_collision@46, show_enemy_vision@47, infinite_life@48, god_mode_btn@49, zoom@50, canvas_origin@51, alert_system@52, rank_system@53, prisoners@54, dialog_banner_label@55, prisoner_dialog@56, _world_process_before_dialog@57, is_game_over@58, game_over_banner@59, shot_gunner@62, shot_gunner_bullets@63, boss_dialog_label@64, defeated_bosses@65, gas_hazard_system@68, gas_clouds@69, rolling_barrels@72, active_missile@75, active_plastic_bomb@78, broken_basement_walls@79, capture_system@82, capture_cutscene@83, tilemap_layer@84, electrified_floor_system@87, power_panel@88, is_player_shocked_flash@89, previous_room_id@98, room_entry_direction@99, is_in_elevator@100, elevator_cabin@101, elevator_y@102, elevator_target_y@103, elevator_state@104, elevator_spawner_timer_sec@107, elevator_spawner_timer@108, elevator_guard2_delay_sec@114, elevator_guard2_delay@115, status_label@121, call_badge@122, weapon_menu@124, item_menu@125, pause_menu@126, binocular_system@129, binocular_overlay@130, home_enemies_backup@131, guard1_exited_lorry@138, guard2_exited_lorry@139, guard3_exited_lorry@140, viewport_area@419, game_world@420, room_display@421
- 142-326 func _ready() -> void
- 328-334 func _on_weapon_menu_selected(w_name: String) -> void
- 336-344 func _on_item_menu_selected(i_name: String) -> void
- 346-359 func _toggle_pause_menu() -> void
- 361-382 func _give_debug_arsenal() -> void
- 384-388 func _on_radio_closed() -> void
- 390-396 func _on_intro_radio_requested(pages: Array[String]) -> void
- 398-405 func _on_intro_finished() -> void
- 406-408 func _radio_enter_room(room_id: int) -> void
- 410-421 func _sync_radio_conditions() -> void
- 423-425 func _post_ready_layout() -> void
- 427-429 func _on_viewport_resized() -> void
- 431-439 func _update_world_transform(area_size: Vector2) -> void
- 441-461 func _draw_room_and_collision() -> void
- 463-496 func _load_initial_room() -> void
- 498-526 func _apply_snapshot() -> void
- 528-758 func _spawn_room_enemies(room_id: int) -> void
- 759-812 func _should_hide_guard(room_id: int, act_y: int, act_x: int) -> bool
- 814-962 func _spawn_room_enemies_fallback(room_id: int, enemy_scene: PackedScene) -> void
- 964-966 func _on_chow_time_called() -> void
- 968-972 func _on_guard_sleepy_dialog(text: String) -> void
- 973-1001 func _process_elevator_spawner(delta: float = 1.0 / 60.0) -> void
- 1003-1023 func _spawn_relieve_guard(target_x: float, is_speaker: bool) -> void
- 1025-1049 func open_binoculars() -> bool
- 1051-1070 func close_binoculars() -> void
- 1072-1076 func toggle_binoculars() -> void
- 1078-1088 func _binocular_look(dir: PlayerController.Direction) -> bool
- 1090-1112 func _show_binocular_preview(room_id: int) -> void
- 1114-1142 func _restore_binocular_home() -> void
- 1144-1182 func _process_binoculars(delta: float = 1.0 / 60.0) -> void
- 1184-1217 func _backup_home_enemies() -> void
- 1219-1267 func _restore_home_enemies() -> void
- 1269-1363 func _spawn_room_items(room_id: int) -> void
- 1366-1507 func _spawn_room_doors(room_id: int) -> void
- 1509-1551 func _spawn_room_prisoners(room_id: int) -> void
- 1553-1579 func _on_prisoner_rescued(prisoner: Prisoner) -> void
- 1581-1631 func _spawn_room_power_panel(room_id: int) -> void
- 1633-1641 func show_dialog_message(speaker: String, text: String, duration_seconds: float = 6.0) -> void
- 1643-1676 func _create_synthetic_fallback_room() -> void
- 1678-1688 func _is_position_safe(pos: Vector2) -> bool
- 1690-1720 func _get_safe_spawn_position() -> Vector2
- 1722-1754 func reset_player() -> void
- 1755-1859 func reset_game_state() -> void
- 1861-1862 func _on_player_died() -> void
- 1864-1881 func trigger_game_over(instant: bool = false) -> void
- 1883-1906 func _execute_game_restart() -> void
- 1908-2203 func _input(event: InputEvent) -> void
- 2204-2208 func _physics_process(_delta: float) -> void
- 2210-2221 func _iteration_cadence() -> int
- 2222-2736 func game_tick() -> void
- 2739-2782 func _check_and_handle_room_transition() -> void
- 2784-2796 func _clamp_to_room_bounds(exit_dir: int) -> void
- 2798-2920 func change_to_room(new_room_id: int, entry_pos: Vector2, entry_dir: int = -1, from_door_id: int = -1) -> bool
- 2921-2956 func _transition_elevator_room(next_room_id: int, move_dir_y: int) -> void
- 2958-2961 func _on_camera_detected(_cam: SecurityCamera) -> void
- 2963-2966 func _on_laser_triggered(_laser_id: int = 0) -> void
- 2968-2971 func _trigger_alarm() -> void
- 2973-2979 func _on_alert_state_changed(_old_state: AlertSystem.AlertState, new_state: AlertSystem.AlertState) -> void
- 2981-2998 func _on_reinforcement_requested(enemy_id: int, spawn_pos: Vector2) -> void
- 3000-3004 func _on_boss_intro_dialog(text: String) -> void
- 3006-3023 func _on_boss_shot_fired(origin: Vector2, target: Vector2) -> void
- 3025-3030 func _on_boss_bullet_hit_player(damage: int) -> void
- 3032-3058 func _on_boss_defeated() -> void
- 3059-3070 func _check_boss_bullet_collision(b: Bullet) -> bool
- 3072-3078 func _on_missile_exploded(pos: Vector2) -> void
- 3080-3116 func _on_plastic_bomb_exploded(bomb_pos: Vector2, radius: float, damage: int) -> void
- 3118-3124 func _on_plastic_bomb_finished(bomb_node: Node2D) -> void
- 3126-3137 func _trigger_capture_event() -> void
- 3139-3144 func _on_capture_teleport_requested() -> void
- 3146-3149 func _on_capture_cutscene_finished() -> void
- 3151-3158 func _update_prison_wall(delta: float) -> void
- 3160-3172 func break_prison_wall(door_id: int = 103) -> void
- 3174-3179 func _on_equipment_restored() -> void

## godot/scripts/scenes/title_screen.gd (299 linhas)
extends Control
const/enum: State@12, VIRTUAL_WIDTH@20, VIRTUAL_HEIGHT@21, MG_LOGO_Y_POSITIONS@25
var: current_state@27, state_timer@28, wipe_line@31, wipe_timer_sec@32, wipe_frame_counter@33, scroll_step_index@39, scroll_timer_sec@40, scroll_frame_counter@41, blink_timer_sec@47, blink_counter@48, blink_visible@53, flash_timer_sec@55, flash_counter@56, flash_visible@61, input_cooldown@62, tex_konami_ribbon@65, tex_metalgear_logo@66, tex_copyright@67, tex_press_start@68, tex_push_space@69, tex_play_start@70, use_press_start_prompt@73, current_logo_y@74
- 76-82 func _ready() -> void
- 84-103 func _load_textures() -> void
- 105-159 func _process(delta: float) -> void
- 161-188 func _unhandled_input(event: InputEvent) -> void
- 190-203 func _handle_action_press() -> void
- 205-211 func _go_to_logo_scroll() -> void
- 213-220 func _go_to_title_idle() -> void
- 222-224 func _start_game() -> void
- 227-299 func _draw() -> void

## godot/scripts/systems/capture_cutscene.gd (398 linhas)
class_name CaptureCutscene · extends Node2D
signals: cutscene_started@12, message_displayed@13, teleport_requested@14, cutscene_finished@15
const/enum: State@17, GUARD_WALK_SPEED_PX_PER_SEC@34, GUARD_B_STOP_X@37, DURATION_SPEAK_A_SEC@40, DURATION_SPEAK_B_SEC@41, DURATION_POST_SPEAK_SEC@42, DURATION_PRE_FADE_SEC@43, DURATION_FADE_OUT_SEC@44, DURATION_DARKNESS_SEC@45, DURATION_FADE_IN_SEC@46
var: current_state@48, is_active@49, state_timer@50, guard_a_pos@53, guard_a_dir@54, guard_a_visible@55, guard_b_pos@57, guard_b_dir@58, guard_b_visible@59, guard_b_moving@60, guard_b_target_y@61, anim_tick@64, anim_frame@65, show_message_box@68, current_message_text@69, fade_alpha@72, target_player@75, guard_texture@78, font_texture@79
- 81-83 func _ready() -> void
- 85-100 func load_msx_textures() -> void
- 101-134 func start_cutscene(player: PlayerController) -> void
- 135-259 func step_tick(delta: float) -> void
- 261-280 func _draw() -> void
- 281-301 func _get_guard_sprite_rect(dir: PlayerController.Direction, moving: bool) -> Rect2
- 302-360 func _draw_guard_soldier(pos: Vector2, dir: PlayerController.Direction, moving: bool) -> void
- 361-372 func _draw_msx_message_box(text: String) -> void
- 373-383 func _draw_msx_text_centered(text: String, box: Rect2) -> void
- 384-398 func _draw_msx_glyph(ascii_code: int, pos: Vector2, color: Color = Color.WHITE) -> void

## godot/scripts/systems/door.gd (493 linhas)
class_name RoomDoor · extends Node2D
const/enum: DoorOrientation@7, BREAKABLE_WALL_SPECS@36, PLAYER_IN_DOOR_DAT@66, DOOR_OPEN_ENTER_DAT@91
var: door_id@16, room_id@17, render_type_id@18, open_rule_id@19, required_card@20, destination_room@21, entry_position@22, destination_direction@23, orientation@24, is_open@25, is_lorry@26, is_entry_disabled@27, trigger_rect@28, is_breakable_wall@31, punch_required_direction@32, collision_tile_indices@122, clearance_tile_indices@124
- 101-107 static func get_door_spawn(draw_xy: Vector2, render_type: int) -> Dictionary
- 109-128 static func get_card_for_rule(rule_id: int) -> String
- 130-140 static func load_door_textures() -> void
- 142-151 func _ready() -> void
- 153-253 func _calculate_collision_tiles() -> void
- 255-277 func inject_collision(collision_grid: Array) -> void
- 278-314 func get_enter_trigger_rect() -> Rect2
- 315-328 func get_open_trigger_rect() -> Rect2
- 329-335 func get_wall_rect() -> Rect2
- 336-359 func check_punch(player_pos: Vector2, player_dir: int) -> bool
- 360-372 func check_bomb_explosion(bomb_pos: Vector2, radius: float, collision_grid: Array) -> bool
- 373-454 func check_interaction(player: PlayerController, inventory: InventoryManager, collision_grid: Array) -> int
- 456-462 func open_door(collision_grid: Array) -> void
- 464-469 func close_door(collision_grid: Array) -> void
- 471-493 func _draw() -> void

## godot/scripts/systems/elevator_system.gd (344 linhas)
class_name ElevatorSystem · extends RefCounted
const/enum: ELEVATOR_CABIN_X@13, PLAYER_ENTRY_X@14, CABIN_TRIGGER_X@15, SHAFT_MIN_X@16, SHAFT_MAX_X@17, ELEVATOR_SPEED@18, ELEVATOR_SPEED_PX_PER_SEC@19, EXIT_UP_Y@20, EXIT_DOWN_Y@21, ENTRY_UP_Y@22, ENTRY_DOWN_Y@23, ELEVATOR_CONNECTIONS@26, ELEVATOR_DATA@51
- 39-123 static func get_connected_elevator_room(room_id: int, direction_y: int) -> int
- 125-126 static func is_elevator_room(room_id: int) -> bool
- 128-131 static func get_elevator_config(room_id: int) -> Dictionary
- 132-167 static func get_entry_state(elevator_room_id: int, previous_room_id: int) -> Dictionary
- 168-243 static func get_next_target_floor(
- 244-303 static func get_entry_moving_target(elevator_room_id: int, move_dir_y: int) -> Dictionary
- 304-344 static func check_exit(

## godot/scripts/systems/enemy.gd (1508 linhas)
class_name EnemyGuard · extends Node2D
signals: chow_time_called@100, dog_barked@101, sleepy_dialog_called@114
const/enum: GuardType@7, SPEED_SLOW_PX_PER_SEC@13, SPEED_MEDIUM_PX_PER_SEC@14, SPEED_FAST_PX_PER_SEC@15, GuardState@17, VIEW_HALF_WIDTH_V@23, VIEW_HALF_HEIGHT_H@24, MAX_VIEW_DISTANCE@25, AlertSubstate@51, ElevatorGuardState@74, DOG_SPEED@86, DOG_SPEED_PX_PER_SEC@87, DogState@89, SleepyState@105
var: punches_received@28, stunned_timer@29, is_dead@30, touch_damage@31, guard_type@33, actor_type_id@34, speed@35, state@36, current_direction@37, is_shooter@38, shoot_cooldown@39, shoot_flash_timer@40, waypoints@42, current_waypoint_idx@43, waypoint_reverse@44, is_alert@46, alert_timer@47, show_debug_vision@48, alert_substate@57, alert_counter@58, walk_away_dir@59, is_lorry_guard@61, lorry_timer@62, is_exiting_lorry@63, is_entering_lorry@64, lorry_anim_pixels@65, lorry_id@66, wait_ticks@67, anim_tick@69, anim_frame@70, is_elevator_guard@73, elev_guard_state@79, elev_guard_target_x@80, elev_guard_idle_timer@81, elev_guard_look_timer@82, is_relieve_speaker@83, is_dog@88, dog_state@94, dog_wait_timer@95, dog_listen_timer@96, dog_bark_timer@97, dog_anim_tick@98, is_sleepy_guard@104, sleepy_state@109, awake_timer@110, sleep_timer@111, snore_anim_tick@112
- 121-139 static func load_enemy_textures() -> void
- 141-162 func _get_guard_sprite_rect() -> Rect2
- 164-187 func _get_dog_sprite_rect() -> Rect2
- 189-230 func _ready() -> void
- 232-244 func init_dog() -> void
- 246-255 func init_sleepy_guard(force_awake_timer: int = -1) -> void
- 257-265 func wake_up_to_chase() -> void
- 267-279 func set_patrol_path(points: Array[Vector2]) -> void
- 280-297 func check_punched(player_pos: Vector2, player_dir: PlayerController.Direction) -> bool
- 299-327 func receive_punch() -> void
- 328-336 func check_bullet_hit(bullet_pos: Vector2) -> bool
- 337-348 func take_bullet_hit(bullet_damage: int = 2) -> bool
- 349-379 func try_shoot(player_pos: Vector2) -> Bullet
- 381-512 func step_tick(collision_grid: Array, player_pos: Vector2, is_punching: bool = false, player_dir: PlayerCon...
- 513-604 func _chase_player(target_pos: Vector2, collision_grid: Array, delta: float = 1.0 / 60.0) -> void
- 606-615 func _start_walk_away(target_pos: Vector2, _collision_grid: Array) -> void
- 617-622 func _get_perpendicular_away_dir(target_pos: Vector2) -> PlayerController.Direction
- 624-628 func _start_wait_shot(target_pos: Vector2) -> void
- 630-650 func _is_colliding_grid(test_pos: Vector2, collision_grid: Array) -> bool
- 652-696 func _follow_patrol_path(collision_grid: Array = [], delta: float = 1.0 / 60.0) -> void
- 698-735 func _advance_waypoint() -> void
- 737-750 func _update_direction_to_target(target: Vector2) -> void
- 751-808 func _process_elevator_guard() -> void
- 809-848 func check_line_of_sight(player_pos: Vector2, collision_grid: Array) -> bool
- 849-867 func _is_path_clear_of_obstacles(start_pos: Vector2, end_pos: Vector2, collision_grid: Array) -> bool
- 869-877 func trigger_alert() -> void
- 878-892 func transform_to_alert_guard() -> void
- 893-913 func reset_to_patrol() -> void
- 915-1148 func _draw() -> void
- 1150-1183 func _draw_guard_overlays() -> void
- 1185-1191 func _draw_snoring_symbol() -> void
- 1193-1202 func _draw_z_char(pos: Vector2, s: float, col: Color) -> void
- 1203-1277 func _step_dog(collision_grid: Array, player_pos: Vector2, player: PlayerController = null, delta: float = ...
- 1279-1291 func _get_dir_vector(dir: PlayerController.Direction) -> Vector2
- 1292-1316 func _reorient_dog_to_player(player_pos: Vector2, collision_grid: Array) -> void
- 1317-1502 func _draw_dog() -> void
- 1504-1507 func _draw_z_symbol(pos: Vector2, size: float, col: Color) -> void

## godot/scripts/systems/hud.gd (344 linhas)
class_name GameHUD · extends Control
const/enum: HUD_WIDTH@16, HUD_HEIGHT@17, HUD_Y@18, POS_LIFE_TEXT@20, RECT_LIFE_BOX@21, POS_LIFE_BAR@22, MAX_BAR_WIDTH@23, POS_CLASS_TEXT@25, POS_CLASS_STARS@26, RECT_CALL_SIGN@28, RECT_WEAPON_BOX@30, POS_WEAPON_SPRITE@31, POS_WEAPON_AMMO@32, RECT_ITEM_BOX@34, POS_ITEM_SPRITE@35, POS_ITEM_CARD_NUM@36, COLOR_BLACK@39, COLOR_WHITE@40, COLOR_LIFE_RED@41, COLOR_LIFE_BG@42, COLOR_CALL_GREEN@43, COLOR_STAR_YELLOW@44, WEAPON_TEX_INDICES@47, ITEM_TEX_INDICES@59
var: tex_weapons@84, tex_items@85, tex_call@86, tex_msx_font@87, current_life@90, max_life@91, current_rank@92, selected_weapon@93, ammo_count@94, selected_item@95, card_number@96, has_incoming_call@97, call_tick_counter@100, call_sign_visible@101, _player@104, _rank_system@105, _weapon_system@106, _inventory@107, _radio_system@108
- 110-114 func _init() -> void
- 116-118 func _ready() -> void
- 120-130 func _load_textures() -> void
- 131-148 func bind_systems(player_ctrl: PlayerController, rank_sys: RankSystem, weapon_sys: WeaponSystem, inv_mgr: I...
- 150-154 func _on_rank_changed(new_rank: int) -> void
- 156-165 func _process(_delta: float) -> void
- 166-208 func update_hud_state() -> bool
- 210-222 func _draw() -> void
- 223-243 func _draw_life() -> void
- 244-256 func _draw_class() -> void
- 257-269 func _draw_call() -> void
- 270-296 func _draw_weapon() -> void
- 297-322 func _draw_item() -> void
- 323-328 func _draw_msx_string(text: String, pos: Vector2, color: Color = COLOR_WHITE) -> void
- 330-344 func _draw_msx_char(ascii_code: int, pos: Vector2, color: Color = COLOR_WHITE) -> void

## godot/scripts/systems/player.gd (849 linhas)
class_name PlayerController · extends Node2D
signals: player_died@46
const/enum: Direction@20, MOV_SPEED_NORMAL@28, MOV_SPEED_SLOW@29, SPEED_NORMAL@30, ANIM_TICKS_PER_FRAME@31, ANIM_STEP_SEC@32, PUNCH_DURATION_SEC@34, INVULNERABLE_DURATION_SEC@35, SHOOT_FLASH_SEC@36, COLLIDER_OFFSETS@39, AnimMode@94
var: current_direction@48, is_moving@49, anim_timer_sec@50, anim_wait_cnt@51, frame_num@56, collision_grid@58, show_debug_colliders@59, life@62, max_life@63, invulnerable_timer_sec@65, invulnerable_timer@66, punch_timer_sec@72, punch_timer@73, is_punching@78, infinite_life@79, equipped_weapon@82, shoot_timer_sec@83, shoot_timer@84, is_in_box@91, anim_mode@105, climb_frame@106, water_frame@107, is_dead@110, can_control@111
- 114-118 func set_rank_life(new_max_life: int, full_heal: bool = true) -> void
- 120-132 func die() -> void
- 134-152 func revive() -> void
- 154-164 static func load_msx_texture() -> void
- 168-217 func _get_msx_sprite_rect() -> Rect2
- 220-222 func _ready() -> void
- 224-225 func set_collision_grid(grid: Array) -> void
- 227-229 func set_grid_position(px: float, py: float) -> void
- 231-243 func punch() -> bool
- 244-270 func fire_weapon(weapon_sys: WeaponSystem) -> Bullet
- 272-288 func apply_damage(amount: int) -> bool
- 289-293 func step_control(controls_hold: int, direction_new: int, delta: float = 1.0 / 60.0) -> bool
- 296-309 static func direction_vector(dir: int) -> Vector2i
- 310-389 func step_tick(input_dir: Vector2i, delta: float = 1.0 / 60.0) -> bool
- 391-411 func is_colliding_at(target_pos: Vector2, dir: Direction) -> bool
- 413-849 func _draw() -> void

## godot/scripts/systems/radio_dialog.gd (548 linhas)
class_name RadioDialog · extends Control
signals: radio_closed@9
const/enum: ENTER_ICON_BITS@43
var: radio_system@11, current_room_id@12, is_active@13, target_full_text@16, displayed_text@17, char_index@18, typewriter_speed@19, typewriter_timer@20, text_finished@21, current_contact@24, current_contact_name@25, current_text@26, has_signal@27, target_leds@30, current_leds@31, led_anim_timer@32, dialog_pages@35, current_page_index@36, is_tuning_locked@37, _up_was_down@38, _left_was_down@39, _right_was_down@40, anim_timer@55, texture_chassis@58, texture_snake_portrait@59, texture_digits@60, texture_120@61, texture_leds@62, texture_msx_font@63
- 65-70 func _ready() -> void
- 72-78 func _load_textures() -> void
- 80-88 func _load_texture(path: String) -> Texture2D
- 90-117 func start_briefing(contact: String, contact_name: String, pages: Array[String], system: RadioSystem = null...
- 118-134 func open_radio(system: RadioSystem, room_id: int, _auto_answer: bool = false) -> void
- 136-148 func close_radio() -> void
- 149-150 func is_showing_text() -> bool
- 152-164 func _physics_process(_delta: float) -> void
- 166-176 func _on_text_requested(text_id: int) -> void
- 178-181 func _finish_text() -> void
- 183-191 func _clear_text() -> void
- 193-223 func _process(delta: float) -> void
- 225-283 func handle_input(event: InputEvent) -> bool
- 285-295 func _display_current_page() -> void
- 296-339 static func _paginate_text(text: String, max_w: float = 184.0, max_lines_per_page: int = 4) -> Array[String]
- 341-443 func _draw() -> void
- 445-459 func _draw_msx_char(ch: int, pos: Vector2, color: Color) -> int
- 461-467 func _draw_msx_line(line_str: String, pos: Vector2, color: Color) -> float
- 469-502 func _draw_msx_multiline(text: String, start_pos: Vector2, max_w: float, line_h: float, color: Color) -> void
- 504-541 func _draw_fallback(is_send: bool) -> void
- 543-548 func _draw_enter_icon(pos: Vector2, color: Color) -> void

## godot/scripts/systems/radio_system.gd (307 linhas)
class_name RadioSystem · extends RefCounted
signals: text_requested@14, sfx_requested@15
const/enum: State@17, CONTACT_BIG_BOSS@19, CONTACT_SCHNEIDER@20, CONTACT_DIANE@21, CONTACT_JENNIFER@22, PERSON_CONTACTS@24, FREQ_BIGBOSS_PR1@28, FREQ_BIGBOSS_PR2@29, FREQ_SCHNEIDER_PR1@30, FREQ_SCHNEIDER_PR2@31, FREQ_DIANE_PR1@32, FREQ_DIANE_PR2@33, FREQ_JENNIFER@34, FREQ_MAX@35, CALL_PENDING@38, CALL_RINGING@39, CALL_STOPPED@40, INCOMING_CALL_BIT@41, CALL_DURATION@42, ANTENNA_CALL_DELAY@43, LED_COUNT@45, LED_FIRST_DELAY@46, LED_STEP_DELAY@47, FREQ_PRESS_DELAY@48, FREQ_REPEAT_DELAY@49, MAP_ZONE_NEEDS_ANTENNA@51, MAP_ZONE_BUILDING1_BASEMENT@52, CLASS_FOUR_STARS@53, SFX_INCOMING_CALL@55, SFX_RADIO_NOISE@56, SFX_MUTE@57, TEXT_SEND@58, TEXT_BUG_WARNING@59, TEXT_SWITCH_OFF_MSX@60, TEXT_MADNAR_CHECK@61, DATA_PATH@63
var: current_freq@65, is_send_mode@66, reply_requested@67, auto_reply_done@68, state@69, signal_leds@70, led_delay@71, hold_wait@72, reply_person@73, waiting_text@74, persons@75, first_person_freq@76, radio_call_flag@77, incoming_call_timer@78, map_zone@79, antenna_taken@81, transmitter_taken@82, schneider_captured@83, jennifer_brother_dead@84, madnar_moved@85, switch_off_msx@86, class_rank@87, has_incoming_call@89
- 98-106 static func data() -> Dictionary
- 107-112 static func text_pages(text_id: int) -> Array[String]
- 114-116 static func room_persons(room_id: int) -> Array
- 118-122 static func room_has_incoming_call(room_id: int) -> bool
- 124-126 static func room_map_zone(room_id: int) -> int
- 128-131 static func bcd_increment(freq: int) -> int
- 133-136 static func bcd_decrement(freq: int) -> int
- 138-139 func get_frequency_string() -> String
- 141-142 func set_frequency(freq: int) -> void
- 144-148 func get_contact_name_for_freq(freq: int) -> String
- 150-153 func reply_contact() -> String
- 154-156 func enter_room(room_id: int) -> void
- 158-167 func update_radio(room_id: int) -> void
- 169-181 func check_radio_calls(room_id: int) -> void
- 183-194 func tick_incoming_call() -> void
- 196-200 func force_pending_call() -> void
- 201-213 func open_radio() -> void
- 214-247 func radio_tick(up_trigger: bool, left_trigger: bool, right_trigger: bool, left_hold: bool, right_hold: boo...
- 249-250 func text_closed() -> void
- 252-254 func _request_text(text_id: int) -> void
- 256-271 func _change_frequency(left_trigger: bool, right_trigger: bool, left_hold: bool, right_hold: bool) -> void
- 273-287 func _check_receive() -> void
- 289-307 func _reply_allowed(person: Dictionary) -> bool

## godot/scripts/systems/room_manager.gd (318 linhas)
class_name RoomManager · extends RefCounted
const/enum: NO_ROOM@22, ROOM_DATA_DIRS@24, EXIT_LEFT_X@27, EXIT_RIGHT_X@28, EXIT_UP_Y@29, EXIT_DOWN_Y@30, ENTRY_Y_FROM_UP@33, ENTRY_Y_FROM_DOWN@34, ENTRY_X_FROM_LEFT@35, ENTRY_X_FROM_RIGHT@36, CONNECTIONS_TABLE@39
var: _snapshot_cache@198, _actors_cache@199
- 202-241 static func get_next_room(room_id: int, dir: PlayerController.Direction) -> int
- 242-253 static func is_room_isolated(room_id: int) -> bool
- 254-265 static func check_room_exit(pos: Vector2) -> int
- 266-279 static func get_entry_position(exit_dir: int, current_pos: Vector2) -> Vector2
- 280-308 func load_room_snapshot(room_id: int) -> RoomSnapshot
- 309-318 func load_room_actors(room_id: int) -> Dictionary

## godot/scripts/systems/shot_gunner.gd (376 linhas)
class_name ShotGunner · extends Node2D
signals: boss_shot_fired@85, boss_defeated@88, intro_dialog@91
const/enum: BOSS_HP@14, BULLET_DAMAGE@18, ROLL_SPEED@21, ROLL_SPEED_PX_PER_SEC@22, ROLL_WAIT@25, ROLL_WAIT_SEC@26, SHOOT_WAIT@29, SHOOT_WAIT_SEC@30, SHOT_INTERVAL@33, SHOT_INTERVAL_SEC@34, INTRO_DELAY@37, INTRO_DELAY_SEC@38, SGunnerState@43
var: boss_hp@52, is_dead@53, state@54, wait_timer@55, anim_tick@56, intro_speech_done@57, roll_dir@60, speed_x@61, collision_grid@64, player_pos@67, flash_timer@70, muzzle_flash_timer@71, has_fired_this_stop@74, roll_frame@78, _boss_texture@97
- 99-102 func _ready() -> void
- 104-115 func setup(spawn_pos: Vector2, grid: Array, initial_player_pos: Vector2) -> void
- 117-140 func step_tick(p_pos: Vector2, grid: Array, delta: float = 1.0 / 60.0) -> void
- 142-159 func _tick_intro() -> void
- 161-180 func _tick_roll(delta: float = 1.0 / 60.0) -> void
- 182-205 func _tick_shoot() -> void
- 207-212 func _transition_to_roll() -> void
- 214-224 func _transition_to_shoot() -> void
- 226-249 func _check_tile_collision_horizontal(going_right: bool) -> bool
- 251-262 func _decide_roll_direction() -> void
- 264-283 func apply_bullet_hit() -> bool
- 285-293 func _on_defeat() -> void
- 294-308 func _get_sprite_rect() -> Rect2
- 310-376 func _draw() -> void

## godot/tests/capture_prison_test.gd (494 linhas)
extends SceneTree
var: _pass@6, _fail@7
- 9-13 func _initialize() -> void
- 15-21 func _assert(cond: bool, msg: String) -> void
- 23-39 func _run_all() -> void
- 40-64 func _test_capture_trigger_bounds() -> void
- 65-108 func _test_execute_capture_and_backup() -> void
- 109-130 func _test_prison_spawn_and_input_restrictions() -> void
- 131-164 func _test_hollow_wall_punch_detection() -> void
- 165-189 func _test_wall_collision_and_tile_break() -> void
- 190-204 func _test_room_connections_211_212() -> void
- 205-244 func _test_bag_restitution() -> void
- 245-263 func _test_reset_state() -> void
- 264-324 func _test_prison_flow_integration() -> void
- 325-366 func _test_room_212_to_room_54_transition() -> void
- 367-390 func _test_capture_cutscene_spawns_and_positions() -> void
- 391-440 func _test_capture_cutscene_dialog_and_timing() -> void
- 441-492 func _test_capture_cutscene_fade_and_completion() -> void

## godot/tests/doors_and_inventory_test.gd (398 linhas)
extends SceneTree
- 3-4 func _initialize() -> void
- 6-11 func require(condition: bool, message: String) -> bool
- 13-397 func _run() -> void

## godot/tests/prisoner_dialog_test.gd (322 linhas)
extends SceneTree
var: failures@3, checks@4
- 6-7 func _initialize() -> void
- 9-13 func check(condition: bool, message: String) -> void
- 15-20 func key(code: Key, echo: bool = false) -> InputEventKey
- 22-24 func ticks(dialog: PrisonerDialog, count: int) -> void
- 26-86 func run() -> void
- 88-94 func full_page() -> Array
- 95-111 func prompt_cell_timing(dialog: PrisonerDialog) -> void
- 112-142 func prisoner_state_machine() -> void
- 143-168 func sandbox_rescue_tick() -> void
- 170-255 func private_integration() -> void
- 257-322 func render_pages(data: Dictionary) -> void
