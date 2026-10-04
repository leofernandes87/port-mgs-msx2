# Citações reversas do assembly

Gerado por `tools/context/build_index.py`; não editar. Para cada trecho de `external/MetalGear/`
citado como `arquivo.asm:linhas`, os arquivos do projeto que o citam (histórico de progresso
excluído). Antes de mudar uma rotina, veja quem depende dela: `rg -n "^## logic/items.asm" -A20`.

## Banks0123.asm
- arquivo: .agents/skills/inspect-msx-disassembly/SKILL.md, AGENTS.md, docs/reverse_engineering/architecture.md, docs/reverse_engineering/enemies.md, docs/reverse_engineering/inventory-and-events.md, docs/reverse_engineering/memory-and-banks.md, docs/reverse_engineering/movement-and-collision.md, docs/reverse_engineering/stage-12b-actors-and-items-evidence.md, docs/reverse_engineering/stage-19-gas-hazard.md, docs/reverse_engineering/stage-3-results.md, docs/reverse_engineering/stage-5-movement-and-collision.md, godot/scripts/systems/elevator_system.gd, godot/scripts/systems/radio_system.gd, godot/scripts/systems/room_manager.gd, tests/test_region_tools.py, tools/extractors/extract.py, tools/extractors/extract_hud_assets.py, tools/extractors/extract_transceiver_sprites.py, tools/extractors/reference.py
- 7: docs/reference.md
- 8: docs/reverse_engineering/architecture.md
- 440: docs/reverse_engineering/architecture.md
- 440-466: docs/reverse_engineering/intro-fence-timing.md, godot/scripts/systems/intro_cutscene.gd
- 552: docs/reverse_engineering/architecture.md
- 554: docs/reverse_engineering/en-eu-reextraction.md, tools/reverse_engineering/compare_regions.py
- 621: docs/reverse_engineering/memory-and-banks.md
- 889: docs/reverse_engineering/stage-6-room-transitions.md, godot/scripts/systems/room_manager.gd
- 889-918: docs/index/rooms.md
- 1005-1020: docs/reverse_engineering/prison-wall.md
- 1009-1026: docs/reverse_engineering/stage-10-lorries-and-canonical-items.md
- 1030: godot/tests/binocular_test.gd
- 1030-1048: godot/scripts/systems/binocular_system.gd, godot/scripts/systems/room_manager.gd
- 1038: docs/index/rooms.md
- 1270: docs/reverse_engineering/inventory-and-events.md, docs/reverse_engineering/stage-4-results.md
- 1283: docs/reverse_engineering/stage-3-results.md
- 1480-1531: docs/reverse_engineering/prison-wall.md, tools/extractors/extract_prison_wall.py
- 1689-1743: .agents/skills/inspect-msx-disassembly/SKILL.md
- 1729-1733: docs/reverse_engineering/en-eu-reextraction.md
- 1729-1739: godot/scripts/systems/radio_system.gd
- 2025: docs/reverse_engineering/en-eu-reextraction.md
- 2092-2141: godot/scripts/systems/hud.gd
- 2139: godot/scripts/systems/hud.gd
- 2270-2312: godot/scripts/systems/hud.gd
- 2413-2425: docs/reverse_engineering/en-eu-reextraction.md
- 2455-2462: godot/scripts/systems/radio_system.gd
- 2549: docs/reverse_engineering/stage-4b-vram-inheritance.md
- 2890: tools/extractors/extract_hud_assets.py
- 2998-3002: tools/extractors/extract_transceiver_sprites.py
- 2999: tests/test_hud_extractor.py, tools/extractors/extract_hud_assets.py
- 3390: docs/reverse_engineering/maps.md
- 3391: docs/reverse_engineering/stage-4-results.md
- 3394: docs/reverse_engineering/stage-4b-vram-inheritance.md
- 3684: docs/reverse_engineering/architecture.md
- 3776: docs/reverse_engineering/stage-4-results.md
- 3982: docs/reverse_engineering/stage-4-results.md
- 4148-4170: godot/scripts/systems/prisoner_dialog.gd
- 4550: tools/extractors/extract_hud_assets.py
- 4703: godot/scripts/systems/radio_dialog.gd
- 4726-4744: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner_dialog.gd
- 4741-4744: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner_dialog.gd
- 4806-4809: godot/scripts/systems/prison_wall_door.gd
- 4885: docs/reverse_engineering/stage-4-results.md
- 5204: docs/reverse_engineering/stage-3-results.md, tools/extractors/extract_hud_assets.py, tools/extractors/extract_transceiver_sprites.py
- 5274: docs/reverse_engineering/inventory-and-events.md
- 5305-5391: docs/reverse_engineering/grey-fox-dialogue.md, tools/extractors/extract_grey_fox_dialogue.py
- 5353: docs/reverse_engineering/en-eu-reextraction.md
- 5405-5457: docs/reverse_engineering/intro-water-colors.md
- 5543-5580: tools/extractors/extract_enemy_sprites.py, tools/extractors/extract_prisoner_sprites.py, tools/extractors/extract_shoot_gunner_sprites.py, tools/extractors/extract_snake_sprites.py
- 5653-5847: godot/scripts/systems/laser_system.gd
- 5797: godot/scripts/systems/laser_system.gd
- 6117: godot/scripts/scenes/sandbox_gameplay.gd
- 6145: docs/reverse_engineering/stage-3-results.md
- 6404: docs/reverse_engineering/stage-12b-actors-and-items-evidence.md, godot/scripts/scenes/sandbox_gameplay.gd
- 6409: godot/scripts/systems/security_camera.gd
- 6550-6720: godot/scripts/systems/alert_system.gd
- 6559-6628: docs/reverse_engineering/stage-17-alert-evasion-reinforcements.md, godot/scripts/systems/alert_system.gd
- 6576: godot/scripts/systems/alert_system.gd
- 6635-6713: docs/reverse_engineering/stage-17-alert-evasion-reinforcements.md
- 6644-6670: godot/scripts/systems/alert_system.gd
- 6646: godot/scripts/systems/alert_system.gd, godot/tests/alert_system_test.gd
- 6669: godot/scripts/systems/alert_system.gd
- 6698: godot/scripts/systems/alert_system.gd
- 6726: godot/scripts/systems/enemy.gd
- 6815-6844: godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/enemy.gd, godot/tests/sleepy_guard_test.gd
- 6822: docs/reverse_engineering/stage-19-gas-hazard.md
- 6832-6837: godot/scripts/systems/enemy.gd
- 6834-6837: godot/tests/sleepy_guard_test.gd
- 6852: docs/reverse_engineering/enemies.md
- 7039: godot/scripts/systems/enemy.gd
- 7042: godot/scripts/systems/enemy.gd
- 7045: godot/scripts/systems/enemy.gd
- 7120: godot/scripts/systems/enemy.gd
- 7188: docs/reverse_engineering/stage-3-results.md
- 7324-7332: godot/scripts/systems/prisoner.gd
- 7570: docs/reverse_engineering/movement-and-collision.md
- 7798-8303: godot/scripts/systems/prisoner_dialog.gd
- 7824-7828: docs/reverse_engineering/grey-fox-dialogue.md
- 7824-7829: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/scenes/sandbox_gameplay.gd
- 7952-7968: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner_dialog.gd
- 7987-7997: docs/reverse_engineering/grey-fox-dialogue.md
- 8010-8033: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner_dialog.gd
- 8035-8043: docs/reverse_engineering/grey-fox-dialogue.md
- 8072: godot/scripts/systems/radio_dialog.gd
- 8102-8107: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner_dialog.gd, godot/tests/prisoner_dialog_test.gd
- 8118: godot/scripts/systems/radio_dialog.gd
- 8130-8136: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner_dialog.gd
- 8179-8185: docs/reverse_engineering/grey-fox-dialogue.md
- 8201-8219: godot/scripts/systems/radio_dialog.gd
- 8344: godot/tests/radio_system_test.gd
- 8345: godot/scripts/systems/capture_cutscene.gd
- 8365-8387: docs/reverse_engineering/grey-fox-dialogue.md
- 8397: docs/reverse_engineering/movement-and-collision.md
- 8400-8402: godot/scripts/systems/hud.gd
- 8407: godot/scripts/systems/player.gd
- 8415: godot/scripts/systems/player.gd
- 8422-8438: godot/scripts/systems/intro_cutscene.gd
- 8468: godot/scripts/scenes/sandbox_gameplay.gd
- 8468-8470: docs/reverse_engineering/stage-20-rc-missile.md
- 8540-8556: godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/elevator_system.gd
- 8840-8842: godot/scripts/systems/intro_cutscene.gd
- 8850-8895: docs/reverse_engineering/intro-fence-timing.md
- 8934: docs/reverse_engineering/stage-8-combat-and-health.md
- 8949: godot/scripts/systems/player.gd
- 8949-8954: docs/reverse_engineering/prison-wall.md
- 8972: docs/reverse_engineering/movement-and-collision.md
- 8972-8997: docs/reverse_engineering/intro-fence-timing.md, godot/scripts/systems/intro_cutscene.gd
- 9360: godot/scripts/systems/player.gd
- 9418: docs/reverse_engineering/movement-and-collision.md, docs/reverse_engineering/stage-6-room-transitions.md, godot/scripts/systems/room_manager.gd
- 9549: docs/reverse_engineering/movement-and-collision.md
- 9574-9679: godot/scripts/systems/rank_system.gd, godot/tests/rank_and_prisoners_test.gd
- 9581-9625: godot/scripts/systems/rank_system.gd
- 9593: docs/reverse_engineering/grey-fox-dialogue.md
- 9634-9641: docs/STATUS.md
- 9651-9677: godot/tests/prisoner_dialog_test.gd
- 9656: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/scenes/sandbox_gameplay.gd
- 9672: docs/reverse_engineering/stage-8-combat-and-health.md, godot/scripts/systems/player.gd
- 9687: docs/reverse_engineering/movement-and-collision.md
- 9724: godot/scripts/systems/player.gd
- 9827-9843: docs/reverse_engineering/intro-water-colors.md, godot/scripts/systems/intro_cutscene.gd
- 9827-9877: docs/reverse_engineering/intro-fence-timing.md
- 10058: docs/reverse_engineering/architecture.md
- 10695-10730: godot/scripts/systems/radio_dialog.gd
- 10787: godot/scripts/systems/radio_dialog.gd
- 10906-10958: godot/tests/radio_system_test.gd
- 10938-10945: godot/scripts/systems/radio_system.gd
- 10948-10957: godot/scripts/systems/radio_system.gd
- 10968: godot/scripts/systems/radio_system.gd
- 10971-10990: docs/reverse_engineering/en-eu-reextraction.md, godot/scripts/systems/radio_system.gd
- 11672-11743: godot/scripts/systems/capture_cutscene.gd
- 11775: godot/scripts/systems/inventory.gd
- 11797-11799: docs/reverse_engineering/prison-wall.md, godot/scripts/systems/capture_system.gd, tools/extractors/extract_capture_prison_data.py
- 11908: docs/reverse_engineering/stage-4-results.md
- 11914-11916: docs/reverse_engineering/intro-water-colors.md, tools/extractors/extract_snake_sprites.py
- 12015: docs/reverse_engineering/architecture.md
- 12072-12087: docs/reverse_engineering/grey-fox-dialogue.md
- 12151: .agents/skills/implement-faithful-mechanic/SKILL.md, docs/reverse_engineering/architecture.md
- 12223-12224: godot/tests/prisoner_dialog_test.gd
- 12250: godot/scripts/scenes/sandbox_gameplay.gd
- 12250-12604: godot/scripts/systems/binocular_system.gd, godot/tests/binocular_test.gd
- 12256: godot/scripts/scenes/sandbox_gameplay.gd
- 12481: godot/scripts/systems/binocular_system.gd
- 12513-12515: godot/tests/binocular_test.gd
- 12572-12604: godot/scripts/systems/binocular_overlay.gd
- 12599: godot/scripts/systems/binocular_overlay.gd
- 12612: docs/reverse_engineering/enemies.md
- 12815: docs/reverse_engineering/stage-8-combat-and-health.md
- 12819: godot/scripts/systems/enemy.gd
- 12822: godot/scripts/systems/enemy.gd
- 12996-13003: docs/reverse_engineering/stage-18-shoot-gunner.md, godot/scripts/systems/shot_gunner.gd

