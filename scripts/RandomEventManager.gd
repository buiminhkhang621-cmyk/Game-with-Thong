extends Node2D
class_name RandomEventManager

var next_event_timer: float = 45.0 # First random event at 45s, then every 65-85s
var active_event_type: String = ""
var active_event_duration: float = 0.0

var meteor_timer: float = 0.0
var vortex_node: Node2D = null
var _bg_node: Node2D = null
var _vortex_player_dmg_timer: float = 0.0

func _ready() -> void:
	z_index = 50

func _exit_tree() -> void:
	if active_event_type != "":
		_end_active_event()

func reset_events() -> void:
	next_event_timer = 45.0
	if active_event_type != "":
		_end_active_event()
	active_event_type = ""
	active_event_duration = 0.0

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
	if GameManager.game_over:
		if active_event_type != "":
			_end_active_event()
		return

	if GameManager.paused_for_levelup:
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
			meteor_timer = 0.6
			GameManager.wave_event_triggered.emit("CATACLYSM: METEOR RAIN", "Infernal meteors bombard the arena from the heavens!")
			
		"void_vortex":
			active_event_duration = 14.0
			_spawn_void_vortex()
			GameManager.wave_event_triggered.emit("ANOMALY: VOID VORTEX", "A cosmic singularity pulls and crushes nearby entities!")
			
		"golden_goblin_rush":
			active_event_duration = 22.0
			_spawn_golden_goblins(3)
			GameManager.wave_event_triggered.emit("EVENT: GOLDEN GOBLIN RUSH", "3 Golden Goblins appeared! Slay them before they flee for rich treasure!")
			
		"blood_sacrifice":
			active_event_duration = 15.0
			GameManager.is_blood_sacrifice = true
			GameManager.wave_event_triggered.emit("TRIAL: BLOOD SACRIFICE", "+200% Might, but draining HP! Slay enemies to restore life!")
			
		"abyssal_fog":
			active_event_duration = 18.0
			GameManager.is_abyssal_fog = true
			GameManager.abyssal_fog_state_changed.emit(true)
			GameManager.wave_event_triggered.emit("ENVIRONMENT: ABYSSAL FOG", "Thick darkness shrouds the realm! Enemies surge +25% speed!")

func _process_active_event(delta: float) -> void:
	match active_event_type:
		"meteor_rain":
			meteor_timer -= delta
			if meteor_timer <= 0.0:
				meteor_timer = randf_range(1.1, 1.6)
				_call_meteor()
				# 40% chance for a second staggered meteor
				if randf() < 0.40 and get_tree():
					get_tree().create_timer(0.25).timeout.connect(_call_meteor)
				
		"void_vortex":
			if is_instance_valid(vortex_node):
				var v_pos = vortex_node.global_position
				var player = GameManager.player
				
				# 1. Gravitational pull & crushing void damage on Player
				if is_instance_valid(player) and not GameManager.game_over:
					var p_dist = player.global_position.distance_to(v_pos)
					if p_dist < 360.0:
						var p_dir = (v_pos - player.global_position).normalized()
						var pull_factor = clampf(1.0 - (p_dist / 360.0), 0.0, 1.0)
						# Fair pull speed (player moves at ~120, so they can escape or jump)
						var pull_speed = lerpf(45.0, 110.0, pull_factor)
						if "external_force" in player:
							player.external_force = p_dir * pull_speed
						else:
							player.global_position += p_dir * (pull_speed * delta)
							
						# Inside event horizon core (< 60px): Crushing void singularity damage
						if p_dist < 60.0:
							_vortex_player_dmg_timer -= delta
							if _vortex_player_dmg_timer <= 0.0:
								_vortex_player_dmg_timer = 0.55
								player.take_damage(14.0, false) # Void crush
								player._shake_intensity = max(player._shake_intensity, 8.0)
					else:
						if "external_force" in player:
							player.external_force = player.external_force.move_toward(Vector2.ZERO, 300.0 * delta)

				# 2. Pull Enemies, damage them in core
				for e in GameManager.active_enemies.duplicate():
					if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
					var dist_sq = e.global_position.distance_squared_to(v_pos)
					if dist_sq < 360.0 * 360.0:
						var dir = (v_pos - e.global_position).normalized()
						var e_pull_speed = 150.0
						e.global_position += dir * e_pull_speed * delta
						
						# Sucked-in enemies take crushing damage in center
						if dist_sq < 60.0 * 60.0 and e.has_method("take_damage"):
							e.take_damage(50.0 * delta)

		"blood_sacrifice":
			var player = GameManager.player
			if is_instance_valid(player) and not GameManager.game_over:
				# Drain 3.5 HP per second, but leave at minimum 1 HP (won't kill by drain alone)
				if player.hp > 1.0:
					player.hp = max(1.0, player.hp - 3.5 * delta)
					GameManager.hp_changed.emit(player.hp, player._effective_max_hp)

