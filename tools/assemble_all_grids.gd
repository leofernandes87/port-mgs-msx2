extends SceneTree

func _init() -> void:
    print("Iniciando montagem de todos os mapas agrupados...")
    
    var room_w: int = 256
    var room_h: int = 192
    
    for i in range(10): # Apenas os grids de 0 a 9 possuem mais de 1 sala
        var path: String = "res://../tools/grid_%d.json" % i
        var f: FileAccess = FileAccess.open(path, FileAccess.READ)
        if not f:
            continue
            
        var data: Dictionary = JSON.parse_string(f.get_as_text())
        var width: int = data["width"]
        var height: int = data["height"]
        var rooms: Dictionary = data["rooms"]
        
        var map_w: int = width * room_w
        var map_h: int = height * room_h
        
        var map_image: Image = Image.create(map_w, map_h, false, Image.FORMAT_RGBA8)
        
        for room_id_str in rooms:
            var room_id: int = room_id_str.to_int()
            var coords: Dictionary = rooms[room_id_str]
            var x: int = coords["x"]
            var y: int = coords["y"]
            
            var img_x: int = x * room_w
            # Y no Godot/imagem cresce para baixo. A matemática do grid Y cresce para cima.
            var img_y: int = (height - 1 - y) * room_h
            
            var img_path: String = "res://../data/extracted/en-eu-rc750/rooms/room-%03d.png" % room_id
            var abs_path: String = ProjectSettings.globalize_path(img_path)
            
            if FileAccess.file_exists(abs_path):
                var room_img: Image = Image.load_from_file(abs_path)
                if room_img:
                    if room_img.get_format() != Image.FORMAT_RGBA8:
                        room_img.convert(Image.FORMAT_RGBA8)
                    map_image.blit_rect(room_img, Rect2i(0, 0, room_w, room_h), Vector2i(img_x, img_y))
                    print("  Blitted room %03d at (%d, %d)" % [room_id, img_x, img_y])
            else:
                print("  Missing room %03d" % room_id)
        
        var out_path: String = "res://../map_grid_%d.png" % i
        map_image.save_png(ProjectSettings.globalize_path(out_path))
        print("Montado: map_grid_%d.png (%dx%d salas)" % [i, width, height])
        
    quit()
