---
name: openmsx-probe
description: >-
  Observar o jogo original rodando no openMSX com scripts Tcl somente leitura (breakpoints, RAM,
  VRAM, temporização) contra a ROM canônica. Use quando o assembly sozinho não resolve um
  comportamento dinâmico, para capturar salas/VRAM ou medir tempos reais por tick.
---

# Sondas no openMSX

## Base existente (reaproveite)

- openMSX 21.0: `/Applications/openMSX.app/Contents/MacOS/openmsx`. Máquina: campo
  `openmsx_machine` do perfil canônico (`C-BIOS_MSX2_EU`), nunca a JP para dados canônicos.
- `tools/emulation/capture.py` (+ `capture.tcl`): salas, RAM, VRAM e paleta.
- `tools/emulation/run_trace.py --script X.tcl --output data/extracted/<novo>`: roda um Tcl seu na
  ROM canônica; `--map OLD=NEW` reloca endereços e `--expect CPU=BYTE` confere opcodes antes.
- `tools/emulation/compare.py`: confere captura contra o pacote extraído.
- Detalhes e breakpoints verificados: `tools/emulation/README.md`.

## Regras de sonda

- Somente leitura: sem escrita em RAM/VRAM/ROM; teclas só se a sonda exigir e forem registradas.
- Cabeçalho Tcl: `set renderer none`, `set throttle off`, `set sound_driver null`,
  `set save_settings_on_exit false`.
- Endereços: CPU dos bancos fixos 0–3 = offset físico + 0x4000. Rotina em banco paginado: o
  breakpoint pode disparar com outro banco mapeado (inclusive no boot). Use condição que confira o
  banco (ex.: `BankInA0 == 9`) e ancore o padrão de bytes (único na ROM) antes de armar.
- Endereços de RAM: `python3 -m tools.context.lookup ram Nome`.
- Sempre um limite emulado (`after time N finish`) e um watchdog real no Python; macOS não tem
  `timeout`.
- Saída em diretório **novo** em `data/extracted/` (ignorado), com manifesto (perfil, hash,
  máquina, script). Scripts que abrem CSV para escrita destroem a captura anterior.

## Resultado

Registre endereços, banco, condição, ticks medidos e limites do que a sonda prova no documento
da mecânica em `docs/reverse_engineering/`, separando evidência de hipótese.