## Banks456.asm
- arquivo: docs/reverse_engineering/memory-and-banks.md
- 9: docs/reference.md
- 66: docs/reverse_engineering/en-eu-reextraction.md
- 66-84: docs/reverse_engineering/en-eu-reextraction.md

## Banks789.asm
- arquivo: docs/reverse_engineering/memory-and-banks.md, docs/reverse_engineering/stage-3-results.md, tools/extractors/reference.py
- 9: docs/reference.md

## BanksABC.asm
- arquivo: docs/reverse_engineering/memory-and-banks.md
- 9: docs/reference.md
- 24: docs/reverse_engineering/en-eu-reextraction.md

## BanksDEF.asm
- arquivo: docs/reverse_engineering/memory-and-banks.md, docs/reverse_engineering/rom-compatibility.md, tools/extractors/reference.py
- 9: docs/reference.md
- 11: docs/reverse_engineering/maps.md
- 21: docs/reverse_engineering/en-eu-reextraction.md

## MetalGear.asm
- arquivo: docs/reverse_engineering/README.md, tools/reverse_engineering/compare_regions.py, tools/rom.py
- 38: .agents/skills/inspect-msx-disassembly/SKILL.md, docs/reference.md, docs/reverse_engineering/README.md, docs/reverse_engineering/rom-compatibility.md
- 59: docs/reverse_engineering/memory-and-banks.md

