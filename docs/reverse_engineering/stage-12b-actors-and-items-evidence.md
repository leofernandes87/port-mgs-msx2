# Evidências de Engenharia Reversa — Etapa 12b: Atores, Itens e Portas da ROM

## 1. Fonte e Procedência

- **Repositório de referência**: `external/MetalGear` (revisão fixada `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`).
- **Arquivos analisados**:
  - `external/MetalGear/Banks0123.asm` (linhas 6140–6470: `SetupEnemyRoom4`, `AddEnemy`, `SetupActor`, tabela de jump index de inicialização).
  - `external/MetalGear/constants/Enums.asm` (linhas 90–165: enums de cartões, portas e itens).
  - `external/MetalGear/data/actorsinrooms.asm` (linhas 1–1030: listas de atores por sala).
  - `external/MetalGear/data/itemsinrooms.asm` (linhas 1–80: ponteiros de itens por sala).
  - `external/MetalGear/data/doors.asm` (linhas 910–930: `IdDoorsLogic`, `DoorOpenEnterDat`).

---

## 2. Tabela Canônica de Inicialização de Atores (57 Tipos)

No código original Z80 (`Banks0123.asm:6404`), cada ator é instanciado em `SetupActor` e despachado via `JumpIndex` subtraindo 1 do ID do ator (`1..57`):

