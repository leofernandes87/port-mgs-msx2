import json
import glob

def main():
    # Load grid 0
    with open("tools/grid_0.json") as f:
        grid = json.load(f)
    
    rooms = grid["rooms"]
    
    # Load all actors to find doors
    actors = {}
    for fpath in glob.glob("data/extracted/*/room-*-actors.json"):
        with open(fpath) as f:
            data = json.load(f)
            actors[data["room_id"]] = data
            
    # Find all connected interior rooms
    interior_rooms = set()
    for room_id_str in rooms.keys():
        r_id = int(room_id_str)
        if r_id in actors:
            for door in actors[r_id].get("doors", []):
                dest = door.get("destination_room_id")
                if dest is not None and str(dest) not in rooms:
                    # Exclude elevators or other buildings if we only want small rooms?
                    # The user wants SMG (137) and others. Let's include all.
                    interior_rooms.add(dest)
                    
    print(f"Found {len(interior_rooms)} interior rooms: {interior_rooms}")
    
    # We will place these interior rooms in new columns to the right of the grid
    # Grid 0 max X is currently 4 (width). Let's start placing at X=5.
    
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
            
    # Recalculate width/height
    all_xs = [c["x"] for c in rooms.values()]
    all_ys = [c["y"] for c in rooms.values()]
    
    min_x, max_x = min(all_xs), max(all_xs)
    min_y, max_y = min(all_ys), max(all_ys)
    
    width = max_x - min_x + 1
    height = max_y - min_y + 1
    
    # Normalize coordinates so min is 0
    for r_id in rooms:
        rooms[r_id]["x"] -= min_x
        rooms[r_id]["y"] -= min_y
        
    grid["width"] = width
    grid["height"] = height
    grid["rooms"] = rooms
    
    with open("tools/grid_0_extended.json", "w") as f:
        json.dump(grid, f)
        
    print(f"Extended grid 0 to {width}x{height}")

if __name__ == "__main__":
    main()