## Variables.asm
- arquivo: .agents/skills/inspect-msx-disassembly/SKILL.md, docs/reference.md, docs/reverse_engineering/README.md, docs/reverse_engineering/inventory-and-events.md, docs/reverse_engineering/stage-5-movement-and-collision.md, tools/emulation/README.md, tools/reverse_engineering/analyze.py
- 8: docs/reverse_engineering/memory-and-banks.md
- 32: docs/reverse_engineering/architecture.md
- 144: docs/reverse_engineering/movement-and-collision.md
- 202: docs/reverse_engineering/stage-4-results.md
- 214: docs/reverse_engineering/inventory-and-events.md
- 272-285: docs/reverse_engineering/stage-17-alert-evasion-reinforcements.md
- 359-360: docs/reverse_engineering/intro-fence-timing.md
- 402: docs/reverse_engineering/stage-4-results.md

## constants/Enums.asm
- arquivo: .agents/skills/inspect-msx-disassembly/SKILL.md, docs/reverse_engineering/stage-12b-actors-and-items-evidence.md, godot/scripts/systems/radio_system.gd, tests/test_region_tools.py, tools/extractors/reference.py
- 15-22: godot/scripts/systems/radio_system.gd
- 63: docs/reverse_engineering/movement-and-collision.md
- 113-122: docs/reverse_engineering/stage-12b-actors-and-items-evidence.md, godot/tests/building_doors_test.gd
- 175: godot/scripts/systems/security_camera.gd
- 202: docs/reverse_engineering/stage-18-shoot-gunner.md
- 212: docs/reverse_engineering/stage-18-shoot-gunner.md

## constants/SystemVariables.asm
- arquivo: docs/reverse_engineering/memory-and-banks.md
- 16: docs/reverse_engineering/architecture.md

## constants/bios.asm
- arquivo: docs/reverse_engineering/architecture.md, docs/reverse_engineering/memory-and-banks.md

## constants/structures.asm
- arquivo: docs/reverse_engineering/enemies.md

## data/actorsinrooms.asm
- arquivo: docs/reverse_engineering/enemies.md, docs/reverse_engineering/stage-12b-actors-and-items-evidence.md, docs/reverse_engineering/stage-19-gas-hazard.md, docs/reverse_engineering/stage-3-results.md, docs/reverse_engineering/stage-7-enemy-patrols.md, godot/tests/dog_patrol_test.gd, tools/extractors/extract_electrified_floor_data.py, tools/extractors/reference.py
- 370-372: docs/reverse_engineering/stage-18-shoot-gunner.md

## data/actorspriteattr.asm
- arquivo: godot/scripts/systems/shot_gunner.gd, tools/extractors/extract_enemy_sprites.py, tools/extractors/extract_prisoner_sprites.py, tools/extractors/extract_shoot_gunner_sprites.py
- 40: godot/scripts/systems/enemy.gd
- 127-130: docs/reverse_engineering/stage-18-shoot-gunner.md
- 129: godot/scripts/systems/shot_gunner.gd
- 378-380: tools/extractors/extract_prisoner_sprites.py
- 434-437: godot/scripts/systems/shot_gunner_bullet.gd

## data/doors.asm
- arquivo: docs/reverse_engineering/maps.md, docs/reverse_engineering/stage-12b-actors-and-items-evidence.md, docs/reverse_engineering/stage-3-results.md, docs/reverse_engineering/stage-9-doors-and-inventory.md, godot/scripts/systems/door.gd, tools/extractors/reference.py
- 15-35: godot/scripts/systems/door.gd
- 26-29: godot/scripts/systems/prison_wall_door.gd
- 27: docs/reverse_engineering/prison-wall.md
- 28-29: docs/reverse_engineering/prison-wall.md, godot/scripts/systems/capture_system.gd
- 311-316: docs/reverse_engineering/stage-10-lorries-and-canonical-items.md
- 314: godot/scripts/scenes/sandbox_gameplay.gd
- 427: docs/reverse_engineering/prison-wall.md
- 634-638: docs/reverse_engineering/stage-10-lorries-and-canonical-items.md
- 724: docs/reverse_engineering/prison-wall.md
- 724-728: docs/index/rooms.md, docs/reverse_engineering/prison-wall.md, godot/scripts/systems/room_manager.gd, tools/extractors/export_local_aliases.py
- 728: tools/extractors/extract_capture_prison_data.py
- 887-902: docs/reverse_engineering/stage-3-results.md
- 917-918: docs/reverse_engineering/stage-10-lorries-and-canonical-items.md
- 992-1031: tools/extractors/extract_prison_wall.py
- 1001-1015: tools/extractors/extract_capture_prison_data.py
- 1001-1031: docs/reverse_engineering/prison-wall.md

## data/elevatorrooms.asm
- arquivo: godot/scripts/systems/elevator_system.gd

## data/hudstartendtexts.asm
- 45: godot/scripts/systems/hud.gd
- 55: godot/scripts/systems/hud.gd

## data/itemgfxxy.asm
- arquivo: tools/extractors/extract_hud_assets.py
- 4-30: godot/scripts/systems/item_box.gd

## data/itemnames.asm
- arquivo: docs/reverse_engineering/en-eu-reextraction.md

## data/itemsinrooms.asm
- arquivo: docs/reverse_engineering/inventory-and-events.md, docs/reverse_engineering/stage-10-lorries-and-canonical-items.md, docs/reverse_engineering/stage-12b-actors-and-items-evidence.md, docs/reverse_engineering/stage-3-results.md, docs/reverse_engineering/stage-9-doors-and-inventory.md, godot/scripts/systems/inventory.gd, godot/scripts/systems/item_box.gd, tools/extractors/extract_capture_prison_data.py, tools/extractors/reference.py, tools/reverse_engineering/compare_regions.py
- 19-46: docs/reverse_engineering/stage-12b-actors-and-items-evidence.md
- 91: docs/reverse_engineering/stage-19-gas-hazard.md
- 155: godot/scripts/systems/capture_system.gd

## data/itemtakeamount.asm
- arquivo: godot/scripts/systems/item_box.gd

## data/itemtaketextid.asm
- 9: docs/reverse_engineering/en-eu-reextraction.md

## data/laserconfig.asm
- arquivo: godot/scripts/systems/laser_system.gd
- 41-51: godot/scripts/systems/laser_system.gd

## data/menuradiotexts.asm
- 7: godot/scripts/systems/radio_dialog.gd
- 11: godot/scripts/systems/radio_dialog.gd

