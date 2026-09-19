import json
import random
import os
import math
from collections import deque
from PIL import Image, ImageDraw

TILE_SIZE = 32

VILLAGE_REALM_NAMES = [
    ("THE DESOLATE COBBLESTONE HAMLET", "Empty timber cottages and shattered cobblestone markets where the restless undead roam."),
    ("THE ABANDONED GOTHIC SETTLEMENT", "Fog-drenched timber houses, collapsed churchyards, and silent town squares frozen in eternal silence."),
    ("THE PLAGUE-STRICKEN CITADEL OUTSKIRTS", "Quarantined timber gates, abandoned wells, and broken barricades crumbling under dark corruption."),
    ("THE SHADOWED BOROUGH OF THE LOST", "Narrow winding alleys between decaying thatched-roof cottages and silent belltowers."),
    ("THE RUINED TIMBER MILL DISTRICT", "Shattered watermills, broken grain carts, and desolate cobblestone roads by the river.")
]

# TILE CONSTANTS (32x32) FOR VILLAGE:
T_VOID = 0                  # Pitch Black Village Outskirts Void
T_FLOOR_COBBLE = 1          # Cobblestone Street Floor (0, 0, 32, 32)
T_FLOOR_DIRT = 2            # Dirt Alley Floor (64, 64, 32, 32)
T_FLOOR_TIMBER = 3          # Wooden Plank Interior Floor (128, 0, 32, 32)
T_FLOOR_PAVER = 4           # High Stone Paver Plaza (64, 0, 32, 32)
T_PATH_AVENUE = 5           # Main Cobblestone Merchant Avenue (96, 0, 32, 32)
T_TOWN_SQUARE = 6           # Town Square Runic Well / Plaza (160, 64, 32, 32)
T_CELLAR_CHASM = 7          # Flooded Cellar / Collapsed Chasm (128, 96, 32, 32)
T_WALL_COTTAGE = 10         # Ruined Timber Cottage Wall Border (Impassable)

# PROPS FOR VILLAGE:
T_TIMBER_COTTAGE_1 = 30     # Rect2(64, 197, 65, 59) Nhà gỗ điêu tàn 1
T_TIMBER_COTTAGE_2 = 31     # Rect2(0, 261, 65, 59) Nhà gỗ đổ nát 2
T_MANOR_HOUSE = 32          # Rect2(131, 195, 60, 62) Nhà gỗ lớn trang viên
T_WOODEN_FENCE_H = 33       # Rect2(304, 223, 32, 49) Hàng rào gỗ ngang
T_WOODEN_FENCE_V = 34       # Rect2(256, 224, 32, 48) Hàng rào gỗ dọc
T_BROKEN_WAGON = 35         # Rect2(274, 120, 56, 39) Xe kéo gỗ vỡ nát
T_STONE_WELL = 36           # Rect2(160, 280, 64, 40) Giếng đá cổ trung tâm
T_KEGS_CRATES = 37          # Rect2(433, 120, 47, 41) Thùng rượu & kiện hàng
T_VILLAGE_SHRINE = 38       # Rect2(10, 131, 42, 58) Đài tế lễ / Tháp chuông nhỏ
T_STONE_STEPS = 41          # Rect2(337, 176, 31, 32) Bậc thềm đá

