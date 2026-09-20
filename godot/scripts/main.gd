extends Control
## Ponto de entrada da infraestrutura; não implementa mecânicas do original.

var boot_completed: bool = false

func _ready() -> void:
	boot_completed = true
	print("BOOT_OK: cena principal pronta")

	var nav := HBoxContainer.new()
	nav.position = Vector2(48, 420)
	nav.add_theme_constant_override("separation", 16)
	add_child(nav)

	var sandbox_btn := Button.new()
	sandbox_btn.text = "Jogar Sandbox Gameplay (Snake)"
	sandbox_btn.custom_minimum_size = Vector2(260, 44)
	sandbox_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/sandbox_gameplay.tscn")
	)
	nav.add_child(sandbox_btn)

	var inspector_btn := Button.new()
	inspector_btn.text = "Abrir Inspetor de Salas"
	inspector_btn.custom_minimum_size = Vector2(220, 44)
	inspector_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/room_inspector.tscn")
	)
	nav.add_child(inspector_btn)