## data/metatiles.asm
- arquivo: docs/reverse_engineering/maps.md, docs/reverse_engineering/rom-compatibility.md, docs/reverse_engineering/stage-3-results.md, tools/extractors/reference.py, tools/reverse_engineering/analyze.py
- 6: docs/reverse_engineering/maps.md
- 229: docs/reverse_engineering/maps.md
- 359: docs/reverse_engineering/maps.md
- 472: docs/reverse_engineering/maps.md
- 498: docs/reverse_engineering/maps.md
- 602: docs/reverse_engineering/maps.md

## data/musicradioconfig.asm
- arquivo: tests/test_region_tools.py
- 9: godot/scripts/systems/radio_system.gd
- 16: docs/reverse_engineering/en-eu-reextraction.md

## data/palettes.asm
- arquivo: docs/reverse_engineering/stage-3-results.md, tools/extractors/extract_shoot_gunner_sprites.py, tools/extractors/extract_transceiver_sprites.py, tools/extractors/reference.py
- 4-10: docs/reverse_engineering/intro-water-colors.md
- 7: tools/extractors/extract_hud_assets.py
- 8-9: godot/scripts/systems/player.gd, tools/extractors/extract_snake_sprites.py
- 15: tools/extractors/extract_transceiver_sprites.py
- 70-168: docs/reverse_engineering/intro-water-colors.md

## data/paths.asm
- arquivo: docs/reverse_engineering/enemies.md, docs/reverse_engineering/intermediate-data-model.md, docs/reverse_engineering/stage-3-results.md, docs/reverse_engineering/stage-7-enemy-patrols.md, godot/scripts/systems/enemy.gd, tools/extractors/extract.py, tools/extractors/reference.py
- 235: docs/reverse_engineering/stage-3-results.md

## data/playersprite.asm
- arquivo: tools/extractors/extract_snake_sprites.py
- 44-45: docs/reverse_engineering/intro-water-colors.md
- 112-116: godot/scripts/systems/player.gd, tools/extractors/extract_snake_sprites.py

## data/radiocalls.asm
- arquivo: .agents/skills/inspect-msx-disassembly/SKILL.md, docs/reverse_engineering/en-eu-reextraction.md, godot/scripts/systems/radio_system.gd, godot/tests/radio_system_test.gd, tests/test_region_tools.py
- 5-10: docs/reverse_engineering/en-eu-reextraction.md
- 15-22: godot/scripts/systems/radio_system.gd
- 188: docs/reverse_engineering/en-eu-reextraction.md, godot/tests/radio_system_test.gd

## data/radiocallsjp.asm
- arquivo: docs/reverse_engineering/en-eu-reextraction.md

## data/respawninfo.asm
- arquivo: docs/reverse_engineering/stage-17-alert-evasion-reinforcements.md, godot/scripts/systems/alert_system.gd, tools/extractors/extract_respawn_info.py
- 13: docs/reverse_engineering/en-eu-reextraction.md, tools/extractors/extract_respawn_info.py, tools/reverse_engineering/compare_regions.py

## data/rooms.asm
- arquivo: docs/reverse_engineering/maps.md, docs/reverse_engineering/rom-compatibility.md, docs/reverse_engineering/stage-3-results.md, tools/extractors/reference.py, tools/reverse_engineering/analyze.py
- 7: docs/reverse_engineering/maps.md
- 268: docs/reverse_engineering/maps.md
- 282: docs/reverse_engineering/maps.md
- 295: docs/reverse_engineering/maps.md

## data/roomsconnections.asm
- arquivo: docs/reverse_engineering/stage-3-results.md, docs/reverse_engineering/stage-6-room-transitions.md, godot/scripts/systems/room_manager.gd, tools/extractors/reference.py, tools/reverse_engineering/analyze.py
- 7: docs/reverse_engineering/maps.md
- 113-114: docs/STATUS.md, docs/index/rooms.md
- 152-162: godot/scripts/systems/elevator_system.gd

## data/roomtileset.asm
- arquivo: docs/reference.md, docs/reverse_engineering/maps.md, tools/reverse_engineering/analyze.py
- 10: docs/reverse_engineering/maps.md

## data/shapes.asm
- arquivo: godot/scripts/systems/plastic_bomb.gd
- 36: docs/reverse_engineering/stage-8-combat-and-health.md, godot/scripts/systems/enemy.gd
- 37: godot/scripts/systems/enemy.gd, godot/tests/dog_patrol_test.gd

## data/texts.asm
- arquivo: docs/reverse_engineering/en-eu-reextraction.md, docs/reverse_engineering/inventory-and-events.md, tools/extractors/extract_grey_fox_dialogue.py
- 64: docs/reverse_engineering/grey-fox-dialogue.md, tools/extractors/extract_grey_fox_dialogue.py
- 189: godot/tests/capture_prison_test.gd
- 189-190: godot/scripts/systems/capture_cutscene.gd, godot/tests/capture_prison_test.gd
- 190: godot/tests/capture_prison_test.gd
- 191: godot/scripts/systems/radio_system.gd, godot/tests/radio_system_test.gd

## data/textsjp.asm
- arquivo: docs/reverse_engineering/en-eu-reextraction.md, docs/reverse_engineering/inventory-and-events.md
- 349-363: docs/reverse_engineering/grey-fox-dialogue.md

## data/tileblocks.asm
- arquivo: tools/extractors/extract_transceiver_sprites.py

## data/weapondamage.asm
- arquivo: docs/reverse_engineering/inventory-and-events.md, godot/scripts/systems/shot_gunner.gd
- 18: docs/reverse_engineering/stage-18-shoot-gunner.md, godot/scripts/systems/enemy.gd, godot/scripts/systems/shot_gunner.gd
- 58: docs/reverse_engineering/stage-20-rc-missile.md, godot/scripts/systems/remote_missile.gd

## data/weapongfxxy.asm
- arquivo: tools/extractors/extract_hud_assets.py
- 5-12: godot/scripts/systems/item_box.gd

## data/weaponnames.asm
- arquivo: docs/reverse_engineering/en-eu-reextraction.md

## gfx/doors.asm
- arquivo: godot/scripts/systems/door.gd, tools/extractors/extract_door_sprites.py

## gfx/font.asm
- arquivo: godot/tests/prisoner_dialog_test.gd, tests/test_grey_fox_dialogue.py, tools/extractors/extract_grey_fox_dialogue.py, tools/extractors/extract_hud_assets.py, tools/extractors/extract_title_intro_sprites.py, tools/extractors/extract_transceiver_sprites.py, tools/reverse_engineering/compare_regions.py
- 29: docs/reverse_engineering/en-eu-reextraction.md
- 29-33: docs/reverse_engineering/en-eu-reextraction.md, tools/extractors/extract_transceiver_sprites.py, tools/reverse_engineering/compare_regions.py
- 29-35: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner_dialog.gd

