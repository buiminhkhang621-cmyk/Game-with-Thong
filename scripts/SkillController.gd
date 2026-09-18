extends Node2D

@onready var player: Node2D = get_parent()

var _last_fire_time: Dictionary = {}
var _hit_cooldowns: Dictionary = {}

var axe_empowered: bool = false
var axe_cooldown_override: bool = false
var _whip_visuals: Array = []
var _lightning_visuals: Array = []

var _last_hp: float = 0.0
var _spell_cooldowns: Dictionary = {}
var _frame_enemies: Array = []

const PROJECTILE_SCENE := preload("res://scenes/Projectile.tscn")

static var _knife_tex: Texture2D = null
static var _magic_ball_tex: Texture2D = null

static func _get_knife_texture() -> Texture2D:
	if _knife_tex == null:
		_knife_tex = UITheme.load_texture("res://Sprite/weapon/knife.png")
	return _knife_tex

static func _get_magic_ball_texture() -> Texture2D:
	if _magic_ball_tex == null:
		_magic_ball_tex = UITheme.load_texture("res://Sprite/weapon/Magic-ball.png")
	return _magic_ball_tex

var _spin_angle: float = 0.0
var _orbs_spin_angle: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	_spin_angle += delta * 3.4
	_orbs_spin_angle += delta * 2.0

	var keep = []
	for v in _whip_visuals:
		v.time -= delta
		if v.time > 0:
			keep.append(v)
	_whip_visuals = keep
	
	var keep_lightning = []
	for v in _lightning_visuals:
		v.time -= delta
		if v.time > 0:
			keep_lightning.append(v)
	_lightning_visuals = keep_lightning
	
	if not GameManager.game_over and not GameManager.paused_for_levelup and not GameManager.weapons_disabled:
		_frame_enemies = GameManager.active_enemies
		for s in GameManager.active_skills:
			var data: SkillData = s.data
			var level: int = s.level
			match data.skill_type:
				"orbit":
					_fire_orbit(s, data, level)
				"projectile":
					_fire_projectile(s, data, level)
				"throwing_knife":
					_fire_throwing_knife(s, data, level)
				"nova":
					_fire_nova(s, data, level)
				"aoe":
					_fire_aoe(s, data, level)
				"throwing_axe":
					_fire_throwing_axe(s, data, level)
				"elemental_orbs":
					_fire_elemental_orbs(s, data, level)
				"whip":
					_fire_whip(s, data, level)
				"lightning":
					_fire_lightning(s, data, level)
				"earthquake":
					_fire_earthquake(s, data, level)
		_process_crafted_spells()
	queue_redraw()
	
	if player:
		_last_hp = player.hp

func _process_crafted_spells() -> void:
	if not player: return
	
	for i in range(GameManager.crafted_spells.size()):
		var spell = GameManager.crafted_spells[i]
		var vong = spell.vong
		var net = spell.net
		
		var t = Time.get_ticks_msec() / 1000.0
		var last = _spell_cooldowns.get(i, 0.0)
		
		var should_fire = false
		if vong == "Guardian":
			if player.hp < _last_hp and (t - last >= 0.5):
				should_fire = true
		elif vong == "Warden":
			if player.velocity.length() < 5.0 and (t - last >= 1.5):
				should_fire = true
				
		if should_fire:
			_spell_cooldowns[i] = t
			_fire_spell_net(net)

func _fire_spell_net(net: String) -> void:
	var target = _find_nearest_enemy()
	if target == null: return
	
	var dmg = 25.0 * (1.0 + GameManager.passive_value("damage"))
	var c = Color(0.9, 0.2, 0.9)
	
	if net == "Chase":
		var dir = (target.global_position - player.global_position).normalized()
		var proj = PROJECTILE_SCENE.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = player.global_position
		proj.setup(dir * 300.0, dmg, c, ["void"])
	elif net == "Split":
		for i in range(4):
			var ang = TAU / 4 * i
			var dir = Vector2(cos(ang), sin(ang))
			var proj = PROJECTILE_SCENE.instantiate()
			get_tree().current_scene.add_child(proj)
			proj.global_position = player.global_position
			proj.setup(dir * 200.0, dmg, c, [])

func on_axe_caught() -> void:
	axe_empowered = true
	axe_cooldown_override = true


