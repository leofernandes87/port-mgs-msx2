# Compatibilidade das ROMs locais

## Resultado

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
