import json
import random
import os
import math
from collections import deque
from PIL import Image, ImageDraw

TILE_SIZE = 32

FOREST_REALM_NAMES = [
    ("THE PRIMORDIAL CANOPY OF AGES", "Vast tangled roots of yggdrasil saplings weave through misty glades and treacherous sylvan bogs."),
    ("THE TWILIGHT SYLVAN THICKET", "Enchanted fairy rings and towering elder oaks guard forgotten elven monoliths deep within the enchanted wilderness."),
    ("THE WHISPERING SHADOWWOOD", "Dark ancient trees murmur forbidden incantations as creeping roots ensnare unwary travelers."),
    ("THE EMERALD BRAMBLE WILDERNESS", "Deep impenetrable thorn hedges and ancient sylvan clearings hidden beneath an eternal leafy canopy."),
    ("THE FORGOTTEN SACRED GROVE", "Ancient moss-covered druidic stones and glowing spirit flora nestled inside an untamed primeval forest.")
]

# TILE CONSTANTS (32x32) FOR FOREST:
T_VOID = 0                  # Pitch Black Forest Void / Out of bounds
T_FLOOR_MOSS = 1            # Mossy Grass Glade Floor (320, 0, 32, 32)
T_FLOOR_DIRT = 2            # Dark Humus Earth Floor (0, 0, 32, 32)
T_FLOOR_PEAT = 3            # Deep Peat / Dark Foliage Floor (64, 0, 32, 32)
T_FLOOR_ROOTS = 4           # Root Knarl Dais Floor (128, 0, 32, 32)
T_PATH_TRAIL = 5            # Winding Forest Dirt Trail (96, 0, 32, 32)
T_FAIRY_RING = 6            # Mystic Floral Fairy Ring Center (352, 0, 32, 32)
T_SWAMP_POND = 7            # Murky Swamp Pond Chasm (128, 96, 32, 32)
T_WALL_THICKET = 10         # Impassable Ancient Canopy / Thick Trunk Border

# PROPS FOR FOREST:
T_GIANT_CANOPY_TREE = 30    # Rect2(196, 130, 126, 94) Cây đại thụ rậm rạp
T_MOSS_MONOLITH = 31        # Rect2(65, 256, 63, 63) Cự thạch phủ rêu
T_ANCIENT_STUMP = 32        # Rect2(194, 256, 87, 64) Gốc cây khổng lồ rỗng ruột
T_STONE_TOTEM = 33          # Rect2(2, 257, 61, 60) Cột đá cổ đại
T_FERN_BUSH = 34            # Rect2(129, 257, 62, 62) Bụi dương xỉ cổ thụ
T_MOSSY_ROCKS = 35          # Rect2(291, 267, 60, 51) Tảng đá rêu
T_ELDER_WILLOW = 36         # Rect2(321, 130, 117, 92) Cây liễu bóng tối
T_FAIRY_MUSHROOMS = 37      # Rect2(1, 197, 45, 41) Nấm dạ quang phát sáng
T_GLOWING_SPORE = 38        # Rect2(128, 224, 31, 31) Bào tử phát quang / Vũng đầm lầy nhỏ
T_ROOT_STAIRS = 41          # Rect2(417, 182, 31, 41) Rễ cây bậc thang

