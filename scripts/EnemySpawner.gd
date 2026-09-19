extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval_start: float = 0.85
@export var spawn_interval_min: float = 0.12
@export var max_enemies: int = 250
@export var spawn_radius: float = 580.0

var _timer: float = 0.0
var _current_wave_idx: int = -1
var _blood_moon_timer: float = 0.0
var _bg_node: Node2D = null
var mob_spawner_sites: Array = []

# Special Formation Timers
var _event_0m40_done: bool = false
var _event_1m20_done: bool = false
var _event_2m20_done: bool = false
var _event_3m20_done: bool = false
var _event_4m20_done: bool = false
var _event_5m00_done: bool = false
var _event_6m30_done: bool = false
var _event_7m30_done: bool = false
var _event_8m30_done: bool = false
var _boss_spawned: bool = false

# --- VAMPIRE SURVIVORS TIME-BASED WAVE DEFINITIONS ---
const WAVES = [
	{
		"start_time": 0.0,
		"end_time": 60.0,
		"wave_num": 1,
		"name": "WAVE 1: AWAKENED SKELETONS",
		"desc": "The ancient dead rise from the cold stone crypts.",
		"types": [
			{"type": "normal", "weight": 100}
		],
		"max_enemies": 45,
		"spawn_interval": 0.65,
		"batch_size": 2,
	},
	{
		"start_time": 60.0,
		"end_time": 120.0,
		"wave_num": 2,
		"name": "WAVE 2: THE SCUTTLING SWARM",
		"desc": "Fast abyssal crawlers surge from the dark edges!",
		"types": [
			{"type": "swarm", "weight": 70},
			{"type": "normal", "weight": 30}
		],
		"max_enemies": 70,
		"spawn_interval": 0.45,
		"batch_size": 3,
	},
	{
		"start_time": 120.0,
		"end_time": 180.0,
		"wave_num": 3,
		"name": "WAVE 3: THE CRYPT GOLEMS",
		"desc": "Heavy armored golems join the encroaching horde.",
		"types": [
			{"type": "tank_yellow", "weight": 40},
			{"type": "normal", "weight": 35},
			{"type": "swarm", "weight": 25}
		],
		"max_enemies": 95,
		"spawn_interval": 0.38,
		"batch_size": 4,
	},
	{
		"start_time": 180.0,
		"end_time": 240.0,
		"wave_num": 4,
		"name": "WAVE 4: NECROTIC MARKSMEN",
		"desc": "Bone snipers emerge at the perimeter to fire shards!",
		"types": [
			{"type": "sniper", "weight": 40},
			{"type": "normal", "weight": 35},
			{"type": "tank_yellow", "weight": 25}
		],
		"max_enemies": 125,
		"spawn_interval": 0.28,
		"batch_size": 4,
	},
	{
		"start_time": 240.0,
		"end_time": 300.0,
		"wave_num": 5,
		"name": "WAVE 5: KAMIKAZE DETONATORS",
		"desc": "Volatile ticking bombers sprint in suicidal charges!",
		"types": [
			{"type": "bomber", "weight": 40},
			{"type": "swarm", "weight": 35},
			{"type": "normal", "weight": 25}
		],
		"max_enemies": 150,
		"spawn_interval": 0.22,
		"batch_size": 5,
	},
	{
		"start_time": 300.0,
		"end_time": 390.0,
		"wave_num": 6,
		"name": "WAVE 6: THE EXECUTIONER LEGION",
		"desc": "Armored executioners advance with lethal strikes!",
		"types": [
			{"type": "tank_blue", "weight": 25},
			{"type": "tank_yellow", "weight": 30},
			{"type": "normal", "weight": 45}
		],
		"max_enemies": 175,
		"spawn_interval": 0.16,
		"batch_size": 5,
	},
	{
		"start_time": 390.0,
		"end_time": 480.0,
		"wave_num": 7,
		"name": "WAVE 7: PHANTOMS OF THE VOID",
		"desc": "Teleporting phantoms warp through space around you!",
		"types": [
			{"type": "teleporter", "weight": 35},
			{"type": "sniper", "weight": 25},
			{"type": "bomber", "weight": 20},
			{"type": "tank_blue", "weight": 20}
		],
		"max_enemies": 200,
		"spawn_interval": 0.13,
		"batch_size": 6,
	},
	{
		"start_time": 480.0,
		"end_time": 600.0,
		"wave_num": 8,
		"name": "WAVE 8: ARCH-SUMMONER CATACLYSM",
		"desc": "Necromancers rip open portals in backline formations!",
		"types": [
			{"type": "summoner", "weight": 15},
			{"type": "tank_blue", "weight": 25},
			{"type": "teleporter", "weight": 20},
			{"type": "sniper", "weight": 20},
			{"type": "swarm", "weight": 20}
		],
		"max_enemies": 220,
		"spawn_interval": 0.10,
		"batch_size": 6,
	},
	{
		"start_time": 600.0,
		"end_time": 999999.0,
		"wave_num": 9,
		"name": "FINAL WAVE: NECROMANCER OVERLORD",
		"desc": "The Supreme Overlord has arrived! Survive the end of days!",
		"types": [
			{"type": "tank_blue", "weight": 30},
			{"type": "summoner", "weight": 20},
			{"type": "bomber", "weight": 25},
			{"type": "teleporter", "weight": 25}
		],
		"max_enemies": 250,
		"spawn_interval": 0.08,
		"batch_size": 7,
	}
]

