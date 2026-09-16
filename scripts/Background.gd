extends Node2D

var tileset_texture: Texture2D
var current_map_data: Dictionary = {}
var grid: Array = []
var grid_width: int = 200
var grid_height: int = 200
var tile_size: float = 64.0
var half_w: float = 0.0
var half_h: float = 0.0

# Exact Full 32x32 Tiles & Entire Props without Slicing (Image 3, 4, 5):
const TILE_RECTS = {
	"floor_gravel": Rect2(96, 0, 32, 32),        # Tier 2: Pure Dark Gravel Floor (Full 32x32)
	"floor_pebble": Rect2(64, 32, 32, 32),       # Tier 1: Sunken Abyssal Trench Floor (Full 32x32)
	"floor_brick": Rect2(64, 0, 32, 32),         # Tier 3: Elevated Terrace Floor (Full 32x32)
	"floor_slab": Rect2(32, 32, 32, 32),         # Tier 4: High Sacrificial Altar Floor (Full 32x32)
	"path_mosaic": Rect2(0, 0, 32, 32),          # Mosaic stone walkway (Full 32x32)
	"spiral_void": Rect2(0, 32, 32, 32),         # Spiral void rune (Full 32x32)
	"chasm": Rect2(96, 32, 32, 32),              # Circular abyss hole (Full 32x32)
	"wall_solid": Rect2(64, 0, 32, 32),          # Solid Wall Border (Full 32x32)
	
	# Entire Props from Image 3, 4, 5 (Exact Pixel Bounding Boxes):
	"tall_pillar": Rect2(320, 6, 32, 90),        # Tall Blood-Veined Runic Pillar
	"broken_monolith": Rect2(234, 38, 54, 58),   # Broken Ancient Monolith
	"sarcophagus": Rect2(257, 113, 64, 48),      # Large Stone Sarcophagus with Carved Lid
	"tombstone_round": Rect2(144, 80, 32, 48),   # Carved Gravestone (Round)
	"tombstone_pointed": Rect2(96, 80, 32, 48),  # Carved Gravestone (Pointed)
	"rubble": Rect2(177, 98, 63, 46),            # Mountain of Rubble
	"brazier": Rect2(98, 191, 45, 49),           # Large Fire Brazier
	"candles": Rect2(95, 145, 31, 31),           # Candles & Skulls
	"blood_pool": Rect2(0, 80, 42, 31),          # Round Blood Pool
	"stairs": Rect2(336, 112, 48, 48)            # Stone Stairs Transition
}

func _ready() -> void:
	z_index = -50
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 1.0))
	tileset_texture = load("res://Sprite/Environment/ruined_tileset.png")
	_load_and_build_random_dungeon()

func _load_and_build_random_dungeon() -> void:
	var vault_path = "res://data/maps/ruin_dungeon_vault.json"
	var file = FileAccess.open(vault_path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_str)
		if parsed and parsed.has("maps") and parsed["maps"].size() > 0:
			var maps_array = parsed["maps"]
			current_map_data = maps_array[randi() % maps_array.size()]
			_instantiate_dungeon(current_map_data)
			return
			
	# Fallback if file not read
	var fallback_gen = AIAgentMapGenerator.new()
	add_child(fallback_gen)
	fallback_gen.map_generation_completed.connect(_instantiate_dungeon)
	fallback_gen.generate_map_blueprint()

