---
name: inspect-msx-disassembly
description: >-
  Passo zero obrigatório: localizar e citar a rotina Z80 original em external/MetalGear/ antes de
  implementar, corrigir ou alterar qualquer mecânica, cutscene, sprite, animação, temporizador,
  velocidade, colisão, texto ou física. Use também para achar endereços de RAM, constantes e quem
  já cita um trecho do assembly.
---

# Inspecionar a desmontagem original

`external/MetalGear/` (revisão `30d1b940`, `JAPANESE equ 0` em `MetalGear.asm:38`) é a fonte de
verdade. O diretório é ignorado pelo Git, pela busca padrão e pela indexação do Cursor.

## 1. Localizar (uma chamada, sem ler arquivos inteiros)

```sh
python3 -m tools.context.lookup asm ChkRadioCalls -n 60   # definição + 60 linhas; sem match, sugere nomes
python3 -m tools.context.lookup ram TextId                # endereço/tamanho em Variables.asm
python3 -m tools.context.lookup mech radio                # cadeia asm → dados → Godot → teste → docs
python3 -m tools.context.lookup cites logic/items.asm:399 # quem no projeto já cita o trecho
```

- Índices locais (refeitos sozinhos quando a fonte muda): `data/extracted/index/asm-symbols.tsv`
  (rótulos e `equ` com arquivo:linha, grupo de bancos e ramo) e `ram-map.tsv`.
  Consulta direta: `rg "^Simbolo\t" data/extracted/index/asm-symbols.tsv`.
- Busca textual: `rg --no-ignore -n 'padrão' external/MetalGear` (sem `--no-ignore` não acha nada).
- Constantes e enums: `constants/Enums.asm`; RAM: `Variables.asm` (`map #c000`).
- Nunca leia `Banks0123.asm` (13,8 mil linhas) inteiro: use `lookup asm` ou `Read` com offset/limit.

## 2. Ler com cuidado

- **Ramos regionais:** blocos `IF (JAPANESE)` / `ELSE` / `ENDIF` (e `IF (!JAPANESE)`). Siga só o ramo
  inglês; o índice marca `jp`/`en` e `lookup asm` oculta o ramo `jp` (use `--jp` só para relatório).
- **Comentários do desmontador podem estar errados.** Ex.: o cabeçalho de `data/radiocalls.asm`
  inverte `RADIO_WAITCALL`/`RADIO_AUTOREPLY`; confirme no código que consome a tabela.
- Confira valores exatos: registradores, flags, contadores por tick (60 Hz), velocidades 8.8
  (`100h` = 1 px/tick), máscaras de bits e a rotina chamadora (ordem dentro de `PlayModeLogic`).
- Rotinas em bancos paginados: o grupo no índice diz qual `BanksXXX.asm` as inclui.

## 3. Citar

Formato: `arquivo.asm:início-fim` relativo a `external/MetalGear/`, com o caminho completo quando o
nome se repete (`logic/actors/camera.asm`, não `camera.asm`). Exemplo em GDScript:

```gdscript
# ChkRadioCalls (Banks0123.asm:1689-1743): CALL só quando RoomsMusic tem o bit 3.
```

`python3 -m tools.context.build_index --check` (também no `validate.py`) falha com citação para
arquivo inexistente/ambíguo ou linha além do fim. Sem evidência no asm: registre como hipótese ou
pendência e não implemente.

## 4. Próximo passo

Implementação: skill `implement-faithful-mechanic`. Dados da ROM: skill `rom-extraction`.
Comportamento dinâmico que o asm não resolve: skill `openmsx-probe`.
