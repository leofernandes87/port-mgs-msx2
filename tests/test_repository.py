"""Verifica limites de versionamento sem precisar de ROM real."""
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]

class RepositoryPolicyTests(unittest.TestCase):
    def ignored(self, path):
        result = subprocess.run(["git", "check-ignore", "--no-index", "-q", path], cwd=ROOT)
        self.assertIn(result.returncode, (0, 1))
        return result.returncode == 0

    def test_private_content_is_ignored(self):
        for path in ("roms/input.dat", "game.ROM", "game.rom", "external/MetalGear/README.md",
                     "data/extracted/map.json", "assets/protected/tile.png",
                     "godot/assets/protected/tile.png", "builds/app", "reports/test.log",
                     "godot/.godot/cache"):
            with self.subTest(path=path):
                self.assertTrue(self.ignored(path))

    def test_original_sources_are_versionable(self):
        for path in ("godot/scripts/main.gd", "godot/scripts/main.gd.uid", "tools/validate.py",
                     "data/schemas/README.md", "external/README.md", "roms/README.md"):
            with self.subTest(path=path):
                self.assertFalse(self.ignored(path))

if __name__ == "__main__":
    unittest.main()
