import json
import random
import os
import math
from PIL import Image, ImageDraw, ImageFont

TILE_SIZE = 16
RENDER_TILE_SIZE = 24 # 128x128 * 24 = 3072x3072 px render!

MEGADUNGEON_NAMES = [
    ("THE LABYRINTH OF A THOUSAND SCREAMS", "A colossal non-linear ancient fortress buried beneath eldritch ruins. Twisting corridors and multi-layered crypts baffle all who enter."),
    ("THE OBSIDIAN SEPULCHER OF TIMELESS SHADOWS", "Carved into the living rock of an abyssal crater, where broken bridges span endless voids and secret chambers hold forbidden curses."),
    ("SANCTUM OF THE WRITHING ABYSS", "A winding subterranean necropolis of spiraling halls, sunken baptismal pools, and narrow deathtrap bottlenecks."),
    ("THE BASTION OF FORGOTTEN KINGS", "Multi-tiered battlements and crumbling halls where staircase terraces connect high ritual sanctuaries with flooded lower dungeons."),
    ("NEXUS OF PRIMORDIAL RUIN", "An ancient titan temple shattered by cosmic rifts, forming an intricate maze of cracked stone slabs, sudden chasms, and hidden vaults.")
]

# Grid Tile Constants
T_VOID = 0
T_FLOOR_PLAIN = 1
T_FLOOR_CRACKED = 2
T_FLOOR_MOSSY = 3
T_FLOOR_DARK = 4
T_FLOOR_RUNIC = 5
T_ELEVATED_FLOOR = 6
T_STAIRS = 7
T_WALL_TOP = 10
T_WALL_FRONT = 11
T_WALL_CORNER = 12
T_RUBBLE = 13
T_CHASM = 20
T_BRIDGE = 21
T_PILLAR = 30
T_SPIKE = 31
T_SPRING = 32
T_VENT = 33
T_ALTAR = 34
T_URN = 35
T_SHRINE_ICE = 40
T_SHRINE_DARK = 41
T_SHRINE_LIGHTNING = 42
T_SHRINE_VOID = 43