## gfx/items.asm
- arquivo: tools/extractors/extract_hud_assets.py

## gfx/konamilogo.asm
- arquivo: tools/extractors/extract_title_intro_sprites.py

## gfx/metalgearlogo.asm
- arquivo: tools/extractors/extract_title_intro_sprites.py

## gfx/powerswitch.asm
- arquivo: docs/reverse_engineering/stage-3-results.md, tools/extractors/reference.py

## gfx/radio.asm
- arquivo: tools/extractors/extract_transceiver_sprites.py

## gfx/snakeportrait.asm
- arquivo: tools/extractors/extract_transceiver_sprites.py

## gfx/sprites.asm
- arquivo: tools/extractors/extract_enemy_sprites.py, tools/extractors/extract_prisoner_sprites.py, tools/extractors/extract_shoot_gunner_sprites.py, tools/extractors/extract_snake_sprites.py
- 365-372: docs/reverse_engineering/intro-water-colors.md

## logic/actors.asm
- arquivo: docs/reverse_engineering/enemies.md

## logic/actors/bullethv.asm
- arquivo: docs/reverse_engineering/enemies.md, godot/scripts/systems/bullet.gd
- 43-46: godot/scripts/systems/bullet.gd

## logic/actors/camera.asm
- arquivo: .agents/skills/inspect-msx-disassembly/SKILL.md, godot/scripts/systems/security_camera.gd
- 93-121: godot/scripts/systems/security_camera.gd
- 145-186: godot/scripts/systems/security_camera.gd
- 146-148: godot/scripts/systems/security_camera.gd
- 174: godot/scripts/systems/security_camera.gd
- 206-210: godot/scripts/systems/security_camera.gd
- 234-238: godot/scripts/systems/security_camera.gd
- 241-248: godot/scripts/systems/security_camera.gd

## logic/actors/chkdiscover.asm
- arquivo: docs/reverse_engineering/stage-7-enemy-patrols.md, godot/scripts/systems/enemy.gd, godot/scripts/systems/security_camera.gd
- 7: docs/reverse_engineering/enemies.md
- 30-48: godot/scripts/systems/security_camera.gd
- 212: godot/scripts/systems/enemy.gd
- 447-491: godot/scripts/systems/enemy.gd
- 502-535: godot/scripts/systems/enemy.gd, godot/tests/sleepy_guard_test.gd

## logic/actors/dog.asm
- arquivo: godot/scripts/systems/enemy.gd
- 7-22: godot/tests/dog_patrol_test.gd
- 11-17: godot/scripts/systems/enemy.gd
- 29-36: godot/scripts/systems/enemy.gd
- 29-201: godot/scripts/systems/enemy.gd
- 45-83: godot/tests/dog_patrol_test.gd
- 49-53: godot/scripts/systems/enemy.gd
- 74-81: godot/scripts/systems/enemy.gd
- 88-98: godot/scripts/systems/enemy.gd
- 88-103: godot/tests/dog_patrol_test.gd
- 95: godot/scripts/systems/enemy.gd
- 123-146: godot/scripts/systems/enemy.gd
- 127-147: godot/scripts/systems/enemy.gd
- 163: godot/scripts/systems/enemy.gd
- 193-200: godot/scripts/systems/enemy.gd
- 193-201: godot/scripts/systems/enemy.gd

## logic/actors/elevatorguardspawner.asm
- arquivo: godot/scripts/scenes/sandbox_gameplay.gd
- 29: godot/scripts/scenes/sandbox_gameplay.gd

## logic/actors/gas.asm
- arquivo: docs/reverse_engineering/stage-19-gas-hazard.md, godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/gas_cloud.gd, godot/tests/gas_hazard_test.gd
- 11: godot/scripts/systems/gas_cloud.gd
- 34: godot/scripts/systems/gas_cloud.gd
- 36-37: godot/scripts/systems/gas_cloud.gd

## logic/actors/guard.asm
- arquivo: godot/scripts/systems/enemy.gd, godot/tests/sleepy_guard_test.gd
- 29: docs/reverse_engineering/enemies.md
- 187-260: godot/scripts/systems/enemy.gd
- 198-216: godot/tests/sleepy_guard_test.gd
- 204: godot/tests/sleepy_guard_test.gd
- 205: godot/scripts/systems/enemy.gd
- 226-232: godot/tests/sleepy_guard_test.gd
- 230-260: godot/tests/sleepy_guard_test.gd
- 233: godot/scripts/systems/enemy.gd, godot/tests/sleepy_guard_test.gd

## logic/actors/guardalert.asm
- arquivo: docs/reverse_engineering/enemies.md, godot/scripts/systems/enemy.gd
- 14-38: godot/scripts/scenes/sandbox_gameplay.gd
- 91-200: godot/scripts/systems/enemy.gd, godot/tests/combat_and_health_test.gd
- 124: godot/scripts/systems/enemy.gd
- 125: godot/tests/combat_and_health_test.gd
- 148-154: godot/scripts/systems/enemy.gd
- 174: docs/reverse_engineering/en-eu-reextraction.md
- 315-316: godot/scripts/systems/enemy.gd

## logic/actors/guardelevator.asm
- arquivo: godot/scripts/systems/enemy.gd
- 19: godot/scripts/scenes/sandbox_gameplay.gd
- 305: godot/scripts/systems/enemy.gd

## logic/actors/guardlorry.asm
- 32: godot/scripts/scenes/sandbox_gameplay.gd, godot/tests/room_007_patrol_test.gd

## logic/actors/guardshot.asm
- arquivo: docs/reverse_engineering/enemies.md

## logic/actors/hideguards.asm
- arquivo: godot/scripts/scenes/sandbox_gameplay.gd
- 10: godot/scripts/scenes/sandbox_gameplay.gd
- 34: godot/scripts/scenes/sandbox_gameplay.gd
- 48: godot/scripts/scenes/sandbox_gameplay.gd
- 62: godot/scripts/scenes/sandbox_gameplay.gd
- 76: godot/scripts/scenes/sandbox_gameplay.gd
- 104: godot/scripts/scenes/sandbox_gameplay.gd
- 123: godot/scripts/scenes/sandbox_gameplay.gd
- 138: godot/scripts/scenes/sandbox_gameplay.gd
- 161: godot/scripts/scenes/sandbox_gameplay.gd

## logic/actors/powerswitch.asm
- arquivo: godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/electrified_floor_system.gd, godot/scripts/systems/power_panel.gd, godot/tests/electrified_floor_test.gd, tools/extractors/extract_electrified_floor_data.py

