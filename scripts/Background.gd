extends Node2D

var tileset_texture: Texture2D
var current_map_data: Dictionary = {}
var grid: Array = []
var grid_width: int = 200
var grid_height: int = 200
var tile_size: float = 64.0
var half_w: float = 0.0
var half_h: float = 0.0
var verified_floor_points: Array[Vector2] = []
var _last_draw_pos: Vector2 = Vector2(INF, INF)

var ambient_particles: CPUParticles2D = null

# Exact 32x32 Tiles & Entire Props for Map 1: Ruin
const RUIN_TILES = {
	"floor_1": Rect2(96, 0, 32, 32),        # Tier 2: Pure Dark Gravel Floor
	"floor_2": Rect2(64, 32, 32, 32),       # Tier 1: Sunken Abyssal Trench Floor
	"floor_3": Rect2(64, 0, 32, 32),         # Tier 3: Elevated Terrace Floor
	"floor_4": Rect2(32, 32, 32, 32),        # Tier 4: High Sacrificial Altar Floor
	"path": Rect2(0, 0, 32, 32),             # Mosaic stone walkway
	"center": Rect2(0, 32, 32, 32),          # Spiral void rune
	"chasm": Rect2(96, 32, 32, 32),          # Circular abyss hole
	"wall": Rect2(64, 0, 32, 32),            # Solid Wall Border
	
	"prop_30": Rect2(320, 6, 32, 90),        # Tall Blood-Veined Runic Pillar
	"prop_31": Rect2(234, 38, 54, 58),       # Broken Ancient Monolith
	"prop_32": Rect2(257, 113, 64, 48),      # Large Stone Sarcophagus with Carved Lid
	"prop_33": Rect2(144, 80, 32, 48),       # Carved Gravestone (Round)
	"prop_34": Rect2(96, 80, 32, 48),        # Carved Gravestone (Pointed)
	"prop_35": Rect2(177, 98, 63, 46),       # Mountain of Rubble
	"prop_36": Rect2(98, 191, 45, 49),       # Large Fire Brazier
	"prop_37": Rect2(95, 145, 31, 31),       # Candles & Skulls
	"prop_38": Rect2(0, 80, 42, 31),         # Round Blood Pool
	"stairs": Rect2(336, 112, 48, 48)        # Stone Stairs Transition
}

# Exact 32x32 Tiles & Entire Props for Map 2: Forest
const FOREST_TILES = {
	"floor_1": Rect2(320, 0, 32, 32),       # Mossy Grass Floor
	"floor_2": Rect2(0, 0, 32, 32),          # Deep Forest Soil / Humus
	"floor_3": Rect2(64, 0, 32, 32),         # Dark Earth / Peat Floor
	"floor_4": Rect2(128, 0, 32, 32),        # Ancient Root Clearing Dais
	"path": Rect2(96, 0, 32, 32),            # Winding Dirt Footpath
	"center": Rect2(352, 0, 32, 32),         # Mystic Fairy Ring Center
	"chasm": Rect2(128, 96, 32, 32),         # Murky Bayou Swamp Pond
	"wall": Rect2(320, 0, 32, 32),           # Dense Ancient Tree Border
	
	"prop_30": Rect2(196, 130, 126, 94),     # Giant Primeval Canopy Tree (126x94)
	"prop_31": Rect2(65, 256, 63, 63),       # Overgrown Moss Monolith (63x63)
	"prop_32": Rect2(194, 256, 87, 64),      # Hollow Ancient Tree Stump (87x64)
	"prop_33": Rect2(2, 257, 61, 60),        # Ancient Stone Totem (61x60)
	"prop_34": Rect2(129, 257, 62, 62),      # Primeval Fern Cluster (62x62)
	"prop_35": Rect2(291, 267, 60, 51),      # Mossy Rock Formation (60x51)
	"prop_36": Rect2(321, 130, 117, 92),     # Elder Willow Tree (117x92)
	"prop_37": Rect2(1, 197, 45, 41),        # Glowing Fairy Mushrooms (45x41)
	"prop_38": Rect2(128, 224, 31, 31),      # Swamp Spore / Lily Mire (31x31)
	"stairs": Rect2(417, 182, 31, 41)        # Twisted Root Stairs
}