var event_mgr: RandomEventManager = null

func _ready() -> void:
	event_mgr = RandomEventManager.new()
	add_child(event_mgr)

func reset_spawner() -> void:
	_timer = 0.0
	_current_wave_idx = -1
	_blood_moon_timer = 0.0
	_event_0m40_done = false
	_event_1m20_done = false
	_event_2m20_done = false
	_event_3m20_done = false
	_event_4m20_done = false
	_event_5m00_done = false
	_event_6m30_done = false
	_event_7m30_done = false
	_event_8m30_done = false
	_boss_spawned = false
	if event_mgr and is_instance_valid(event_mgr):
		event_mgr.reset_events()

func _get_bg() -> Node2D:
	if not _bg_node or not is_instance_valid(_bg_node):
		if get_parent() and get_parent().has_node("Background"):
			_bg_node = get_parent().get_node("Background")
		elif get_tree() and get_tree().current_scene:
			_bg_node = get_tree().current_scene.find_child("Background", true, false)
	return _bg_node

func _sanitize_pos(target_pos: Vector2, fallback_pos: Vector2) -> Vector2:
	var bg = _get_bg()
	if bg:
		if bg.has_method("is_walkable_tile") and bg.is_walkable_tile(target_pos):
			return target_pos
		if bg.has_method("get_valid_floor_pos"):
			var checked = bg.get_valid_floor_pos(target_pos, fallback_pos)
			if bg.is_walkable_tile(checked):
				return checked
		if bg.has_method("get_closest_valid_floor_pos"):
			return bg.get_closest_valid_floor_pos(fallback_pos)
	return fallback_pos

func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup or GameManager.player == null:
		return
	if enemy_scene == null:
		return

	var run_time = GameManager.run_time
	_process_wave_progression(run_time)
	_process_special_events(delta, run_time)

	# Active Wave Spawning
	var wave = _get_current_wave(run_time)
	_timer += delta

	var interval: float = wave["spawn_interval"]
	if GameManager.is_blood_moon:
		interval *= 0.65

	var current_cap = wave["max_enemies"]
	var tier = GameManager.current_map_tier
	if tier == 1: current_cap = int(current_cap * 0.85)
	elif tier == 3: current_cap = int(current_cap * 1.3)
	if GameManager.is_blood_moon: current_cap += 50

	if _timer >= interval and GameManager.active_enemies.size() < current_cap:
		_timer = 0.0
		var batch = wave["batch_size"]
		if GameManager.is_blood_moon: batch += 2
		
		for i in range(batch):
			if GameManager.active_enemies.size() >= current_cap:
				break
			_spawn_wave_enemy(wave)