## logic/actors/prisoner.asm
- arquivo: godot/scripts/systems/prisoner.gd, godot/tests/rank_and_prisoners_test.gd
- 63-67: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner.gd
- 79-80: godot/scripts/systems/prisoner.gd
- 90-95: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner.gd, godot/tests/prisoner_dialog_test.gd
- 94: godot/scripts/systems/prisoner.gd
- 244-256: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/scenes/sandbox_gameplay.gd
- 244-277: tools/extractors/extract_grey_fox_dialogue.py

## logic/actors/shooter.asm
- arquivo: godot/scripts/systems/enemy.gd

## logic/actors/shotgunner.asm
- arquivo: docs/reverse_engineering/stage-18-shoot-gunner.md, godot/scripts/systems/shot_gunner.gd, godot/tests/shot_gunner_test.gd
- 7-10: godot/scripts/scenes/sandbox_gameplay.gd
- 13: godot/scripts/systems/shot_gunner.gd
- 16-23: godot/scripts/systems/shot_gunner.gd
- 18-22: godot/scripts/systems/shot_gunner.gd
- 28: godot/scripts/systems/shot_gunner.gd
- 29: godot/scripts/systems/shot_gunner.gd
- 55-70: godot/scripts/systems/shot_gunner.gd
- 80-103: godot/scripts/systems/shot_gunner.gd
- 100: godot/scripts/systems/shot_gunner.gd
- 102: godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/shot_gunner.gd
- 113-148: godot/scripts/systems/shot_gunner.gd
- 117-123: godot/scripts/systems/shot_gunner.gd
- 126-131: godot/scripts/systems/shot_gunner.gd
- 127: godot/scripts/systems/shot_gunner.gd
- 135-146: godot/scripts/systems/shot_gunner.gd
- 161-162: godot/scripts/systems/shot_gunner.gd
- 174-177: godot/scripts/systems/shot_gunner.gd
- 188-235: godot/scripts/systems/shot_gunner_bullet.gd

## logic/actors/shottoplayer.asm
- arquivo: docs/reverse_engineering/enemies.md

## logic/actors/snoringsymbol.asm
- arquivo: godot/scripts/systems/enemy.gd

## logic/addroomitems.asm
- arquivo: tools/extractors/reference.py
- 8: docs/reverse_engineering/inventory-and-events.md, docs/reverse_engineering/maps.md
- 15-20: docs/reverse_engineering/stage-3-results.md
- 19-35: docs/reverse_engineering/stage-10-lorries-and-canonical-items.md

## logic/capturescene.asm
- arquivo: docs/reverse_engineering/inventory-and-events.md, godot/tests/capture_prison_test.gd, tools/extractors/extract_capture_prison_data.py
- 1-280: godot/scripts/systems/capture_cutscene.gd
- 27-36: godot/scripts/systems/capture_cutscene.gd, godot/tests/capture_prison_test.gd
- 32-34: godot/tests/capture_prison_test.gd
- 38-47: godot/scripts/systems/capture_cutscene.gd
- 69-72: godot/scripts/systems/capture_cutscene.gd
- 69-118: godot/tests/capture_prison_test.gd
- 87-118: docs/index/rooms.md, docs/reverse_engineering/prison-wall.md, godot/scripts/systems/capture_system.gd, tools/extractors/export_local_aliases.py, tools/extractors/extract_capture_prison_data.py
- 115: godot/tests/capture_prison_test.gd
- 115-118: godot/scripts/systems/capture_cutscene.gd
- 170-186: godot/scripts/systems/capture_cutscene.gd
- 177-184: godot/scripts/systems/capture_cutscene.gd
- 179: godot/tests/capture_prison_test.gd
- 182: godot/tests/capture_prison_test.gd
- 208-213: godot/scripts/systems/capture_cutscene.gd
- 208-260: godot/tests/capture_prison_test.gd
- 216-225: godot/scripts/systems/capture_cutscene.gd
- 232-239: godot/scripts/systems/capture_cutscene.gd
- 242: godot/scripts/systems/capture_cutscene.gd
- 251-260: godot/scripts/systems/capture_cutscene.gd
- 266: godot/scripts/systems/capture_cutscene.gd

## logic/checkpoints.asm
- 10: docs/reverse_engineering/inventory-and-events.md

## logic/checkweaponalert.asm
- arquivo: docs/reverse_engineering/enemies.md
- 37-40: docs/reverse_engineering/stage-18-shoot-gunner.md

## logic/collisions.asm
- arquivo: docs/reverse_engineering/stage-5-movement-and-collision.md, godot/scripts/systems/shot_gunner.gd, tools/reverse_engineering/analyze.py
- 15: docs/reverse_engineering/movement-and-collision.md
- 155: godot/scripts/systems/electrified_floor_system.gd

## logic/common.asm
- arquivo: godot/tests/capture_prison_test.gd, tools/extractors/extract_capture_prison_data.py
- 8: docs/reverse_engineering/architecture.md
- 21: docs/reverse_engineering/prison-wall.md
- 26-47: godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/capture_cutscene.gd, godot/scripts/systems/capture_system.gd, godot/tests/capture_prison_test.gd, tools/extractors/extract_capture_prison_data.py
- 43: godot/scripts/systems/capture_cutscene.gd, godot/tests/capture_prison_test.gd

## logic/controls.asm
- 8: docs/reverse_engineering/architecture.md, docs/reverse_engineering/movement-and-collision.md
- 53-57: docs/reverse_engineering/grey-fox-dialogue.md

## logic/damageelectric.asm
- arquivo: godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/electrified_floor_system.gd, godot/tests/electrified_floor_test.gd, tools/extractors/extract_electrified_floor_data.py
- 56: godot/scripts/systems/electrified_floor_system.gd
- 59-60: godot/scripts/systems/electrified_floor_system.gd
- 62: godot/scripts/systems/electrified_floor_system.gd

## logic/damagegas.asm
- arquivo: docs/reverse_engineering/stage-19-gas-hazard.md, godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/gas_hazard_system.gd, godot/tests/gas_hazard_test.gd, tools/extractors/extract_gas_hazard.py
- 9-47: docs/reverse_engineering/stage-19-gas-hazard.md
- 34: godot/scripts/systems/gas_hazard_system.gd, tools/extractors/extract_gas_hazard.py
- 45: godot/scripts/systems/gas_hazard_system.gd, godot/tests/gas_hazard_test.gd, tools/extractors/extract_gas_hazard.py
- 53: docs/reverse_engineering/stage-19-gas-hazard.md, godot/scripts/systems/gas_hazard_system.gd, godot/tests/gas_hazard_test.gd, tools/extractors/extract_gas_hazard.py

## logic/damagetoenemy.asm
- arquivo: docs/reverse_engineering/stage-20-rc-missile.md, godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/power_panel.gd, godot/scripts/systems/remote_missile.gd, godot/tests/electrified_floor_test.gd, tools/extractors/extract_electrified_floor_data.py
- 7: docs/reverse_engineering/inventory-and-events.md
- 108-132: godot/scripts/systems/enemy.gd
- 216: godot/scripts/systems/enemy.gd