# Exact 32x32 Tiles & Entire Props for Map 3: Village
const VILLAGE_TILES = {
	"floor_1": Rect2(0, 0, 32, 32),          # Cobblestone Street Floor
	"floor_2": Rect2(64, 64, 32, 32),        # Dirt Back-Alley Floor
	"floor_3": Rect2(128, 0, 32, 32),        # Wooden Timber Planks Floor
	"floor_4": Rect2(64, 0, 32, 32),         # Town Square Stone Paver Dais
	"path": Rect2(96, 0, 32, 32),            # Cobblestone Merchant Avenue
	"center": Rect2(160, 64, 32, 32),        # Town Square Well / Plaza Center
	"chasm": Rect2(128, 96, 32, 32),         # Flooded Cellar / Collapsed Trench
	"wall": Rect2(64, 0, 32, 32),            # Ruined Timber Cottage Wall Border
	
	"prop_30": Rect2(64, 197, 65, 59),       # Ruined Timber Cottage 1 (65x59)
	"prop_31": Rect2(0, 261, 65, 59),        # Ruined Timber Cottage 2 (65x59)
	"prop_32": Rect2(131, 195, 60, 62),      # Forsaken Village Manor (60x62)
	"prop_33": Rect2(304, 223, 32, 49),      # Wooden Picket Fence (Horizontal)
	"prop_34": Rect2(256, 224, 32, 48),      # Wooden Picket Fence (Vertical)
	"prop_35": Rect2(274, 120, 56, 39),      # Shattered Supply Wagon (56x39)
	"prop_36": Rect2(160, 280, 64, 40),      # Stone Town Water Well (64x40)
	"prop_37": Rect2(433, 120, 47, 41),      # Stack of Ale Kegs & Crates (47x41)
	"prop_38": Rect2(10, 131, 42, 58),       # Village Obelisk / Bell Shrine (42x58)
	"stairs": Rect2(337, 176, 31, 32)        # Cobble Steps / Cottage Threshold
}

var active_tiles: Dictionary = RUIN_TILES
var backdrop_color: Color = Color(0.0, 0.0, 0.0, 1.0)

func _ready() -> void:
	z_index = -50
	_setup_map_theme()
	_load_and_build_random_dungeon()

func rebuild_dungeon() -> void:
	for c in get_children():
		c.queue_free()
	
	ambient_particles = null
	verified_floor_points.clear()
	grid.clear()
	current_map_data.clear()
	_last_draw_pos = Vector2(INF, INF)
	
	_setup_map_theme()
	_load_and_build_random_dungeon()
	queue_redraw()

func _setup_map_theme() -> void:
	var tier = GameManager.current_map_tier
	match tier:
		1:
			tileset_texture = load("res://Sprite/Environment/ruined_tileset.png")
			active_tiles = RUIN_TILES
			backdrop_color = Color(0.01, 0.01, 0.02, 1.0)
			RenderingServer.set_default_clear_color(backdrop_color)
			_setup_particles(Color(0.7, 0.15, 0.15, 0.4), Vector2(0, -10), 40)
		2:
			tileset_texture = load("res://Sprite/Environment/Forest_tileset.png")
			active_tiles = FOREST_TILES
			backdrop_color = Color(0.015, 0.035, 0.02, 1.0)
			RenderingServer.set_default_clear_color(backdrop_color)
			_setup_particles(Color(0.35, 0.85, 0.45, 0.45), Vector2(10, 5), 55)
		3:
			tileset_texture = load("res://Sprite/Environment/Village_tileset.png")
			active_tiles = VILLAGE_TILES
			backdrop_color = Color(0.03, 0.025, 0.02, 1.0)
			RenderingServer.set_default_clear_color(backdrop_color)
			_setup_particles(Color(0.85, 0.65, 0.35, 0.35), Vector2(-5, -8), 45)
		_:
			tileset_texture = load("res://Sprite/Environment/ruined_tileset.png")
			active_tiles = RUIN_TILES
			backdrop_color = Color(0.0, 0.0, 0.0, 1.0)

func _setup_particles(p_color: Color, p_gravity: Vector2, p_amount: int) -> void:
	if is_instance_valid(ambient_particles):
		ambient_particles.queue_free()
		
	ambient_particles = CPUParticles2D.new()
	ambient_particles.z_index = -40
	ambient_particles.amount = p_amount
	ambient_particles.lifetime = 6.0
	ambient_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ambient_particles.emission_rect_extents = Vector2(900, 600)
	ambient_particles.gravity = p_gravity
	ambient_particles.scale_amount_min = 2.0
	ambient_particles.scale_amount_max = 5.0
	ambient_particles.color = p_color
	ambient_particles.direction = Vector2(1, -1)
	ambient_particles.spread = 45.0
	ambient_particles.initial_velocity_min = 10.0
	ambient_particles.initial_velocity_max = 25.0
	add_child(ambient_particles)

