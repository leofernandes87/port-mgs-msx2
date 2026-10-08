---
name: rom-extraction
description: >-
  Ler dados da ROM canônica do Metal Gear MSX2 e gerar dados intermediários: resolver a ROM por
  hash com tools/rom.py, escrever extratores em tools/extractors/, proveniência e saídas em
  data/extracted/en-eu-rc750/. Use ao criar ou alterar extratores, reextrair dados, comparar
  regiões ou quando o Godot recusar dados por proveniência.
---

# Extração da ROM canônica

## Identidade (já implementada; não refazer)

- Perfil canônico `en-eu-rc750` em `data/rom-profiles.json`: 131072 bytes, CRC32 `E85C5731`,
  SHA-256 `d16fff4a…a295ae`. Idêntica à montagem da referência com `JAPANESE equ 0`.
- `python3 -m tools.rom --check` confere a ROM local (`--rom`, depois `$MG_ROM`, depois busca por
  hash em `roms/`). Nome do arquivo e ordem do diretório não importam.
- A ROM japonesa é ignorada salvo pedido explícito do usuário: nunca fallback, mistura ou tradução.
- A ROM é somente leitura; nenhum extrator escreve fora de um diretório de saída novo.

## API para extratores (`tools/rom.py`)

```python
from tools.rom import resolve_canonical_rom, canonical_data_dir, require_canonical_provenance
rom = resolve_canonical_rom(args.rom)        # recusa qualquer hash diferente
data = rom.data                              # bytes; offset físico = banco*0x2000 + (cpu - janela)
out = canonical_data_dir() / 'meu-dado'      # data/extracted/en-eu-rc750/... (ignorado pelo Git)
record = {**rom.provenance(), ...}           # rom_profile + input_sha256
require_canonical_provenance(record)          # o Godot (RomProvenance) também recusa outra origem
rom.assert_unchanged()                        # antes de gravar: a ROM não mudou durante a leitura
```

- Offsets: derive por símbolo da desmontagem (padrão em `tools/extractors/reference.py`), não por
  número fixo sem conferência. Proibido `DEFAULT_ROM`, nome de arquivo de ROM ou varrer `roms/`
  (`tests/test_rom.py` falha).
- Recuse sobrescrever saída existente; grave manifesto com perfil, hash e revisão da referência.
- Testes em `tests/` só com fixtures sintéticas próprias, nunca bytes do jogo.

## Dados existentes

- Consumidos pelo Godot: só `data/extracted/en-eu-rc750/` (`package/`, `rooms/`, `local-aliases/`,
  `*.json`, `prison-walls/`, `dialogues/`). Qual extrator gera o quê: `lookup mech ID`.
- `package/package.json` tem ~19 MB: nunca ler inteiro; use `rooms/room-NNN*.json` ou
  `jq '.chave' arquivo` para um campo.
- `data/extracted/legacy-jp-rc750-local/` só para `tools/reverse_engineering/compare_regions.py`.
- Diferenças EN×JP e auditoria regional: `docs/reverse_engineering/en-eu-reextraction.md`.