func _blade_count(level: int) -> int:
	return 1 + int(level / 2.0)


func _fire_orbit(s_dict: Dictionary, data: SkillData, level: int) -> void:
	if not player: return
	var count := _blade_count(level)
	var radius: float = data.base_radius + data.radius_per_level * level
	var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	
	if s_dict.has("runes") and s_dict.runes.has("damage"):
		dmg *= 1.2
		
	var t := Time.get_ticks_msec() / 1000.0
	var spin := _spin_angle # Exactly synchronized with visual _spin_angle in _draw()!

	var blade_positions = []
	for i in range(count):
		var ang: float = spin + TAU / count * i
		blade_positions.append(player.global_position + Vector2(cos(ang), sin(ang)) * radius)

	var blade_hit_radius = 28.0
	for enemy in _frame_enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion(): continue
		if "hp" in enemy and enemy.hp <= 0: continue
		if "is_dying" in enemy and enemy.is_dying: continue

		var key: String = data.id + "_" + str(enemy.get_instance_id())
		var last: float = _hit_cooldowns.get(key, 0.0)
		if t - last < 0.35:
			continue
			
		var enemy_r = enemy.hit_radius if "hit_radius" in enemy else 12.0
		var r_total = blade_hit_radius + enemy_r
		var r_sq = r_total * r_total
		for pos in blade_positions:
			if pos.distance_squared_to(enemy.global_position) <= r_sq:
				_hit_cooldowns[key] = t
				if s_dict.has("runes"):
					for r in s_dict.runes:
						if r != "damage" and enemy.has_method("apply_element"):
							enemy.apply_element(r, dmg * 0.5)
				enemy.take_damage(dmg)
				if enemy.has_method("apply_knockback"):
					var kb_dir = (enemy.global_position - player.global_position).normalized()
					enemy.apply_knockback(kb_dir, 80.0)
				break


func _fire_projectile(s_dict: Dictionary, data: SkillData, level: int) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.2, data.base_cooldown - level * 0.08) * (1.0 - GameManager.passive_value("cooldown"))
	var last: float = _last_fire_time.get(data.id, 0.0)
	if t - last < cd:
		return

	var target := _find_nearest_enemy()
	if target == null:
		return
	_last_fire_time[data.id] = t

	var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	if s_dict.has("runes") and s_dict.runes.has("damage"):
		dmg *= 1.2
	var dir: Vector2 = (target.global_position - player.global_position).normalized()

	var proj = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = player.global_position
	var r = s_dict.runes if s_dict.has("runes") else []
	proj.setup(dir * data.projectile_speed, dmg, data.color, r)


func _fire_nova(s_dict: Dictionary, data: SkillData, level: int) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.3, data.base_cooldown - level * 0.07) * (1.0 - GameManager.passive_value("cooldown"))
	var last: float = _last_fire_time.get(data.id, 0.0)
	if t - last < cd:
		return
	_last_fire_time[data.id] = t

	var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	if s_dict.has("runes") and s_dict.runes.has("damage"):
		dmg *= 1.2
	var count = 4 + int(level * 1.5)
	for i in range(count):
		var ang = TAU / count * i
		var dir = Vector2(cos(ang), sin(ang))
		var proj = PROJECTILE_SCENE.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = player.global_position
		var r = s_dict.runes if s_dict.has("runes") else []
		proj.setup(dir * data.projectile_speed, dmg, data.color, r)

func _fire_aoe(s_dict: Dictionary, data: SkillData, level: int) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.3, data.base_cooldown - level * 0.08) * (1.0 - GameManager.passive_value("cooldown"))
	var last: float = _last_fire_time.get(data.id, 0.0)
	if t - last < cd:
		return
	_last_fire_time[data.id] = t

	var radius = data.base_radius + data.radius_per_level * level
	var dps: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	if s_dict.has("runes") and s_dict.runes.has("damage"):
		dps *= 1.2
		
	var duration: float = 3.0

	for enemy in _frame_enemies:
		var r_sq = (radius + enemy.hit_radius) * (radius + enemy.hit_radius)
		if player.global_position.distance_squared_to(enemy.global_position) < r_sq:
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(dps, duration)
			if s_dict.has("runes"):
				for r in s_dict.runes:
					if r != "damage" and enemy.has_method("apply_element"):
						enemy.apply_element(r, dps * 0.5)

