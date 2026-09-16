import json
import random
import math

DUNGEON_NAMES = [
    ("AZGARTH'S COLOSSEUM OF RUIN", "An ancient titan colosseum where fallen warriors were pitted against eldritch beasts."),
    ("THE SUBTERRANEAN NECROPOLIS OF THORNE", "Decaying catacombs etched with elder futhark runes and cursed royal tombs."),
    ("TEMPLE OF THE FRACTURED STARS", "A forgotten observatory where cosmic void rifts tore the marble sanctum apart."),
    ("CITADEL OF THE FROSTBITE QUEEN", "Glacial ice has crystallized the throne room and ancient archways in perpetual winter."),
    ("THE ABYSSAL BARRACKS OF MALICE", "Iron-gated dungeons where demonic shock troops once trained in pitch darkness."),
    ("LABYRINTH OF THE SHADOW WEAVER", "A twisting maze of jagged stone pillars and treacherous pit traps."),
    ("SANCTUM OF THE THUNDER GOD", "Tesla energy arcs constantly through ancient gilded monoliths."),
    ("THE FORGOTTEN SEPULCHER OF OBLIVION", "A massive underground complex swallowed by singularity anomalies."),
    ("VAULT OF THE CRIMSON BLOOD LORD", "Sacrificial blood channels carve through cracked obsidian flagstones."),
    ("THE SUNKEN BASTION OF AEONS", "Moss-covered ruined halls filled with unstable springboards and spike grates."),
    ("GRAND MAUSOLEUM OF THE FIRST EMPEROR", "Massive pillared halls housing ancient sarcophagi and locked treasures."),
    ("THE OBSIDIAN FORGE OF CHAOS", "Molten energy and cracked stone tiles create a perilous labyrinth."),
    ("SANCTUARY OF THE ELDER TITANS", "Colossal ruined pillars tower over ancient battle pits and yawning chasms."),
    ("THE FROZEN LABYRINTH OF NIFLHEIM", "Icy floors and freezing vents punish anyone who lingers in the corridors."),
    ("TEMPLE OF THE DUALITY ECLIPSE", "Where blinding celestial lightning collides with primordial shadow."),
    ("THE HALLOWED RUINS OF VALKYRIA", "Decayed stone bridges span endless abyssal drops."),
    ("CATACOMBS OF THE BLACK PHANTOM", "Hidden spike traps and toxic vents lurk beneath the crumbling floor tiles."),
    ("THE CELESTIAL SINGULARITY SHRINE", "Gravity anomalies drag unwary adventurers toward the central black hole."),
    ("BASTION OF THE THOUSAND SCYTHES", "Deadly blades and springboards line the narrow corridor bottlenecks."),
    ("THE SACRIFICIAL ALTAR OF BALOR", "Ancient stone altars await offerings of vital essence in exchange for power."),
]