| ID | Símbolo ASM | Categoria | Comportamento no MSX2 | Velocidade / Perfil |
|:---|:---|:---|:---|:---|
| 1 | `InitBridge` | Cenário/Mecânica | Ponte retrátil / armadilha | Estático |
| 2 | `InitBridge` | Cenário/Mecânica | Ponte retrátil (variante) | Estático |
| 3 | `InitEllenVoice` | Evento/Áudio | Gatilho de voz de Ellen | Evento |
| 4 | `InitGuardSlow` | Inimigo (Soldado) | Patrulha lenta regular | SLOW (0.5 px/tick) |
| 5 | `InitGuardMedium` | Inimigo (Soldado) | Patrulha padrão regular | MEDIUM (1.0 px/tick) |
| 6 | `InitCamera` | Sensor/Vigilância | Câmera de segurança oscilante | Estático (varredura) |
| 7 | `InitMines` | Perigo de Chão | Mina terrestre ativa no chão | Estático / Dano ao contato |
| 8 | `InitGas` | Perigo Ambiental | Sala com gás venenoso | Dano por tempo |
| 9 | `InitTank` | Chefe / Veículo | Tanque de guerra | Chefe |
| 10 | `InitGuardAlert` | Inimigo (Soldado) | Guarda em alerta imediato | MEDIUM (1.0 px/tick) |
| 11 | `InitGuardAlert` | Inimigo (Soldado) | Guarda em alerta imediato (var) | MEDIUM (1.0 px/tick) |
| 12 | `InitTankShell` | Projétil / Chefe | Disparo de canhão do tanque | Balístico |
| 13 | `InitShooter` | Inimigo (Soldado) | Guarda atirador estacionário | MEDIUM (1.0 px/tick) |
| 14 | `InitGuardElevat` | Inimigo (Soldado) | Guarda de elevador | SLOW (0.5 px/tick) |
| 15 | `InitRollingBarrel` | Perigo | Barril rolante em descida | Objeto móvel |
| 16 | `InitPitfall` | Armadilha | Alçapão que se abre sob Snake | Chão destrutível |
| 17 | `InitMetalGear` | Chefe Final | Supercomputador / Metal Gear | Chefe |
| 18 | `InitBulldozer` | Chefe / Veículo | Trator de esteiras | Chefe móvel |
| 19 | `InitGuardLorry` | Inimigo (Soldado) | Guarda de vigia do caminhão | MEDIUM (1.0 px/tick) |
| 20 | `InitJetpackTakeoff` | Inimigo Especial | Soldado voador decolando | Aéreo |
| 21 | `InitJetpackSwitch` | Inimigo Especial | Gatilho do soldado voador | Aéreo |
| 22 | `InitJetpack` | Inimigo Especial | Soldado com jetpack ativo | Aéreo rápido |
| 23 | `InitTankShellBoss` | Projétil | Projétil de chefe | Balístico |
| 24 | `InitGuardSwitch` | Inimigo (Soldado) | Guarda acionador de alarme | SLOW (0.5 px/tick) |
| 25 | `InitDog` | Inimigo (Animal) | Cão de guarda de patrulha | FAST (1.5 px/tick) |
| 26 | `InitArnold` | Chefe | Soldado cibernético (Arnold) | Chefe |
| 27 | `InitDogBasement` | Inimigo (Animal) | Cão de guarda do subsolo | FAST (1.5 px/tick) |
| 28 | `InitLorryShooter` | Inimigo (Soldado) | Atirador de caminhão | MEDIUM (1.0 px/tick) |
| 29 | `InitSpawnDog` | Gatilho | Spawner de cães contínuos | Gerador |
| 30 | `InitGuardFast` | Inimigo (Soldado) | Guarda de velocidade alta | FAST (1.5 px/tick) |
| 31 | `InitScorpion` | Inimigo (Animal) | Escorpião do deserto | SLOW (0.5 px/tick) |
| 32 | `InitBigBoss` | Chefe | Big Boss | Chefe final |
| 33 | `InitShotGunner` | Chefe | Shotgunner | Chefe |
| 34 | `InitMachGunKid` | Chefe | Machine Gun Kid | Chefe |
| 35 | `InitLaserRoom` | Perigo | Barreira de feixes laser | Dano / Alarme |
| 36 | `InitFireTrooper` | Chefe | Fire Trooper (lança-chamas) | Chefe |
| 37 | `InitFlame` | Projétil | Jato de chamas | Dano de fogo |
| 38 | `InitHindD` | Chefe / Veículo | Helicóptero Hind D no telhado | Chefe |
| 39 | `InitSpawnTankShell` | Projétil | Disparo repetido de tanque | Gerador |
| 40 | `InitSpawnGuardElev` | Gatilho | Spawner de guardas no elevador | Gerador |
| 41 | `InitCowardDuck` | Chefe | Coward Duck | Chefe |
| 42 | `InitDummy` | Nenhum | Slot vazio / sem ação | Nenhum |
| 43 | `InitShotGunnerShot` | Projétil | Chumbo de espingarda | Projétil |
| 44 | `InitPowerSwitch` | Mecânica | Caixa de força / alta tensão | Destrutível |
| 45 | `InitCaptureScene` | Evento | Cena de captura no Prédio 2 | Cinemática |
| 46 | `InitDesertSecurity` | Inimigo (Soldado) | Guardas da entrada do Prédio 2 | SLOW (0.5 px/tick) |
| 47 | `InitGuardShot` | Projétil | Bala disparada por guarda | Projétil |
| 48 | `InitSentinel` | Inimigo (Soldado) | Sentinela estático de vigia | SLOW (0.5 px/tick) |
| 49 | `InitPrisoner` | NPC / Resgate | Prisioneiro comum | Interativo |
| 50 | `InitPrisoner` | NPC / Resgate | Prisioneiro comum | Interativo |
| 51 | `InitPrisoner` | NPC / Resgate | Grey Fox | Interativo / Chave |
| 52 | `InitPrisoner` | NPC / Resgate | Prisioneiro comum | Interativo |
| 53 | `InitCameraLaser` | Sensor / Defesa | Câmera armada com laser | Vigilância / Tiro |
| 54 | `InitLaserShot` | Projétil | Disparo laser | Projétil |
| 55 | `InitPrisoner` | NPC / Resgate | Prisioneiro comum | Interativo |
| 56 | `InitPrisoner` | NPC / Resgate | Prisioneiro (Dr. Pettrovich) | Interativo |
| 57 | `InitGuardSilencer` | Inimigo (Soldado) | Guarda com silenciador | MEDIUM (1.0 px/tick) |

---