func _get_current_wave(run_time: float) -> Dictionary:
	for w in WAVES:
		if run_time >= w["start_time"] and run_time < w["end_time"]:
			return w
	return WAVES[WAVES.size() - 1]

func _process_wave_progression(run_time: float) -> void:
	for idx in range(WAVES.size()):
		var w = WAVES[idx]
		if run_time >= w["start_time"] and run_time < w["end_time"]:
			if _current_wave_idx != idx:
				_current_wave_idx = idx
				# Announce new wave to player HUD!
				GameManager.wave_event_triggered.emit(w["name"], w["desc"])
			break

func _spawn_wave_enemy(wave: Dictionary) -> void:
	var player = GameManager.player
	if not player: return

	# 1. 360-degree perimeter spawn outside camera view (Vampire Survivors style!)
	var angle = randf() * TAU
	var rx = randf_range(580.0, 720.0)
	var ry = randf_range(380.0, 500.0)
	var raw_pos = player.global_position + Vector2(cos(angle) * rx, sin(angle) * ry)
	var pos = _sanitize_pos(raw_pos, player.global_position)

	# 2. Pick enemy type according to wave pool weights
	var type_pool = wave["types"]
	var total_w = 0.0
	for p in type_pool: total_w += p.weight
	var r = randf_range(0.0, total_w)
	var chosen_type = "normal"
	for p in type_pool:
		r -= p.weight
		if r <= 0:
			chosen_type = p.type
			break

	var e = enemy_scene.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = pos

	if e.has_method("setup_type"):
		e.setup_type(chosen_type)

	var tier = GameManager.current_map_tier
	var hp_mult = 1.0 if tier == 1 else (1.45 if tier == 2 else 1.95)
	if e.has_method("setup_evolution"):
		e.setup_evolution(GameManager.run_time, hp_mult)

	# Dynamic Elite Infiltration (Elites become increasingly common and intimidating)
	var t_minutes = GameManager.run_time / 60.0
	var elite_chance = clampf(0.04 + t_minutes * 0.035, 0.04, 0.32)
	if chosen_type != "boss" and chosen_type != "golden_goblin" and randf() < elite_chance:
		e.is_elite = true
		e.scale *= 1.28
		e.max_hp *= 2.2
		e.hp = e.max_hp
		e.contact_dps *= 1.5
		e.armor = min(0.80, e.armor + 0.18)
		e.color = Color(1.3, 0.95, 0.35)
		if e.get_node_or_null("AnimatedSprite2D"):
			e.get_node("AnimatedSprite2D").modulate = Color(1.3, 0.95, 0.35)

