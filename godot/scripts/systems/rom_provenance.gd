class_name RomProvenance
extends RefCounted
## Mirrors data/rom-profiles.json (kept in sync by tests/test_rom.py). Extracted data is
## accepted only from the canonical English ROM or from synthetic fixtures.

enum Status { CANONICAL, SYNTHETIC, REJECTED }

const CANONICAL_PROFILE: String = "en-eu-rc750"
const CANONICAL_SHA256: String = "d16fff4a59ce26b570851c7200f67e05f385978598dcad91c83bf9c671a295ae"
const SYNTHETIC_PROFILE: String = "synthetic"
const SYNTHETIC_SHA256: String = "0000000000000000000000000000000000000000000000000000000000000000"
const CANONICAL_DATA_DIR: String = "res://../data/extracted/en-eu-rc750"

static func classify(rom_profile: Variant, sha256: Variant) -> Status:
	if rom_profile is String and sha256 is String:
		if rom_profile == CANONICAL_PROFILE and sha256 == CANONICAL_SHA256:
			return Status.CANONICAL
		if rom_profile == SYNTHETIC_PROFILE and sha256 == SYNTHETIC_SHA256:
			return Status.SYNTHETIC
	return Status.REJECTED

static func classify_record(record: Dictionary) -> Status:
	return classify(record.get("rom_profile"), record.get("input_sha256"))

static func canonical_path(relative: String) -> String:
	return ProjectSettings.globalize_path(CANONICAL_DATA_DIR.path_join(relative))

## Returns the parsed dictionary only when it was extracted from the canonical ROM.
static func load_canonical_json(relative: String) -> Dictionary:
	var path: String = canonical_path(relative)
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		push_warning("JSON inválido: %s" % path)
		return {}
	if classify_record(data as Dictionary) != Status.CANONICAL:
		push_warning("ROM_PROVENANCE_REJECTED: %s não foi extraído da ROM canônica %s" % [path, CANONICAL_PROFILE])
		return {}
	return data as Dictionary
