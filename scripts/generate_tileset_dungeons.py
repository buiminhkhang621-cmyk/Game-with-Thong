import json
import random
import os
import math
from PIL import Image, ImageDraw

TILE_SIZE = 16 # Original tile pixels in tileset
RENDER_TILE_SIZE = 32 # Scaled pixel size in high-res render

DUNGEON_REALMS = [
    ("AZGARTH'S COLOSSEUM OF RUIN", "An ancient titan colosseum where fallen warriors were pitted against eldritch beasts."),
    ("THE SUBTERRANEAN NECROPOLIS OF THORNE", "Decaying catacombs etched with elder futhark runes and cursed royal tombs."),
    ("TEMPLE OF THE FRACTURED STARS", "A forgotten observatory where cosmic void rifts tore the marble sanctum apart."),
    ("CITADEL OF THE FROSTBITE QUEEN", "Glacial ice has crystallized the throne room and ancient archways in perpetual winter."),
    ("THE ABYSSAL BARRACKS OF MALICE", "Iron-gated dungeons where demonic shock troops once trained in pitch darkness."),
    ("LABYRINTH OF THE SHADOW WEAVER", "A twisting maze of jagged stone pillars and treacherous pit traps."),
    ("SANCTUM OF THE THUNDER GOD", "Tesla energy arcs constantly through ancient gilded monoliths."),
    ("THE FORGOTTEN SEPULCHER OF OBLIVION", "A massive underground complex swallowed by singularity anomalies."),
    ("VAULT OF THE CRIMSON BLOOD LORD", "Sacrificial blood channels carve through cracked obsidian flagstones."),
    ("THE SUNKEN BASTION OF AEONS", "Moss-covered ruined halls filled with unstable springboards and spike grates.")
]

# Tile mapping from ruined_tileset.png (x, y, w, h)
TILE_COORDS = {
    'floor_plain': (16, 128, 16, 16),
    'floor_cracked': (0, 128, 16, 16),
    'floor_moss': (32, 128, 16, 16),
    'floor_dark': (48, 128, 16, 16),
    'floor_runic': (16, 144, 16, 16),
    'wall_top': (16, 0, 16, 16),
    'wall_front': (16, 16, 16, 16),
    'wall_left': (0, 16, 16, 16),
    'wall_right': (32, 16, 16, 16),
    'wall_corner_tl': (0, 0, 16, 16),
    'wall_corner_tr': (32, 0, 16, 16),
    'wall_corner_bl': (0, 32, 16, 16),
    'wall_corner_br': (32, 32, 16, 16),
    'pillar': (0, 80, 16, 32),
    'chasm': (240, 112, 16, 16),
    'bridge': (192, 112, 16, 16)
}

