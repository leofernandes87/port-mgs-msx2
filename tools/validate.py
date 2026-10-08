"""Validação local sem dependências Python externas. Execute da raiz."""
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

# (etapa, script em godot/tests/, marcador obrigatório na saída, descrição da falha).
# Índice derivado: docs/index/tests.md (tools/context/build_index.py).
GODOT_TESTS = [
    ("godot-smoke", "smoke_test.gd", "SMOKE_OK:", "Teste Godot"),
    ("godot-room-snapshot", "room_snapshot_test.gd", "ROOM_SNAPSHOT_OK:", "Teste de snapshot"),
    ("godot-player-movement", "player_movement_test.gd", "PLAYER_MOVEMENT_OK:", "Teste de movimento do jogador"),
    ("godot-room-transition", "room_transition_test.gd", "ROOM_TRANSITION_OK:", "Teste de transição de salas"),
    ("godot-enemy-patrol", "enemy_patrol_test.gd", "ENEMY_PATROL_OK:", "Teste de patrulha e visão de inimigos"),
    ("godot-combat-health", "combat_and_health_test.gd", "COMBAT_AND_HEALTH_OK:", "Teste de combate e vida"),
    ("godot-doors-inventory", "doors_and_inventory_test.gd", "DOORS_AND_INVENTORY_OK:", "Teste de portas e inventário"),
    ("godot-elevator", "elevator_test.gd", "ELEVATOR_OK:", "Teste de elevador"),
    ("godot-weapon-combat", "weapon_and_combat_test.gd", "WEAPONS_AND_COMBAT_OK:", "Teste de armas e combate"),
    ("godot-building-doors", "building_doors_test.gd", "BUILDING_DOORS_OK:", "Teste de portas de edifícios"),
    ("godot-radio-system", "radio_system_test.gd", "RADIO_SYSTEM_OK:", "Teste de rádio transceptor"),
    ("godot-cameras-and-lasers", "cameras_and_lasers_test.gd", "CAMERAS_AND_LASERS_OK:", "Teste de câmeras e lasers"),
    ("godot-alert-system", "alert_system_test.gd", "ALERT_SYSTEM_OK:", "Teste de sistema de alerta e evasão"),
    ("godot-boss-shoot-gunner", "shot_gunner_test.gd", "BOSS_SHOOT_GUNNER_OK:", "Teste do Boss Shoot Gunner"),
    ("godot-rank-and-prisoners", "rank_and_prisoners_test.gd", "RANK_AND_PRISONERS_OK:", "Teste de prisioneiros e patente militar"),
    ("godot-prisoner-dialog", "prisoner_dialog_test.gd", "PRISONER_DIALOG_OK:", "Teste de diálogo paginado"),
    ("godot-gas-hazard", "gas_hazard_test.gd", "GAS_HAZARD_OK:", "Teste de perigo de gás e máscara"),
    ("godot-remote-missile", "remote_missile_test.gd", "REMOTE_MISSILE_OK:", "Teste de míssil teleguiado"),
    ("godot-capture-prison", "capture_prison_test.gd", "CAPTURE_PRISON_OK:", "Teste de captura e prisão"),
    ("godot-prison-wall", "prison_wall_integration_test.gd", "PRISON_WALL_INTEGRATION_OK:", "Teste da parede da prisão"),
    ("godot-electrified-floor", "electrified_floor_test.gd", "ELECTRIFIED_FLOOR_TEST_OK:", "Teste de pisos eletrificados"),
    ("godot-elevator-guards", "elevator_guard_test.gd", "ELEVATOR_GUARD_OK:", "Teste de sentinelas do elevador"),
    ("godot-room-007-patrol", "room_007_patrol_test.gd", "ROOM_007_PATROL_OK:", "Teste de patrulha e caminhões da Sala 007"),
    ("godot-binoculars", "binocular_test.gd", "BINOCULARS_TEST_OK:", "Teste do binóculo"),
    ("godot-dogs", "dog_patrol_test.gd", "DOG_PATROL_TEST_OK:", "Teste dos cães de guarda"),
    ("godot-sleepy-guard", "sleepy_guard_test.gd", "SLEEPY_GUARD_TEST_OK:", "Teste do guarda sonolento"),
    ("godot-floor3-review", "floor3_review_test.gd", "FLOOR3_REVIEW_TEST_OK:", "Teste de revisão do Floor 3"),
    ("godot-basement-and-plastic-bomb", "basement_and_plastic_bomb_test.gd", "BASEMENT_AND_PLASTIC_BOMB_TEST_OK:", "Teste do Basement e bomba plástica"),
    ("godot-title-screen", "title_screen_test.gd", "TITLE_SCREEN_INTEGRATION_OK:", "Teste de abertura e tela de título"),
    ("godot-intro-cutscene", "intro_cutscene_test.gd", "INTRO_CUTSCENE_INTEGRATION_OK:", "Teste de cutscene de abertura"),
    ("godot-hud", "hud_test.gd", "HUD_INTEGRATION_TEST_OK:", "Teste do HUD original MSX2"),
    ("godot-item-box-sprites", "item_box_sprites_test.gd", "ITEM_BOX_SPRITES_TEST_OK:", "Teste de sprites de itens no mapa"),
    ("godot-rolling-barrels", "rolling_barrel_test.gd", "ROLLING_BARREL_TEST_OK:", "Teste de barris rolantes"),
]

