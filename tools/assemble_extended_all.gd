extends SceneTree

func _init() -> void:
    var room_w: int = 256
    var room_h: int = 192
    
    var names: Array[String] = [
        "predio1_completo_com_interiores",
        "predio_2_terreo",
        "predio_2_telhado",
        "predio_1_telhado",
        "predio_1_subsolo",
        "selva_deserto",
        "labirinto_1",
        "labirinto_2",
        "labirinto_3",
        "subsolo_profundo"
    ]
    
    for i in range(10):
        var path: String = "res://../tools/grid_%d_extended.json" % i
        var f: FileAccess = FileAccess.open(path, FileAccess.READ)
        if not f: continue
        
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
            var img_y: int = (height - 1 - y) * room_h
            
            var abs_path: String = ""
            for sub in ["stage5-batch", "stage4c-validated", "stage5-lorries", "stage5-elevators"]:
                var p = ProjectSettings.globalize_path("res://../data/extracted/%s/room-%03d.png" % [sub, room_id])
                if FileAccess.file_exists(p):
                    abs_path = p
                    break
            
            if abs_path != "":
                var room_img: Image = Image.load_from_file(abs_path)
                if room_img:
                    if room_img.get_format() != Image.FORMAT_RGBA8:
                        room_img.convert(Image.FORMAT_RGBA8)
                    map_image.blit_rect(room_img, Rect2i(0, 0, room_w, room_h), Vector2i(img_x, img_y))
        
        var out_path: String = "res://../maps_to_remaster/%s.png" % names[i]
        map_image.save_png(ProjectSettings.globalize_path(out_path))
        print("Montado: %s.png (%dx%d)" % [names[i], width, height])
        
    quit()
