extends Control
## Ponto de entrada da infraestrutura; não implementa mecânicas do original.

var boot_completed: bool = false

func _ready() -> void:
	boot_completed = true
	print("BOOT_OK: cena principal pronta")
