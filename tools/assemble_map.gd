extends SceneTree

func _init() -> void:
    print("Iniciando montagem do mapa do Prédio 1 (Salas 0 a 15)...")
    
    var room_w: int = 256
    var room_h: int = 192
    
    var cols: int = 4
    var rows: int = 4
    
    var map_w: int = cols * room_w
    var map_h: int = rows * room_h
    
    var map_image: Image = Image.create(map_w, map_h, false, Image.FORMAT_RGBA8)
    
    # Layout (Colunas X e Linhas Y da grade, Y cresce para baixo)
    # Coluna 0: 0, 1, 2, 3 (onde 0 é embaixo, 3 é em cima)
    for col in range(4):
        for row in range(4):
            var room_id = col * 4 + row
            
            # Y no mapa precisa ser invertido, pois row 0 é embaixo no jogo, mas na imagem Y cresce pra baixo
            var img_x = col * room_w
            var img_y = (3 - row) * room_h
            
            var path: String = "res://../data/extracted/stage5-batch/room-%03d.png" % room_id
            var room_img: Image = Image.load_from_file(path)
            if room_img:
                if room_img.get_format() != Image.FORMAT_RGBA8:
                    room_img.convert(Image.FORMAT_RGBA8)
                var src_rect := Rect2i(0, 0, room_w, room_h)
                map_image.blit_rect(room_img, src_rect, Vector2i(img_x, img_y))
            else:
                print("Imagem da sala %d não encontrada." % room_id)
                
    var out_path: String = "res://../building1_map.png"
    var err: int = map_image.save_png(out_path)
    if err == OK:
        print("Mapa salvo com sucesso em: " + out_path)
    else:
        print("Erro ao salvar o mapa: ", err)
        
    quit()
