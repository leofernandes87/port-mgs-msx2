extends SceneTree

func _init() -> void:
    print("Iniciando fatiamento do mapa do Prédio 1 (Salas 0 a 15)...")
    
    var in_path: String = "res://../building1_map.png"
    var map_img: Image = Image.load_from_file(in_path)
    
    if not map_img:
        print("Erro: Não foi possível carregar o mapa em ", in_path)
        quit()
        return
        
    # Calcula a resolução dinamicamente para aceitar mapas HD/4K (4 colunas x 4 linhas)
    var room_w: int = map_img.get_width() / 4
    var room_h: int = map_img.get_height() / 4
    
    var dir: DirAccess = DirAccess.open("res://../")
    if not dir.dir_exists("assets/remastered"):
        dir.make_dir_recursive("assets/remastered")
    
    # O fatiamento respeita a mesma grade X/Y do montador:
    for col in range(4):
        for row in range(4):
            var room_id = col * 4 + row
            
            var img_x = col * room_w
            var img_y = (3 - row) * room_h
            
            var room_img: Image = map_img.get_region(Rect2i(img_x, img_y, room_w, room_h))
            var out_path: String = "res://../assets/remastered/room-%03d.png" % room_id
            
            var err: int = room_img.save_png(out_path)
            if err == OK:
                print("Fatiada e salva: %s" % out_path)
            else:
                print("Erro ao salvar: %s" % out_path)
                
    print("Fatiamento concluído! Imagens prontas para o Remaster.")
    quit()
