extends SceneTree

func _init() -> void:
    var width = 128
    var height = 128
    var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
    
    # Preenche com transparente
    img.fill(Color(0,0,0,0))
    
    # Desenha grades para orientar o artista
    var grid_color = Color(1, 0, 1, 0.5) # Magenta semi-transparente
    var text_color = Color(1, 1, 1, 1)
    
    for x in range(0, width, 32):
        for y in range(height):
            img.set_pixel(x, y, grid_color)
    for y in range(0, height, 32):
        for x in range(width):
            img.set_pixel(x, y, grid_color)
            
    # Marcar os centros
    for r in range(4):
        for c in range(4):
            img.set_pixel(c*32 + 16, r*32 + 16, Color.RED)
            
    var out_path = ProjectSettings.globalize_path("res://../assets/snake_template.png")
    img.save_png(out_path)
    print("Template salvo!")
    quit()
