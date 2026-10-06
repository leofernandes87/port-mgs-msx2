# Índice de testes

Gerado por `tools/context/build_index.py` a partir de `tools/validate.py`; não editar.
Rodar uma suíte: `$GODOT --headless --path godot --script res://tests/ARQUIVO`; passa só se o
marcador aparecer e não houver `ERROR:`. Suíte nova: acrescentar a `GODOT_TESTS` e regenerar.

## Godot (ordem do validate)

- `godot-smoke` · `smoke_test.gd` · `SMOKE_OK:` · scenes/main.tscn
- `godot-game-clock` · `game_clock_test.gd` · `GAME_CLOCK_OK:` · scenes/sandbox_gameplay.tscn, scripts/scenes/sandbox_gameplay.gd, scripts/systems/game_clock.gd, scripts/systems/intro_cutscene.gd
- `godot-room-snapshot` · `room_snapshot_test.gd` · `ROOM_SNAPSHOT_OK:` · scenes/room_inspector.tscn, scripts/systems/rom_provenance.gd, scripts/systems/room_canvas.gd, scripts/systems/room_manager.gd, scripts/systems/room_snapshot.gd
- `godot-player-movement` · `player_movement_test.gd` · `PLAYER_MOVEMENT_OK:` · scenes/player.tscn, scenes/sandbox_gameplay.tscn, scripts/systems/player.gd
- `godot-room-transition` · `room_transition_test.gd` · `ROOM_TRANSITION_OK:` · scenes/sandbox_gameplay.tscn, scripts/systems/enemy.gd, scripts/systems/player.gd, scripts/systems/room_manager.gd, scripts/systems/room_snapshot.gd
- `godot-enemy-patrol` · `enemy_patrol_test.gd` · `ENEMY_PATROL_OK:` · scenes/enemy.tscn, scripts/systems/enemy.gd, scripts/systems/player.gd
- `godot-combat-health` · `combat_and_health_test.gd` · `COMBAT_AND_HEALTH_OK:` · scenes/enemy.tscn, scenes/player.tscn, scenes/sandbox_gameplay.tscn, scripts/systems/alert_system.gd, scripts/systems/bullet.gd, scripts/systems/enemy.gd, scripts/systems/inventory.gd, scripts/systems/player.gd, scripts/systems/room_snapshot.gd, scripts/systems/weapon_system.gd
- `godot-doors-inventory` · `doors_and_inventory_test.gd` · `DOORS_AND_INVENTORY_OK:` · scenes/player.tscn, scenes/sandbox_gameplay.tscn, scripts/scenes/sandbox_gameplay.gd, scripts/systems/door.gd, scripts/systems/inventory.gd, scripts/systems/item_box.gd, scripts/systems/player.gd, scripts/systems/room_manager.gd
- `godot-elevator` · `elevator_test.gd` · `ELEVATOR_OK:` · scenes/sandbox_gameplay.tscn, scripts/systems/door.gd, scripts/systems/elevator_system.gd, scripts/systems/player.gd
- `godot-weapon-combat` · `weapon_and_combat_test.gd` · `WEAPONS_AND_COMBAT_OK:` · scenes/enemy.tscn, scenes/player.tscn, scripts/systems/bullet.gd, scripts/systems/enemy.gd, scripts/systems/player.gd, scripts/systems/weapon_system.gd
- `godot-building-doors` · `building_doors_test.gd` · `BUILDING_DOORS_OK:` · scenes/sandbox_gameplay.tscn, scripts/systems/door.gd, scripts/systems/inventory.gd, scripts/systems/item_box.gd, scripts/systems/player.gd, scripts/systems/weapon_system.gd
- `godot-radio-system` · `radio_system_test.gd` · `RADIO_SYSTEM_OK:` · scenes/sandbox_gameplay.tscn, scripts/systems/player.gd, scripts/systems/radio_dialog.gd, scripts/systems/radio_system.gd
- `godot-cameras-and-lasers` · `cameras_and_lasers_test.gd` · `CAMERAS_AND_LASERS_OK:` · scripts/systems/laser_system.gd, scripts/systems/security_camera.gd
- `godot-alert-system` · `alert_system_test.gd` · `ALERT_SYSTEM_OK:` · scripts/systems/alert_system.gd
- `godot-boss-shoot-gunner` · `shot_gunner_test.gd` · `BOSS_SHOOT_GUNNER_OK:` · scripts/systems/shot_gunner.gd, scripts/systems/shot_gunner_bullet.gd
- `godot-rank-and-prisoners` · `rank_and_prisoners_test.gd` · `RANK_AND_PRISONERS_OK:` · scripts/systems/inventory.gd, scripts/systems/player.gd, scripts/systems/prisoner.gd, scripts/systems/rank_system.gd, scripts/systems/weapon_system.gd
- `godot-prisoner-dialog` · `prisoner_dialog_test.gd` · `PRISONER_DIALOG_OK:` · scenes/sandbox_gameplay.tscn, scripts/scenes/sandbox_gameplay.gd, scripts/systems/bullet.gd, scripts/systems/prisoner.gd, scripts/systems/prisoner_dialog.gd, scripts/systems/rom_provenance.gd
- `godot-gas-hazard` · `gas_hazard_test.gd` · `GAS_HAZARD_OK:` · scripts/systems/gas_cloud.gd, scripts/systems/gas_hazard_system.gd, scripts/systems/inventory.gd, scripts/systems/player.gd
- `godot-remote-missile` · `remote_missile_test.gd` · `REMOTE_MISSILE_OK:` · scripts/systems/enemy.gd, scripts/systems/inventory.gd, scripts/systems/item_box.gd, scripts/systems/player.gd, scripts/systems/rank_system.gd, scripts/systems/remote_missile.gd, scripts/systems/room_manager.gd, scripts/systems/weapon_system.gd
- `godot-capture-prison` · `capture_prison_test.gd` · `CAPTURE_PRISON_OK:` · scripts/systems/bullet.gd, scripts/systems/capture_cutscene.gd, scripts/systems/capture_system.gd, scripts/systems/door.gd, scripts/systems/inventory.gd, scripts/systems/item_box.gd, scripts/systems/player.gd, scripts/systems/prison_wall_door.gd, scripts/systems/room_manager.gd, scripts/systems/weapon_system.gd
- `godot-prison-wall` · `prison_wall_integration_test.gd` · `PRISON_WALL_INTEGRATION_OK:` · scenes/sandbox_gameplay.tscn, scripts/systems/capture_system.gd, scripts/systems/door.gd, scripts/systems/player.gd, scripts/systems/prison_wall_door.gd, scripts/systems/rom_provenance.gd, scripts/systems/room_snapshot.gd
- `godot-electrified-floor` · `electrified_floor_test.gd` · `ELECTRIFIED_FLOOR_TEST_OK:` · scripts/systems/electrified_floor_system.gd, scripts/systems/power_panel.gd
- `godot-elevator-guards` · `elevator_guard_test.gd` · `ELEVATOR_GUARD_OK:` · scenes/sandbox_gameplay.tscn, scripts/systems/enemy.gd, scripts/systems/player.gd
- `godot-room-007-patrol` · `room_007_patrol_test.gd` · `ROOM_007_PATROL_OK:` · scenes/sandbox_gameplay.tscn, scripts/systems/enemy.gd, scripts/systems/inventory.gd, scripts/systems/item_box.gd, scripts/systems/player.gd, scripts/systems/weapon_system.gd
- `godot-binoculars` · `binocular_test.gd` · `BINOCULARS_TEST_OK:` · scripts/scenes/sandbox_gameplay.gd, scripts/systems/binocular_overlay.gd, scripts/systems/binocular_system.gd, scripts/systems/inventory.gd, scripts/systems/item_menu.gd, scripts/systems/player.gd, scripts/systems/room_manager.gd
- `godot-dogs` · `dog_patrol_test.gd` · `DOG_PATROL_TEST_OK:` · scenes/sandbox_gameplay.tscn, scripts/scenes/sandbox_gameplay.gd, scripts/systems/alert_system.gd, scripts/systems/enemy.gd, scripts/systems/player.gd
- `godot-sleepy-guard` · `sleepy_guard_test.gd` · `SLEEPY_GUARD_TEST_OK:` · scenes/sandbox_gameplay.tscn, scripts/scenes/sandbox_gameplay.gd, scripts/systems/enemy.gd, scripts/systems/player.gd
- `godot-floor3-review` · `floor3_review_test.gd` · `FLOOR3_REVIEW_TEST_OK:` · scenes/sandbox_gameplay.tscn, scripts/systems/door.gd, scripts/systems/electrified_floor_system.gd, scripts/systems/enemy.gd, scripts/systems/inventory.gd, scripts/systems/item_box.gd, scripts/systems/player.gd, scripts/systems/prisoner.gd, scripts/systems/security_camera.gd, scripts/systems/weapon_system.gd
- `godot-basement-and-plastic-bomb` · `basement_and_plastic_bomb_test.gd` · `BASEMENT_AND_PLASTIC_BOMB_TEST_OK:` · scenes/sandbox_gameplay.tscn, scripts/systems/door.gd, scripts/systems/enemy.gd, scripts/systems/inventory.gd, scripts/systems/item_box.gd, scripts/systems/plastic_bomb.gd, scripts/systems/player.gd, scripts/systems/weapon_system.gd
- `godot-title-screen` · `title_screen_test.gd` · `TITLE_SCREEN_INTEGRATION_OK:` · scenes/title_screen.tscn
- `godot-intro-cutscene` · `intro_cutscene_test.gd` · `INTRO_CUTSCENE_INTEGRATION_OK:` · scripts/systems/intro_cutscene.gd, scripts/systems/player.gd, scripts/systems/radio_dialog.gd, scripts/systems/radio_system.gd
- `godot-hud` · `hud_test.gd` · `HUD_INTEGRATION_TEST_OK:` · scripts/systems/hud.gd, scripts/systems/inventory.gd, scripts/systems/player.gd, scripts/systems/radio_system.gd, scripts/systems/rank_system.gd, scripts/systems/weapon_system.gd
- `godot-item-box-sprites` · `item_box_sprites_test.gd` · `ITEM_BOX_SPRITES_TEST_OK:` · scripts/systems/inventory.gd, scripts/systems/item_box.gd, scripts/systems/weapon_system.gd
- `godot-rolling-barrels` · `rolling_barrel_test.gd` · `ROLLING_BARREL_TEST_OK:` · scenes/sandbox_gameplay.tscn, scripts/systems/player.gd, scripts/systems/rolling_barrel.gd