func _fire_throwing_axe(s_dict: Dictionary, data: SkillData, level: int) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.3, data.base_cooldown - level * 0.2) * (1.0 - GameManager.passive_value("cooldown"))
	var last: float = _last_fire_time.get(data.id, 0.0)
	if not axe_cooldown_override and (t - last < cd):
		return

	var target := _find_nearest_enemy()
	if target == null:
		return
		
	_last_fire_time[data.id] = t
	axe_cooldown_override = false

	var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	if s_dict.has("runes") and s_dict.runes.has("damage"):
		dmg *= 1.2
	var dir: Vector2 = (target.global_position - player.global_position).normalized()

	var axe = Node2D.new()
	axe.set_script(load("res://scripts/ThrowingAxe.gd"))
	get_tree().current_scene.add_child(axe)
	axe.global_position = player.global_position
	var r = s_dict.runes if s_dict.has("runes") else []
	axe.setup(dir * data.projectile_speed, dmg, data.color, axe_empowered, self, r)
	
	axe_empowered = false # Reset after throw

func _fire_throwing_knife(s_dict: Dictionary, data: SkillData, level: int) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.25, data.base_cooldown - level * 0.05) * (1.0 - GameManager.passive_value("cooldown"))
	var last: float = _last_fire_time.get(data.id, 0.0)
	if t - last < cd:
		return
		
	var target = _find_nearest_enemy()
	var base_dir = Vector2.RIGHT
	if target:
		base_dir = (target.global_position - player.global_position).normalized()
	elif player.velocity.length() > 5.0:
		base_dir = player.velocity.normalized()
	elif player.sprite and player.sprite.flip_h:
		base_dir = Vector2.LEFT
		
	_last_fire_time[data.id] = t

	var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	if s_dict.has("runes") and s_dict.runes.has("damage"):
		dmg *= 1.25

	var count = 1 + int(level / 2.0)
	var pierce = 1 + int(level / 3.0)
	var r = s_dict.runes if s_dict.has("runes") else []
	var is_crit = randf() < (0.25 + GameManager.passive_value("crit_chance"))
	
	var spread_angle = deg_to_rad(9.0)
	var start_offset = -((count - 1) * spread_angle) * 0.5
	
	for i in range(count):
		var dir = base_dir.rotated(start_offset + i * spread_angle)
		var knife = Node2D.new()
		knife.set_script(load("res://scripts/ThrowingKnife.gd"))
		get_tree().current_scene.add_child(knife)
		knife.global_position = player.global_position + dir * 12.0
		knife.setup(dir * data.projectile_speed, dmg, is_crit, pierce, r)

func _fire_elemental_orbs(s_dict: Dictionary, data: SkillData, level: int) -> void:
	var count = 1 + int(level / 2.0)
	var radius: float = data.base_radius
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.3, data.base_cooldown - level * 0.12) * (1.0 - GameManager.passive_value("cooldown"))
	
	var last: float = _last_fire_time.get(data.id, 0.0)
	if t - last >= cd:
		var target = _find_nearest_enemy()
		if target != null:
			_last_fire_time[data.id] = t
			var elements = ["lightning", "ice", "dark", "void"]
			var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
			if s_dict.has("runes") and s_dict.runes.has("damage"):
				dmg *= 1.2
			
			for i in range(count):
				var ang: float = _orbs_spin_angle + TAU / count * i
				var pos: Vector2 = player.global_position + Vector2(cos(ang), sin(ang)) * radius
				var dir: Vector2 = (target.global_position - pos).normalized()
				
				var orb = Node2D.new()
				orb.set_script(load("res://scripts/OrbProjectile.gd"))
				get_tree().current_scene.add_child(orb)
				orb.global_position = pos
				var type = elements[randi() % elements.size()]
				orb.setup(dir * data.projectile_speed, dmg, type)

