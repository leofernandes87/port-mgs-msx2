"""Validação local sem dependências Python externas. Execute da raiz."""
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def find_godot():
    candidates = [os.environ.get("GODOT_BIN"), shutil.which("godot"),
                  shutil.which("godot4"), "/Applications/Godot.app/Contents/MacOS/Godot"]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return candidate
    raise RuntimeError("Godot ausente: defina GODOT_BIN com o caminho do executável")

def main():
    godot = find_godot()
    version = subprocess.check_output([godot, "--version"], text=True).strip()
    if not version.startswith("4."):
        raise RuntimeError("Godot 4 obrigatório: " + version)
    reports = ROOT / "reports"
    reports.mkdir(exist_ok=True)
    commands = [
        ("python-tests", [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"]),
        ("godot-import", [godot, "--headless", "--path", str(ROOT / "godot"), "--editor", "--quit"]),
        ("godot-smoke", [godot, "--headless", "--path", str(ROOT / "godot"), "--script", "res://tests/smoke_test.gd"]),
        ("godot-room-snapshot", [godot, "--headless", "--path", str(ROOT / "godot"), "--script", "res://tests/room_snapshot_test.gd"]),
        ("godot-player-movement", [godot, "--headless", "--path", str(ROOT / "godot"), "--script", "res://tests/player_movement_test.gd"]),
        ("godot-room-transition", [godot, "--headless", "--path", str(ROOT / "godot"), "--script", "res://tests/room_transition_test.gd"]),
        ("godot-enemy-patrol", [godot, "--headless", "--path", str(ROOT / "godot"), "--script", "res://tests/enemy_patrol_test.gd"]),
        ("godot-combat-health", [godot, "--headless", "--path", str(ROOT / "godot"), "--script", "res://tests/combat_and_health_test.gd"]),
        ("godot-doors-inventory", [godot, "--headless", "--path", str(ROOT / "godot"), "--script", "res://tests/doors_and_inventory_test.gd"]),
        ("godot-elevator", [godot, "--headless", "--path", str(ROOT / "godot"), "--script", "res://tests/elevator_test.gd"]),
        ("godot-weapon-combat", [godot, "--headless", "--path", str(ROOT / "godot"), "--script", "res://tests/weapon_and_combat_test.gd"]),
        ("godot-main", [godot, "--headless", "--path", str(ROOT / "godot"), "--quit-after", "5"]),
    ]
    for name, command in commands:
        result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=120)
        (reports / (name + ".log")).write_text(result.stdout)
        print(result.stdout, end="")
        if result.returncode or "SCRIPT ERROR:" in result.stdout or "ERROR:" in result.stdout:
            raise RuntimeError(name + " falhou; consulte reports/")
        if name == "godot-smoke" and "SMOKE_OK:" not in result.stdout:
            raise RuntimeError("Teste Godot não confirmou conclusão")
        if name == "godot-room-snapshot" and "ROOM_SNAPSHOT_OK:" not in result.stdout:
            raise RuntimeError("Teste de snapshot não confirmou conclusão")
        if name == "godot-player-movement" and "PLAYER_MOVEMENT_OK:" not in result.stdout:
            raise RuntimeError("Teste de movimento do jogador não confirmou conclusão")
        if name == "godot-room-transition" and "ROOM_TRANSITION_OK:" not in result.stdout:
            raise RuntimeError("Teste de transição de salas não confirmou conclusão")
        if name == "godot-enemy-patrol" and "ENEMY_PATROL_OK:" not in result.stdout:
            raise RuntimeError("Teste de patrulha e visão de inimigos não confirmou conclusão")
        if name == "godot-combat-health" and "COMBAT_AND_HEALTH_OK:" not in result.stdout:
            raise RuntimeError("Teste de combate e vida não confirmou conclusão")
        if name == "godot-doors-inventory" and "DOORS_AND_INVENTORY_OK:" not in result.stdout:
            raise RuntimeError("Teste de portas e inventário não confirmou conclusão")
        if name == "godot-elevator" and "ELEVATOR_OK:" not in result.stdout:
            raise RuntimeError("Teste de elevador não confirmou conclusão")
        if name == "godot-weapon-combat" and "WEAPONS_AND_COMBAT_OK:" not in result.stdout:
            raise RuntimeError("Teste de armas e combate não confirmou conclusão")
        if name == "godot-main" and "BOOT_OK:" not in result.stdout:
            raise RuntimeError("Cena principal não iniciou")
        print(name + ": PASS")

if __name__ == "__main__":
    main()