def generate_dungeon_grid(width=90, height=90, map_id=1):
    grid = [[0 for _ in range(width)] for _ in range(height)]
    rooms = []
    
    # 1. Place Central Colosseum
    cw, ch = 20, 20
    cx, cy = (width - cw) // 2, (height - ch) // 2
    rooms.append({"id": "center", "name": "Central Colosseum", "x": cx, "y": cy, "w": cw, "h": ch, "elem": "neutral"})
    for y in range(cy, cy + ch):
        for x in range(cx, cx + cw):
            grid[y][x] = 1 # Floor

    # 2. Place 4 Elemental Wings
    wing_offset = 26
    # North: Frost
    nw, nh = random.randint(14, 18), random.randint(12, 16)
    nx, ny = (width - nw) // 2, max(4, cy - wing_offset)
    rooms.append({"id": "north", "name": "Glacial Frost Sanctum", "x": nx, "y": ny, "w": nw, "h": nh, "elem": "ice"})
    for y in range(ny, ny + nh):
        for x in range(nx, nx + nw): grid[y][x] = 2 # Cracked/Frost floor
        
    # South: Dark
    sw, sh = random.randint(14, 18), random.randint(12, 16)
    sx, sy = (width - sw) // 2, min(height - sh - 4, cy + ch + wing_offset - 10)
    rooms.append({"id": "south", "name": "Abyssal Dark Catacomb", "x": sx, "y": sy, "w": sw, "h": sh, "elem": "dark"})
    for y in range(sy, sy + sh):
        for x in range(sx, sx + sw): grid[y][x] = 4 # Dark floor
        
    # East: Lightning
    ew, eh = random.randint(12, 16), random.randint(14, 18)
    ex, ey = min(width - ew - 4, cx + cw + wing_offset - 10), (height - eh) // 2
    rooms.append({"id": "east", "name": "Thunder Lightning Armory", "x": ex, "y": ey, "w": ew, "h": eh, "elem": "lightning"})
    for y in range(ey, ey + eh):
        for x in range(ex, ex + ew): grid[y][x] = 1 # Stone floor
        
    # West: Void
    vw, vh = random.randint(12, 16), random.randint(14, 18)
    vx, vy = max(4, cx - wing_offset), (height - vh) // 2
    rooms.append({"id": "west", "name": "Void Singularity Vault", "x": vx, "y": vy, "w": vw, "h": vh, "elem": "void"})
    for y in range(vy, vy + vh):
        for x in range(vx, vx + vw): grid[y][x] = 5 # Runic floor

    # 3. Place 4 Corner Labyrinth Rooms
    corners = [
        ("ne", "Frost-Storm Gauntlet", ex - 4, ny + 2, random.randint(10, 14), random.randint(10, 14), "ice"),
        ("nw", "Void-Glacier Labyrinth", vx + 2, ny + 2, random.randint(10, 14), random.randint(10, 14), "void"),
        ("se", "Thunder-Abyss Arena", ex - 4, sy - 2, random.randint(10, 14), random.randint(10, 14), "lightning"),
        ("sw", "Dark-Void Crypt", vx + 2, sy - 2, random.randint(10, 14), random.randint(10, 14), "dark")
    ]
    for cid, cname, rx, ry, rw, rh, celem in corners:
        rooms.append({"id": cid, "name": cname, "x": rx, "y": ry, "w": rw, "h": rh, "elem": celem})
        for y in range(ry, ry + rh):
            for x in range(rx, rx + rw): grid[y][x] = 3 # Mossy floor

    # 4. Carve Corridors (Wide dungeon corridors connecting rooms)
    def carve_h_corridor(x1, x2, y, width_t=3):
        for x in range(min(x1, x2), max(x1, x2) + 1):
            for dy in range(width_t):
                if 0 <= y + dy < height and 0 <= x < width:
                    if grid[y + dy][x] == 0: grid[y + dy][x] = 1

    def carve_v_corridor(y1, y2, x, width_t=3):
        for y in range(min(y1, y2), max(y1, y2) + 1):
            for dx in range(width_t):
                if 0 <= y < height and 0 <= x + dx < width:
                    if grid[y][x + dx] == 0: grid[y][x + dx] = 1

    # Connect Center to North, South, East, West
    carve_v_corridor(ny + nh, cy, cx + cw // 2 - 1, 4)
    carve_v_corridor(cy + ch, sy, cx + cw // 2 - 1, 4)
    carve_h_corridor(vx + vw, cx, cy + ch // 2 - 1, 4)
    carve_h_corridor(cx + cw, ex, cy + ch // 2 - 1, 4)

    # Connect Corners
    for cid, cname, rx, ry, rw, rh, _ in corners:
        carve_h_corridor(rx, cx + cw // 2, ry + rh // 2, 3)
        carve_v_corridor(ry, cy + ch // 2, rx + rw // 2, 3)

    # 5. Place Chasms & Bridges
    chasms = []
    # North Chasm
    n_mid_y = (ny + nh + cy) // 2
    for dx in range(-4, 5):
        for dy in range(-2, 3):
            gx = cx + cw // 2 + dx
            gy = n_mid_y + dy
            if 0 <= gy < height and 0 <= gx < width:
                if abs(dx) > 1: # Center 2 tiles are bridge
                    grid[gy][gx] = 20 # Chasm
                else:
                    grid[gy][gx] = 21 # Stone Bridge
    chasms.append({"x": (cx + cw // 2) * 32, "y": n_mid_y * 32, "radius": 90, "has_bridge": True})

    # South Chasm
    s_mid_y = (cy + ch + sy) // 2
    for dx in range(-4, 5):
        for dy in range(-2, 3):
            gx = cx + cw // 2 + dx
            gy = s_mid_y + dy
            if 0 <= gy < height and 0 <= gx < width:
                if abs(dx) > 1:
                    grid[gy][gx] = 20
                else:
                    grid[gy][gx] = 21
    chasms.append({"x": (cx + cw // 2) * 32, "y": s_mid_y * 32, "radius": 90, "has_bridge": True})

    # 6. Autotiling: Build Solid Walls around all floors
    wall_grid = [[0 for _ in range(width)] for _ in range(height)]
    for y in range(height):
        for x in range(width):
            if grid[y][x] in [1, 2, 3, 4, 5, 20, 21]:
                # Check 8 neighbors
                for dy in [-1, 0, 1]:
                    for dx in [-1, 0, 1]:
                        ny_pos = y + dy
                        nx_pos = x + dx
                        if 0 <= ny_pos < height and 0 <= nx_pos < width:
                            if grid[ny_pos][nx_pos] == 0:
                                wall_grid[ny_pos][nx_pos] = 10 # Wall tile

    # Merge walls into grid
    for y in range(height):
        for x in range(width):
            if grid[y][x] == 0 and wall_grid[y][x] == 10:
                # Classify wall type
                has_floor_below = (y + 1 < height and grid[y + 1][x] in [1, 2, 3, 4, 5, 21])
                if has_floor_below:
                    grid[y][x] = 11 # Wall Front Face
                else:
                    grid[y][x] = 10 # Wall Top

    # 7. Place Pillars, Traps & Altars
    pillars = []
    # Center Colosseum Pillar Ring
    p_radius = 6
    for i in range(8):
        angle = (math.tau / 8.0) * i
        px = int(cx + cw // 2 + math.cos(angle) * p_radius)
        py = int(cy + ch // 2 + math.sin(angle) * p_radius)
        if grid[py][px] in [1, 2, 3, 4, 5]:
            grid[py][px] = 30
            pillars.append({"x": (px - width//2) * 48, "y": (py - height//2) * 48})

    # Traps & Interactive POIs
    spike_traps = []
    spring_traps = []
    elemental_vents = []
    blood_altars = []
    urns = []

    for r in rooms:
        # Place Shrines
        rx, ry, rw, rh = r["x"], r["y"], r["w"], r["h"]
        if r["elem"] == "ice": grid[ry + rh//2][rx + rw//2] = 40
        elif r["elem"] == "dark": grid[ry + rh//2][rx + rw//2] = 41
        elif r["elem"] == "lightning": grid[ry + rh//2][rx + rw//2] = 42
        elif r["elem"] == "void": grid[ry + rh//2][rx + rw//2] = 43
        
        # Place Traps
        for _ in range(random.randint(2, 4)):
            tx = rx + random.randint(2, rw - 3)
            ty = ry + random.randint(2, rh - 3)
            if grid[ty][tx] in [1, 2, 3, 4, 5]:
                grid[ty][tx] = 31 # Spike
                spike_traps.append({"x": (tx - width//2) * 48, "y": (ty - height//2) * 48, "interval": 2.5})
                
        # Springboards
        if random.random() < 0.7:
            sx = rx + random.randint(2, rw - 3)
            sy = ry + random.randint(2, rh - 3)
            if grid[sy][sx] in [1, 2, 3, 4, 5]:
                grid[sy][sx] = 32
                spring_traps.append({"x": (sx - width//2) * 48, "y": (sy - height//2) * 48, "launch_force": 450})

        # Blood Altar in corner rooms
        if r["id"] in ["ne", "sw"]:
            ax, ay = rx + 3, ry + 3
            if grid[ay][ax] in [1, 2, 3, 4, 5]:
                grid[ay][ax] = 34
                blood_altars.append({"x": (ax - width//2) * 48, "y": (ay - height//2) * 48})

    realm_idx = (map_id - 1) % len(DUNGEON_REALMS)
    realm_name, realm_lore = DUNGEON_REALMS[realm_idx]
    if map_id > len(DUNGEON_REALMS):
        realm_name += f" - ACT {(map_id // len(DUNGEON_REALMS)) + 1}"

    return {
        "map_id": map_id,
        "name": realm_name,
        "lore": realm_lore,
        "grid_width": width,
        "grid_height": height,
        "tile_size": 48,
        "rooms": rooms,
        "grid": grid,
        "chasms": chasms,
        "spike_traps": spike_traps,
        "spring_traps": spring_traps,
        "elemental_vents": elemental_vents,
        "blood_altars": blood_altars,
        "pillars": pillars,
        "urns": urns
    }

def render_tileset_preview(dungeon_data, tileset_img, output_path):
    grid = dungeon_data["grid"]
    gw = dungeon_data["grid_width"]
    gh = dungeon_data["grid_height"]
    ts = RENDER_TILE_SIZE
    
    img = Image.new("RGBA", (gw * ts, gh * ts), (8, 9, 12, 255))
    
    # Pre-crop tiles from tileset
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
    t_pillar = tileset_img.crop((0, 80, 16, 112)).resize((ts, ts * 2), Image.NEAREST)
    t_bridge = get_tile('bridge')

    for y in range(gh):
        for x in range(gw):
            val = grid[y][x]
            pos = (x * ts, y * ts)
            
            if val == 1: img.paste(t_floor_plain, pos)
            elif val == 2: img.paste(t_floor_cracked, pos)
            elif val == 3: img.paste(t_floor_moss, pos)
            elif val == 4: img.paste(t_floor_dark, pos)
            elif val == 5: img.paste(t_floor_runic, pos)
            elif val == 10: img.paste(t_wall_top, pos)
            elif val == 11: img.paste(t_wall_front, pos)
            elif val == 20: # Chasm
                pass # black void
            elif val == 21: # Bridge
                img.paste(t_bridge, pos)
            elif val == 30: # Pillar
                img.paste(t_floor_plain, pos)
                img.paste(t_pillar, (pos[0], pos[1] - ts), t_pillar)

    draw = ImageDraw.Draw(img)

    # Draw Trap / Shrine Markers & Labels
    for y in range(gh):
        for x in range(gw):
            val = grid[y][x]
            p = (x * ts, y * ts)
            if val == 31: # Spike
                draw.rectangle([p[0]+4, p[1]+4, p[0]+ts-4, p[1]+ts-4], fill=(120, 20, 20, 200), outline=(255, 60, 60, 255), width=2)
            elif val == 32: # Spring
                draw.rectangle([p[0]+4, p[1]+4, p[0]+ts-4, p[1]+ts-4], fill=(120, 100, 20, 200), outline=(255, 215, 0, 255), width=2)
            elif val == 34: # Altar
                draw.rectangle([p[0]+2, p[1]+2, p[0]+ts-2, p[1]+ts-2], fill=(180, 20, 40, 240), outline=(255, 80, 100, 255), width=3)
            elif val == 40: # Ice Shrine
                draw.ellipse([p[0]-4, p[1]-4, p[0]+ts+4, p[1]+ts+4], fill=(85, 195, 245, 255), outline=(255, 255, 255, 255), width=3)
            elif val == 41: # Dark Shrine
                draw.ellipse([p[0]-4, p[1]-4, p[0]+ts+4, p[1]+ts+4], fill=(185, 75, 235, 255), outline=(255, 255, 255, 255), width=3)
            elif val == 42: # Lightning Shrine
                draw.ellipse([p[0]-4, p[1]-4, p[0]+ts+4, p[1]+ts+4], fill=(245, 215, 85, 255), outline=(255, 255, 255, 255), width=3)
            elif val == 43: # Void Shrine
                draw.ellipse([p[0]-4, p[1]-4, p[0]+ts+4, p[1]+ts+4], fill=(235, 85, 235, 255), outline=(255, 255, 255, 255), width=3)

    # Title & Legend Banner
    banner_h = 130
    draw.rectangle([40, 40, img.width - 40, 40 + banner_h], fill=(12, 14, 20, 240), outline=(215, 185, 110, 255), width=3)
    draw.text((60, 56), f"AUTHENTIC RUIN DUNGEON: {dungeon_data['name']}", fill=(245, 215, 110, 255))
    draw.text((60, 92), f"LORE: {dungeon_data['lore']}", fill=(180, 185, 200, 255))

    # Bottom Legend
    draw.rectangle([40, img.height - 90, img.width - 40, img.height - 40], fill=(12, 14, 20, 240), outline=(130, 140, 165, 255), width=2)
    legend_text = "Brick Walls (Autotiled) | Ruined Slabs & Corridors | Chasm Pits & Bridges | Pillars | Spikes | Springboards | Altars | 4 Elemental Shrines"
    draw.text((60, img.height - 72), legend_text, fill=(220, 225, 240, 255))

    img.save(output_path)
    # Also save in artifact directory
    artifact_dir = r"C:\Users\Admin\.gemini\antigravity-ide\brain\139bf2d1-a9c2-46da-9225-301c22798bea"
    os.makedirs(artifact_dir, exist_ok=True)
    img.save(os.path.join(artifact_dir, "dungeon_map_preview.png"))
    print(f"Rendered authentic tileset map preview to {output_path}!")

def main():
    tileset_img = Image.open('Sprite/Environment/ruined_tileset.png')
    all_dungeons = []
    print("Generating 40 Authentic Tileset Ruin Dungeon Maps...")
    
    for i in range(1, 41):
        d = generate_dungeon_grid(90, 90, i)
        all_dungeons.append(d)
        print(f"  [{i}/40] Generated {d['name']} (90x90 Grid, {len(d['rooms'])} Rooms)")

    vault_path = "data/maps/ruin_dungeon_vault.json"
    with open(vault_path, "w", encoding="utf-8") as f:
        json.dump({"total_maps": len(all_dungeons), "maps": all_dungeons}, f, indent=2, ensure_ascii=False)
    print(f"\nSaved 40 Dungeon Maps to {vault_path}!")

    # Render High-Res Preview of Map 1
    render_tileset_preview(all_dungeons[0], tileset_img, "data/maps/dungeon_map_preview.png")

if __name__ == "__main__":
    main()