func _instantiate_dungeon(map_blueprint: Dictionary) -> void:
	grid = map_blueprint.get("grid", [])
	grid_width = map_blueprint.get("grid_width", 200)
	grid_height = map_blueprint.get("grid_height", 200)
	tile_size = map_blueprint.get("tile_size", 64.0)
	half_w = grid_width * tile_size * 0.5
	half_h = grid_height * tile_size * 0.5
	
	# 1. Announce Realm Name and Lore to HUD
	var realm_name = map_blueprint.get("name", "CHAOTIC LABYRINTH OF THE SHATTERED TITANS")
	var lore = map_blueprint.get("lore", "An ancient strongly-connected asymmetrical ruined megastructure with 60 chambers across 4 tiers.")
	GameManager.wave_event_triggered.emit("📍 REALM: " + realm_name, lore)
	
	# 2. Forward Mob Spawner sites to EnemySpawner (Guaranteed ONLY on interior room floors!)
	var spawners = map_blueprint.get("mob_spawners", [])
	var enemy_spawner = get_tree().current_scene.find_child("EnemySpawner", true, false)
	if enemy_spawner:
		enemy_spawner.mob_spawner_sites = spawners
		
	# 3. Spawn Chasms (Abyssal Pits & Bridges)
	var chasm_script = load("res://scripts/AbyssalChasm.gd")
	var chasms = map_blueprint.get("chasms", [])
	for c_data in chasms:
		var chasm = Node2D.new()
		chasm.set_script(chasm_script)
		add_child(chasm)
		chasm.setup(c_data)
		
	# 4. Spawn 4 Mythic Rune Shrines (Far apart across 4 quadrants!)
	var cardinal_shrines = map_blueprint.get("cardinal_shrines", [])
	for sh in cardinal_shrines:
		var fountain = Area2D.new()
		fountain.set_script(load("res://scripts/RuneFountain.gd"))
		fountain.rune_type = sh.get("elem", "ice")
		fountain.global_position = Vector2(sh.get("x", 0), sh.get("y", 0))
		add_child(fountain)

	# 5. Solid Wall Collisions on Layer 1 (Obstacles)
	if grid.size() > 0:
		var wall_body = StaticBody2D.new()
		wall_body.collision_layer = 1
		wall_body.collision_mask = 0
		add_child(wall_body)
		
		for y in range(grid_height):
			var span_start = -1
			for x in range(grid_width):
				var val = grid[y][x]
				var is_wall = (val == 10) # T_WALL_SOLID
				if is_wall:
					if span_start == -1: span_start = x
				else:
					if span_start != -1:
						var span_len = x - span_start
						var c_shape = CollisionShape2D.new()
						var rect_shape = RectangleShape2D.new()
						rect_shape.size = Vector2(span_len * tile_size, tile_size)
						c_shape.shape = rect_shape
						var wx = (span_start - grid_width/2.0 + span_len * 0.5) * tile_size
						var wy = (y - grid_height/2.0 + 0.5) * tile_size
						c_shape.position = Vector2(wx, wy)
						wall_body.add_child(c_shape)
						span_start = -1
			if span_start != -1:
				var span_len = grid_width - span_start
				var c_shape = CollisionShape2D.new()
				var rect_shape = RectangleShape2D.new()
				rect_shape.size = Vector2(span_len * tile_size, tile_size)
				c_shape.shape = rect_shape
				var wx = (span_start - grid_width/2.0 + span_len * 0.5) * tile_size
				var wy = (y - grid_height/2.0 + 0.5) * tile_size
				c_shape.position = Vector2(wx, wy)
				wall_body.add_child(c_shape)

	queue_redraw()

func is_walkable_tile(world_pos: Vector2) -> bool:
	if grid.is_empty():
		return true
	var gx = int(floor((world_pos.x + half_w) / tile_size))
	var gy = int(floor((world_pos.y + half_h) / tile_size))
	if gx < 0 or gx >= grid_width or gy < 0 or gy >= grid_height:
		return false
	var val = grid[gy][gx]
	return val != 0 and val != 10 # 0=Void, 10=Solid Wall