func _end_active_event() -> void:
	match active_event_type:
		"magic_silence":
			GameManager.weapons_disabled = false
			GameManager.grant_xp(25) # Reward for surviving silence trial!
			GameManager.wave_event_triggered.emit("TRIAL CLEARED!", "Weapons restored! Awarded +25 Bonus XP!")
		"blood_sacrifice":
			GameManager.is_blood_sacrifice = false
			GameManager.wave_event_triggered.emit("SACRIFICE CONCLUDED", "Blood pact ended. Health stabilized!")
		"abyssal_fog":
			GameManager.is_abyssal_fog = false
			GameManager.abyssal_fog_state_changed.emit(false)
			GameManager.wave_event_triggered.emit("FOG DISSIPATED", "The abyssal mist clears. Enemy speed normalized.")
		"void_vortex":
			if is_instance_valid(vortex_node):
				vortex_node.queue_free()
				vortex_node = null
			if GameManager.player and "external_force" in GameManager.player:
				GameManager.player.external_force = Vector2.ZERO
			_vortex_player_dmg_timer = 0.0
		"golden_goblin_rush":
			# Any surviving golden goblins escape into the abyss!
			var escaped_count = 0
			for e in GameManager.active_enemies.duplicate():
				if is_instance_valid(e) and not e.is_queued_for_deletion() and e.get("enemy_type") == "golden_goblin":
					escaped_count += 1
					var p = load("res://scenes/DeathParticle.tscn").instantiate()
					if p:
						p.position = e.global_position
						p.modulate = Color(1.0, 0.85, 0.2)
						get_tree().current_scene.add_child(p)
					e.queue_free()
			if escaped_count > 0:
				GameManager.wave_event_triggered.emit("GOBLINS ESCAPED!", str(escaped_count) + " Golden Goblin(s) burrowed back into the shadows!")
				
	active_event_type = ""
	active_event_duration = 0.0

func _call_meteor() -> void:
	var player = GameManager.player
	if not player or GameManager.game_over: return
	var raw_target = player.global_position + Vector2(randf_range(-280, 280), randf_range(-200, 200))
	var target_pos = _sanitize_pos(raw_target, player.global_position)
	
	var strike = load("res://scripts/MeteorStrike.gd").new()
	strike.global_position = target_pos
	get_tree().current_scene.add_child(strike)

func _spawn_void_vortex() -> void:
	var player = GameManager.player
	if not player: return
	# Spawn at a medium distance (240-320px) so player is NOT immediately inside the core!
	var angle = randf() * TAU
	var dist = randf_range(240.0, 320.0)
	var raw_v_pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var v_pos = _sanitize_pos(raw_v_pos, player.global_position)
	
	vortex_node = load("res://scripts/VoidVortexProp.gd").new()
	vortex_node.global_position = v_pos
	get_tree().current_scene.add_child(vortex_node)

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
		if e.has_method("setup_type"): e.setup_type("golden_goblin")
