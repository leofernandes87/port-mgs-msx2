extends SceneTree

func _init() -> void:
    print("Iniciando montagem do grid estendido...")
    
    var room_w: int = 256
    var room_h: int = 192
    
    var path: String = "res://../tools/grid_0_extended.json"
    var f: FileAccess = FileAccess.open(path, FileAccess.READ)
    if not f:
        print("Erro: grid_0_extended.json nao encontrado")
        quit()
        return
        
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
        
        var img_path: String = "res://../data/extracted/en-eu-rc750/rooms/room-%03d.png" % room_id
        var abs_path: String = ProjectSettings.globalize_path(img_path)
        
        if FileAccess.file_exists(abs_path):
            var room_img: Image = Image.load_from_file(abs_path)
            if room_img:
                if room_img.get_format() != Image.FORMAT_RGBA8:
                    room_img.convert(Image.FORMAT_RGBA8)
                map_image.blit_rect(room_img, Rect2i(0, 0, room_w, room_h), Vector2i(img_x, img_y))
                # print("  Blitted room %03d" % room_id)
        else:
            print("  Missing room %03d" % room_id)
    
    var out_path: String = "res://../maps_to_remaster/predio1_completo_com_interiores.png"
    map_image.save_png(ProjectSettings.globalize_path(out_path))
    print("Montado: predio1_completo_com_interiores.png (%dx%d salas)" % [width, height])
    
    quit()
