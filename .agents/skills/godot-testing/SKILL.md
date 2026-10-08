---
name: godot-testing
description: >-
  Escrever, registrar e rodar testes headless do Godot 4 e a validação completa do projeto. Use
  ao criar ou alterar testes em godot/tests/, ao registrar uma suíte no tools/validate.py, ao rodar
  uma suíte isolada ou ao diagnosticar falha do validate.
---

# Testes Godot e validação

## Ambiente verificado

- Godot 4.7.2: `/Applications/Godot.app/Contents/MacOS/Godot` (ou `$GODOT_BIN`). Python 3 stdlib.
- macOS não tem `timeout`; use o timeout do `subprocess` ou do próprio teste.
- `python3 tools/validate.py` e o Godot escrevem em `user://logs`: rode **fora do sandbox**
  (permissão `all`); dentro dele aparecem erros de log falsos.

## Rodar

```sh
python3 tools/validate.py     # ROM (se houver) → índices → unittest → import → suítes → boot
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --path godot --script res://tests/radio_system_test.gd   # uma suíte
python3 -m unittest tests.test_region_tools -v                            # um módulo Python
```

Uma etapa falha se o processo sai com erro, se a saída contém `ERROR:`/`SCRIPT ERROR:` ou se falta
o marcador. Logs completos em `reports/<etapa>.log` (leia o fim, não o arquivo todo).

## Escrever uma suíte

Modelo (igual às existentes, ex. `godot/tests/radio_system_test.gd`):

```gdscript
extends SceneTree

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error("FALHA: " + message)
		quit(1)
		return false
	return true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var system: MeuSistema = MeuSistema.new()
	if not require(system.valor == 4, "valor de X (arquivo.asm:linhas)"): return
	print("MEU_SISTEMA_OK: resumo")
	quit(0)
```

- Cite o asm nas mensagens das asserções. Dados privados ausentes: o teste deve funcionar com
  fixtures sintéticas (`RomProvenance` aceita o perfil `synthetic`).
- Registre em `GODOT_TESTS` de `tools/validate.py`: `(etapa, script, "MARCADOR_OK:", descrição)`.
- Regenere `docs/index/tests.md` com `python3 -m tools.context.build_index`.
- Quem cobre um sistema: `rg sistema.gd docs/index/tests.md`.
