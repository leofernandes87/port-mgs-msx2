extends SceneTree

func _init() -> void:
    print("Iniciando fatiamento inteligente de mapa...")
    
    # === EDITE AQUI ===
    # 1. Caminho da sua imagem pintada
    var in_path: String = ProjectSettings.globalize_path("res://../maps_to_remaster/predio_2_terreo_new.png")
    # 2. Número do grid correspondente (veja o arquivo tools/grid_X.json correspondente ao mapa que você está editando)
    # Exemplo: map_grid_1.png corresponde ao grid 1
    var grid_id: int = 1
    # =================
    
    var map_img: Image = Image.load_from_file(in_path)
    if not map_img:
        print("Erro: Não foi possível carregar o mapa em ", in_path)
        quit()
        return
        
    var json_path: String = "res://../tools/grid_%d.json" % grid_id
    var f: FileAccess = FileAccess.open(json_path, FileAccess.READ)
    if not f:
        print("Erro: JSON de mapeamento não encontrado em ", json_path)
        quit()
        return
        
    var data: Dictionary = JSON.parse_string(f.get_as_text())
    var width: int = data["width"]
    var height: int = data["height"]
    var rooms: Dictionary = data["rooms"]
    
    # Calcula a resolução dinamicamente para aceitar mapas HD/4K
    var room_w: int = map_img.get_width() / width
    var room_h: int = map_img.get_height() / height
    
    var base_dir: String = ProjectSettings.globalize_path("res://../")
    var dir: DirAccess = DirAccess.open(base_dir)
    if not dir.dir_exists("assets/remastered"):
        dir.make_dir_recursive("assets/remastered")
    
    for room_id_str in rooms:
        var room_id: int = room_id_str.to_int()
        var coords: Dictionary = rooms[room_id_str]
        var x: int = coords["x"]
        var y: int = coords["y"]
        
        var img_x = x * room_w
        var img_y = (height - 1 - y) * room_h
        
        var room_img: Image = map_img.get_region(Rect2i(img_x, img_y, room_w, room_h))
        var out_path: String = base_dir + "assets/remastered/room-%03d.png" % room_id
        
        var err: int = room_img.save_png(out_path)
        if err == OK:
            print("Fatiada e salva: %s" % out_path)
        else:
            print("Erro ao salvar: %s" % out_path)
            
    print("Fatiamento concluído com sucesso!")
    quit()