func get_valid_floor_pos(target_pos: Vector2, fallback_pos: Vector2) -> Vector2:
	if is_walkable_tile(target_pos):
		return target_pos
	for r in range(1, 12):
		for angle_i in range(8):
			var a = (TAU / 8.0) * angle_i
			var test_pos = target_pos + Vector2(cos(a), sin(a)) * (r * tile_size * 0.6)
			if is_walkable_tile(test_pos):
				return test_pos
	return fallback_pos

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw massive pure pitch black backdrop
	draw_rect(Rect2(-30000, -30000, 60000, 60000), Color(0.0, 0.0, 0.0, 1.0), true)
	
	if not tileset_texture or grid.is_empty():
		return
		
	var player = GameManager.player
	var center_pos = player.global_position if player else Vector2.ZERO
	
	# Viewport Culling: Only draw tiles visible in camera viewport (~1400x1000px)
	var view_margin = 160.0
	var min_x = int(clamp((center_pos.x - 700.0 - view_margin + half_w) / tile_size, 0, grid_width - 1))
	var max_x = int(clamp((center_pos.x + 700.0 + view_margin + half_w) / tile_size, 0, grid_width - 1))
	var min_y = int(clamp((center_pos.y - 500.0 - view_margin + half_h) / tile_size, 0, grid_height - 1))
	var max_y = int(clamp((center_pos.y + 500.0 + view_margin + half_h) / tile_size, 0, grid_height - 1))
	
	# Pass 1: Render Floors across 4 Tiers, Mosaic Pathways, Solid Wall Borders
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var val = grid[y][x]
			if val == 0:
				continue # PURE VOID BLACK OUTSIDE!
				
			var dest_rect = Rect2((x - grid_width/2.0) * tile_size, (y - grid_height/2.0) * tile_size, tile_size, tile_size)
			
			if val == 1 or val >= 30: # Tier 2 Ground Floor (also base under props!)
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["floor_gravel"])
			elif val == 2: # Tier 1 Sunken Abyssal Trench
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["floor_pebble"])
			elif val == 3: # Tier 3 Elevated Terrace
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["floor_brick"])
			elif val == 4: # Tier 4 High Sacrificial Altar
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["floor_slab"])
			elif val == 5: # Pathway Mosaic
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["path_mosaic"])
			elif val == 6: # Spiral Void Rune
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["spiral_void"])
			elif val == 7: # Chasm Hole
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["chasm"])
			elif val == 10: # Solid Wall Border
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["wall_solid"])
			
	# Pass 2: Render Staircases & Entire Props from Image 3, 4, 5
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var val = grid[y][x]
			var dest_base = Vector2((x - grid_width/2.0) * tile_size, (y - grid_height/2.0) * tile_size)
			
			if val == 41: # Stone Stairs Transition (48x48)
				var dest_rect = Rect2(dest_base.x - 8, dest_base.y - tile_size * 0.5, tile_size * 1.5, tile_size * 1.5)
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["stairs"])
			elif val == 30: # Tall Blood Pillar (32x90)
				var dest_rect = Rect2(dest_base.x, dest_base.y - tile_size * 1.8, tile_size, tile_size * 2.8)
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["tall_pillar"])
			elif val == 31: # Broken Ancient Monolith (54x58)
				var dest_rect = Rect2(dest_base.x - 10, dest_base.y - tile_size * 0.8, tile_size * 1.7, tile_size * 1.8)
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["broken_monolith"])
			elif val == 32: # Large Sarcophagus with Carved Lid (64x48)
				var dest_rect = Rect2(dest_base.x - 16, dest_base.y - tile_size * 0.5, tile_size * 2.0, tile_size * 1.5)
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["sarcophagus"])
			elif val == 33: # Round Tombstone (32x48)
				var dest_rect = Rect2(dest_base.x, dest_base.y - tile_size * 0.5, tile_size, tile_size * 1.5)
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["tombstone_round"])
			elif val == 34: # Pointed Tombstone (32x48)
				var dest_rect = Rect2(dest_base.x, dest_base.y - tile_size * 0.5, tile_size, tile_size * 1.5)
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["tombstone_pointed"])
			elif val == 35: # Mountain of Rubble (63x46)
				var dest_rect = Rect2(dest_base.x - 16, dest_base.y, tile_size * 2.0, tile_size * 1.4)
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["rubble"])
			elif val == 36: # Large Fire Brazier (45x49)
				var dest_rect = Rect2(dest_base.x - 6, dest_base.y - tile_size * 0.5, tile_size * 1.4, tile_size * 1.5)
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["brazier"])
			elif val == 37: # Candles & Skulls (31x31)
				var dest_rect = Rect2(dest_base.x, dest_base.y, tile_size, tile_size)
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["candles"])
			elif val == 38: # Round Blood Pool (42x31)
				var dest_rect = Rect2(dest_base.x, dest_base.y, tile_size * 1.3, tile_size)
				draw_texture_rect_region(tileset_texture, dest_rect, TILE_RECTS["blood_pool"])
