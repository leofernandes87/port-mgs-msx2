# Compatibilidade das ROMs locais

## ROM canônica (2026-10-04)

**Única entrada aceita pelo pipeline:** edição inglesa oficial (europeia), perfil `en-eu-rc750` em `data/rom-profiles.json`.

- size `131072`, crc32 `E85C5731`, sha1 `b656bd19df58fc1ba4628342b87beeec5948e0b3`
- sha256 `d16fff4a59ce26b570851c7200f67e05f385978598dcad91c83bf9c671a295ae`
- Evidência primária: montagem com Sjasm 0.39j de `external/MetalGear` (revisão `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`, `MetalGear.asm:38` `JAPANESE equ 0`) é **idêntica byte a byte** à ROM. Reproduzível com `SJASM=… python3 -m tools.rom --verify-build`. O CRC coincide com o declarado em `external/MetalGear/README.md:26`.
- Seleção por conteúdo (`tools/rom.py`): `--rom`, senão `$MG_ROM`, senão busca por SHA-256 em `roms/`. Nome e ordem são irrelevantes; não há fallback.
- Captura: máquina openMSX `C-BIOS_MSX2_EU`. O Godot permanece em 60 Hz por decisão do usuário.

Perfis conhecidos e **recusados** (identificados pelo nome do perfil na mensagem de erro): `jp-rc750-local` (dump japonês local descrito abaixo, 1 byte diferente da montagem `JAPANESE equ 1` em 0x1322), `en-nekura-hoka-1.995c` (tradução de fãs) e `en-6873-bitflip` (variante inglesa com dois bits trocados em 0x7CE1 e 0x13272, movida para fora de `roms/`). A ROM japonesa só deve ser usada a pedido explícito; nunca como fallback, fonte de tradução ou mistura.

**Dados ainda não reextraídos:** os JSON locais em `data/extracted/` têm `input_sha256` do dump japonês. O Godot os aceita apenas como `LEGACY_PENDING_REEXTRACTION` (`godot/scripts/systems/rom_provenance.gd`), com aviso único; reextrair da ROM canônica e remover essa exceção é o critério de saída da próxima fase. Diferenças EN×JP a revalidar depois: texto de coleta de item (`logic/items.asm:409`), configuração de rádio/música (`musicradioconfig.asm:16-20`), nomes de armas, `flagTxtItem` e demo.

O restante deste documento é o histórico da análise anterior, quando apenas o dump japonês estava disponível.

## Resultado (histórico)

**Compatibilidade parcial comprovada, identidade integral/região exata pendente.** As duas ROMs preservam o segmento de salas/metatiles e as demais tabelas descritas abaixo. O CRC diferente não as invalida para o estudo. A candidata principal é a de 128 KiB, por ter os 16 bancos correspondentes à organização da referência; isso não prova qual lançamento/revisão é.

### Candidata de 128 KiB

Arquivo: `roms/Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom`.

- size: `131072`
- crc32: `BE84C94F`
- sha1: `7d685547c2a4b92fa62e00854e4a9689d495f93d`
- sha256: `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf`

### Variante de 160 KiB

Arquivo: `roms/Metal Gear - Konami (1987) [English Version - Nekura_Hoka v.1.995c] [RC-750] [Translated] [7660].rom`.

- size: `163840`
- crc32: `87EC113E`
- sha1: `1b460026e324ab0bf5935b1be211597e3321a398`
- sha256: `89cfeee7d990a6bed050dcffa12ddff179e1632f13450247ee8860587adec6f4`

## Checksums e formato

O README da revisão fixada declara CRC32 japonês FAFE1303 e inglês E85C5731. Nenhuma entrada corresponde. Esses são valores documentados pelo autor, não verificados por uma montagem nossa. Não foi encontrada evidência suficiente para atribuir a divergência a dump incorreto, tradução, revisão oficial ou erro no README.

**B:** as duas começam com AB em offset zero e têm entrada little-endian 0x41F3. Testes de prefixo em offsets 16 e 512 não localizaram AB; tamanhos são múltiplos exatos de 8192 (16 e 20 blocos). O grande segmento de dados está no offset esperado sem deslocamento. **Conclusão limitada:** não há evidência de cabeçalho externo prefixado nessas entradas. A assinatura AB é cabeçalho interno do cartucho, não algo a remover. Não se descarta toda forma de modificação apenas com esses testes. Nenhuma normalização foi necessária ou realizada.

## Comparação binária reproduzível

A ferramenta própria interpreta somente labels/DB/DW literais e ponteiros locais em rooms.asm + metatiles.asm. Resolve forward references em duas passagens, com ORG-base 0x6000 demonstrado por BanksDEF.asm. Compara todos os bytes sem salvar o payload.

| Região | Offset físico | Bytes | Resultado em ambas |
| --- | --- | --- | --- |
| rooms + metatiles (inclui índices e ponteiros) | 0x1A000 | 18176 | zero diferenças |
| RoomGfxSetIds | 0x0E000 | 126 | ocorrência única exata |
| RoomConnections | 0x0AE0E | 624 | ocorrência única exata |
| BoxColliderDat | 0x0431A | 48 | ocorrência única exata |
| Sete CollTiles* | 0x0E0E9–0x0E1C8 | 224 | sete blocos exatos de 32 |

Room000, já incluída no primeiro segmento, também foi localizada isoladamente em 0x1A280 (48 bytes). As comparações adicionais cobrem dados; não estabelecem equivalência das instruções que os consomem. A SHA-256 do segmento de 18176 bytes é `229420e763b52e1f956ec5d61b29d9935e050bf32cfad2d9c34b8285a21c09c9`.

O relatório inclui hashes por banco para comparar as ROMs entre si: alguns bancos coincidem e outros divergem. Não atribuir toda diferença a texto nem supor mapper dos bancos extras. A condição JAPANESE altera region lock e dados/rotinas no disassembly; o nome japonês do arquivo e o aviso “Does not work…” não demonstram a implementação local dessa condição.

## Limites e próximos passos

P: montar duas variantes da referência em área privada, comparar integralmente, localizar intervalos divergentes e verificar código de RegionLock/rotinas principais. Sjasm 0.39 ou compatível não está no PATH e não foi instalado. Não é necessário bloquear a extração das regiões já comprovadas por essa pendência. Cada novo grupo precisa de validação própria.

Nenhum emulador/debugger MSX foi encontrado no PATH ou entre os aplicativos com nome MSX/Retro na inspeção. Isso não prova ausência em todo o disco; significa que não há execução validada nesta etapa. DSK/ZIP anteriores não foram usados na análise do cartucho.

As entradas foram lidas com read_bytes, sem escrita; hashes antes/depois coincidem. git check-ignore confirmou que ambas estão ignoradas. Relatório com hashes e offsets, sem payload: reports/reverse-engineering.json.

## Atualização da Etapa 3

Na Etapa 3, a verificação foi ampliada a nove segmentos, somando 45.982 bytes, em ambas as ROMs. A de 128 KiB gerou o pacote privado; a tradução passou em dry-run. Compatibilidade continua regional, sem identidade integral do executável. Veja [manifesto e resultados](stage-3-results.md).
