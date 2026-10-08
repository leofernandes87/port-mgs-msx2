import re

with open("godot/scripts/systems/room_manager.gd", "r") as f:
    text = f.read()

# find the CONNECTIONS_TABLE array
table_str = re.search(r'const CONNECTIONS_TABLE[^\[]+\[(.*?)\];', text, re.DOTALL)
if not table_str:
    table_str = re.search(r'const CONNECTIONS_TABLE.*?=\s*\[(.*?)\]\s*$', text, re.DOTALL | re.MULTILINE)
    
if table_str:
    matches = re.findall(r'\[\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\]', table_str.group(1))
    rooms = []
    for m in matches:
        rooms.append([int(x) if x != '255' else None for x in m])
else:
    print("Could not find CONNECTIONS_TABLE")
    exit(1)

visited = set()
grids = []

for i in range(len(rooms)):
    if i in visited:
        continue
    if all(x is None for x in rooms[i]):
        continue
    
    grid = {}
    q = [(i, 0, 0)]
    while q:
        curr, x, y = q.pop(0)
        if curr in visited:
            continue
        visited.add(curr)
        grid[(x,y)] = curr
        
        u, d, l, r = rooms[curr]
        if u is not None and u not in visited:
            if u < len(rooms): q.append((u, x, y+1))
        if d is not None and d not in visited:
            if d < len(rooms): q.append((d, x, y-1))
        if l is not None and l not in visited:
            if l < len(rooms): q.append((l, x-1, y))
        if r is not None and r not in visited:
            if r < len(rooms): q.append((r, x+1, y))
            
    grids.append(grid)

for idx, g in enumerate(grids):
    print(f"Grid {idx} has {len(g)} rooms.")
    min_x = min(x for x, y in g.keys())
    max_x = max(x for x, y in g.keys())
    min_y = min(y for x, y in g.keys())
    max_y = max(y for x, y in g.keys())
    
    width = max_x - min_x + 1
    height = max_y - min_y + 1
    
    print(f"  Bounds: {width}x{height} (X: {min_x} to {max_x}, Y: {min_y} to {max_y})")
    print(f"  Rooms: {sorted(g.values())}")
    
    normalized_g = {}
    for (x,y), r in g.items():
        normalized_g[r] = {"x": x - min_x, "y": y - min_y}
        
    with open(f"tools/grid_{idx}.json", "w") as f:
        import json
        json.dump({"width": width, "height": height, "rooms": normalized_g}, f)