## 3. Regras Canônicas de Portas (`Enums.asm:113-122`)

Cada porta possui um `open_logic_raw` em `IdDoorsLogic`. Os 5 bits inferiores (`open_rule_id = logic & 31`) definem a regra de destrancamento:

| `open_rule_id` | Nome no Disassembly | Comportamento / Requisito |
|:---|:---|:---|
| 1 | `DOOR_ELEVATOR` | Aberta / Destrancada / Elevador |
| 2 | `DOOR_CARD1` | Requer `CARD1` selecionado no inventário |
| 3 | `DOOR_CARD2` | Requer `CARD2` selecionado no inventário |
| 4 | `DOOR_CARD3` | Requer `CARD3` selecionado no inventário |
| 5 | `DOOR_CARD4` | Requer `CARD4` selecionado no inventário |
| 6 | `DOOR_CARD5` | Requer `CARD5` selecionado no inventário |
| 7 | `DOOR_CARD6` | Requer `CARD6` selecionado no inventário |
| 8 | `DOOR_CARD7` | Requer `CARD7` selecionado no inventário |
| 9 | `DOOR_CARD8` | Requer `CARD8` selecionado no inventário |
| 10 | `DOOR_PUNCH` | Abre com soco ou interação direta (lorry) |
| 11 | Lorry Door | Entrada/saída de caminhão |

---

## 4. Catálogo de Itens da ROM (`data/itemsinrooms.asm:19-46`)

A tabela `idxRoomItems` contém os ponteiros de configuração dos itens:

| Índice | Símbolo ASM | Tipo | Item correspondente |
|:---|:---|:---|:---|
| 1 | `ItemRation` | Consumível | `RATION` |
| 2 | `ItemCard1` | Chave | `CARD1` |
| 3 | `ItemBinoculars` | Equipamento | `BINOCULARS` |
| 4 | `ItemMines` | Arma | Minas Terrestres |
| 5 | `ItemGasMask` | Equipamento | Máscara de Gás |
| 6 | `ItemSMG` | Arma | Submetralhadora |
| 7 | `ItemCard4` | Chave | `CARD4` |
| 8 | `ItemMines2` | Arma | Minas Terrestres |
| 9 | `ItemGoggles` | Equipamento | Óculos Noturnos |
| 10 | `ItemParachute` | Equipamento | Paraquedas |
| 11 | `ItemPBombAmmo` | Munição | Munição Explosivo Plástico |
| 12 | `ItemAmmo` | Munição | Caixa de Munição |
| 13 | `ItemMissile` | Arma | Mísseis Teleguiados |
| 14 | `ItemGrenade` | Arma | Lança-granadas |
| 15 | `ItemPBomb` | Arma | Explosivo Plástico (C4) |
| 16 | `ItemCard2` | Chave | `CARD2` |
| 17 | `ItemBox` | Equipamento | Caixa de Papelão (`CARDBOARD_BOX`) |
| 18 | `ItemCard3` | Chave | `CARD3` |
| 19 | `ItemMineDetect` | Equipamento | Detector de Minas |
| 20 | `ItemBag` | Equipamento | Mochila de Munição |
| 21 | `ItemRation2` | Consumível | `RATION` |
| 22 | `ItemCard1` | Chave | `CARD1` (Caminhão 127) |
| 23 | `ItemArmor` | Equipamento | Colete à Prova de Balas |
| 24 | `ItemBombSuit` | Equipamento | Traje Antibomba |
| 25 | `ItemPBomb2` | Arma | Explosivo Plástico |
| 26 | `ItemUniform` | Equipamento | Uniforme Inimigo |
| 27 | `ItemAntenna` | Equipamento | Antena de Rádio |
| 28 | `ItemUniMineAmm` | Item composto | Munição e Uniforme |
| 29 | `ItemFlashLight` | Equipamento | Lanterna |
| 30 | `ItemRation` | Consumível | `RATION` (Caminhão 126) |
| 35 | `ItemSMG` | Arma | Submetralhadora (Sala 122) |