func _load_and_build_random_dungeon() -> void:
	var vault_path = "res://data/maps/ruin_dungeon_vault.json"
	match GameManager.current_map_tier:
		1: vault_path = "res://data/maps/ruin_dungeon_vault.json"
		2: vault_path = "res://data/maps/forest_dungeon_vault.json"
		3: vault_path = "res://data/maps/village_dungeon_vault.json"
		
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
	
	# GUARANTEE SAFE SANCTUARY CENTRAL PLAZA (NO CHASM / NO VOID / NO WALL AT SPAWN)
	var cx_tile = int(grid_width / 2)
	var cy_tile = int(grid_height / 2)
	var safe_r = 10
	for dy in range(-safe_r, safe_r + 1):
		for dx in range(-safe_r, safe_r + 1):
			var dist = sqrt(dx*dx + dy*dy)
			if dist <= safe_r:
				var gx = cx_tile + dx
				var gy = cy_tile + dy
				if gy >= 0 and gy < grid_height and gx >= 0 and gx < grid_width:
					var current_val = grid[gy][gx]
					if current_val == 0 or current_val == 10 or current_val == 7 or current_val >= 30:
						if dx == 0 and dy == 0:
							grid[gy][gx] = 6 # Center Sanctuary Node
						elif dist <= 4:
							grid[gy][gx] = 5 # Main Pathway
						else:
							grid[gy][gx] = 1 # Solid Walkable Floor
	
	# 1. Announce Realm Name and Lore to HUD
	var realm_name = ""
	var lore = ""
	match GameManager.current_map_tier:
		1:
			realm_name = "LIMINAL RUINS — CORRUPTED THRESHOLD"
			lore = "Distorted corridors and uncanny voids stretch into infinity under a motionless sky."
		2:
			realm_name = "UNCANNY GROVE — CORRUPTED WOODLANDS"
			lore = "Trees frozen in unnatural symmetry. Shadows mimic lost human voices in the mist."
		3:
			realm_name = "HOLLOW VALLEY — FORSAKEN SETTLEMENT"
			lore = "A silent ghost town trapped between dimensions; ground zero of the corruption."
		_:
			realm_name = map_blueprint.get("name", "CORRUPTED REALM")
			lore = map_blueprint.get("lore", "Survive the liminal horrors.")
	
	var prefix = "📍 TIER %d: " % GameManager.current_map_tier
	GameManager.wave_event_triggered.emit(prefix + realm_name, lore)
	
	# 2. Forward Mob Spawner sites to EnemySpawner
	var spawners = map_blueprint.get("mob_spawners", [])
	var enemy_spawner = get_tree().current_scene.find_child("EnemySpawner", true, false)
	if enemy_spawner:
		enemy_spawner.mob_spawner_sites = spawners
		
	# 3. Spawn Chasms / Water Ponds - STRICTLY FORBID NEAR SPAWN
	var chasm_script = load("res://scripts/AbyssalChasm.gd")
	var chasms = map_blueprint.get("chasms", [])
	for c_data in chasms:
		var c_pos = Vector2(c_data.get("x", 0), c_data.get("y", 0))
		if c_pos.length() < 750.0:
			continue
		var chasm = Node2D.new()
		chasm.set_script(chasm_script)
		add_child(chasm)
		chasm.setup(c_data)
		
	# 4. Spawn 4 Mythic Rune Shrines in 4 Far Quadrants
	var cardinal_shrines = map_blueprint.get("cardinal_shrines", [])
	for sh in cardinal_shrines:
		var fountain = Area2D.new()
		fountain.set_script(load("res://scripts/RuneFountain.gd"))
		fountain.rune_type = sh.get("elem", "ice")
		fountain.global_position = Vector2(sh.get("x", 0), sh.get("y", 0))
		add_child(fountain)

	# 5. Solid Wall & Void Collisions on Layer 1 (Obstacles)
	verified_floor_points.clear()
	if grid.size() > 0:
		var wall_body = StaticBody2D.new()
		wall_body.collision_layer = 1
		wall_body.collision_mask = 0
		add_child(wall_body)
		
		for y in range(grid_height):
			var span_start = -1
			for x in range(grid_width):
				var val = grid[y][x]
				# Non-walkable if Void (0), Solid Wall (10), or Chasm (7)
				var is_solid = (val == 0 or val == 10 or val == 7)
				
				if not is_solid and (x % 3 == 0 and y % 3 == 0):
					var fx = (x - grid_width/2.0 + 0.5) * tile_size
					var fy = (y - grid_height/2.0 + 0.5) * tile_size
					verified_floor_points.append(Vector2(fx, fy))
					
				if is_solid:
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

	# 6. Position Player on Guaranteed Safe Walkable Sanctuary Plaza
	var player = GameManager.player
	if not player and get_tree().current_scene:
		player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		player.global_position = Vector2.ZERO
		player.velocity = Vector2.ZERO
		if "external_force" in player:
			player.external_force = Vector2.ZERO

	queue_redraw()

