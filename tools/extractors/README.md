# Extração privada e reproduzível

Python 3, somente biblioteca padrão. Scripts próprios; requer a cópia externa da referência no commit fixado em docs/reference.md. Não monta Z80 nem transfere fontes/assets externos para o Git.

A ROM de entrada é sempre a canônica de `data/rom-profiles.json`, resolvida por `tools/rom.py` pelo SHA-256: `--rom CAMINHO`, senão `$MG_ROM`, senão busca por conteúdo em `roms/`. Nome de arquivo e ordem da pasta não importam; perfis conhecidos não canônicos são recusados pelo nome do perfil, sem fallback. Offsets são localizados por símbolo da referência na ROM canônica, nunca fixados no código. Todo artefato registra `rom_profile` e `input_sha256`.

`extract.py` exige saída explícita; saída deve ser diretório novo sob data/extracted/. Não sobrescreve arquivos/diretórios existentes, symlinks ou hardlinks. Lê a ROM sem escrita e confirma conteúdo ao final. Publica somente depois de validar todas as regiões e o contrato; falha aborta o pacote. Não execute duas publicações concorrentes no mesmo destino. O protocolo de diretório temporário não é proteção contra um processo hostil trocando caminhos simultaneamente.

Na raiz:

```sh
python3 -m tools.rom --check
python3 tools/extractors/extract.py --output data/extracted/meu-run --dry-run
python3 tools/extractors/extract.py --output data/extracted/meu-run
python3 tools/extractors/extract.py --output data/extracted/meu-repeat
python3 tools/extractors/verify.py --package data/extracted/meu-run --repeat-package data/extracted/meu-repeat
python3 tools/validate.py
```

`SJASM=/caminho/sjasm python3 -m tools.rom --verify-build` remonta a referência (`JAPANESE equ 0`) numa cópia temporária e exige igualdade byte a byte com a ROM canônica.

Use nomes de saída ainda inexistentes para repetir. `--reference` permite indicar outra cópia local do mesmo commit limpo. ROM com hash diferente do perfil canônico é rejeitada antes de qualquer decodificação; cabeçalho adicional não é removido automaticamente. Não altere a entrada para forçar aceitação.

Saída: package.json (original compacto + valores derivados + evidências), checksums.json (SHA-256 de todos os outros arquivos), previews/ com 8 atlas, 7 salas × imagem/máscara/overlay, folha de contato e legenda. JSON é a fonte dos índices; PNG é prévia nominal. Tiles nulos ficam magenta. Conteúdo real não é fixture de teste.

`reference.py` localiza/verifica DB/DW e constantes; `codecs.py` contém decoders limitados; `schema.py` valida contrato local e relações; `verify.py` reconstrói tudo em memória, compara arquivos e faz testes negativos sem modificar a ROM. Os testes normais não requerem qualquer conteúdo privado.

[Resultados e limites](../../docs/reverse_engineering/stage-3-results.md). Não exporta gameplay, sprites completos, áudio ou textos. Nunca importar automaticamente saídas para godot/ nem publicar previews no Git.

O verificador exclui somente arquivos chamados `.DS_Store` da conferência do inventário e informa-os em `ignored_os_metadata`; o Finder pode criá-los após a extração. Qualquer outro arquivo adicional é erro. Os hashes cobrem todos os arquivos gerados, sem metadados do sistema.