## Python (`python3 -m unittest discover -s tests`)

- `tests/test_context_index.py` · AsmSymbolTests, CitationTests, OutlineTests, MechanicsTests, CoverageTests, EntryDocTests, ProgressArchiveTests · tools.context
- `tests/test_context_lookup.py` · MechanicsLookupTests · tools.context
- `tests/test_door_sprite_extractor.py` · DoorSpriteExtractorTests · tools.extractors.extract_door_sprites
- `tests/test_emulation.py` · CaptureComparisonTests · tools.emulation.compare, tools.extractors.schema
- `tests/test_enemy_sprite_extractor.py` · EnemySpriteExtractorTests · tools.extractors.extract_enemy_sprites
- `tests/test_extractors.py` · CodecTests, ContractAndSafetyTests, BatchSnapshotTests, ExportRoomDataTests · tools.extractors.batch_snapshots, tools.extractors.codecs, tools.extractors.export_room_data, tools.extractors.extract, tools.extractors.schema, tools.reverse_engineering.analyze
- `tests/test_grey_fox_dialogue.py` · DialogueTests · tools.extractors.extract_grey_fox_dialogue, tools.extractors.extract_transceiver_sprites
- `tests/test_hud_extractor.py` · TestHUDExtractor · tools.extractors.extract_hud_assets
- `tests/test_prison_wall_extractor.py` · PrisonWallExtractorTests · tools.extractors.extract_prison_wall
- `tests/test_prisoner_sprite_extractor.py` · PrisonerSpriteExtractorTests · tools.extractors.extract_prisoner_sprites
- `tests/test_radio_dialogue_extractor.py` · RadioDialogueTests · tools.extractors.extract_radio_dialogue
- `tests/test_region_tools.py` · LocalAliases, TraceRelocation, RegionClassifier, GodotRadioFollowsEnglishEdition · tools.emulation.run_trace, tools.extractors.export_local_aliases, tools.reverse_engineering.compare_regions, tools.rom
- `tests/test_repository.py` · RepositoryPolicyTests · —
- `tests/test_reverse_engineering.py` · AnalysisTests · tools.reverse_engineering.analyze
- `tests/test_rolling_barrel_extractor.py` · RollingBarrelExtractorTests · tools.extractors.codecs, tools.extractors.extract_rolling_barrel
- `tests/test_rom.py` · SyntheticProfiles, RealProfileFile, CanonicalProvenance, ConsumedDataProvenance, RomPolicyLint · tools.rom
- `tests/test_shoot_gunner_sprite_extractor.py` · ShootGunnerSpriteExtractorTests · tools.extractors.extract_shoot_gunner_sprites
- `tests/test_snake_sprite_extractor.py` · SnakeSpriteExtractorTests · tools.extractors.extract_snake_sprites
- `tests/test_title_intro_extractor.py` · TitleIntroExtractorTests · tools.extractors.extract_title_intro_sprites
- `tests/test_transceiver_extractor.py` · TestTransceiverExtractor · tools.extractors.extract_transceiver_sprites
