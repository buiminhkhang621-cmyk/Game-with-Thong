import json
import os
import math
from PIL import Image, ImageDraw, ImageFont

def render_map():
    with open('data/maps/ruin_dungeon_vault.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    m = data['maps'][0]
    map_name = m['name']
    map_lore = m['lore']
    print(f"Rendering {map_name}...")

    IMG_SIZE = 2048
    WORLD_SIZE = 4800.0
    SCALE = IMG_SIZE / WORLD_SIZE
    OFFSET = IMG_SIZE / 2.0

    def to_img(x, y):
        return (int(x * SCALE + OFFSET), int(y * SCALE + OFFSET))

    img = Image.new('RGBA', (IMG_SIZE, IMG_SIZE), (15, 17, 23, 255))
    draw = ImageDraw.Draw(img)

    # 1. Background Grid & Stone Tiles
    for x in range(0, IMG_SIZE, 32):
        draw.line([(x, 0), (x, IMG_SIZE)], fill=(25, 28, 38, 255), width=1)
    for y in range(0, IMG_SIZE, 32):
        draw.line([(0, y), (IMG_SIZE, y)], fill=(25, 28, 38, 255), width=1)

    # 2. Draw Rooms with Elemental Tints
    for r in m['rooms']:
        rx, ry = r['x'], r['y']
        rw, rh = r['w'], r['h']
        p1 = to_img(rx - rw/2, ry - rh/2)
        p2 = to_img(rx + rw/2, ry + rh/2)
        
        elem = r.get('element', 'neutral')
        fill_col = (28, 32, 44, 230)
        border_col = (70, 80, 105, 255)
        
        if elem == 'ice':
            fill_col = (20, 45, 65, 230)
            border_col = (85, 195, 245, 255)
        elif elem == 'dark':
            fill_col = (40, 20, 55, 230)
            border_col = (185, 75, 235, 255)
        elif elem == 'lightning':
            fill_col = (55, 50, 20, 230)
            border_col = (245, 215, 85, 255)
        elif elem == 'void':
            fill_col = (55, 20, 55, 230)
            border_col = (235, 85, 235, 255)
        elif r.get('type') == 'colosseum':
            fill_col = (45, 38, 28, 240)
            border_col = (215, 185, 110, 255)
            
        draw.rectangle([p1, p2], fill=fill_col, outline=border_col, width=3)
        draw.text((p1[0] + 12, p1[1] + 12), r['name'].upper(), fill=border_col)

    # 3. Draw Chasms (Abyssal Pits & Bridges)
    for c in m['chasms']:
        cx, cy = c['x'], c['y']
        c_rad = int(c['radius'] * SCALE)
        cp = to_img(cx, cy)
        draw.ellipse([cp[0]-c_rad, cp[1]-c_rad, cp[0]+c_rad, cp[1]+c_rad], fill=(5, 3, 8, 255), outline=(100, 40, 140, 255), width=2)
        if c.get('has_bridge', False):
            bw = int(36 * SCALE * 0.5)
            draw.rectangle([cp[0]-c_rad-4, cp[1]-bw, cp[0]+c_rad+4, cp[1]+bw], fill=(60, 65, 80, 255), outline=(130, 140, 160, 255), width=2)

    # 4. Draw Spike Traps
    for s in m['spike_traps']:
        sp = to_img(s['x'], s['y'])
        sr = int(18 * SCALE)
        draw.rectangle([sp[0]-sr, sp[1]-sr, sp[0]+sr, sp[1]+sr], fill=(70, 20, 20, 255), outline=(230, 60, 60, 255), width=2)

    # 5. Draw Springboards
    for sp in m['spring_traps']:
        spp = to_img(sp['x'], sp['y'])
        spr = int(16 * SCALE)
        draw.rectangle([spp[0]-spr, spp[1]-spr, spp[0]+spr, spp[1]+spr], fill=(60, 50, 15, 255), outline=(245, 200, 50, 255), width=2)

    # 6. Draw Elemental Vents
    for v in m['elemental_vents']:
        vp = to_img(v['x'], v['y'])
        vr = int(16 * SCALE)
        v_col = (245, 200, 50, 255)
        if v['element'] == 'ice': v_col = (85, 195, 245, 255)
        elif v['element'] == 'dark': v_col = (185, 75, 235, 255)
        elif v['element'] == 'void': v_col = (235, 85, 235, 255)
        draw.ellipse([vp[0]-vr, vp[1]-vr, vp[0]+vr, vp[1]+vr], fill=(20, 20, 25, 255), outline=v_col, width=2)

    # 7. Draw Blood Altars
    for a in m['blood_altars']:
        ap = to_img(a['x'], a['y'])
        ar = int(22 * SCALE)
        draw.rectangle([ap[0]-ar, ap[1]-ar, ap[0]+ar, ap[1]+ar], fill=(90, 15, 30, 255), outline=(245, 40, 70, 255), width=3)
        draw.text((ap[0]-ar+4, ap[1]-ar+4), 'ALTAR', fill=(255, 180, 190, 255))

    # 8. Draw Ruined Pillars
    for p in m['pillars']:
        pp = to_img(p['x'], p['y'])
        pr = max(3, int(22 * SCALE))
        draw.ellipse([pp[0]-pr, pp[1]-pr, pp[0]+pr, pp[1]+pr], fill=(75, 82, 100, 255), outline=(150, 160, 185, 255), width=1)

    # 9. Draw Rune Shrines in 4 Wings
    shrine_coords = [
        (0, -1124, 'ICE RUNE SHRINE', (85, 195, 245, 255)),
        (0, 1124, 'DARK RUNE SHRINE', (185, 75, 235, 255)),
        (1124, 0, 'LIGHTNING RUNE SHRINE', (245, 215, 85, 255)),
        (-1124, 0, 'VOID RUNE SHRINE', (235, 85, 235, 255))
    ]
    for sx, sy, sname, scol in shrine_coords:
        sp = to_img(sx, sy)
        draw.ellipse([sp[0]-16, sp[1]-16, sp[0]+16, sp[1]+16], fill=scol, outline=(255, 255, 255, 255), width=3)
        draw.text((sp[0]-60, sp[1]+22), sname, fill=scol)

    # 10. Title Header & Legend Overlay Banner
    draw.rectangle([40, 40, IMG_SIZE - 40, 140], fill=(12, 14, 20, 245), outline=(215, 185, 110, 255), width=3)
    draw.text((60, 56), f"REALM: {map_name}", fill=(245, 215, 110, 255))
    draw.text((60, 92), f"LORE: {map_lore}", fill=(180, 185, 200, 255))

    # Legend Box
    draw.rectangle([40, IMG_SIZE - 120, IMG_SIZE - 40, IMG_SIZE - 40], fill=(12, 14, 20, 245), outline=(130, 140, 165, 255), width=2)
    legend_items = [
        ("Central Colosseum", (215, 185, 110, 255)),
        ("Frost Sanctum", (85, 195, 245, 255)),
        ("Dark Catacomb", (185, 75, 235, 255)),
        ("Thunder Armory", (245, 215, 85, 255)),
        ("Void Vault", (235, 85, 235, 255)),
        ("Chasm Pits", (100, 40, 140, 255)),
        ("Spike Traps", (230, 60, 60, 255)),
        ("Springboards", (245, 200, 50, 255))
    ]
    lx = 60
    for label, col in legend_items:
        draw.text((lx, IMG_SIZE - 90), label, fill=col)
        lx += 230

    output_path = 'data/maps/dungeon_map_preview.png'
    img.save(output_path)

    # Also save into artifact directory
    artifact_dir = r'C:\Users\Admin\.gemini\antigravity-ide\brain\139bf2d1-a9c2-46da-9225-301c22798bea'
    os.makedirs(artifact_dir, exist_ok=True)
    img.save(os.path.join(artifact_dir, 'dungeon_map_preview.png'))
    print(f"SUCCESS! Rendered full map preview to {output_path} and artifact directory!")

if __name__ == '__main__':
    render_map()