func _fire_whip(s_dict: Dictionary, data: SkillData, level: int) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.3, data.base_cooldown - level * 0.06) * (1.0 - GameManager.passive_value("cooldown"))
	var last: float = _last_fire_time.get(data.id, 0.0)
	
	if t - last < cd:
		return
		
	var target = _find_nearest_enemy()
	if target == null:
		return
		
	_last_fire_time[data.id] = t
	
	var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	if s_dict.has("runes") and s_dict.runes.has("damage"):
		dmg *= 1.2
		
	var radius = data.base_radius + data.radius_per_level * level
	var sweep_angle = deg_to_rad(100.0 + 15.0 * int(level / 2.0))
	var to_target = (target.global_position - player.global_position).normalized()
	var center_angle = to_target.angle()
	
	for enemy in _frame_enemies:
		var r_sq = (radius + enemy.hit_radius) * (radius + enemy.hit_radius)
		if player.global_position.distance_squared_to(enemy.global_position) <= r_sq:
			var to_enemy = (enemy.global_position - player.global_position).normalized()
			var angle_diff = abs(angle_difference(center_angle, to_enemy.angle()))
			if angle_diff <= sweep_angle / 2.0:
				if s_dict.has("runes"):
					for r in s_dict.runes:
						if r != "damage" and enemy.has_method("apply_element"):
							enemy.apply_element(r, dmg * 0.5)
							
				enemy.take_damage(dmg)
				if enemy.has_method("apply_knockback"):
					enemy.apply_knockback(to_enemy, 150.0)
							
	_whip_visuals.append({
		"center": center_angle,
		"sweep": sweep_angle,
		"radius": radius,
		"color": data.color,
		"time": 0.15 # duration
	})


func _find_nearest_enemy() -> Node:
	var best: Node = null
	var best_dist_sq := 260.0 * 260.0
	for e in _frame_enemies:
		var d_sq: float = player.global_position.distance_squared_to(e.global_position)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			best = e
	return best

func _fire_lightning(_s: Dictionary, data: SkillData, level: int) -> void:
	var last: float = _last_fire_time.get(data.id, 0.0)
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.4, data.base_cooldown - level * 0.11) * (1.0 - GameManager.passive_value("cooldown"))
	if t - last < cd:
		return
	
	var first_target = _find_nearest_enemy()
	if first_target == null: return
	
	_last_fire_time[data.id] = t
	var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	var jumps = 2 + level
	
	var current = first_target
	var hit_enemies = [current]
	var path = [player.global_position, current.global_position]
	
	if current.has_method("take_damage"):
		current.take_damage(dmg)
		
	for i in range(jumps):
		var next_target: Node = null
		var best_dist_sq := 150.0 * 150.0
		for e in _frame_enemies:
			if e not in hit_enemies:
				var d_sq: float = current.global_position.distance_squared_to(e.global_position)
				if d_sq < best_dist_sq:
					best_dist_sq = d_sq
					next_target = e
		
		if next_target:
			path.append(next_target.global_position)
			hit_enemies.append(next_target)
			if next_target.has_method("take_damage"):
				next_target.take_damage(dmg * 0.8) # 20% less damage per jump
			current = next_target
		else:
			break
			
	# Spawn stunning elemental lightning visual effect for each jump segment
	var target_parent = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
	if target_parent and path.size() >= 2:
		for j in range(path.size() - 1):
			var fx = ElementalVisualEffect.new()
			target_parent.add_child(fx)
			fx.setup_lightning(path[j], path[j+1], j)
			
	# Play high voltage lightning audio
	GameManager.play_sfx(GameManager.sfx_electric_shock, randf_range(0.95, 1.15))
	
	# Subtle screen shake
	if player and GameManager.setting_screen_shake:
		player._shake_intensity = max(player._shake_intensity, 4.0)

	# Store for drawing
	_lightning_visuals.append({"path": path, "time": 0.25, "color": data.color})

func _fire_earthquake(_s: Dictionary, data: SkillData, level: int) -> void:
	var last: float = _last_fire_time.get(data.id, 0.0)
	var t := Time.get_ticks_msec() / 1000.0
	var cd: float = max(0.8, data.base_cooldown - level * 0.2) * (1.0 - GameManager.passive_value("cooldown"))
	if t - last < cd:
		return
		
	_last_fire_time[data.id] = t
	var dmg: float = (data.base_damage + data.damage_per_level * level) * (1.0 + GameManager.passive_value("damage"))
	var radius: float = data.base_radius + data.radius_per_level * level
	
	# Shake screen
	if player:
		player._shake_intensity = 10.0
		
	for e in _frame_enemies:
		if player.global_position.distance_squared_to(e.global_position) <= radius * radius:
			if e.has_method("take_damage"):
				e.take_damage(dmg)
			if e.has_method("apply_knockback"):
				e.apply_knockback((e.global_position - player.global_position).normalized(), 200.0)