# --- VAMPIRE SURVIVORS SPECIAL EVENTS & FORMATIONS ---
func _process_special_events(delta: float, t: float) -> void:
	# Blood Moon countdown
	if GameManager.is_blood_moon:
		_blood_moon_timer -= delta
		if _blood_moon_timer <= 0.0:
			GameManager.is_blood_moon = false
			GameManager.blood_moon_state_changed.emit(false)

	# 0:40 - Early Skeleton Ring Encirclement
	if t >= 40.0 and not _event_0m40_done:
		_event_0m40_done = true
		GameManager.wave_event_triggered.emit("FORMATION: SKELETON RING", "A circle of crypt skeletons surrounds you!")
		_spawn_ring(18, "normal", 440.0)

	# 1:20 - Fast Swarm Wave Rush (From left or right side)
	if t >= 80.0 and not _event_1m20_done:
		_event_1m20_done = true
		GameManager.wave_event_triggered.emit("EVENT: SWARM RUSH", "A scuttling swarm charges from the darkness!")
		_spawn_swarm_rush(26)

	# 2:20 - Golem Wall March
	if t >= 140.0 and not _event_2m20_done:
		_event_2m20_done = true
		GameManager.wave_event_triggered.emit("FORMATION: GOLEM WALL", "Armored stone titans advance in formation!")
		_spawn_wall(16, "tank_yellow")

	# 3:20 - Sniper Firing Squad
	if t >= 200.0 and not _event_3m20_done:
		_event_3m20_done = true
		GameManager.wave_event_triggered.emit("EVENT: SNIPER BRIGADE", "Necrotic marksmen emerge at perimeter!")
		_spawn_sniper_squad(14)

	# 4:20 - Volatile Bomber Encirclement
	if t >= 260.0 and not _event_4m20_done:
		_event_4m20_done = true
		GameManager.wave_event_triggered.emit("EVENT: KAMIKAZE AMBUSH", "Detonators enclose with ticking fuses!")
		_spawn_ring(16, "bomber", 460.0)

	# 5:00 - Mini-Boss The Executioner
	if t >= 300.0 and not _event_5m00_done:
		_event_5m00_done = true
		GameManager.wave_event_triggered.emit("MINI-BOSS: THE EXECUTIONER", "An elite blue armored champion challenges you!")
		_spawn_mini_boss("tank_blue", "The Executioner")
		_spawn_ring(20, "normal", 420.0)

	# 6:30 - Phantom Warp Wave
	if t >= 390.0 and not _event_6m30_done:
		_event_6m30_done = true
		GameManager.wave_event_triggered.emit("EVENT: PHANTOM INVASION", "Teleporting entities disrupt reality!")
		_spawn_ring(16, "teleporter", 400.0)

	# 7:30 - Blood Moon Rises
	if t >= 450.0 and not _event_7m30_done:
		_event_7m30_done = true
		GameManager.is_blood_moon = true
		_blood_moon_timer = 45.0
		GameManager.blood_moon_state_changed.emit(true)
		GameManager.wave_event_triggered.emit("EVENT: BLOOD MOON RISES", "Horde movement speed and spawns surge to maximum!")
		_spawn_swarm_rush(36)

	# 8:30 - Mini-Boss Void Summoner
	if t >= 510.0 and not _event_8m30_done:
		_event_8m30_done = true
		GameManager.wave_event_triggered.emit("MINI-BOSS: VOID SUMMONER", "An arch-necromancer manifests with dark portals!")
		_spawn_mini_boss("summoner", "Void Summoner")

	# 10:00 - Final Boss
	if t >= 600.0 and not _boss_spawned:
		_boss_spawned = true
		GameManager.wave_event_triggered.emit("FINAL BOSS: NECROMANCER OVERLORD", "Survive the cataclysmic final trial!")
		_spawn_boss()

func _spawn_ring(count: int, mob_type: String, radius: float = 450.0) -> void:
	var player = GameManager.player
	if not player: return
	var bg = _get_bg()
	for i in range(count):
		var angle = (TAU / count) * i
		var raw_pos = player.global_position + Vector2(cos(angle), sin(angle)) * radius
		var pos = _sanitize_pos(raw_pos, player.global_position)
		if pos.distance_squared_to(player.global_position) < 180.0 * 180.0:
			continue
		if bg and bg.has_method("is_walkable_tile") and not bg.is_walkable_tile(pos):
			continue
		var e = enemy_scene.instantiate()
		get_tree().current_scene.add_child(e)
		e.global_position = pos
		if e.has_method("setup_type"): e.setup_type(mob_type)
		if e.has_method("setup_evolution"): e.setup_evolution(GameManager.run_time, 1.0)

func _spawn_wall(count: int, mob_type: String) -> void:
	var player = GameManager.player
	if not player: return
	var bg = _get_bg()
	# Choose left, right, top, or bottom
	var side = randi() % 4
	var base_offset = Vector2.ZERO
	var span_axis = Vector2.ZERO
	match side:
		0: # Top
			base_offset = Vector2(0, -480)
			span_axis = Vector2(1, 0)
		1: # Bottom
			base_offset = Vector2(0, 480)
			span_axis = Vector2(1, 0)
		2: # Left
			base_offset = Vector2(-680, 0)
			span_axis = Vector2(0, 1)
		3: # Right
			base_offset = Vector2(680, 0)
			span_axis = Vector2(0, 1)

	var spacing = 45.0
	var start_p = player.global_position + base_offset - span_axis * ((count - 1) * spacing * 0.5)
	for i in range(count):
		var raw_pos = start_p + span_axis * (i * spacing)
		var pos = _sanitize_pos(raw_pos, player.global_position)
		if pos.distance_squared_to(player.global_position) < 180.0 * 180.0:
			continue
		if bg and bg.has_method("is_walkable_tile") and not bg.is_walkable_tile(pos):
			continue
		var e = enemy_scene.instantiate()
		get_tree().current_scene.add_child(e)
		e.global_position = pos
		if e.has_method("setup_type"): e.setup_type(mob_type)
		if e.has_method("setup_evolution"): e.setup_evolution(GameManager.run_time, 1.0)

