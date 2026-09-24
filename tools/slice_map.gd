extends SceneTree

# Este script é a "Faca Mágica". Ele pega o seu mapa gigante que você desenhou (ex: o Andar 1 inteiro),
# olha para a malha invisível (grid) e recorta automaticamente sala por sala, salvando em imagens
# separadas prontas para o Godot usar dentro do jogo.

func _init() -> void:
    print("Iniciando fatiamento inteligente de mapa (Slicer)...")
    
    # ==========================================
    # 🔴 ÁREA DE CONFIGURAÇÃO - EDITE AQUI 🔴
    # ==========================================
    
    # 1. Caminho da Imagem Finalizada:
    # Troque o nome "predio_2_terreo_new.png" pelo nome do arquivo que você acabou de pintar/remasterizar.
    # Lembre-se que a imagem precisa estar na pasta "maps_to_remaster/".
    var in_path: String = ProjectSettings.globalize_path("res://../maps_to_remaster/predio_2_terreo_new.png")
    
    # 2. Número do Andar/Grid (Grid ID):
    # Diga para o script qual andar você está cortando. 
    # Por exemplo: Building 1 (Térreo) = 1. Basement = 0. Roof = 2.
    # Isso diz ao Godot qual arquivo "grid_X_extended.json" ele deve ler para saber onde cortar.
    var grid_id: int = 1
    
    # ==========================================
    # 🛠 FIM DA CONFIGURAÇÃO (O resto é automático)
    # ==========================================
    
    # Carrega a imagem gigante que você desenhou na memória RAM.
    var map_img: Image = Image.load_from_file(in_path)
    if not map_img:
        print("Erro: Não foi possível carregar o mapa em ", in_path)
        quit()
        return
        
    # Abre o arquivo JSON invisível (ex: grid_1_extended.json) que tem as coordenadas de corte.
    var json_path: String = "res://../tools/grid_%d_extended.json" % grid_id
    var f: FileAccess = FileAccess.open(json_path, FileAccess.READ)
    if not f:
        print("Erro: JSON de mapeamento não encontrado em ", json_path)
        quit()
        return
        
    # Lê as informações da "planta baixa" (quantos blocos de largura e altura o mapa tem)
    var data: Dictionary = JSON.parse_string(f.get_as_text())
    var width: int = data["width"]
    var height: int = data["height"]
    var rooms: Dictionary = data["rooms"]
    
    # 🔍 MATEMÁTICA HD: 
    # Aqui o script é esperto. Ele não espera que a sala tenha exatos 256x192 pixels.
    # Ele divide a largura total da SUA imagem pela quantidade de blocos. 
    # Então se você desenhou em 4K, ele vai descobrir sozinho qual o tamanho do recorte!
    var room_w: int = map_img.get_width() / width
    var room_h: int = map_img.get_height() / height
    
    # Cria a pasta de destino "assets/remastered" (se ela ainda não existir)
    var base_dir: String = ProjectSettings.globalize_path("res://../")
    var dir: DirAccess = DirAccess.open(base_dir)
    if not dir.dir_exists("assets/remastered"):
        dir.make_dir_recursive("assets/remastered")
    
    # Loop principal: Passa de sala em sala lendo o JSON
    for room_id_str in rooms:
        var room_id: int = room_id_str.to_int()
        var coords: Dictionary = rooms[room_id_str]
        
        # Onde a sala está na grade (grid)
        var x: int = coords["x"]
        var y: int = coords["y"]
        
        # Converte as coordenadas do Grid para as coordenadas em Pixels da imagem gigante.
        # (O eixo Y é invertido pois na imagem o (0,0) é no topo-esquerdo)
        var img_x = x * room_w
        var img_y = (height - 1 - y) * room_h
        
        # "Tesoura": Recorta um retângulo (Rect2i) da imagem gigante
        var room_img: Image = map_img.get_region(Rect2i(img_x, img_y, room_w, room_h))
        
        # Caminho e nome do arquivo novo (ex: room-011.png)
        var out_path: String = base_dir + "assets/remastered/room-%03d.png" % room_id
        
        # Salva o pedaço recortado como PNG definitivo!
        var err: int = room_img.save_png(out_path)
        if err == OK:
            print("Fatiada e salva: %s" % out_path)
        else:
            print("Erro ao salvar: %s" % out_path)
            
    print("Fatiamento concluído com sucesso!")
    quit()