def find_godot():
    candidates = [os.environ.get("GODOT_BIN"), shutil.which("godot"),
                  shutil.which("godot4"), "/Applications/Godot.app/Contents/MacOS/Godot"]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return candidate
    raise RuntimeError("Godot ausente: defina GODOT_BIN com o caminho do executável")

def check_rom_profile(reports):
    """Private ROM is optional; when present it must be exactly the canonical profile."""
    roms = ROOT / "roms"
    private = [p for p in roms.iterdir() if p.is_file() and not p.name.startswith(".")
               and p.name != "README.md"] if roms.is_dir() else []
    if not private and not os.environ.get("MG_ROM"):
        print("rom-profile: SKIP (nenhuma ROM privada disponível)")
        return
    result = subprocess.run([sys.executable, "-m", "tools.rom", "--check"], cwd=ROOT, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
    (reports / "rom-profile.log").write_text(result.stdout)
    print(result.stdout, end="")
    if result.returncode or "ROM_CHECK_OK:" not in result.stdout:
        raise RuntimeError("rom-profile falhou: ROM canônica ausente ou divergente; consulte reports/")
    print("rom-profile: PASS")

def check_context_indexes(reports):
    """Fast, before Godot: stale indexes or broken references fail early."""
    result = subprocess.run([sys.executable, "-m", "tools.context.build_index", "--check"], cwd=ROOT,
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
    (reports / "context-indexes.log").write_text(result.stdout)
    print(result.stdout, end="")
    if result.returncode or "CONTEXT_INDEX_OK:" not in result.stdout:
        raise RuntimeError("context-indexes falhou: rode python3 -m tools.context.build_index")
    print("context-indexes: PASS")

def main():
    godot = find_godot()
    version = subprocess.check_output([godot, "--version"], text=True).strip()
    if not version.startswith("4."):
        raise RuntimeError("Godot 4 obrigatório: " + version)
    reports = ROOT / "reports"
    reports.mkdir(exist_ok=True)
    check_rom_profile(reports)
    check_context_indexes(reports)
    project = str(ROOT / "godot")
    commands = [
        ("python-tests", [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"], None, None),
        ("godot-import", [godot, "--headless", "--path", project, "--editor", "--quit"], None, None),
    ]
    commands += [(name, [godot, "--headless", "--path", project, "--script", "res://tests/" + script],
                  marker, label) for name, script, marker, label in GODOT_TESTS]
    commands.append(("godot-main", [godot, "--headless", "--path", project, "--quit-after", "5"],
                     "BOOT_OK:", "Cena principal"))
    for name, command, marker, label in commands:
        result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=120)
        (reports / (name + ".log")).write_text(result.stdout)
        print(result.stdout, end="")
        if result.returncode or "SCRIPT ERROR:" in result.stdout or "ERROR:" in result.stdout:
            raise RuntimeError(name + " falhou; consulte reports/")
        if marker and marker not in result.stdout:
            raise RuntimeError(label + " não confirmou conclusão (" + marker + ")")
        print(name + ": PASS")

if __name__ == "__main__":
    main()