def generate_strongly_connected_forest(gw=200, gh=200, map_id=1):
    grid = [[T_VOID for _ in range(gw)] for _ in range(gh)]
    elevation = [[0 for _ in range(gw)] for _ in range(gh)]
    
    cx = gw // 2
    cy = gh // 2
    
    rooms = []
    mob_spawners = []
    
    # 1. Guaranteed Centered Spawn Nexus (Safe Fairy Grove Sanctuary)
    c_rad = 14
    for dy in range(-c_rad, c_rad + 1):
        for dx in range(-c_rad, c_rad + 1):
            dist = math.hypot(dx, dy)
            ang = math.atan2(dy, dx)
            r_limit = c_rad + math.sin(ang * 4 + 1.2) * 1.5
            if dist <= r_limit:
                grid[cy + dy][cx + dx] = T_FLOOR_MOSS
                elevation[cy + dy][cx + dx] = 2

    # Inner floral fairy circle
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            if dx*dx + dy*dy <= 16:
                grid[cy + dy][cx + dx] = T_PATH_TRAIL

    grid[cy][cx] = T_FAIRY_RING
    rooms.append({"id": "grove_hub", "name": "Sacred Spring Grove", "elem": "neutral", "x": cx, "y": cy, "tier": 2})

    # 2. GENERATE 55-65 ORGANIC ASYMMETRICAL FOREST GLADES
    num_glades = random.randint(55, 65)
    ELEMENTS = ["ice", "dark", "lightning", "void", "neutral"]
    TIER_FLOORS = {1: T_FLOOR_DIRT, 2: T_FLOOR_MOSS, 3: T_FLOOR_PEAT, 4: T_FLOOR_ROOTS}
    
    placed_positions = [(cx, cy)]
    
    for r_i in range(num_glades):
        for attempt in range(40):
            rx = random.randint(18, gw - 19)
            ry = random.randint(18, gh - 19)
            
            min_d = min(math.hypot(rx - px, ry - py) for px, py in placed_positions)
            if 14 <= min_d <= 45:
                placed_positions.append((rx, ry))
                relem = random.choice(ELEMENTS)
                tier_lvl = random.choice([1, 1, 2, 2, 3, 3, 4])
                rfloor = TIER_FLOORS[tier_lvl]
                
                rw = random.randint(10, 22)
                rh = random.randint(10, 22)
                base_rad = max(rw, rh) // 2
                
                num_sub_nodes = random.randint(2, 5)
                sub_nodes = [(rx, ry, base_rad)]
                for _ in range(num_sub_nodes):
                    sox = rx + random.randint(-base_rad//2, base_rad//2)
                    soy = ry + random.randint(-base_rad//2, base_rad//2)
                    srad = random.randint(int(base_rad * 0.5), int(base_rad * 0.9))
                    sub_nodes.append((sox, soy, srad))
                    
                for snx, sny, snr in sub_nodes:
                    for dy in range(-snr, snr + 1):
                        for dx in range(-snr, snr + 1):
                            dist = math.hypot(dx, dy)
                            ang = math.atan2(dy, dx)
                            perturb = math.sin(ang * 4) * 1.5 + math.cos(ang * 2) * 1.2
                            if dist <= snr + perturb:
                                gx, gy = snx + dx, sny + dy
                                if 6 <= gx < gw - 6 and 6 <= gy < gh - 6:
                                    grid[gy][gx] = rfloor
                                    elevation[gy][gx] = tier_lvl
                                    
                r_obj = {
                    "id": f"glade_{r_i}",
                    "name": f"Ancient Glade {r_i}",
                    "elem": relem,
                    "x": rx, "y": ry,
                    "tier": tier_lvl,
                    "floor": rfloor
                }
                rooms.append(r_obj)

                # Forest Decor Props
                feat = random.choice(["tree", "monolith", "stump", "totem", "fern", "rocks", "willow", "mushrooms"])
                if feat == "tree":
                    grid[ry][rx] = T_GIANT_CANOPY_TREE
                elif feat == "monolith":
                    grid[ry][rx] = T_MOSS_MONOLITH
                elif feat == "stump":
                    grid[ry][rx] = T_ANCIENT_STUMP
                elif feat == "totem":
                    grid[ry][rx] = T_STONE_TOTEM
                elif feat == "fern":
                    grid[ry][rx] = T_FERN_BUSH
                elif feat == "rocks":
                    grid[ry][rx] = T_MOSSY_ROCKS
                elif feat == "willow":
                    grid[ry][rx] = T_ELDER_WILLOW
                elif feat == "mushrooms":
                    grid[ry][rx] = T_FAIRY_MUSHROOMS
                    
                mtype = "swarm" if relem == "dark" else ("tank" if relem == "lightning" else ("sniper" if relem == "ice" else "bomber"))
                mob_spawners.append({"type": mtype, "x": (rx - gw//2)*64, "y": (ry - gh//2)*64, "tier": tier_lvl})
                break

    # 3. HIGHLY ORGANIC WINDING GAME TRAILS
    def carve_forest_trail(p1, p2, width=2):
        cur_x, cur_y = p1[0], p1[1]
        target_x, target_y = p2[0], p2[1]
        steps = 0
        
        while (cur_x != target_x or cur_y != target_y) and steps < 600:
            steps += 1
            if random.random() < 0.60:
                if abs(target_x - cur_x) > abs(target_y - cur_y):
                    cur_x += 1 if target_x > cur_x else -1
                else:
                    cur_y += 1 if target_y > cur_y else -1
            else:
                if random.random() < 0.5: cur_x += random.choice([-1, 1])
                else: cur_y += random.choice([-1, 1])
                    
            cur_x = max(6, min(gw - 7, cur_x))
            cur_y = max(6, min(gh - 7, cur_y))
            
            for dy in range(-width//2, width//2 + 1):
                for dx in range(-width//2, width//2 + 1):
                    gy, gx = cur_y + dy, cur_x + dx
                    if 0 <= gy < gh and 0 <= gx < gw:
                        if grid[gy][gx] == T_VOID:
                            grid[gy][gx] = T_FLOOR_MOSS
                            elevation[gy][gx] = 2
                        grid[gy][gx] = T_PATH_TRAIL

    # Connect central grove to 6 closest glades
    dists_hub = sorted(rooms[1:], key=lambda r: math.hypot(cx - r['x'], cy - r['y']))
    for hr in dists_hub[:6]:
        carve_forest_trail((cx, cy), (hr['x'], hr['y']), 2)

    # Interconnect all glades with 2-3 closest neighbors
    for i in range(len(rooms)):
        p1 = rooms[i]
        dists = []
        for j in range(len(rooms)):
            if i != j:
                p2 = rooms[j]
                d = math.hypot(p1['x'] - p2['x'], p1['y'] - p2['y'])
                dists.append((d, p2))
        dists.sort(key=lambda x: x[0])
        for _, neighbor in dists[:random.choice([2, 3])]:
            carve_forest_trail((p1['x'], p1['y']), (neighbor['x'], neighbor['y']), 2)

    # 4. STRONG CONNECTIVITY GUARANTEE (BFS Flood Fill)
    visited = [[False for _ in range(gw)] for _ in range(gh)]
    q = deque([(cx, cy)])
    visited[cy][cx] = True
    
    while q:
        qx, qy = q.popleft()
        for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
            nx, ny = qx + dx, qy + dy
            if 0 <= ny < gh and 0 <= nx < gw:
                if not visited[ny][nx] and grid[ny][nx] != T_VOID:
                    visited[ny][nx] = True
                    q.append((nx, ny))

    for r in rooms:
        if not visited[r['y']][r['x']]:
            carve_forest_trail((cx, cy), (r['x'], r['y']), 3)

    # 5. RANDOM DEAD-END TRAIL SPURS
    for _ in range(30):
        start_r = random.choice(rooms)
        sx, sy = start_r['x'], start_r['y']
        end_x = max(8, min(gw - 9, sx + random.randint(-20, 20)))
        end_y = max(8, min(gh - 9, sy + random.randint(-20, 20)))
        carve_forest_trail((sx, sy), (end_x, end_y), 2)
        grid[end_y][end_x] = random.choice([T_FAIRY_MUSHROOMS, T_GLOWING_SPORE, T_FERN_BUSH, T_MOSSY_ROCKS])

    # 6. ROOT STAIRS TRANSITIONS
    stairs_candidates = []
    for y in range(8, gh - 8):
        for x in range(8, gw - 8):
            if grid[y][x] == T_PATH_TRAIL:
                cur_t = elevation[y][x]
                for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
                    ny, nx = y + dy, x + dx
                    adj_t = elevation[ny][nx]
                    if adj_t > 0 and cur_t > 0 and cur_t != adj_t:
                        stairs_candidates.append((x, y))
                        break

    if len(stairs_candidates) >= 9:
        for sx, sy in random.sample(stairs_candidates, 9):
            grid[sy][sx] = T_ROOT_STAIRS

    # 7. SOLID DENSE ANCIENT TREE TRUNK WALL BORDER
    wall_grid = [[0 for _ in range(gw)] for _ in range(gh)]
    for y in range(gh):
        for x in range(gw):
            if grid[y][x] != T_VOID:
                for dy in [-1, 0, 1]:
                    for dx in [-1, 0, 1]:
                        ny_pos, nx_pos = y + dy, x + dx
                        if 0 <= ny_pos < gh and 0 <= nx_pos < gw:
                            if grid[ny_pos][nx_pos] == T_VOID:
                                wall_grid[ny_pos][nx_pos] = T_WALL_THICKET

    for y in range(gh):
        for x in range(gw):
            if grid[y][x] == T_VOID and wall_grid[y][x] == T_WALL_THICKET:
                grid[y][x] = T_WALL_THICKET

    # 8. SWAMP PONDS / BAYOU WATER PITS (NEVER NEAR SPAWN)
    chasms = []
    for _ in range(12):
        rand_r = random.choice(rooms[1:])
        hx = rand_r['x'] + random.randint(-4, 4)
        hy = rand_r['y'] + random.randint(-4, 4)
        if math.hypot(hx - cx, hy - cy) < 15:
            continue
        if 8 <= hx < gw - 8 and 8 <= hy < gh - 8 and grid[hy][hx] not in [T_VOID, T_WALL_THICKET]:
            grid[hy][hx] = T_SWAMP_POND
            chasms.append({"x": (hx - gw//2)*64, "y": (hy - gh//2)*64, "radius": 45, "has_bridge": True})

    # 9. 4 CARDINAL NATURE RUNE FOUNTAINS IN 4 FAR QUADRANTS (>3500px apart)
    q_NW = [r for r in rooms[1:] if r['x'] < cx and r['y'] < cy]
    q_NE = [r for r in rooms[1:] if r['x'] >= cx and r['y'] < cy]
    q_SW = [r for r in rooms[1:] if r['x'] < cx and r['y'] >= cy]
    q_SE = [r for r in rooms[1:] if r['x'] >= cx and r['y'] >= cy]

    def get_farthest_room(room_list, default_fallback):
        if room_list:
            return max(room_list, key=lambda r: math.hypot(cx - r['x'], cy - r['y']))
        return default_fallback

    shrine_NW = get_farthest_room(q_NW, rooms[1])
    shrine_NE = get_farthest_room(q_NE, rooms[2])
    shrine_SW = get_farthest_room(q_SW, rooms[3])
    shrine_SE = get_farthest_room(q_SE, rooms[4])

    cardinal_shrines = [
        {"elem": "ice", "x": (shrine_NW['x'] - gw//2) * 64, "y": (shrine_NW['y'] - gh//2) * 64},
        {"elem": "dark", "x": (shrine_SW['x'] - gw//2) * 64, "y": (shrine_SW['y'] - gh//2) * 64},
        {"elem": "lightning", "x": (shrine_NE['x'] - gw//2) * 64, "y": (shrine_NE['y'] - gh//2) * 64},
        {"elem": "void", "x": (shrine_SE['x'] - gw//2) * 64, "y": (shrine_SE['y'] - gh//2) * 64}
    ]

    # Props extraction
    trees = []
    monoliths = []
    stumps = []
    totems = []
    ferns = []
    mossy_rocks = []
    willows = []
    mushrooms = []
    glowing_spores = []
    stairs = []

    for y in range(gh):
        for x in range(gw):
            val = grid[y][x]
            world_pos = {"x": (x - gw//2) * 64, "y": (y - gh//2) * 64}
            if val == T_GIANT_CANOPY_TREE: trees.append(world_pos)
            elif val == T_MOSS_MONOLITH: monoliths.append(world_pos)
            elif val == T_ANCIENT_STUMP: stumps.append(world_pos)
            elif val == T_STONE_TOTEM: totems.append(world_pos)
            elif val == T_FERN_BUSH: ferns.append(world_pos)
            elif val == T_MOSSY_ROCKS: mossy_rocks.append(world_pos)
            elif val == T_ELDER_WILLOW: willows.append(world_pos)
            elif val == T_FAIRY_MUSHROOMS: mushrooms.append(world_pos)
            elif val == T_GLOWING_SPORE: glowing_spores.append(world_pos)
            elif val == T_ROOT_STAIRS: stairs.append(world_pos)

    name_idx = (map_id - 1) % len(FOREST_REALM_NAMES)
    d_name, d_lore = FOREST_REALM_NAMES[name_idx]
    if map_id > len(FOREST_REALM_NAMES):
        d_name += f" - LAYER {(map_id // len(FOREST_REALM_NAMES)) + 1}"

    return {
        "map_id": map_id,
        "name": d_name,
        "lore": d_lore,
        "grid_width": gw,
        "grid_height": gh,
        "tile_size": 64,
        "grid": grid,
        "rooms": rooms,
        "cardinal_shrines": cardinal_shrines,
        "mob_spawners": mob_spawners,
        "chasms": chasms,
        "trees": trees,
        "monoliths": monoliths,
        "stumps": stumps,
        "totems": totems,
        "ferns": ferns,
        "mossy_rocks": mossy_rocks,
        "willows": willows,
        "mushrooms": mushrooms,
        "glowing_spores": glowing_spores,
        "stairs": stairs
    }

def main():
    all_maps = []
    print("Generating 40 Strongly Connected Forest Maps with Separated Shrines...")
    for i in range(1, 41):
        m = generate_strongly_connected_forest(200, 200, i)
        all_maps.append(m)
        print(f"  [{i}/40] Generated {m['name']}")

    vault_path = "data/maps/forest_dungeon_vault.json"
    os.makedirs("data/maps", exist_ok=True)
    with open(vault_path, "w", encoding="utf-8") as f:
        json.dump({"total_maps": len(all_maps), "maps": all_maps}, f, indent=2, ensure_ascii=False)
    print(f"\nSaved 40 Forest Maps to {vault_path}!")

if __name__ == "__main__":
    main()
