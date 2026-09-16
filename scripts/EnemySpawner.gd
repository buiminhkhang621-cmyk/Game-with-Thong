extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval_start: float = 1.0
@export var spawn_interval_min: float = 0.1
@export var max_enemies: int = 125
@export var spawn_radius: float = 400.0

var _timer: float = 0.0
var _boss_spawned: bool = false
var _event_2m_done: bool = false
var _event_4m_done: bool = false
var _event_6m_done: bool = false
var _event_7m30_done: bool = false
var _event_8m30_done: bool = false
var _blood_moon_timer: float = 0.0
var _bg_node: Node2D = null

func _ready() -> void:
	var event_mgr = RandomEventManager.new()
	add_child(event_mgr)

func _get_bg() -> Node2D:
	if not _bg_node or not is_instance_valid(_bg_node):
		_bg_node = get_tree().current_scene.find_child("Background", true, false)
	return _bg_node

func _sanitize_pos(target_pos: Vector2, fallback_pos: Vector2) -> Vector2:
	var bg = _get_bg()
	if bg and bg.has_method("get_valid_floor_pos"):
		return bg.get_valid_floor_pos(target_pos, fallback_pos)
	return target_pos

func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup or GameManager.player == null:
		return
	if enemy_scene == null:
		return

	_process_events(delta)

	_timer += delta
	var t_minutes = GameManager.run_time / 60.0
	
	# Progressive spawn interval: slow at start (1.4s), hyper-dense late game (0.12s)
	var base_interval = 1.4
	if t_minutes < 1.5:
		base_interval = 1.4 - t_minutes * 0.4
	elif t_minutes < 5.0:
		base_interval = 0.8 - (t_minutes - 1.5) * 0.12
	else:
		base_interval = max(0.12, 0.38 - (t_minutes - 5.0) * 0.05)

	var speed_mult = 1.6 if GameManager.is_blood_moon else 1.0
	var interval: float = max(spawn_interval_min, base_interval / speed_mult)

	var tier: int = GameManager.current_map_tier
	var actual_max_enemies: int = 40 + int(t_minutes * 22.0)
	if tier == 1: actual_max_enemies = int(actual_max_enemies * 0.75)
	elif tier == 3: actual_max_enemies = int(actual_max_enemies * 1.35)
	if GameManager.is_blood_moon: actual_max_enemies += 50
	
	if _timer >= interval and GameManager.active_enemies.size() < actual_max_enemies:
		_timer = 0.0
		var batch_size = 1
		if t_minutes < 1.0: batch_size = 1
		elif t_minutes < 2.5: batch_size = 2
		elif t_minutes < 5.0: batch_size = 4
		elif t_minutes < 7.5: batch_size = 7
		else: batch_size = 12
		
		if tier == 3: batch_size += 2
		if GameManager.is_blood_moon: batch_size = int(batch_size * 1.8)
		
		for i in range(batch_size):
			if GameManager.active_enemies.size() >= actual_max_enemies:
				break
			_spawn()

func _process_events(delta: float) -> void:
	var t = GameManager.run_time
	
	# Blood Moon countdown
	if GameManager.is_blood_moon:
		_blood_moon_timer -= delta
		if _blood_moon_timer <= 0.0:
			GameManager.is_blood_moon = false
			GameManager.blood_moon_state_changed.emit(false)
	
	# 2:00 - Swarm Surge
	if t >= 120.0 and not _event_2m_done:
		_event_2m_done = true
		GameManager.wave_event_triggered.emit("EVENT: SWARM SURGE", "A massive insect horde approaches from all sides!")
		_spawn_swarm_ring(35)
		
	# 4:00 - Death Encirclement
	if t >= 240.0 and not _event_4m_done:
		_event_4m_done = true
		GameManager.wave_event_triggered.emit("EVENT: DEATH ENCIRCLEMENT", "Armored vanguards form a tightening ring!")
		_spawn_tank_encirclement(16)
		
	# 6:00 - Mini-Boss Executioner
	if t >= 360.0 and not _event_6m_done:
		_event_6m_done = true
		GameManager.wave_event_triggered.emit("MINI-BOSS: THE EXECUTIONER", "An elite warrior approaches with heavy blade!")
		_spawn_mini_boss("tank_blue", "The Executioner")
		
	# 7:30 - Blood Moon Rises
	if t >= 450.0 and not _event_7m30_done:
		_event_7m30_done = true
		GameManager.is_blood_moon = true
		_blood_moon_timer = 35.0
		GameManager.blood_moon_state_changed.emit(true)
		GameManager.wave_event_triggered.emit("EVENT: BLOOD MOON RISES", "Horde movement speed and spawns surge for 35 seconds!")
		
	# 8:30 - Mini-Boss Void Summoner
	if t >= 510.0 and not _event_8m30_done:
		_event_8m30_done = true
		GameManager.wave_event_triggered.emit("MINI-BOSS: VOID SUMMONER", "An arch-necromancer manifests with dark portals!")
		_spawn_mini_boss("summoner", "Void Summoner")
		
	# 10:00 - Final Boss
	if t >= 600.0 and not _boss_spawned:
		_boss_spawned = true
		GameManager.wave_event_triggered.emit("FINAL BOSS: NECROMANCER OVERLORD", "Survive the cataclysmic trial!")
		_spawn_boss()