def generate_map(map_id):
    name_idx = (map_id - 1) % len(DUNGEON_NAMES)
    base_name, base_lore = DUNGEON_NAMES[name_idx]
    if map_id > len(DUNGEON_NAMES):
        variant = f" - ACT {(map_id // len(DUNGEON_NAMES)) + 1}"
        name = base_name + variant
    else:
        name = base_name

    # World size ~4800x4800
    rooms = []
    
    # 1. Central Grand Plaza / Colosseum
    rooms.append({
        "id": "room_center",
        "name": "Central Colosseum",
        "type": "colosseum",
        "x": 0, "y": 0, "w": 850, "h": 850,
        "element": "neutral",
        "pillar_ring": True
    })
    
    # 2. Four Elemental Wings
    wing_dist = random.randint(1100, 1400)
    
    # North: Frost Sanctum
    rooms.append({
        "id": "room_north",
        "name": "Glacial Frost Sanctum",
        "type": "sanctum",
        "x": 0, "y": -wing_dist, "w": random.randint(700, 900), "h": random.randint(600, 800),
        "element": "ice",
        "has_shrine": "ice"
    })
    
    # South: Abyssal Dark Catacomb
    rooms.append({
        "id": "room_south",
        "name": "Abyssal Catacomb",
        "type": "catacomb",
        "x": 0, "y": wing_dist, "w": random.randint(700, 900), "h": random.randint(600, 800),
        "element": "dark",
        "has_shrine": "dark"
    })
    
    # East: Storm Lightning Armory
    rooms.append({
        "id": "room_east",
        "name": "Thunder Armory",
        "type": "armory",
        "x": wing_dist, "y": 0, "w": random.randint(600, 800), "h": random.randint(700, 900),
        "element": "lightning",
        "has_shrine": "lightning"
    })
    
    # West: Void Singularity Observatory
    rooms.append({
        "id": "room_west",
        "name": "Void Singularity Vault",
        "type": "vault",
        "x": -wing_dist, "y": 0, "w": random.randint(600, 800), "h": random.randint(700, 900),
        "element": "void",
        "has_shrine": "void"
    })
    
    # 3. Corner Labyrinths & Gauntlets
    corner_dist = int(wing_dist * 0.75)
    corners = [
        ("room_ne", "Frost-Storm Gauntlet", corner_dist, -corner_dist, "ice"),
        ("room_nw", "Void-Glacier Labyrinth", -corner_dist, -corner_dist, "void"),
        ("room_se", "Thunder-Abyss Arena", corner_dist, corner_dist, "lightning"),
        ("room_sw", "Dark-Void Crypt", -corner_dist, corner_dist, "dark"),
    ]
    for cid, cname, cx, cy, celem in corners:
        rooms.append({
            "id": cid,
            "name": cname,
            "type": "labyrinth",
            "x": cx + random.randint(-80, 80),
            "y": cy + random.randint(-80, 80),
            "w": random.randint(550, 750),
            "h": random.randint(550, 750),
            "element": celem
        })

    # Generate Chasms (Abyssal Pits)
    chasms = []
    # 4 Cardinal Chasms with narrow bridge crossings
    for angle in [0, math.pi/2, math.pi, 3*math.pi/2]:
        dist = random.randint(550, 750)
        cx = int(math.cos(angle) * dist)
        cy = int(math.sin(angle) * dist)
        chasms.append({
            "x": cx, "y": cy,
            "radius": random.randint(90, 140),
            "has_bridge": True
        })
    # Additional random pit holes
    for _ in range(random.randint(4, 8)):
        chasms.append({
            "x": random.randint(-1800, 1800),
            "y": random.randint(-1800, 1800),
            "radius": random.randint(70, 110),
            "has_bridge": False
        })

    # Generate Spike Traps
    spike_traps = []
    for _ in range(random.randint(16, 28)):
        spike_traps.append({
            "x": random.randint(-2000, 2000),
            "y": random.randint(-2000, 2000),
            "interval": round(random.uniform(1.8, 3.2), 2)
        })

    # Generate Troll Springboards (bounces player/monsters)
    spring_traps = []
    for _ in range(random.randint(8, 14)):
        spring_traps.append({
            "x": random.randint(-1900, 1900),
            "y": random.randint(-1900, 1900),
            "launch_force": random.randint(380, 520)
        })

    # Generate Elemental Vents
    elemental_vents = []
    vent_elements = ["lightning", "ice", "dark", "void"]
    for _ in range(random.randint(10, 18)):
        elemental_vents.append({
            "x": random.randint(-2100, 2100),
            "y": random.randint(-2100, 2100),
            "element": random.choice(vent_elements),
            "interval": round(random.uniform(2.5, 4.5), 2)
        })

    # Generate Sacrificial Blood Altars
    blood_altars = []
    for _ in range(random.randint(2, 4)):
        blood_altars.append({
            "x": random.randint(-1600, 1600),
            "y": random.randint(-1600, 1600)
        })

    # Generate Ruined Pillars
    pillars = []
    # Central ring
    for i in range(12):
        a = (math.tau / 12.0) * i
        r = 340.0
        pillars.append({"x": int(math.cos(a) * r), "y": int(math.sin(a) * r)})
    # Room pillars
    for r in rooms:
        if r["type"] in ["sanctum", "catacomb", "armory", "vault", "labyrinth"]:
            rx, ry = r["x"], r["y"]
            p_cnt = random.randint(4, 8)
            for _ in range(p_cnt):
                pillars.append({
                    "x": rx + random.randint(-int(r["w"]*0.35), int(r["w"]*0.35)),
                    "y": ry + random.randint(-int(r["h"]*0.35), int(r["h"]*0.35))
                })

    # Generate Destructible Urns & Props
    urns = []
    for _ in range(random.randint(45, 70)):
        urns.append({
            "x": random.randint(-2200, 2200),
            "y": random.randint(-2200, 2200)
        })

    return {
        "map_id": map_id,
        "name": name,
        "lore": base_lore,
        "rooms": rooms,
        "chasms": chasms,
        "spike_traps": spike_traps,
        "spring_traps": spring_traps,
        "elemental_vents": elemental_vents,
        "blood_altars": blood_altars,
        "pillars": pillars,
        "urns": urns,
        "world_size": 4800
    }

def main():
    map_pool = []
    print("Generating 40 Masterpiece Ruin Dungeon Maps...")
    for i in range(1, 41):
        m = generate_map(i)
        map_pool.append(m)
        print(f"  [{i}/40] Generated: {m['name']} ({len(m['rooms'])} Rooms, {len(m['chasms'])} Chasms, {len(m['spike_traps'])} Spike Traps)")
    
    output_path = "data/maps/ruin_dungeon_vault.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({"total_maps": len(map_pool), "maps": map_pool}, f, indent=2, ensure_ascii=False)
    
    print(f"\nSUCCESS: Saved 40 complex Ruin Dungeon Maps into {output_path}!")

if __name__ == "__main__":
    main()
