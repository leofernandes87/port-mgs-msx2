# Verificação em execução e snapshots

openMSX 21.0 instalado localmente; máquina `C-BIOS_MSX2_JP`, disponibilizada com o aplicativo. Nenhum BIOS proprietário novo, instalação ou patch necessário. Captura por debugger em leitura, durante sequência natural de título/demo, sem teclas ou escritas em RAM/VRAM/ROM. Configurações não são salvas ao sair. O aplicativo pode criar arquivos normais de estado em sua pasta de usuário.

`capture.py` aceita somente SHA-256 principal analisado. Verifica dois padrões de instrução únicos antes de usar breakpoints; não é localizador genérico de rotinas para qualquer variante. Breakpoints: RenderRoom 0x4CF0 e RET de WaitVdpCmd 0x4EDB. Ambas as rotinas estão no banco fixo 0; endereço CPU = offset físico + 0x4000. `Variables.asm` fundamenta Room 0xC130, CurrentTileSet 0xC157, RoomTileBuffer 0xE000, DoorsList 0xC3D0 e DoorOpenArray 0xC450.

Na volta de RenderRoom, coleta RAM e VRAM. Se o VDP ainda estiver ocupado, captura novamente a VRAM no primeiro retorno de WaitVdpCmd. A igualdade integral do framebuffer é verificada, não presumida pela posição do breakpoint. Até quatro salas, limite de 120 segundos emulados e watchdog de 45 segundos reais. A execução Python também tem timeout. Saída nova obrigatória em data/extracted/; falha pode deixar evidências incompletas para diagnóstico, mas não gera manifesto de sucesso.

```sh
ROM_INPUT='roms/Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom'
python3 tools/emulation/capture.py --rom "$ROM_INPUT" --output data/extracted/minha-captura
python3 tools/emulation/compare.py --package data/extracted/rc750-verified/package.json --capture data/extracted/minha-captura --output data/extracted/meus-snapshots
```

`compare.py` verifica hashes, contrato de extração, 768 bytes de RoomTileBuffer, todos os tiles carregados do tileset, registros de portas de 16 bytes e 49.152 pixels do fundo. Preenche graficamente slots antes nulos apenas com a VRAM observada **daquela sala/captura**, não por regra global. O arquivo JSON resultante é contrato diagnóstico, não substitui a representação original por metatiles.

Dados desta entrega: `emulator-stage4-settled/` contém captura final; `stage4-validated/` contém snapshots, PNGs, checksums e comparison.json. `emulator-stage4/` e `stage4-snapshots/` são investigações intermediárias preservadas. Toda saída real permanece ignorada.

Visualizador, na raiz do projeto (caminho de snapshot absoluto):

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path godot res://scenes/room_inspector.tscn -- --snapshot /caminho/absoluto/data/extracted/stage4-validated/room-005.json
```

Alternativamente execute `godot/scenes/room_inspector.tscn` com F6 e use **Abrir snapshot local**. Escolha `room-NNN.json`, não package.json. O botão de colisão mostra a máscara estática. A cena principal original permanece independente de ROM. Não copia dados para res:// nem salva recursos protegidos no projeto Godot.

Teste opcional da integração real:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/room_snapshot_integration.gd -- --snapshot /caminho/absoluto/room-005.json --expected /caminho/absoluto/room-005.png
```

Sem `--headless`, `--screenshots /caminho/absoluto/reports/minha-inspecao` grava duas imagens novas, com e sem overlay. A rotina recusa sobrescrita. Testes sem dados privados: `python3 tools/validate.py`.

O teste de imagem compara índices em Python e RGB nominal entre Python/Godot. **Não** comprova a paleta dinâmica, o frame com portas/atores, toda a sequência de jogo ou o hardware original. O modo demo é a origem das quatro observações desta entrega.