func _spawn_swarm_ring(count: int) -> void:
	var player = GameManager.player
	if not player: return
	for i in range(count):
		var angle = (TAU / count) * i
		var raw_pos = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(380.0, 480.0)
		var pos = _sanitize_pos(raw_pos, player.global_position)
		var e = enemy_scene.instantiate()
		get_tree().current_scene.add_child(e)
		e.global_position = pos
		if e.has_method("setup_type"): e.setup_type("swarm")
		if e.has_method("setup_evolution"): e.setup_evolution(GameManager.run_time, 1.0)

func _spawn_tank_encirclement(count: int) -> void:
	var player = GameManager.player
	if not player: return
	for i in range(count):
		var angle = (TAU / count) * i
		var raw_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 420.0
		var pos = _sanitize_pos(raw_pos, player.global_position)
		var e = enemy_scene.instantiate()
		get_tree().current_scene.add_child(e)
		e.global_position = pos
		if e.has_method("setup_type"): e.setup_type("tank_yellow")
		if e.has_method("setup_evolution"): e.setup_evolution(GameManager.run_time, 1.0)

func _spawn_mini_boss(base_type: String, _boss_name: String) -> void:
	var player = GameManager.player
	if not player: return
	var angle = randf() * TAU
	var raw_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 300.0
	var pos = _sanitize_pos(raw_pos, player.global_position)
	var e = enemy_scene.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = pos
	if e.has_method("setup_type"): e.setup_type(base_type)
	e.enemy_type = "mini_boss"
	if e.has_method("setup_evolution"): e.setup_evolution(GameManager.run_time, 2.0)
	e.max_hp *= 3.0
	e.hp = e.max_hp
	e.scale *= 1.4
	if e.has_node("AnimatedSprite2D"):
		e.get_node("AnimatedSprite2D").modulate = Color(1.0, 0.35, 0.35)

var mob_spawner_sites: Array = []

func _spawn() -> void:
	var player = GameManager.player
	if not player: return
	
	var pos: Vector2 = Vector2.ZERO
	var preferred_type = ""
	
	# Try to find nearby AI spawner site (distance between 250px and 700px)
	var candidate_spawners = []
	for sp in mob_spawner_sites:
		var sp_pos = Vector2(sp.get("x", 0), sp.get("y", 0))
		var d = player.global_position.distance_to(sp_pos)
		if d >= 220.0 and d <= 750.0:
			candidate_spawners.append(sp)
			
	if candidate_spawners.size() > 0 and randf() < 0.65:
		var chosen = candidate_spawners[randi() % candidate_spawners.size()]
		var raw_pos = Vector2(chosen.get("x", 0), chosen.get("y", 0)) + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		pos = _sanitize_pos(raw_pos, player.global_position)
		preferred_type = chosen.get("type", "")
	else:
		var angle := randf() * TAU
		var raw_pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		pos = _sanitize_pos(raw_pos, player.global_position)

	var e = enemy_scene.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = pos
	
	# Determine type based on time
	var t_minutes = GameManager.run_time / 60.0
	var type_pool = [{"type": "normal", "weight": 100.0}]
	
	if t_minutes >= 0.8:
		type_pool.append({"type": "swarm", "weight": 45.0})
	if t_minutes >= 1.5:
		type_pool.append({"type": "sniper", "weight": 25.0})
		type_pool.append({"type": "tank_yellow", "weight": 10.0})
	if t_minutes >= 2.0:
		type_pool.append({"type": "bomber", "weight": 25.0})
		type_pool.append({"type": "teleporter", "weight": 20.0})
	if t_minutes >= 3.0:
		type_pool.append({"type": "summoner", "weight": 18.0})
		type_pool.append({"type": "tank_blue", "weight": 8.0})
		
	var total_weight = 0.0
	for p in type_pool: total_weight += p.weight
	var r = randf_range(0, total_weight)
	var selected_type = "normal"
	for p in type_pool:
		r -= p.weight
		if r <= 0:
			selected_type = p.type
			break
			
	if e.has_method("setup_type"):
		e.setup_type(selected_type)

	var tier: int = GameManager.current_map_tier
	var hp_mult = 1.0
	if tier == 1: hp_mult = 0.8
	elif tier == 3: hp_mult = 1.5
	
	if e.has_method("setup_evolution"):
		e.setup_evolution(GameManager.run_time, hp_mult)

func _spawn_boss() -> void:
	var angle := randf() * TAU
	var raw_pos: Vector2 = GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * 250.0
	var pos: Vector2 = _sanitize_pos(raw_pos, GameManager.player.global_position)
	
	var e = enemy_scene.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = pos
	
	if e.has_method("setup_type"):
		e.setup_type("boss")
		
	var tier: int = GameManager.current_map_tier
	var hp_mult = 1.0
	if tier == 1: hp_mult = 0.8
	elif tier == 3: hp_mult = 1.5
	
	if e.has_method("setup_evolution"):
		e.setup_evolution(GameManager.run_time, hp_mult * 8.0)
	GameManager.boss_spawned.emit()