def generate_complex_megadungeon(gw=120, gh=120, map_id=1):
    grid = [[T_VOID for _ in range(gw)] for _ in range(gh)]
    elevation = [[0 for _ in range(gw)] for _ in range(gh)] # 0: normal, 1: elevated terrace, -1: sunken
    
    rooms = []
    
    # 1. Carve 20-30 Organic / Irregular / Polygon Rooms
    # A. Central Grand Colosseum (Irregular Octagon / Circle)
    cx, cy = gw // 2, gh // 2
    c_rad = 11
    for dy in range(-c_rad, c_rad + 1):
        for dx in range(-c_rad, c_rad + 1):
            if dx*dx + dy*dy <= c_rad * c_rad:
                grid[cy + dy][cx + dx] = T_FLOOR_RUNIC
    rooms.append({"id": "center_colosseum", "name": "Central Colosseum of Ruin", "x": cx, "y": cy, "r": c_rad, "elem": "neutral"})

    # B. Generate 18-24 Scattered Non-Linear Chambers across the map
    room_archetypes = [
        ("Spiral Sanctum", "ice", 14, 14, "spiral"),
        ("The Shattered Basilica", "dark", 18, 16, "pillared"),
        ("Sunken Crypt of Azgarth", "dark", 16, 14, "sunken"),
        ("High Terrace of Lightning", "lightning", 16, 16, "elevated"),
        ("Void Singularity Rift", "void", 18, 18, "chasm_center"),
        ("Torture Vault", "dark", 12, 12, "maze"),
        ("Forgotten Armory", "lightning", 14, 12, "standard"),
        ("Glacial Reliquary", "ice", 14, 14, "elevated"),
        ("Catacomb Maze", "dark", 16, 16, "maze"),
        ("Altar of Severed Souls", "void", 14, 14, "altar_room"),
        ("Titan Pillar Hall", "lightning", 20, 14, "pillared"),
        ("The Flooded Cistern", "ice", 16, 16, "sunken"),
        ("Astral Observatory", "void", 16, 14, "elevated"),
        ("Secret Gold Vault", "neutral", 10, 10, "secret"),
        ("The Bone Labyrinth", "dark", 16, 16, "maze"),
        ("Glacier Peak", "ice", 14, 14, "elevated")
    ]

    placed_rooms = []
    for r_idx, (rname, relem, rw, rh, rtype) in enumerate(room_archetypes):
        # Pick scattered organic positions (Avoid strict symmetry!)
        for attempt in range(25):
            angle = random.uniform(0, math.tau)
            dist = random.uniform(18, 46)
            rx = int(cx + math.cos(angle) * dist)
            ry = int(cy + math.sin(angle) * dist)
            
            # Keep within bounds
            if rx - rw//2 < 6 or rx + rw//2 >= gw - 6 or ry - rh//2 < 6 or ry + rh//2 >= gh - 6:
                continue
                
            # Check overlap with existing rooms (allow slight touches, but not full engulf)
            overlap = False
            for pr in placed_rooms:
                if abs(rx - pr['x']) < (rw + pr['w']) // 2 + 3 and abs(ry - pr['y']) < (rh + pr['h']) // 2 + 3:
                    overlap = True
                    break
            if not overlap:
                placed_rooms.append({"id": f"room_{r_idx}", "name": rname, "elem": relem, "x": rx, "y": ry, "w": rw, "h": rh, "type": rtype})
                
                # Carve room shape
                floor_tile = T_FLOOR_PLAIN
                if relem == "ice": floor_tile = T_FLOOR_CRACKED
                elif relem == "dark": floor_tile = T_FLOOR_DARK
                elif relem == "lightning": floor_tile = T_FLOOR_MOSSY
                elif relem == "void": floor_tile = T_FLOOR_RUNIC
                
                is_elev = (rtype == "elevated")
                is_sunk = (rtype == "sunken")
                
                for dy in range(-rh//2, rh//2 + 1):
                    for dx in range(-rw//2, rw//2 + 1):
                        gx, gy = rx + dx, ry + dy
                        if 0 <= gy < gh and 0 <= gx < gw:
                            # Irregular corners (rounded or notched)
                            if abs(dx) == rw//2 and abs(dy) == rh//2:
                                continue
                            grid[gy][gx] = floor_tile
                            if is_elev: elevation[gy][gx] = 1
                            elif is_sunk: elevation[gy][gx] = -1
                
                # Inner Room Features
                if rtype == "chasm_center":
                    # Deep abyss inside void room with central platform
                    for cdy in range(-3, 4):
                        for cdx in range(-3, 4):
                            if cdx*cdx + cdy*cdy <= 9 and (abs(cdx) > 1 or abs(cdy) > 1):
                                grid[ry + cdy][rx + cdx] = T_CHASM
                elif rtype == "spiral":
                    # Spiral stone partition wall inside
                    for s_step in range(-rw//3, rw//3):
                        grid[ry - rh//4][rx + s_step] = T_WALL_FRONT
                elif rtype == "pillared":
                    # 4 internal pillars
                    for pdy in [-rh//3, rh//3]:
                        for pdx in [-rw//3, rw//3]:
                            grid[ry + pdy][rx + pdx] = T_PILLAR
                break

    # 2. Carve Twisted, Winding, Maze-Like Corridors (Non-linear & unexpected!)
    def carve_winding_path(p1, p2, width_t=3):
        cur_x, cur_y = p1[0], p1[1]
        target_x, target_y = p2[0], p2[1]
        
        while cur_x != target_x or cur_y != target_y:
            # 70% move toward target, 30% zigzag / meander randomly
            if random.random() < 0.75:
                if abs(target_x - cur_x) > abs(target_y - cur_y):
                    cur_x += 1 if target_x > cur_x else -1
                else:
                    cur_y += 1 if target_y > cur_y else -1
            else:
                # Random meander step
                if random.random() < 0.5:
                    cur_x += random.choice([-1, 1])
                else:
                    cur_y += random.choice([-1, 1])
                    
            cur_x = max(6, min(gw - 7, cur_x))
            cur_y = max(6, min(gh - 7, cur_y))
            
            # Carve width
            for dy in range(-width_t//2, width_t//2 + 1):
                for dx in range(-width_t//2, width_t//2 + 1):
                    gy, gx = cur_y + dy, cur_x + dx
                    if 0 <= gy < gh and 0 <= gx < gw:
                        if grid[gy][gx] == T_VOID:
                            grid[gy][gx] = T_FLOOR_PLAIN

    # Connect Center to nearby 4 major rooms
    for pr in placed_rooms[:6]:
        carve_winding_path((cx, cy), (pr['x'], pr['y']), 3)

    # Interconnect all rooms into a complex web (Minimum Spanning Tree + Random Loops)
    for i in range(len(placed_rooms)):
        # Connect to 2 nearest neighbors
        p1 = placed_rooms[i]
        dists = []
        for j in range(len(placed_rooms)):
            if i != j:
                p2 = placed_rooms[j]
                d = math.hypot(p1['x'] - p2['x'], p1['y'] - p2['y'])
                dists.append((d, p2))
        dists.sort(key=lambda x: x[0])
        for _, neighbor in dists[:2]:
            carve_winding_path((p1['x'], p1['y']), (neighbor['x'], neighbor['y']), random.choice([2, 3]))

    # Add Random Dead-end Maze Tentacles (To confuse and baffle players!)
    for _ in range(25):
        start_r = random.choice(placed_rooms)
        sx, sy = start_r['x'], start_r['y']
        end_x = max(6, min(gw - 7, sx + random.randint(-18, 18)))
        end_y = max(6, min(gh - 7, sy + random.randint(-18, 18)))
        carve_winding_path((sx, sy), (end_x, end_y), 2)
        # Place trap or chest at dead-end tip
        if grid[end_y][end_x] != T_VOID:
            grid[end_y][end_x] = random.choice([T_SPIKE, T_SPRING, T_ALTAR, T_URN])

    # 3. Add Stairs between Elevated Terraces & Corridors
    for y in range(1, gh - 1):
        for x in range(1, gw - 1):
            if grid[y][x] != T_VOID and elevation[y][x] == 1:
                # Check if adjacent to level 0 floor
                for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    if grid[y+dy][x+dx] != T_VOID and elevation[y+dy][x+dx] == 0:
                        grid[y][x] = T_STAIRS
                        break

    # 4. Generate Autotiled Solid Ruin Brick Walls around all floors
    wall_grid = [[0 for _ in range(gw)] for _ in range(gh)]
    for y in range(gh):
        for x in range(gw):
            if grid[y][x] in [T_FLOOR_PLAIN, T_FLOOR_CRACKED, T_FLOOR_MOSSY, T_FLOOR_DARK, T_FLOOR_RUNIC, T_ELEVATED_FLOOR, T_STAIRS, T_CHASM, T_BRIDGE, T_SPIKE, T_SPRING, T_VENT, T_ALTAR, T_URN]:
                for dy in [-1, 0, 1]:
                    for dx in [-1, 0, 1]:
                        ny_pos, nx_pos = y + dy, x + dx
                        if 0 <= ny_pos < gh and 0 <= nx_pos < gw:
                            if grid[ny_pos][nx_pos] == T_VOID:
                                wall_grid[ny_pos][nx_pos] = T_WALL_TOP

    for y in range(gh):
        for x in range(gw):
            if grid[y][x] == T_VOID and wall_grid[y][x] == T_WALL_TOP:
                has_floor_below = (y + 1 < gh and grid[y + 1][x] not in [T_VOID, T_WALL_TOP, T_WALL_FRONT])
                if has_floor_below:
                    grid[y][x] = T_WALL_FRONT
                else:
                    grid[y][x] = T_WALL_TOP

    # 5. Place 4 Mythic Rune Shrines in 4 Elemental Sanctums
    for pr in placed_rooms:
        if pr['elem'] == 'ice' and not any(T_SHRINE_ICE in row for row in grid):
            grid[pr['y']][pr['x']] = T_SHRINE_ICE
        elif pr['elem'] == 'dark' and not any(T_SHRINE_DARK in row for row in grid):
            grid[pr['y']][pr['x']] = T_SHRINE_DARK
        elif pr['elem'] == 'lightning' and not any(T_SHRINE_LIGHTNING in row for row in grid):
            grid[pr['y']][pr['x']] = T_SHRINE_LIGHTNING
        elif pr['elem'] == 'void' and not any(T_SHRINE_VOID in row for row in grid):
            grid[pr['y']][pr['x']] = T_SHRINE_VOID

    # 6. Extract Traps & Points of Interest for GDScript
    chasms = []
    spike_traps = []
    spring_traps = []
    elemental_vents = []
    blood_altars = []
    pillars = []
    urns = []

    for y in range(gh):
        for x in range(gw):
            val = grid[y][x]
            world_pos = {"x": (x - gw//2) * 48, "y": (y - gh//2) * 48}
            if val == T_SPIKE: spike_traps.append({"x": world_pos["x"], "y": world_pos["y"], "interval": random.uniform(1.8, 3.2)})
            elif val == T_SPRING: spring_traps.append({"x": world_pos["x"], "y": world_pos["y"], "launch_force": 480})
            elif val == T_ALTAR: blood_altars.append(world_pos)
            elif val == T_PILLAR: pillars.append(world_pos)
            elif val == T_CHASM: chasms.append({"x": world_pos["x"], "y": world_pos["y"], "radius": 40, "has_bridge": False})

    name_idx = (map_id - 1) % len(MEGADUNGEON_NAMES)
    d_name, d_lore = MEGADUNGEON_NAMES[name_idx]
    if map_id > len(MEGADUNGEON_NAMES):
        d_name += f" - LEVEL {(map_id // len(MEGADUNGEON_NAMES)) + 1}"

    return {
        "map_id": map_id,
        "name": d_name,
        "lore": d_lore,
        "grid_width": gw,
        "grid_height": gh,
        "tile_size": 48,
        "grid": grid,
        "rooms": placed_rooms,
        "chasms": chasms,
        "spike_traps": spike_traps,
        "spring_traps": spring_traps,
        "elemental_vents": elemental_vents,
        "blood_altars": blood_altars,
        "pillars": pillars,
        "urns": urns
    }

def render_megadungeon_map_capture(dungeon, tileset_img, output_path):
    grid = dungeon["grid"]
    gw = dungeon["grid_width"]
    gh = dungeon["grid_height"]
    ts = RENDER_TILE_SIZE
    
    img = Image.new("RGBA", (gw * ts, gh * ts), (5, 6, 8, 255))
    
    TILE_COORDS = {
        'floor_plain': (16, 128, 16, 16),
        'floor_cracked': (0, 128, 16, 16),
        'floor_moss': (32, 128, 16, 16),
        'floor_dark': (48, 128, 16, 16),
        'floor_runic': (16, 144, 16, 16),
        'wall_top': (16, 0, 16, 16),
        'wall_front': (16, 16, 16, 16),
        'stairs': (192, 112, 16, 16),
        'pillar': (0, 80, 16, 112)
    }

    def get_tile(key):
        box = TILE_COORDS[key]
        t = tileset_img.crop((box[0], box[1], box[0]+box[2], box[1]+box[3]))
        return t.resize((ts, ts), Image.NEAREST)

    t_floor_plain = get_tile('floor_plain')
    t_floor_cracked = get_tile('floor_cracked')
    t_floor_moss = get_tile('floor_moss')
    t_floor_dark = get_tile('floor_dark')
    t_floor_runic = get_tile('floor_runic')
    t_wall_top = get_tile('wall_top')
    t_wall_front = get_tile('wall_front')
    t_stairs = get_tile('stairs')
    t_pillar = tileset_img.crop((0, 80, 16, 112)).resize((ts, ts * 2), Image.NEAREST)

    # 1. Render Base Tiles
    for y in range(gh):
        for x in range(gw):
            val = grid[y][x]
            pos = (x * ts, y * ts)
            
            if val == T_FLOOR_PLAIN: img.paste(t_floor_plain, pos)
            elif val == T_FLOOR_CRACKED: img.paste(t_floor_cracked, pos)
            elif val == T_FLOOR_MOSSY: img.paste(t_floor_moss, pos)
            elif val == T_FLOOR_DARK: img.paste(t_floor_dark, pos)
            elif val == T_FLOOR_RUNIC: img.paste(t_floor_runic, pos)
            elif val == T_STAIRS: img.paste(t_stairs, pos)
            elif val == T_WALL_TOP: img.paste(t_wall_top, pos)
            elif val == T_WALL_FRONT: img.paste(t_wall_front, pos)
            elif val == T_PILLAR:
                img.paste(t_floor_plain, pos)
                img.paste(t_pillar, (pos[0], pos[1] - ts), t_pillar)

    draw = ImageDraw.Draw(img)

    # 2. Draw Traps, Altars, and Shrines
    for y in range(gh):
        for x in range(gw):
            val = grid[y][x]
            p = (x * ts, y * ts)
            if val == T_SPIKE:
                draw.rectangle([p[0]+3, p[1]+3, p[0]+ts-3, p[1]+ts-3], fill=(160, 20, 20, 220), outline=(255, 60, 60, 255), width=2)
            elif val == T_SPRING:
                draw.rectangle([p[0]+3, p[1]+3, p[0]+ts-3, p[1]+ts-3], fill=(160, 130, 20, 220), outline=(255, 225, 50, 255), width=2)
            elif val == T_ALTAR:
                draw.rectangle([p[0]+2, p[1]+2, p[0]+ts-2, p[1]+ts-2], fill=(190, 20, 50, 240), outline=(255, 80, 120, 255), width=3)
            elif val == T_SHRINE_ICE:
                draw.ellipse([p[0]-6, p[1]-6, p[0]+ts+6, p[1]+ts+6], fill=(85, 195, 245, 255), outline=(255, 255, 255, 255), width=3)
            elif val == T_SHRINE_DARK:
                draw.ellipse([p[0]-6, p[1]-6, p[0]+ts+6, p[1]+ts+6], fill=(185, 75, 235, 255), outline=(255, 255, 255, 255), width=3)
            elif val == T_SHRINE_LIGHTNING:
                draw.ellipse([p[0]-6, p[1]-6, p[0]+ts+6, p[1]+ts+6], fill=(245, 215, 85, 255), outline=(255, 255, 255, 255), width=3)
            elif val == T_SHRINE_VOID:
                draw.ellipse([p[0]-6, p[1]-6, p[0]+ts+6, p[1]+ts+6], fill=(235, 85, 235, 255), outline=(255, 255, 255, 255), width=3)

    # 3. Header Title & Lore Banner
    draw.rectangle([40, 40, img.width - 40, 180], fill=(10, 12, 18, 245), outline=(215, 185, 110, 255), width=4)
    draw.text((60, 56), f"MEGADUNGEON RUIN: {dungeon['name']}", fill=(245, 215, 110, 255))
    draw.text((60, 96), f"LORE: {dungeon['lore']}", fill=(190, 195, 210, 255))
    draw.text((60, 136), f"STRUCTURE: {len(dungeon['rooms'])} Non-Linear Twisted Chambers | 120x120 Labyrinth Matrix | Multi-Layer Elevation", fill=(130, 210, 240, 255))

    # Bottom Legend
    draw.rectangle([40, img.height - 90, img.width - 40, img.height - 40], fill=(10, 12, 18, 245), outline=(130, 140, 165, 255), width=2)
    legend_text = "Brick Walls (Autotiled) | Winding Labyrinth Corridors | Elevated Terraces & Stairs | Sunken Pit Halls | Spikes | Springboards | 4 Elemental Shrines"
    draw.text((60, img.height - 70), legend_text, fill=(220, 225, 240, 255))

    img.save(output_path)
    # Save into artifact directory for embedding
    artifact_dir = r"C:\Users\Admin\.gemini\antigravity-ide\brain\139bf2d1-a9c2-46da-9225-301c22798bea"
    os.makedirs(artifact_dir, exist_ok=True)
    img.save(os.path.join(artifact_dir, "dungeon_map_preview.png"))
    print(f"Rendered authentic megadungeon map preview to {output_path}!")

def main():
    tileset_img = Image.open('Sprite/Environment/ruined_tileset.png')
    all_dungeons = []
    print("Generating 40 Non-Linear, Multi-Layered Megadungeon Maps...")
    
    for i in range(1, 41):
        d = generate_complex_megadungeon(120, 120, i)
        all_dungeons.append(d)
        print(f"  [{i}/40] Generated {d['name']} (120x120 Matrix, {len(d['rooms'])} Complex Rooms)")

    vault_path = "data/maps/ruin_dungeon_vault.json"
    with open(vault_path, "w", encoding="utf-8") as f:
        json.dump({"total_maps": len(all_dungeons), "maps": all_dungeons}, f, indent=2, ensure_ascii=False)
    print(f"\nSaved 40 Megadungeon Maps to {vault_path}!")

    # Render High-Res Preview of Map 1 (120x120 Grid @ 24px = 2880x2880 px!)
    render_megadungeon_map_capture(all_dungeons[0], tileset_img, "data/maps/dungeon_map_preview.png")

if __name__ == "__main__":
    main()
