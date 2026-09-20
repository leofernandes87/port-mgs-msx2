class_name WeaponSystem
extends RefCounted

## Gerenciador de armas, munição e balística fiel ao MSX2 RC750 (Etapa 13).
## Lógica revertida de logic/weaponuse.asm, logic/items.asm e logic/maxammo.asm.

const WEAPON_NONE: String = ""
const WEAPON_HANDGUN: String = "HANDGUN"                 # ID 1 na ROM (HAND_GUN)
const WEAPON_SMG: String = "SMG"                         # ID 2 na ROM (SUB_MACHINE_GUN)
const WEAPON_GRENADE_LAUNCHER: String = "GRENADE_LAUNCHER" # ID 3 na ROM (GRENADE_LAUNCHER)

var owned_weapons: Array[String] = []
var selected_weapon: String = WEAPON_NONE

# Contadores de munição atuais
var ammo: Dictionary = {
	WEAPON_HANDGUN: 0,
	WEAPON_SMG: 0,
	WEAPON_GRENADE_LAUNCHER: 0,
}

# Limites de munição para Rank 1 (Class 0 na ROM - MaxAmmoLv1 em maxammo.asm:112-119)
# HAND_GUN: 50h = 50 balas, SMG: 50h = 50 balas, GRENADE: 15h = 15 granadas
var max_ammo: Dictionary = {
	WEAPON_HANDGUN: 50,
	WEAPON_SMG: 50,
	WEAPON_GRENADE_LAUNCHER: 15,
}

# Supressor de ruído (InvSupressor em logic/items.asm:188)
var has_silencer: bool = false

func has_weapon(weapon_id: String) -> bool:
	return owned_weapons.has(weapon_id)

func add_weapon(weapon_id: String, initial_ammo: int = 0) -> bool:
	if not weapon_id in [WEAPON_HANDGUN, WEAPON_SMG, WEAPON_GRENADE_LAUNCHER]:
		return false

	var is_first: bool = owned_weapons.is_empty()

	if not owned_weapons.has(weapon_id):
		owned_weapons.append(weapon_id)
		# Se for a primeira arma coletada e não for lançador de granadas, auto-seleciona (logic/items.asm:253-261)
		if is_first and weapon_id != WEAPON_GRENADE_LAUNCHER:
			selected_weapon = weapon_id
		elif selected_weapon == WEAPON_NONE:
			selected_weapon = weapon_id

		if initial_ammo > 0:
			var cap: int = int(max_ammo.get(weapon_id, 50))
			ammo[weapon_id] = mini(cap, int(ammo.get(weapon_id, 0)) + initial_ammo)

		print("WEAPON_ACQUIRED: %s adicionada ao arsenal! Munição: %d" % [weapon_id, ammo.get(weapon_id, 0)])
		return true

	# Se já possuía a arma, adicionar munição extra
	if initial_ammo > 0:
		var cap: int = int(max_ammo.get(weapon_id, 50))
		ammo[weapon_id] = mini(cap, int(ammo.get(weapon_id, 0)) + initial_ammo)
		print("WEAPON_AMMO_REFILLED: %s recarregada com %d balas. Total: %d" % [
			weapon_id, initial_ammo, ammo.get(weapon_id, 0)
		])
		return true

	return false

## Coleta de caixa de munição (PickAmmoCrate em logic/items.asm:333-356)
## Concede +20 balas de pistola, +20 de SMG e +6 granadas respeitando os limites da patente
func add_ammo_crate(amount_handgun: int = 20, amount_smg: int = 20, amount_grenade: int = 6) -> void:
	if owned_weapons.has(WEAPON_HANDGUN):
		var cap_hg: int = int(max_ammo.get(WEAPON_HANDGUN, 50))
		ammo[WEAPON_HANDGUN] = mini(cap_hg, int(ammo.get(WEAPON_HANDGUN, 0)) + amount_handgun)

	if owned_weapons.has(WEAPON_SMG):
		var cap_smg: int = int(max_ammo.get(WEAPON_SMG, 50))
		ammo[WEAPON_SMG] = mini(cap_smg, int(ammo.get(WEAPON_SMG, 0)) + amount_smg)

	if owned_weapons.has(WEAPON_GRENADE_LAUNCHER):
		var cap_gr: int = int(max_ammo.get(WEAPON_GRENADE_LAUNCHER, 15))
		ammo[WEAPON_GRENADE_LAUNCHER] = mini(cap_gr, int(ammo.get(WEAPON_GRENADE_LAUNCHER, 0)) + amount_grenade)

	print("AMMO_CRATE_COLLECTED: Armas recarregadas! Handgun: %d/%d, SMG: %d/%d" % [
		ammo.get(WEAPON_HANDGUN, 0), max_ammo.get(WEAPON_HANDGUN, 50),
		ammo.get(WEAPON_SMG, 0), max_ammo.get(WEAPON_SMG, 50)
	])

func cycle_weapon() -> void:
	if owned_weapons.is_empty():
		selected_weapon = WEAPON_NONE
		return

	# Lista de opções inclui [DESARMADO] + armas possuídas
	var options: Array[String] = [WEAPON_NONE]
	for w: String in owned_weapons:
		options.append(w)

	var current_idx: int = options.find(selected_weapon)
	var next_idx: int = (current_idx + 1) % options.size()
	selected_weapon = options[next_idx]
	print("WEAPON_SELECTED: %s" % (selected_weapon if not selected_weapon.is_empty() else "[DESARMADO]"))

func select_weapon(weapon_id: String) -> bool:
	if weapon_id.is_empty() or owned_weapons.has(weapon_id):
		selected_weapon = weapon_id
		return true
	return false

func can_fire() -> bool:
	if selected_weapon.is_empty():
		return false
	return int(ammo.get(selected_weapon, 0)) > 0

func consume_ammo() -> bool:
	if can_fire():
		ammo[selected_weapon] = int(ammo[selected_weapon]) - 1
		return true
	return false

func set_silencer(active: bool) -> void:
	has_silencer = active
	print("SILENCER_STATE: %s" % ("EQUIPADO" if active else "DESEQUIPADO"))

func get_status_text() -> String:
	if selected_weapon.is_empty():
		return "[DESARMADO]"
	var count: int = int(ammo.get(selected_weapon, 0))
	var sil_tag: String = " (SIL)" if has_silencer else ""
	return "[%s x%02d%s]" % [selected_weapon, count, sil_tag]