## logic/destructiontimer.asm
- arquivo: docs/reverse_engineering/inventory-and-events.md

## logic/doors/drawdoors.asm
- arquivo: tools/extractors/extract_door_sprites.py
- 92: docs/reverse_engineering/maps.md
- 262-269: docs/reverse_engineering/prison-wall.md
- 262-319: godot/scripts/systems/prison_wall_door.gd, tools/extractors/extract_prison_wall.py
- 272-319: docs/reverse_engineering/prison-wall.md

## logic/doors/enterdoor.asm
- arquivo: godot/scripts/systems/door.gd
- 64-88: docs/reverse_engineering/prison-wall.md, godot/scripts/systems/prison_wall_door.gd, godot/scripts/systems/room_manager.gd
- 66-84: godot/scripts/scenes/sandbox_gameplay.gd

## logic/doors/erasedoor.asm
- 24: docs/reverse_engineering/prison-wall.md
- 25: godot/scripts/systems/capture_system.gd, godot/scripts/systems/prison_wall_door.gd, tools/extractors/extract_capture_prison_data.py
- 25-26: docs/reverse_engineering/prison-wall.md
- 65-76: docs/reverse_engineering/prison-wall.md

## logic/doors/opendoor.asm
- arquivo: docs/reverse_engineering/stage-9-doors-and-inventory.md, godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/door.gd, godot/tests/capture_prison_test.gd, tools/extractors/extract_capture_prison_data.py
- 8: docs/reverse_engineering/inventory-and-events.md
- 68: docs/reverse_engineering/stage-4b-vram-inheritance.md
- 121: docs/reverse_engineering/inventory-and-events.md
- 285-319: docs/reverse_engineering/prison-wall.md, godot/scripts/systems/capture_system.gd
- 300-319: godot/scripts/systems/capture_system.gd
- 300-320: tools/extractors/extract_capture_prison_data.py
- 307-316: docs/reverse_engineering/prison-wall.md, godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/capture_system.gd
- 325-393: godot/scripts/systems/door.gd
- 331-348: godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/door.gd
- 350-373: godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/door.gd
- 369-372: docs/reverse_engineering/prison-wall.md
- 384: docs/reverse_engineering/prison-wall.md
- 385: docs/reverse_engineering/prison-wall.md

## logic/drawitemsinroom.asm
- arquivo: godot/tests/item_box_sprites_test.gd
- 1-75: godot/scripts/systems/item_box.gd
- 17-68: godot/scripts/systems/item_box.gd
- 21-68: godot/scripts/systems/item_box.gd

## logic/drawlaserbeams.asm
- arquivo: godot/scripts/systems/laser_system.gd
- 8-10: godot/scripts/systems/laser_system.gd

## logic/elevatorroom.asm
- arquivo: docs/reverse_engineering/stage-3-results.md, godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/elevator_system.gd, tools/extractors/reference.py
- 227-241: godot/scripts/systems/elevator_cabin.gd

## logic/gamedemo.asm
- 216: docs/reverse_engineering/en-eu-reextraction.md
- 216-238: docs/reverse_engineering/en-eu-reextraction.md

## logic/helperdirections.asm
- 52: godot/scripts/systems/enemy.gd

## logic/hud.asm
- arquivo: docs/reverse_engineering/inventory-and-events.md
- 25-56: godot/scripts/systems/hud.gd
- 40: godot/scripts/systems/hud.gd
- 107: docs/reverse_engineering/inventory-and-events.md
- 162-205: godot/scripts/systems/hud.gd
- 166-170: godot/scripts/systems/hud.gd
- 179-184: godot/scripts/systems/hud.gd
- 214-244: godot/scripts/systems/hud.gd

## logic/hudspritemask.asm
- 37-41: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner_dialog.gd

## logic/inithardware.asm
- 14: docs/reverse_engineering/architecture.md
- 27-31: docs/reverse_engineering/stage-4-results.md

## logic/introscene.asm
- arquivo: godot/scripts/systems/intro_cutscene.gd, godot/scripts/systems/radio_dialog.gd
- 32-166: godot/scripts/systems/intro_cutscene.gd
- 51-58: docs/reverse_engineering/intro-water-colors.md
- 196-203: godot/scripts/systems/radio_dialog.gd
- 224-235: docs/reverse_engineering/intro-fence-timing.md, godot/scripts/systems/intro_cutscene.gd
- 243-267: docs/reverse_engineering/intro-fence-timing.md
- 255-261: docs/reverse_engineering/intro-fence-timing.md, godot/scripts/systems/intro_cutscene.gd
- 275-285: docs/reverse_engineering/intro-fence-timing.md
- 288-299: docs/reverse_engineering/intro-fence-timing.md, godot/scripts/systems/intro_cutscene.gd
- 307-333: docs/reverse_engineering/intro-fence-timing.md
- 312-318: godot/scripts/systems/intro_cutscene.gd
- 321-333: godot/scripts/systems/intro_cutscene.gd
- 341-364: docs/reverse_engineering/intro-fence-timing.md, godot/scripts/systems/intro_cutscene.gd
- 372-378: godot/scripts/systems/intro_cutscene.gd
- 380: godot/scripts/systems/intro_cutscene.gd

## logic/items.asm
- arquivo: docs/reverse_engineering/inventory-and-events.md, godot/scripts/systems/weapon_system.gd, godot/tests/capture_prison_test.gd, tools/extractors/extract_capture_prison_data.py
- 7: docs/reverse_engineering/inventory-and-events.md
- 60-98: godot/scripts/systems/item_box.gd
- 120-124: godot/scripts/systems/capture_system.gd, tools/extractors/extract_capture_prison_data.py
- 188: godot/scripts/systems/weapon_system.gd
- 253-261: godot/scripts/systems/weapon_system.gd
- 333-356: godot/scripts/systems/weapon_system.gd
- 399: .agents/skills/inspect-msx-disassembly/SKILL.md
- 399-414: docs/reverse_engineering/en-eu-reextraction.md
- 409: docs/reverse_engineering/en-eu-reextraction.md
- 409-413: docs/reverse_engineering/en-eu-reextraction.md

## logic/konamilogo.asm
- arquivo: tools/extractors/extract_title_intro_sprites.py

## logic/laserbeams.asm
- arquivo: godot/scripts/systems/laser_system.gd
- 11-68: godot/scripts/systems/laser_system.gd

## logic/loadfont.asm
- 10-18: docs/reverse_engineering/grey-fox-dialogue.md
- 28: godot/scripts/systems/hud.gd
- 57: tools/extractors/extract_hud_assets.py