func is_walkable_tile(world_pos: Vector2) -> bool:
	if grid.is_empty():
		return false
	var gx = int(floor((world_pos.x + half_w) / tile_size))
	var gy = int(floor((world_pos.y + half_h) / tile_size))
	if gx < 0 or gx >= grid_width or gy < 0 or gy >= grid_height:
		return false
	var val = grid[gy][gx]
	return val != 0 and val != 10 and val != 7

func get_closest_valid_floor_pos(pos: Vector2) -> Vector2:
	if verified_floor_points.is_empty():
		return pos
	var best_pos = verified_floor_points[0]
	var best_dist_sq = pos.distance_squared_to(best_pos)
	for fp in verified_floor_points:
		var d_sq = pos.distance_squared_to(fp)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			best_pos = fp
	return best_pos

func get_valid_floor_pos(target_pos: Vector2, fallback_pos: Vector2) -> Vector2:
	if is_walkable_tile(target_pos):
		return target_pos
	for r in range(1, 14):
		for angle_i in range(10):
			var a = (TAU / 10.0) * angle_i
			var test_pos = target_pos + Vector2(cos(a), sin(a)) * (r * tile_size * 0.5)
			if is_walkable_tile(test_pos):
				return test_pos
	if is_walkable_tile(fallback_pos):
		return fallback_pos
	return get_closest_valid_floor_pos(target_pos)

func _process(_delta: float) -> void:
	var player = GameManager.player
	var cam_pos = player.global_position if player else Vector2.ZERO
	if is_instance_valid(ambient_particles):
		ambient_particles.global_position = cam_pos
	if cam_pos.distance_squared_to(_last_draw_pos) > 144.0:
		_last_draw_pos = cam_pos
		queue_redraw()

func _draw() -> void:
	# Draw massive backdrop color matching map atmosphere
	draw_rect(Rect2(-30000, -30000, 60000, 60000), backdrop_color, true)
	
	if not tileset_texture or grid.is_empty():
		return
		
	var player = GameManager.player
	var center_pos = player.global_position if player else Vector2.ZERO
	
	# Viewport Culling (~1400x1000px)
	var view_margin = 180.0
	var min_x = int(clamp((center_pos.x - 700.0 - view_margin + half_w) / tile_size, 0, grid_width - 1))
	var max_x = int(clamp((center_pos.x + 700.0 + view_margin + half_w) / tile_size, 0, grid_width - 1))
	var min_y = int(clamp((center_pos.y - 500.0 - view_margin + half_h) / tile_size, 0, grid_height - 1))
	var max_y = int(clamp((center_pos.y + 500.0 + view_margin + half_h) / tile_size, 0, grid_height - 1))
	
	# Pass 1: Render Floors and Walls
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var val = grid[y][x]
			if val == 0:
				continue
				
			var dest_rect = Rect2((x - grid_width/2.0) * tile_size, (y - grid_height/2.0) * tile_size, tile_size, tile_size)
			
			if val == 1 or val >= 30:
				draw_texture_rect_region(tileset_texture, dest_rect, active_tiles["floor_1"])
			elif val == 2:
				draw_texture_rect_region(tileset_texture, dest_rect, active_tiles["floor_2"])
			elif val == 3:
				draw_texture_rect_region(tileset_texture, dest_rect, active_tiles["floor_3"])
			elif val == 4:
				draw_texture_rect_region(tileset_texture, dest_rect, active_tiles["floor_4"])
			elif val == 5:
				draw_texture_rect_region(tileset_texture, dest_rect, active_tiles["path"])
			elif val == 6:
				draw_texture_rect_region(tileset_texture, dest_rect, active_tiles["center"])
			elif val == 7:
				draw_texture_rect_region(tileset_texture, dest_rect, active_tiles["chasm"])
			elif val == 10:
				draw_texture_rect_region(tileset_texture, dest_rect, active_tiles["wall"])
			
	# Pass 2: Render Staircases & Entire Props
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var val = grid[y][x]
			if val < 30 and val != 41:
				continue
				
			var dest_base = Vector2((x - grid_width/2.0) * tile_size, (y - grid_height/2.0) * tile_size)
			var prop_key = ""
			if val == 41: prop_key = "stairs"
			elif val >= 30 and val <= 38: prop_key = "prop_%d" % val
			
			if prop_key != "" and active_tiles.has(prop_key):
				var p_rect: Rect2 = active_tiles[prop_key]
				# Scale from 32px base to tile_size (64px) = factor 2.0
				var pw = p_rect.size.x * 2.0
				var ph = p_rect.size.y * 2.0
				var dest_rect = Rect2(dest_base.x - (pw - tile_size) * 0.5, dest_base.y - (ph - tile_size), pw, ph)
				draw_texture_rect_region(tileset_texture, dest_rect, p_rect)
