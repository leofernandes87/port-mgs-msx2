class_name RomProvenance
extends RefCounted
## Mirrors data/rom-profiles.json (kept in sync by tests/test_rom.py). Extracted data is
## accepted only from the canonical English ROM or from synthetic fixtures.

enum Status { CANONICAL, SYNTHETIC, LEGACY_PENDING_REEXTRACTION, REJECTED }

const CANONICAL_PROFILE: String = "en-eu-rc750"
const CANONICAL_SHA256: String = "d16fff4a59ce26b570851c7200f67e05f385978598dcad91c83bf9c671a295ae"
const SYNTHETIC_SHA256: String = "0000000000000000000000000000000000000000000000000000000000000000"
## Snapshots produced before the canonical ROM existed came from the local Japanese dump.
## Tolerated only until they are re-extracted from the canonical ROM; then remove this entry.
const LEGACY_PENDING_REEXTRACTION_SHA256: String = "254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf"

static var _legacy_reported: bool = false

static func classify(sha256: String) -> Status:
	if sha256 == CANONICAL_SHA256:
		return Status.CANONICAL
	if sha256 == SYNTHETIC_SHA256:
		return Status.SYNTHETIC
	if sha256 == LEGACY_PENDING_REEXTRACTION_SHA256:
		if not _legacy_reported:
			_legacy_reported = true
			print("ROM_PROVENANCE_LEGACY: dados de sala ainda derivados do dump japonês local; reextração da ROM canônica pendente")
		return Status.LEGACY_PENDING_REEXTRACTION
	return Status.REJECTED