## logic/lorry.asm
- 23: godot/scripts/scenes/sandbox_gameplay.gd

## logic/madnarbigbossevent.asm
- arquivo: docs/reverse_engineering/inventory-and-events.md

## logic/mainmenu.asm
- arquivo: tools/extractors/extract_title_intro_sprites.py
- 240: godot/scripts/scenes/title_screen.gd

## logic/maxammo.asm
- arquivo: godot/scripts/systems/rank_system.gd, godot/scripts/systems/weapon_system.gd, godot/tests/remote_missile_test.gd, tools/extractors/extract_missile_data.py
- 20-35: godot/scripts/systems/inventory.gd
- 112-146: tools/extractors/extract_missile_data.py
- 112-147: godot/scripts/systems/weapon_system.gd

## logic/menuequipment.asm
- arquivo: docs/reverse_engineering/stage-9-doors-and-inventory.md, godot/scripts/systems/inventory.gd
- 228: docs/reverse_engineering/stage-9-doors-and-inventory.md, godot/scripts/systems/inventory.gd
- 295: godot/scripts/scenes/sandbox_gameplay.gd
- 295-350: godot/scripts/systems/binocular_system.gd
- 295-361: godot/tests/binocular_test.gd
- 300: godot/scripts/systems/binocular_system.gd, godot/scripts/systems/room_manager.gd
- 338-361: godot/scripts/systems/binocular_overlay.gd
- 355: godot/scripts/systems/binocular_overlay.gd

## logic/nextroom.asm
- arquivo: godot/scripts/systems/elevator_system.gd, godot/scripts/systems/room_manager.gd
- 13: docs/reverse_engineering/maps.md
- 64-98: godot/scripts/scenes/sandbox_gameplay.gd
- 90: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner_dialog.gd
- 120-155: docs/reverse_engineering/stage-9-doors-and-inventory.md
- 342: docs/reverse_engineering/stage-6-room-transitions.md, godot/scripts/systems/room_manager.gd
- 362: godot/scripts/systems/room_manager.gd
- 398-453: docs/reverse_engineering/prison-wall.md, godot/scripts/scenes/sandbox_gameplay.gd
- 418-453: docs/reverse_engineering/stage-10-lorries-and-canonical-items.md
- 457-480: godot/scripts/systems/door.gd, godot/tests/building_doors_test.gd
- 463-482: docs/reverse_engineering/stage-10-lorries-and-canonical-items.md
- 474-475: docs/reverse_engineering/prison-wall.md
- 476-477: godot/scripts/systems/door.gd

## logic/passwords.asm
- arquivo: docs/reverse_engineering/inventory-and-events.md

## logic/punchenemy.asm
- arquivo: docs/reverse_engineering/inventory-and-events.md, godot/scripts/systems/enemy.gd, godot/tests/combat_and_health_test.gd
- 29-87: godot/scripts/systems/enemy.gd, godot/tests/sleepy_guard_test.gd
- 46-87: docs/reverse_engineering/stage-8-combat-and-health.md

## logic/regionlock.asm
- 28: docs/reverse_engineering/en-eu-reextraction.md

## logic/saveload.asm
- arquivo: docs/reverse_engineering/inventory-and-events.md

## logic/setalert.asm
- arquivo: godot/scripts/systems/alert_system.gd
- 11-40: docs/reverse_engineering/stage-17-alert-evasion-reinforcements.md
- 12: docs/reverse_engineering/enemies.md
- 14-40: godot/scripts/systems/alert_system.gd
- 25-36: godot/scripts/systems/inventory.gd
- 35-39: godot/scripts/systems/alert_system.gd
- 36: godot/tests/alert_system_test.gd

## logic/textboxappear.asm
- 10-62: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner_dialog.gd
- 51-62: docs/reverse_engineering/grey-fox-dialogue.md, godot/scripts/systems/prisoner_dialog.gd

## logic/touchenemy.asm
- arquivo: godot/tests/combat_and_health_test.gd
- 8: docs/reverse_engineering/inventory-and-events.md
- 55-57: godot/scripts/systems/prisoner.gd, godot/tests/prisoner_dialog_test.gd
- 137: godot/scripts/systems/enemy.gd
- 137-189: docs/reverse_engineering/stage-8-combat-and-health.md
- 155: godot/scripts/systems/player.gd

## logic/updatesprites.asm
- arquivo: docs/reverse_engineering/architecture.md

## logic/weapon/handgun.asm
- arquivo: godot/scripts/systems/bullet.gd
- 39-65: godot/scripts/systems/player.gd
- 86-90: godot/scripts/systems/bullet.gd

## logic/weapon/missile.asm
- arquivo: docs/reverse_engineering/stage-20-rc-missile.md, godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/remote_missile.gd, godot/tests/remote_missile_test.gd, tools/extractors/extract_missile_data.py
- 23-25: docs/reverse_engineering/stage-20-rc-missile.md
- 37-47: godot/scripts/systems/remote_missile.gd
- 80: tools/extractors/extract_missile_data.py
- 112-133: docs/reverse_engineering/stage-20-rc-missile.md, godot/scripts/systems/remote_missile.gd
- 150-165: godot/scripts/systems/remote_missile.gd
- 165: tools/extractors/extract_missile_data.py

## logic/weapon/plasticbomb.asm
- arquivo: godot/scripts/scenes/sandbox_gameplay.gd, godot/scripts/systems/plastic_bomb.gd
- 80-84: godot/scripts/systems/plastic_bomb.gd, godot/tests/basement_and_plastic_bomb_test.gd
- 144-164: docs/reverse_engineering/stage-20-rc-missile.md
- 150: godot/scripts/systems/remote_missile.gd

## logic/weaponuse.asm
- arquivo: docs/reverse_engineering/stage-20-rc-missile.md, godot/scripts/systems/bullet.gd, godot/scripts/systems/remote_missile.gd, godot/scripts/systems/weapon_system.gd
- 8: docs/reverse_engineering/inventory-and-events.md
- 52: docs/reverse_engineering/inventory-and-events.md
- 338: godot/scripts/systems/bullet.gd
- 365: godot/scripts/systems/remote_missile.gd
- 365-375: docs/reverse_engineering/stage-20-rc-missile.md, godot/scripts/systems/remote_missile.gd
- 366-376: godot/scripts/systems/bullet.gd

## sound/bgmdriver.asm
- arquivo: docs/reverse_engineering/architecture.md
- 12: docs/reverse_engineering/architecture.md

## sound/instruments.asm
- arquivo: docs/reverse_engineering/architecture.md

## sound/setsound.asm
- arquivo: docs/reverse_engineering/architecture.md

## sound/sound.asm
- arquivo: docs/reference.md, docs/reverse_engineering/architecture.md

## sound/sounddata.asm
- arquivo: docs/reverse_engineering/architecture.md
