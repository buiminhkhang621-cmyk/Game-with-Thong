extends Node2D

@onready var player: Node2D = get_parent()

var _last_fire_time: Dictionary = {}
var _hit_cooldowns: Dictionary = {}

const PROJECTILE_SCENE := preload("res://scenes/Projectile.tscn")


func _process(_delta: float) -> void:
	if not GameManager.game_over and not GameManager.paused_for_levelup:
		for s in GameManager.active_skills:
			var data: SkillData = s.data
			var level: int = s.level
			match data.skill_type:
				"orbit":
					_fire_orbit(data, level)
				"projectile":
					_fire_projectile(data, level)
				"nova":
					_fire_nova(data, level)
				"aoe":
					_fire_aoe(data, level)
	queue_redraw()


func _blade_count(level: int) -> int:
	return 1 + int(level / 2.0)


func _fire_orbit(data: SkillData, level: int) -> void:
	var count := _blade_count(level)
	var radius: float = data.base_radius + data.radius_per_level * level
	var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	var t := Time.get_ticks_msec() / 1000.0
	var spin := t * 3.4

	for i in range(count):
		var ang: float = spin + TAU / count * i
		var pos: Vector2 = player.global_position + Vector2(cos(ang), sin(ang)) * radius
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var key: String = data.id + "_" + str(enemy.get_instance_id())
			var last: float = _hit_cooldowns.get(key, 0.0)
			if t - last < 0.45:
				continue
			if pos.distance_to(enemy.global_position) < 10.0 + enemy.hit_radius:
				_hit_cooldowns[key] = t
				enemy.take_damage(dmg)


func _fire_projectile(data: SkillData, level: int) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.35, data.base_cooldown - level * 0.12) * (1.0 - GameManager.passive_value("cooldown"))
	cd = max(0.15, cd)
	var last: float = _last_fire_time.get(data.id, 0.0)
	if t - last < cd:
		return

	var target := _find_nearest_enemy()
	if target == null:
		return
	_last_fire_time[data.id] = t

	var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	var dir: Vector2 = (target.global_position - player.global_position).normalized()

	var proj = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = player.global_position
	proj.setup(dir * data.projectile_speed, dmg, data.color)


func _fire_nova(data: SkillData, level: int) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.8, data.base_cooldown - level * 0.15) * (1.0 - GameManager.passive_value("cooldown"))
	var last: float = _last_fire_time.get(data.id, 0.0)
	if t - last < cd:
		return
	_last_fire_time[data.id] = t

	var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	var count = 4 + int(level * 1.5)
	for i in range(count):
		var ang = TAU / count * i
		var dir = Vector2(cos(ang), sin(ang))
		var proj = PROJECTILE_SCENE.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = player.global_position
		proj.setup(dir * data.projectile_speed, dmg, data.color)

func _fire_aoe(data: SkillData, level: int) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.5, data.base_cooldown - level * 0.1) * (1.0 - GameManager.passive_value("cooldown"))
	var last: float = _last_fire_time.get(data.id, 0.0)
	if t - last < cd:
		return
	_last_fire_time[data.id] = t

	var radius = data.base_radius + data.radius_per_level * level
	var dps: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	var duration: float = 3.0

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if player.global_position.distance_to(enemy.global_position) < radius + enemy.hit_radius:
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(dps, duration)


func _find_nearest_enemy() -> Node:
	var best: Node = null
	var best_dist := 260.0
	for e in get_tree().get_nodes_in_group("enemies"):
		var d: float = player.global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best


func _draw() -> void:
	for s in GameManager.active_skills:
		var data: SkillData = s.data
		if data.skill_type == "orbit":
			var level: int = s.level
			var count := _blade_count(level)
			var radius: float = data.base_radius + data.radius_per_level * level
			var spin := Time.get_ticks_msec() / 1000.0 * 3.4
			for i in range(count):
				var ang: float = spin + TAU / count * i
				var local_pos: Vector2 = Vector2(cos(ang), sin(ang)) * radius
				draw_circle(local_pos, 10.0, data.color)

		elif data.skill_type == "aoe":
			var level: int = s.level
			var radius: float = data.base_radius + data.radius_per_level * level
			var last: float = _last_fire_time.get(data.id, 0.0)
			var t := Time.get_ticks_msec() / 1000.0
			if t - last < 0.2:
				draw_circle(Vector2.ZERO, radius, Color(1.0, 0.3, 0.0, 0.3 * (1.0 - (t - last) / 0.2)))
			else:
				draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.3, 0.0, 0.1), 2.0)