def generate_strongly_connected_village(gw=200, gh=200, map_id=1):
    grid = [[T_VOID for _ in range(gw)] for _ in range(gh)]
    elevation = [[0 for _ in range(gw)] for _ in range(gh)]
    
    cx = gw // 2
    cy = gh // 2
    
    rooms = []
    mob_spawners = []
    
    # 1. Guaranteed Safe Town Center Sanctuary (Fountain Plaza)
    c_rad = 14
    for dy in range(-c_rad, c_rad + 1):
        for dx in range(-c_rad, c_rad + 1):
            dist = math.hypot(dx, dy)
            ang = math.atan2(dy, dx)
            r_limit = c_rad + math.sin(ang * 4) * 1.2
            if dist <= r_limit:
                grid[cy + dy][cx + dx] = T_FLOOR_COBBLE
                elevation[cy + dy][cx + dx] = 2

    # Inner circular promenade
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            if dx*dx + dy*dy <= 16:
                grid[cy + dy][cx + dx] = T_PATH_AVENUE

    grid[cy][cx] = T_TOWN_SQUARE
    rooms.append({"id": "town_hub", "name": "Town Central Square", "elem": "neutral", "x": cx, "y": cy, "tier": 2})

    # 2. GENERATE 55-65 ORGANIC ASYMMETRICAL VILLAGE DISTRICTS & COTTAGES
    num_districts = random.randint(55, 65)
    ELEMENTS = ["ice", "dark", "lightning", "void", "neutral"]
    TIER_FLOORS = {1: T_FLOOR_DIRT, 2: T_FLOOR_COBBLE, 3: T_FLOOR_TIMBER, 4: T_FLOOR_PAVER}
    
    placed_positions = [(cx, cy)]
    
    for r_i in range(num_districts):
        for attempt in range(40):
            rx = random.randint(18, gw - 19)
            ry = random.randint(18, gh - 19)
            
            min_d = min(math.hypot(rx - px, ry - py) for px, py in placed_positions)
            if 14 <= min_d <= 45:
                placed_positions.append((rx, ry))
                relem = random.choice(ELEMENTS)
                tier_lvl = random.choice([1, 1, 2, 2, 3, 3, 4])
                rfloor = TIER_FLOORS[tier_lvl]
                
                rw = random.randint(10, 20)
                rh = random.randint(10, 20)
                base_rad = max(rw, rh) // 2
                
                num_sub_nodes = random.randint(2, 4)
                sub_nodes = [(rx, ry, base_rad)]
                for _ in range(num_sub_nodes):
                    sox = rx + random.randint(-base_rad//2, base_rad//2)
                    soy = ry + random.randint(-base_rad//2, base_rad//2)
                    srad = random.randint(int(base_rad * 0.5), int(base_rad * 0.85))
                    sub_nodes.append((sox, soy, srad))
                    
                for snx, sny, snr in sub_nodes:
                    for dy in range(-snr, snr + 1):
                        for dx in range(-snr, snr + 1):
                            dist = math.hypot(dx, dy)
                            ang = math.atan2(dy, dx)
                            perturb = math.sin(ang * 4) * 1.3
                            if dist <= snr + perturb:
                                gx, gy = snx + dx, sny + dy
                                if 6 <= gx < gw - 6 and 6 <= gy < gh - 6:
                                    grid[gy][gx] = rfloor
                                    elevation[gy][gx] = tier_lvl
                                    
                r_obj = {
                    "id": f"district_{r_i}",
                    "name": f"Hamlet Quarter {r_i}",
                    "elem": relem,
                    "x": rx, "y": ry,
                    "tier": tier_lvl,
                    "floor": rfloor
                }
                rooms.append(r_obj)

                # Village Decor Props
                feat = random.choice(["cottage1", "cottage2", "manor", "fence_h", "fence_v", "wagon", "well", "kegs", "shrine"])
                if feat == "cottage1":
                    grid[ry][rx] = T_TIMBER_COTTAGE_1
                elif feat == "cottage2":
                    grid[ry][rx] = T_TIMBER_COTTAGE_2
                elif feat == "manor":
                    grid[ry][rx] = T_MANOR_HOUSE
                elif feat == "fence_h":
                    grid[ry][rx] = T_WOODEN_FENCE_H
                elif feat == "fence_v":
                    grid[ry][rx] = T_WOODEN_FENCE_V
                elif feat == "wagon":
                    grid[ry][rx] = T_BROKEN_WAGON
                elif feat == "well":
                    grid[ry][rx] = T_STONE_WELL
                elif feat == "kegs":
                    grid[ry][rx] = T_KEGS_CRATES
                elif feat == "shrine":
                    grid[ry][rx] = T_VILLAGE_SHRINE
                    
                mtype = "swarm" if relem == "dark" else ("tank" if relem == "lightning" else ("sniper" if relem == "ice" else "bomber"))
                mob_spawners.append({"type": mtype, "x": (rx - gw//2)*64, "y": (ry - gh//2)*64, "tier": tier_lvl})
                break

    # 3. HIGHLY CONNECTED COBBLESTONE HIGHWAYS & ALLEYWAYS
    def carve_village_road(p1, p2, width=2):
        cur_x, cur_y = p1[0], p1[1]
        target_x, target_y = p2[0], p2[1]
        steps = 0
        
        while (cur_x != target_x or cur_y != target_y) and steps < 600:
            steps += 1
            if random.random() < 0.65:
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
                            grid[gy][gx] = T_FLOOR_COBBLE
                            elevation[gy][gx] = 2
                        grid[gy][gx] = T_PATH_AVENUE

    # Connect central square to 6 closest districts
    dists_hub = sorted(rooms[1:], key=lambda r: math.hypot(cx - r['x'], cy - r['y']))
    for hr in dists_hub[:6]:
        carve_village_road((cx, cy), (hr['x'], hr['y']), 2)

    # Interconnect all districts with 2-3 closest neighbors
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
            carve_village_road((p1['x'], p1['y']), (neighbor['x'], neighbor['y']), 2)

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
            carve_village_road((cx, cy), (r['x'], r['y']), 3)

    # 5. RANDOM DEAD-END ALLEY SPURS
    for _ in range(30):
        start_r = random.choice(rooms)
        sx, sy = start_r['x'], start_r['y']
        end_x = max(8, min(gw - 9, sx + random.randint(-20, 20)))
        end_y = max(8, min(gh - 9, sy + random.randint(-20, 20)))
        carve_village_road((sx, sy), (end_x, end_y), 2)
        grid[end_y][end_x] = random.choice([T_BROKEN_WAGON, T_KEGS_CRATES, T_WOODEN_FENCE_H, T_STONE_WELL])

    # 6. STONE STEPS TRANSITIONS
    stairs_candidates = []
    for y in range(8, gh - 8):
        for x in range(8, gw - 8):
            if grid[y][x] == T_PATH_AVENUE:
                cur_t = elevation[y][x]
                for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
                    ny, nx = y + dy, x + dx
                    adj_t = elevation[ny][nx]
                    if adj_t > 0 and cur_t > 0 and cur_t != adj_t:
                        stairs_candidates.append((x, y))
                        break

    if len(stairs_candidates) >= 9:
        for sx, sy in random.sample(stairs_candidates, 9):
            grid[sy][sx] = T_STONE_STEPS

    # 7. SOLID RUINED COTTAGE TIMBER WALL BORDER
    wall_grid = [[0 for _ in range(gw)] for _ in range(gh)]
    for y in range(gh):
        for x in range(gw):
            if grid[y][x] != T_VOID:
                for dy in [-1, 0, 1]:
                    for dx in [-1, 0, 1]:
                        ny_pos, nx_pos = y + dy, x + dx
                        if 0 <= ny_pos < gh and 0 <= nx_pos < gw:
                            if grid[ny_pos][nx_pos] == T_VOID:
                                wall_grid[ny_pos][nx_pos] = T_WALL_COTTAGE

    for y in range(gh):
        for x in range(gw):
            if grid[y][x] == T_VOID and wall_grid[y][x] == T_WALL_COTTAGE:
                grid[y][x] = T_WALL_COTTAGE

    # 8. COLLAPSED CELLAR CHASM PITS (NEVER NEAR SPAWN)
    chasms = []
    for _ in range(12):
        rand_r = random.choice(rooms[1:])
        hx = rand_r['x'] + random.randint(-4, 4)
        hy = rand_r['y'] + random.randint(-4, 4)
        if math.hypot(hx - cx, hy - cy) < 15:
            continue
        if 8 <= hx < gw - 8 and 8 <= hy < gh - 8 and grid[hy][hx] not in [T_VOID, T_WALL_COTTAGE]:
            grid[hy][hx] = T_CELLAR_CHASM
            chasms.append({"x": (hx - gw//2)*64, "y": (hy - gh//2)*64, "radius": 45, "has_bridge": True})

    # 9. 4 CARDINAL RUNE SHRINES IN 4 FAR QUADRANTS (>3500px apart)
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
    cottages = []
    manors = []
    fences = []
    wagons = []
    wells = []
    kegs = []
    shrines = []
    stairs = []

    for y in range(gh):
        for x in range(gw):
            val = grid[y][x]
            world_pos = {"x": (x - gw//2) * 64, "y": (y - gh//2) * 64}
            if val == T_TIMBER_COTTAGE_1 or val == T_TIMBER_COTTAGE_2: cottages.append(world_pos)
            elif val == T_MANOR_HOUSE: manors.append(world_pos)
            elif val == T_WOODEN_FENCE_H or val == T_WOODEN_FENCE_V: fences.append(world_pos)
            elif val == T_BROKEN_WAGON: wagons.append(world_pos)
            elif val == T_STONE_WELL: wells.append(world_pos)
            elif val == T_KEGS_CRATES: kegs.append(world_pos)
            elif val == T_VILLAGE_SHRINE: shrines.append(world_pos)
            elif val == T_STONE_STEPS: stairs.append(world_pos)

    name_idx = (map_id - 1) % len(VILLAGE_REALM_NAMES)
    d_name, d_lore = VILLAGE_REALM_NAMES[name_idx]
    if map_id > len(VILLAGE_REALM_NAMES):
        d_name += f" - LAYER {(map_id // len(VILLAGE_REALM_NAMES)) + 1}"

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
        "cottages": cottages,
        "manors": manors,
        "fences": fences,
        "wagons": wagons,
        "wells": wells,
        "kegs": kegs,
        "shrines": shrines,
        "stairs": stairs
    }

def main():
    all_maps = []
    print("Generating 40 Strongly Connected Village Maps with Separated Shrines...")
    for i in range(1, 41):
        m = generate_strongly_connected_village(200, 200, i)
        all_maps.append(m)
        print(f"  [{i}/40] Generated {m['name']}")

    vault_path = "data/maps/village_dungeon_vault.json"
    os.makedirs("data/maps", exist_ok=True)
    with open(vault_path, "w", encoding="utf-8") as f:
        json.dump({"total_maps": len(all_maps), "maps": all_maps}, f, indent=2, ensure_ascii=False)
    print(f"\nSaved 40 Village Maps to {vault_path}!")

if __name__ == "__main__":
    main()
