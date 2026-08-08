extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval_start: float = 1.0
@export var spawn_interval_min: float = 0.1
@export var max_enemies: int = 250
@export var spawn_radius: float = 400.0

var _timer: float = 0.0

func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup or GameManager.player == null:
		return
	if enemy_scene == null:
		return

	_timer += delta
	var interval: float = max(spawn_interval_min, spawn_interval_start - GameManager.run_time * 0.005)

	var tier: int = GameManager.current_map_tier
	var actual_max_enemies: int = max_enemies
	if tier == 1: actual_max_enemies = 150
	elif tier == 3: actual_max_enemies = 400
	
	if _timer >= interval and get_tree().get_nodes_in_group("enemies").size() < actual_max_enemies:
		_timer = 0.0
		var batch_size = 1 + int(GameManager.run_time / 60.0) * (2 if tier < 3 else 3)
		for i in range(batch_size):
			if get_tree().get_nodes_in_group("enemies").size() >= actual_max_enemies:
				break
			_spawn()

func _spawn() -> void:
	var angle := randf() * TAU
	var pos: Vector2 = GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius

	var e = enemy_scene.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	# Determine type based on time
	var t_minutes = GameManager.run_time / 60.0
	var type_pool = [{"type": "normal", "weight": 100.0}]
	
	if t_minutes >= 1.0:
		type_pool.append({"type": "swarm", "weight": 40.0})
	if t_minutes >= 3.0:
		type_pool.append({"type": "tank", "weight": 20.0})
		type_pool.append({"type": "sniper", "weight": 20.0})
	if t_minutes >= 4.0:
		type_pool.append({"type": "teleporter", "weight": 15.0})
	if t_minutes >= 5.0:
		type_pool.append({"type": "summoner", "weight": 10.0})
	if t_minutes >= 6.0:
		type_pool.append({"type": "bomber", "weight": 15.0})
		
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
	
	e.max_hp = (e.max_hp + floor(GameManager.run_time / 30.0) * 3.0) * hp_mult
	e.hp = e.max_hp
