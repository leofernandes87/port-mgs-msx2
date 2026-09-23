import json
import glob
import os

def extend_grid(grid_idx):
    fname = f"tools/grid_{grid_idx}.json"
    if not os.path.exists(fname): return
    with open(fname) as f:
        grid = json.load(f)
    
    rooms = grid["rooms"]
    
    actors = {}
    for fpath in glob.glob("data/extracted/*/room-*-actors.json"):
        with open(fpath) as f:
            data = json.load(f)
            actors[data["room_id"]] = data
            
    interior_rooms = set()
    for room_id_str in rooms.keys():
        r_id = int(room_id_str)
        if r_id in actors:
            for door in actors[r_id].get("doors", []):
                dest = door.get("destination_room_id")
                if dest is not None and str(dest) not in rooms:
                    interior_rooms.add(dest)
                    
    # Only extend if there are interior rooms
    if not interior_rooms:
        # Just copy to extended
        with open(f"tools/grid_{grid_idx}_extended.json", "w") as f:
            json.dump(grid, f)
        return
        
    current_xs = [c["x"] for c in rooms.values()]
    current_ys = [c["y"] for c in rooms.values()]
    
    min_x, max_x = min(current_xs), max(current_xs)
    min_y, max_y = min(current_ys), max(current_ys)
    
    place_x = max_x + 2
    place_y = max_y
    
    for int_room in sorted(interior_rooms):
        rooms[str(int_room)] = {"x": place_x, "y": place_y}
        place_y -= 1
        if place_y < min_y:
            place_y = max_y
            place_x += 1
            
    all_xs = [c["x"] for c in rooms.values()]
    all_ys = [c["y"] for c in rooms.values()]
    min_x, max_x = min(all_xs), max(all_xs)
    min_y, max_y = min(all_ys), max(all_ys)
    width = max_x - min_x + 1
    height = max_y - min_y + 1
    
    for r_id in rooms:
        rooms[r_id]["x"] -= min_x
        rooms[r_id]["y"] -= min_y
        
    grid["width"] = width
    grid["height"] = height
    grid["rooms"] = rooms
    
    with open(f"tools/grid_{grid_idx}_extended.json", "w") as f:
        json.dump(grid, f)

for i in range(10):
    extend_grid(i)