func _spawn_swarm_rush(count: int) -> void:
	var player = GameManager.player
	if not player: return
	var bg = _get_bg()
	var side_dir = Vector2.LEFT if randf() < 0.5 else Vector2.RIGHT
	var base_p = player.global_position + side_dir * 650.0
	for i in range(count):
		var raw_pos = base_p + Vector2(randf_range(-60, 60), randf_range(-300, 300))
		var pos = _sanitize_pos(raw_pos, player.global_position)
		if pos.distance_squared_to(player.global_position) < 180.0 * 180.0:
			continue
		if bg and bg.has_method("is_walkable_tile") and not bg.is_walkable_tile(pos):
			continue
		var e = enemy_scene.instantiate()
		get_tree().current_scene.add_child(e)
		e.global_position = pos
		if e.has_method("setup_type"): e.setup_type("swarm")
		if e.has_method("setup_evolution"): e.setup_evolution(GameManager.run_time, 1.0)

func _spawn_sniper_squad(count: int) -> void:
	var player = GameManager.player
	if not player: return
	var bg = _get_bg()
	for i in range(count):
		var angle = (TAU / count) * i
		var raw_pos = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(440.0, 560.0)
		var pos = _sanitize_pos(raw_pos, player.global_position)
		if pos.distance_squared_to(player.global_position) < 180.0 * 180.0:
			continue
		if bg and bg.has_method("is_walkable_tile") and not bg.is_walkable_tile(pos):
			continue
		var e = enemy_scene.instantiate()
		get_tree().current_scene.add_child(e)
		e.global_position = pos
		if e.has_method("setup_type"): e.setup_type("sniper")
		if e.has_method("setup_evolution"): e.setup_evolution(GameManager.run_time, 1.1)

func _spawn_mini_boss(base_type: String, _boss_name: String) -> void:
	var player = GameManager.player
	if not player: return
	var bg = _get_bg()
	var angle = randf() * TAU
	var raw_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 380.0
	var pos = _sanitize_pos(raw_pos, player.global_position)
	if bg and bg.has_method("is_walkable_tile") and not bg.is_walkable_tile(pos):
		pos = bg.get_closest_valid_floor_pos(pos)
	var e = enemy_scene.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = pos
	if e.has_method("setup_type"): e.setup_type(base_type)
	e.enemy_type = "mini_boss"
	if e.has_method("setup_evolution"): e.setup_evolution(GameManager.run_time, 3.2)
	e.max_hp *= 4.5
	e.hp = e.max_hp
	e.contact_dps *= 2.2
	e.scale *= 1.55
	if e.has_node("AnimatedSprite2D"):
		e.get_node("AnimatedSprite2D").modulate = Color(1.3, 0.35, 0.35)

func _spawn_boss() -> void:
	var player = GameManager.player
	if not player: return
	var angle := randf() * TAU
	var raw_pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * 320.0
	var pos: Vector2 = _sanitize_pos(raw_pos, player.global_position)
	
	var e = enemy_scene.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = pos
	
	if e.has_method("setup_type"):
		e.setup_type("boss")
		
	var tier: int = GameManager.current_map_tier
	var hp_mult = 1.0 if tier == 1 else (1.6 if tier == 2 else 2.4)
	
	if e.has_method("setup_evolution"):
		e.setup_evolution(GameManager.run_time, hp_mult * 10.0)
	GameManager.boss_spawned.emit()
