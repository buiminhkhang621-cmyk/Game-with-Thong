extends Node2D
class_name RandomEventManager

var next_event_timer: float = 45.0 # First random event at 45s, then every 60-80s
var active_event_type: String = ""
var active_event_duration: float = 0.0

# Event state trackers
var meteor_timer: float = 0.0
var vortex_node: Node2D = null
var _bg_node: Node2D = null

func _ready() -> void:
	z_index = 50

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
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
		
	# Process active event
	if active_event_type != "":
		active_event_duration -= delta
		_process_active_event(delta)
		if active_event_duration <= 0.0:
			_end_active_event()
	else:
		# Count down to next random event (don't overlap with 10m boss)
		if GameManager.run_time < 580.0:
			next_event_timer -= delta
			if next_event_timer <= 0.0:
				next_event_timer = randf_range(65.0, 85.0)
				_trigger_random_event()

func _trigger_random_event() -> void:
	var events_pool = [
		"magic_silence",
		"meteor_rain",
		"void_vortex",
		"golden_goblin_rush",
		"blood_sacrifice",
		"abyssal_fog"
	]
	
	var chosen = events_pool[randi() % events_pool.size()]
	active_event_type = chosen
	
	match chosen:
		"magic_silence":
			active_event_duration = 10.0
			GameManager.weapons_disabled = true
			GameManager.wave_event_triggered.emit("TRIAL: MAGIC SILENCE", "All weapons jammed for 10s! +50% Speed & Jump Stomp activated!")
			
		"meteor_rain":
			active_event_duration = 16.0
			meteor_timer = 0.2
			GameManager.wave_event_triggered.emit("CATACLYSM: METEOR RAIN", "Infernal meteors bombard the arena from the heavens!")
			
		"void_vortex":
			active_event_duration = 14.0
			_spawn_void_vortex()
			GameManager.wave_event_triggered.emit("ANOMALY: VOID VORTEX", "A cosmic singularity pulls and crushes all entities!")
			
		"golden_goblin_rush":
			active_event_duration = 22.0
			_spawn_golden_goblins(3)
			GameManager.wave_event_triggered.emit("EVENT: GOLDEN GOBLIN RUSH", "3 Golden Goblins have appeared! Hunt them before they flee!")
			
		"blood_sacrifice":
			active_event_duration = 15.0
			GameManager.is_blood_sacrifice = true
			GameManager.wave_event_triggered.emit("TRIAL: BLOOD SACRIFICE", "+200% Might, but draining HP! Slay enemies to restore life!")
			
		"abyssal_fog":
			active_event_duration = 18.0
			GameManager.is_abyssal_fog = true
			GameManager.wave_event_triggered.emit("ENVIRONMENT: ABYSSAL FOG", "Thick darkness shrouds the realm! Enemies surge +25% speed!")

func _process_active_event(delta: float) -> void:
	match active_event_type:
		"meteor_rain":
			meteor_timer -= delta
			if meteor_timer <= 0.0:
				meteor_timer = randf_range(0.35, 0.55)
				_call_meteor()
				
		"void_vortex":
			if is_instance_valid(vortex_node):
				var v_pos = vortex_node.global_position
				for e in GameManager.active_enemies:
					if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
					var dist_sq = e.global_position.distance_squared_to(v_pos)
					if dist_sq < 380.0 * 380.0:
						var dir = (v_pos - e.global_position).normalized()
						e.global_position += dir * 180.0 * delta
						if dist_sq < 60.0 * 60.0 and e.has_method("take_damage"):
							e.take_damage(40.0 * delta)

func _end_active_event() -> void:
	match active_event_type:
		"magic_silence":
			GameManager.weapons_disabled = false
			GameManager.grant_xp(60) # Reward for surviving silence trial!
			GameManager.wave_event_triggered.emit("TRIAL CLEARED!", "Weapons restored! Awarded +60 Bonus XP!")
		"blood_sacrifice":
			GameManager.is_blood_sacrifice = false
		"abyssal_fog":
			GameManager.is_abyssal_fog = false
		"void_vortex":
			if is_instance_valid(vortex_node):
				vortex_node.queue_free()
				
	active_event_type = ""
	active_event_duration = 0.0

func _call_meteor() -> void:
	var player = GameManager.player
	if not player: return
	var raw_target = player.global_position + Vector2(randf_range(-300, 300), randf_range(-220, 220))
	var target_pos = _sanitize_pos(raw_target, player.global_position)
	
	var strike = Node2D.new()
	get_tree().current_scene.add_child(strike)
	strike.global_position = target_pos
	strike.set_script(load("res://scripts/MeteorStrike.gd"))

func _spawn_void_vortex() -> void:
	var player = GameManager.player
	if not player: return
	var raw_v_pos = player.global_position + Vector2(randf_range(-150, 150), randf_range(-150, 150))
	var v_pos = _sanitize_pos(raw_v_pos, player.global_position)
	
	vortex_node = Node2D.new()
	get_tree().current_scene.add_child(vortex_node)
	vortex_node.global_position = v_pos
	vortex_node.set_script(load("res://scripts/VoidVortexProp.gd"))

func _spawn_golden_goblins(count: int) -> void:
	var player = GameManager.player
	if not player: return
	for i in range(count):
		var angle = (TAU / count) * i + randf_range(-0.3, 0.3)
		var raw_pos = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(280.0, 360.0)
		var pos = _sanitize_pos(raw_pos, player.global_position)
		var e = load("res://scenes/EnemyCommon.tscn").instantiate()
		get_tree().current_scene.add_child(e)
		e.global_position = pos
		if e.has_method("setup_type"): e.setup_type("teleporter")
		e.speed *= 1.45
		e.max_hp *= 3.0
		e.hp = e.max_hp
		e.xp_value = 50
		e.color = Color(1.0, 0.85, 0.1) # Gilded Gold
		if e.has_node("AnimatedSprite2D"):
			e.get_node("AnimatedSprite2D").modulate = Color(1.0, 0.9, 0.2)