func _draw() -> void:
	for s in GameManager.active_skills:
		var data: SkillData = s.data
		if data.skill_type == "orbit":
			var level: int = s.level
			var count := _blade_count(level)
			var radius: float = data.base_radius + data.radius_per_level * level
			var spin := _spin_angle
			var k_tex = _get_knife_texture()
			var k_size = (k_tex.get_size() * 0.35) if k_tex else Vector2(14, 17)
			for i in range(count):
				var ang: float = spin + TAU / count * i
				var local_pos: Vector2 = Vector2(cos(ang), sin(ang)) * radius
				var blade_angle = ang + deg_to_rad(52.3) # Radial outward knife tip orientation
				
				# Glowing motion slash trail behind the knife
				var trail_ang = ang - 0.20
				var trail_pos = Vector2(cos(trail_ang), sin(trail_ang)) * radius
				draw_line(trail_pos, local_pos, Color(data.color.r, data.color.g, data.color.b, 0.4), 1.8)
				
				if k_tex:
					draw_set_transform(local_pos, blade_angle, Vector2.ONE)
					draw_texture_rect(k_tex, Rect2(-k_size * 0.5, k_size), false, data.color)
					draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
				else:
					draw_circle(local_pos, 14.0, data.color)

		elif data.skill_type == "aoe":
			var level: int = s.level
			var radius: float = data.base_radius + data.radius_per_level * level
			var last: float = _last_fire_time.get(data.id, 0.0)
			var t := Time.get_ticks_msec() / 1000.0
			if t - last < 0.2:
				draw_circle(Vector2.ZERO, radius, Color(1.0, 0.3, 0.0, 0.3 * (1.0 - (t - last) / 0.2)))
			else:
				draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.3, 0.0, 0.1), 2.0)
				
		elif data.skill_type == "earthquake":
			var level: int = s.level
			var radius: float = data.base_radius + data.radius_per_level * level
			var last: float = _last_fire_time.get(data.id, 0.0)
			var t := Time.get_ticks_msec() / 1000.0
			if t - last < 0.3:
				draw_circle(Vector2.ZERO, radius, Color(0.6, 0.4, 0.2, 0.5 * (1.0 - (t - last) / 0.3)))
				
		elif data.skill_type == "elemental_orbs":
			var level: int = s.level
			var count = 1 + int(level / 2.0)
			var radius: float = data.base_radius
			var spin := _orbs_spin_angle
			var b_tex = _get_magic_ball_texture()
			var b_size = b_tex.get_size() * 0.7 if b_tex else Vector2(22, 23)
			var element_colors = [
				Color(1.0, 0.95, 0.25), # Lightning
				Color(0.3, 0.8, 1.0),   # Ice
				Color(0.8, 0.25, 0.95), # Void
				Color(1.0, 0.35, 0.1)   # Fire
			]
			for i in range(count):
				var ang: float = spin + TAU / count * i
				var local_pos: Vector2 = Vector2(cos(ang), sin(ang)) * radius
				var col = element_colors[i % element_colors.size()]
				
				# Elemental orbit trail
				draw_arc(Vector2.ZERO, radius, ang - 0.25, ang, 8, Color(col.r, col.g, col.b, 0.35), 2.0)
				
				if b_tex:
					# Soft glow behind
					draw_circle(local_pos, 10.0, Color(col.r, col.g, col.b, 0.25))
					draw_texture_rect(b_tex, Rect2(local_pos - b_size * 0.5, b_size), false, col)
				else:
					draw_circle(local_pos, 8.0, col)

				
	for v in _whip_visuals:
		var start_ang = v.center - v.sweep / 2.0
		var end_ang = v.center + v.sweep / 2.0
		draw_arc(Vector2.ZERO, v.radius, start_ang, end_ang, 16, v.color, 4.0)

	for v in _lightning_visuals:
		var local_path = PackedVector2Array()
		for p in v.path:
			local_path.append(p - global_position)
		if local_path.size() >= 2:
			draw_polyline(local_path, Color(0.2, 0.8, 1.0, 0.45), 7.0)
			draw_polyline(local_path, v.color, 3.5)
			draw_polyline(local_path, Color.WHITE, 1.5)
