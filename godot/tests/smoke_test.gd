extends SceneTree
## Código de saída explícito: falhas não dependem de assert habilitado.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("Cena principal não carregou")
		return
	var scene: Control = packed.instantiate() as Control
	if scene == null:
		_fail("Raiz da cena não é Control")
		return
	root.add_child(scene)
	await process_frame
	if scene.get("boot_completed") != true:
		_fail("_ready não completou")
		return
	var label: Label = scene.get_node_or_null("Status") as Label
	if label == null or label.text.is_empty():
		_fail("Status ausente ou vazio")
		return
	scene.queue_free()
	await process_frame
	print("SMOKE_OK: cena, ciclo de vida e status verificados")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
