class_name EnemyCommon
extends CharacterBody2D

@export var max_hp: float = 14.0
@export var speed: float = 65.0
@export var contact_dps: float = 10.0
@export var xp_value: int = 1
@export var hit_radius: float = 10.0
@export var color: Color = Color.WHITE
@export var _is_flashing: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var wobble_time: float = 0.0
var _flash_timer: float = 0.0
var _original_color: Color
var _burn_time: float = 0.0
var _burn_dps: float = 0.0

var _void_target_timer: float = 0.0
var _void_target: Node = null

var ice_slow_time: float = 0.0
var is_frozen: bool = false
var void_mark_time: float = 0.0

var active_auras: Array = []
var reaction_cooldown: float = 0.0
var _hurt_timer: float = 0.0
var _attack_timer: float = 0.0
var is_dying: bool = false

var knockback_vel: Vector2 = Vector2.ZERO
var knockback_time: float = 0.0

var enemy_type: String = "normal"
var sniper_cooldown: float = 0.0
var bomber_fuse: float = -1.0
var teleport_cooldown: float = 0.0
var summon_cooldown: float = 0.0
var mega_summon_timer: float = 0.0

var hp: float

# Boss Variables
var boss_phase: int = 1
var boss_state: String = "idle"
var boss_state_timer: float = 0.0
var boss_attack_cooldown: float = 3.0
var boss_target_pos: Vector2 = Vector2.ZERO
var boss_warning_line: Line2D
var boss_charge_dir: Vector2 = Vector2.ZERO
var boss_charge_count: int = 0

const XP_ORB_SCENE := preload("res://scenes/XPOrb.tscn")
const DEATH_PARTICLE := preload("res://scenes/DeathParticle.tscn")


func setup_type(type: String) -> void:
	enemy_type = type
	match type:
		"boss":
			speed *= 0.6
			max_hp *= 10.0 # Will be multiplied again by 50 in Spawner
			hit_radius *= 3.0
			contact_dps *= 2.0
			boss_phase = 1
			boss_state = "idle"
			boss_attack_cooldown = 4.0
		"swarm":
			speed *= 1.5
			max_hp *= 0.3
			hit_radius *= 0.6
		"tank_blue":
			speed *= 0.5
			max_hp *= 400.0
			hit_radius *= 2.0
			contact_dps *= 0.5
		"tank_yellow":
			speed *= 0.6
			max_hp *= 200.0
			hit_radius *= 1.5
			contact_dps *= 0.5
		"tank":
			speed *= 0.5
			max_hp *= 10.0
			hit_radius *= 2.0
			contact_dps *= 0.5
		"sniper":
			max_hp *= 0.5
			contact_dps *= 2.0
			sniper_cooldown = randf_range(1.0, 2.0)
		"bomber":
			pass
		"teleporter":
			speed *= 1.2
			teleport_cooldown = randf_range(2.0, 4.0)
		"summoner":
			speed *= 0.8
			max_hp *= 1.5
			summon_cooldown = randf_range(10.0, 15.0)
			mega_summon_timer = 100.0
			
	hp = max_hp
	_original_color = color
	
	# Apply sprite tint, frames and scale based on enemy type
	if sprite:
		match type:
			"boss":
				sprite.sprite_frames = load("res://Sprite/NPC/NecromancerFrames.tres")
				sprite.scale = Vector2(4.5, 4.5)
				color = Color.WHITE
				_original_color = color
			"swarm":
				sprite.sprite_frames = load("res://Sprite/NPC/SwarmFrames.tres")
				sprite.scale = Vector2(2.2, 2.2)
			"tank_blue", "tank":
				sprite.sprite_frames = load("res://Sprite/NPC/TankBlueFrames.tres")
				sprite.scale = Vector2(4.16, 4.16)
			"tank_yellow":
				sprite.sprite_frames = load("res://Sprite/NPC/TankYellowFrames.tres")
				sprite.scale = Vector2(2.7, 2.7)
			"sniper":
				sprite.sprite_frames = load("res://Sprite/NPC/SniperFrames.tres")
				sprite.scale = Vector2(2.2, 2.2)
			"bomber":
				sprite.sprite_frames = load("res://Sprite/NPC/BomberFrames.tres")
				sprite.scale = Vector2(2.6, 2.6)
			"teleporter":
				sprite.sprite_frames = load("res://Sprite/NPC/TeleporterFrames.tres")
				sprite.scale = Vector2(3.5, 3.5)
			"summoner":
				sprite.sprite_frames = load("res://Sprite/NPC/SummonerFrames.tres")
				sprite.scale = Vector2(4.5, 4.5)
			_:
				sprite.sprite_frames = load("res://Sprite/NPC/SkeletonFrames.tres")
				sprite.scale = Vector2(2.5, 2.5)
				
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
	
func _ready() -> void:
	hp = max_hp
	_original_color = color
	add_to_group("enemies")
	
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = hit_radius * 0.8
	col.shape = shape
	add_child(col)
	collision_layer = 4
	collision_mask = 5 # 1 (Obstacles) + 4 (Enemies)

	queue_redraw()


func _physics_process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
	var player = GameManager.player
	if player == null or is_dying:
		return

	# Handle status effect timers
	if _is_flashing:
		_flash_timer -= delta
		if _flash_timer <= 0:
			_is_flashing = false
			if sprite:
				sprite.modulate = color
	
	if ice_slow_time > 0:
		ice_slow_time -= delta
		if ice_slow_time <= 0:
			is_frozen = false
			active_auras.erase("ice")
			queue_redraw()
	
	var target_pos: Vector2 = player.global_position
	if void_mark_time > 0:
		void_mark_time -= delta
		_void_target_timer -= delta
		if _void_target_timer <= 0.0:
			_void_target_timer = 0.25
			_void_target = _get_nearest_enemy_except(self)
			if _void_target:
				target_pos = _void_target.global_position
			else:
				_void_target = null
			
		if void_mark_time <= 0:
			_trigger_void_spread()
			if randf() < 0.20:
				_die()
				return
			else:
				var base_dmg = max_hp * 0.2
				if GameManager.current_class == "void_mage": base_dmg *= 1.2
				take_damage(base_dmg)
				if is_dying: return
			
	if reaction_cooldown > 0:
		reaction_cooldown -= delta

	var to_player: Vector2 = target_pos - global_position
	var dist: float = to_player.length()
	
	var current_speed = speed
	if is_frozen:
		current_speed = 0.0
	elif ice_slow_time > 0:
		current_speed *= 0.6
		
	var should_move = true
	
	if enemy_type == "boss":
		if hp <= max_hp * 0.5 and boss_phase == 1:
			boss_phase = 2
			_original_color = Color(0.8, 0.1, 1.0)
			color = _original_color
			
		boss_attack_cooldown -= delta
		
		if boss_state == "idle":
			should_move = true
			if dist > 600.0 and boss_attack_cooldown <= 0:
				boss_state = "blink"
				boss_state_timer = 0.5
				should_move = false
			elif boss_attack_cooldown <= 0:
				var rand_atk = randf()
				if rand_atk < 0.4:
					boss_state = "charge_warn"
					boss_state_timer = 1.0
					boss_charge_dir = to_player.normalized()
					boss_charge_count = 3 if boss_phase == 2 else 1
					
					boss_warning_line = Line2D.new()
					get_tree().current_scene.add_child(boss_warning_line)
					boss_warning_line.width = 10.0
					boss_warning_line.default_color = Color(1, 0, 0, 0.5)
					boss_warning_line.points = [global_position, global_position + boss_charge_dir * 1000.0]
				elif rand_atk < 0.7:
					boss_state = "laser_warn"
					boss_state_timer = 1.5
					boss_charge_dir = to_player.normalized()
					
					boss_warning_line = Line2D.new()
					get_tree().current_scene.add_child(boss_warning_line)
					boss_warning_line.width = 40.0
					boss_warning_line.default_color = Color(0.6, 0.1, 0.8, 0.4)
					boss_warning_line.points = [global_position, global_position + boss_charge_dir * 800.0]
				else:
					boss_state = "bombard"
					boss_state_timer = 2.0
					for i in range(5 + (5 if boss_phase == 2 else 0)):
						var warn = Sprite2D.new()
						warn.set_script(load("res://scripts/MagicCircle.gd"))
						get_tree().current_scene.add_child(warn)
						if i == 0:
							warn.global_position = player.global_position
						else:
							var r = randf() * TAU
							warn.global_position = player.global_position + Vector2(cos(r), sin(r)) * randf_range(50, 300)
						warn.setup("small")
						warn.modulate = Color(1, 0.2, 0.2)
						warn.set_meta("boss_bomb", true)
						
				boss_attack_cooldown = 4.0 if boss_phase == 1 else 2.5
				should_move = false
				
		elif boss_state == "blink":
			should_move = false
			boss_state_timer -= delta
			if sprite:
				if int(boss_state_timer * 10) % 2 == 0:
					sprite.modulate.a = 0.2
				else:
					sprite.modulate.a = 1.0
				
			if boss_state_timer <= 0:
				var move_dir = player.velocity.normalized()
				if player.velocity.length() < 10.0:
					var r = randf() * TAU
					move_dir = Vector2(cos(r), sin(r))
				global_position = player.global_position + move_dir * 300.0
				boss_state = "idle"
				if sprite: sprite.modulate.a = 1.0
				
		elif boss_state == "charge_warn":
			should_move = false
			boss_state_timer -= delta
			if is_instance_valid(boss_warning_line):
				boss_warning_line.points[0] = global_position
				
			if boss_state_timer <= 0:
				if is_instance_valid(boss_warning_line): boss_warning_line.queue_free()
				boss_state = "charge_dash"
				boss_state_timer = 0.4
				
		elif boss_state == "charge_dash":
			should_move = false
			velocity = boss_charge_dir * 1200.0
			boss_state_timer -= delta
			if boss_state_timer <= 0:
				velocity = Vector2.ZERO
				boss_charge_count -= 1
				if boss_charge_count > 0:
					boss_state = "charge_warn"
					boss_state_timer = 0.5
					boss_charge_dir = (player.global_position - global_position).normalized()
					boss_warning_line = Line2D.new()
					get_tree().current_scene.add_child(boss_warning_line)
					boss_warning_line.width = 10.0
					boss_warning_line.default_color = Color(1, 0, 0, 0.5)
					boss_warning_line.points = [global_position, global_position + boss_charge_dir * 1000.0]
				else:
					boss_state = "idle"
					
		elif boss_state == "laser_warn":
			should_move = false
			boss_state_timer -= delta
			if is_instance_valid(boss_warning_line):
				boss_warning_line.points[0] = global_position
				
			if boss_state_timer <= 0:
				boss_state = "laser_fire"
				boss_state_timer = 2.0
				if is_instance_valid(boss_warning_line):
					boss_warning_line.default_color = Color(0.8, 0.1, 1.0, 1.0)
					
		elif boss_state == "laser_fire":
			should_move = false
			boss_state_timer -= delta
			
			var current_angle = boss_charge_dir.angle()
			var target_angle = (player.global_position - global_position).angle()
			var new_angle = lerp_angle(current_angle, target_angle, delta * 1.5)
			boss_charge_dir = Vector2(cos(new_angle), sin(new_angle))
			
			if is_instance_valid(boss_warning_line):
				boss_warning_line.points[0] = global_position
				boss_warning_line.points[1] = global_position + boss_charge_dir * 1200.0
				
				var to_p = player.global_position - global_position
				var dist_p = to_p.length()
				if dist_p < 1200.0:
					var angle_diff = abs(to_p.angle() - boss_charge_dir.angle())
					if angle_diff > PI: angle_diff = TAU - angle_diff
					var hit_angle = 40.0 / max(10.0, dist_p)
					if angle_diff < hit_angle:
						player.take_damage(60.0 * delta, true)
						
			if boss_state_timer <= 0:
				if is_instance_valid(boss_warning_line): boss_warning_line.queue_free()
				boss_state = "idle"
				
		elif boss_state == "bombard":
			should_move = false
			boss_state_timer -= delta
			if boss_state_timer <= 0:
				for n in get_tree().current_scene.get_children():
					if n.has_meta("boss_bomb"):
						if DEATH_PARTICLE:
							var p = DEATH_PARTICLE.instantiate()
							p.position = n.global_position
							p.modulate = Color.RED
							p.scale = Vector2(4.0, 4.0)
							get_tree().current_scene.add_child(p)
						
						if player.global_position.distance_to(n.global_position) < 60.0:
							player.take_damage(40.0, true)
							
						n.queue_free()
				boss_state = "idle"
	
	if enemy_type == "sniper":
		if dist < 150.0:
			should_move = false
		sniper_cooldown -= delta
		if sniper_cooldown <= 0:
			sniper_cooldown = 2.0
			_fire_sniper_projectile(to_player.normalized())
			
	if enemy_type == "bomber":
		if bomber_fuse < 0 and dist < 40.0:
			bomber_fuse = 1.0
			
		if bomber_fuse >= 0:
			should_move = false
			bomber_fuse -= delta
			
			# Blink red via sprite modulate instead of color var
			if sprite:
				if int(bomber_fuse * 10) % 2 == 0:
					sprite.modulate = Color.RED
				else:
					sprite.modulate = _original_color
			queue_redraw()
			
			if bomber_fuse < 0:
				_explode_bomber()
				return
				
	if enemy_type == "teleporter":
		teleport_cooldown -= delta
		if teleport_cooldown <= 0 and dist > 120.0:
			teleport_cooldown = randf_range(2.0, 4.0)
			var angle = randf() * TAU
			global_position = player.global_position + Vector2(cos(angle), sin(angle)) * 50.0
			# Show a particle or something? Just keep it simple.
			
	if enemy_type == "summoner":
		if dist < 120.0:
			should_move = true
			to_player = - to_player # run away
		
		summon_cooldown -= delta
		mega_summon_timer -= delta
		
		if summon_cooldown <= 0:
			summon_cooldown = randf_range(10.0, 15.0)
			_attack_timer = 0.5
			
			var mc = Sprite2D.new()
			mc.set_script(load("res://scripts/MagicCircle.gd"))
			get_tree().current_scene.add_child(mc)
			mc.global_position = global_position
			mc.setup("small")
			
			var batch = randi_range(10, 25) # Reduced batch size
			for i in range(batch):
				_spawn_swarm_near(50.0)
				
		if mega_summon_timer <= 0:
			mega_summon_timer = 60.0 # Changed to 60s
			_attack_timer = 1.0
			
			var mc = Sprite2D.new()
			mc.set_script(load("res://scripts/MagicCircle.gd"))
			get_tree().current_scene.add_child(mc)
			mc.global_position = global_position
			mc.setup("big")
			
			_spawn_mega_swarm()
		
	if _attack_timer > 0:
		_attack_timer -= delta
		
	if knockback_time > 0:
		knockback_time -= delta
		velocity = knockback_vel
		knockback_vel = knockback_vel.lerp(Vector2.ZERO, delta * 5.0)
	elif dist > 0.001 and current_speed > 0 and should_move:
		velocity = (to_player / dist) * current_speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()

	# Update sprite direction and procedural animation
	if sprite:
		if not is_frozen:
			var faces_left = (enemy_type == "swarm")
			if faces_left:
				sprite.flip_h = to_player.x > 0
			else:
				sprite.flip_h = to_player.x < 0
		
		if _hurt_timer > 0:
			if sprite.animation != "hurt" and sprite.sprite_frames and sprite.sprite_frames.has_animation("hurt"): sprite.play("hurt")
		elif _attack_timer > 0 or (enemy_type != "sniper" and dist < hit_radius + 25.0): # Attack anim for melee or when shooting
			if sprite.animation != "attack" and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"): sprite.play("attack")
		elif velocity.length() > 5.0:
			if sprite.animation != "move" and sprite.sprite_frames and sprite.sprite_frames.has_animation("move"): sprite.play("move")
		else:
			if sprite.animation != "idle" and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"): sprite.play("idle")
			
	if _burn_time > 0:
		_burn_time -= delta
		hp -= _burn_dps * delta
		if hp <= 0:
			_die()
			return
			
	if not _is_flashing:
		var target_color = _original_color
		if ice_slow_time > 0:
			target_color = Color(0.3, 0.6, 1.0)
		elif _burn_time > 0:
			target_color = _original_color.lerp(Color(1.0, 0.4, 0.0), 0.5)
		elif active_auras.has("dark"):
			var drain_ratio = min(1.0, GameManager.stolen_dark_hp / 100.0)
			target_color = _original_color.lerp(Color.BLACK, 0.3 + drain_ratio * 0.5)
		
		if color != target_color:
			color = target_color
			if sprite:
				sprite.modulate = color
			queue_redraw()

	var actual_dist_to_player: float = global_position.distance_squared_to(player.global_position)
	var pr_sq = (hit_radius + player.hit_radius) * (hit_radius + player.hit_radius)
	if actual_dist_to_player < pr_sq:
		player.take_damage(contact_dps * delta, true)
		
	# Infighting logic for Void
	if void_mark_time > 0 and is_instance_valid(_void_target):
		var vr_sq = (hit_radius + _void_target.hit_radius) * (hit_radius + _void_target.hit_radius)
		if global_position.distance_squared_to(_void_target.global_position) < vr_sq:
			if _void_target.has_method("take_damage"):
				_void_target.take_damage(contact_dps * delta * 15.0)


func take_damage(amount: float) -> void:
	if is_dying: return
	
	var final_dmg = amount
	if randf() < GameManager.passive_value("crit"):
		final_dmg *= 2.0
		color = Color.WHITE
		_is_flashing = true
		_flash_timer = 0.15
		if sprite:
			sprite.modulate = Color.WHITE
	hp -= final_dmg
	
	if final_dmg >= 1.0:
		GameManager.add_combo_damage(final_dmg)
	
	if hp <= 0.0:
		_die()

func _fire_sniper_projectile(dir: Vector2) -> void:
	var proj = Node2D.new()
	proj.set_script(load("res://scripts/EnemyProjectile.gd"))
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.setup(dir * 120.0, 15.0) # 15 damage
	
func _explode_bomber() -> void:
	var player = GameManager.player
	if player and global_position.distance_squared_to(player.global_position) < 3600.0:
		player.take_damage(40.0) # Massive damage
	
	# Explosion visuals
	var p = DEATH_PARTICLE.instantiate()
	if p:
		p.position = global_position
		p.modulate = Color.RED
		p.scale = Vector2(3.0, 3.0)
		get_tree().current_scene.add_child(p)

	queue_free()

func _trigger_void_spread() -> void:
	if not active_auras.has("void"): return
	active_auras.erase("void")
	queue_redraw()
	
	var void_count = 0
	var pool = []
	var r_sq = 350.0 * 350.0
	for e in GameManager.active_enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		if e.get("active_auras") != null and type_string(typeof(e.active_auras)) == "Array" and e.active_auras.has("void"):
			void_count += 1
		elif e != self and not e.is_dying:
			var d_sq: float = global_position.distance_squared_to(e.global_position)
			if d_sq < r_sq:
				pool.append({"node": e, "dist_sq": d_sq})
				
	if void_count >= 60:
		return
		
	var base_dmg = max_hp * 0.2
	if GameManager.current_class == "void_mage": base_dmg *= 1.2
	
	pool.sort_custom(func(a, b): return a.dist_sq < b.dist_sq)
	var targets = []
	for i in range(min(2, pool.size())):
		targets.append(pool[i].node)
		
	for t in targets:
		if t.has_method("apply_element"):
			t.apply_element("void", base_dmg)

func _spawn_swarm_near(radius: float) -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= 250:
		return
	var e = load("res://scenes/EnemyCommon.tscn").instantiate()
	get_tree().current_scene.add_child(e)
	var angle = randf() * TAU
	var dist = randf() * radius
	e.global_position = global_position + Vector2(cos(angle), sin(angle)) * dist
	if e.has_method("setup_type"):
		e.setup_type("swarm")

func _spawn_mega_swarm() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= 250:
		return
	var types = ["normal", "swarm", "tank_blue", "tank_yellow", "sniper", "teleporter", "bomber", "summoner"]
	for type in types:
		var count = randi_range(5, 15)
		for i in range(count):
			var e = load("res://scenes/EnemyCommon.tscn").instantiate()
			get_tree().current_scene.add_child(e)
			var angle = randf() * TAU
			# Toàn bản đồ (map wide), outside screen
			var dist = randf_range(500.0, 1000.0) 
			if GameManager.player:
				e.global_position = GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * dist
			else:
				e.global_position = global_position + Vector2(cos(angle), sin(angle)) * dist
			if e.has_method("setup_type"):
				e.setup_type(type)
			
			# Make it elite
			e.max_hp *= 5.0
			e.hp = e.max_hp
			e.speed *= 1.5
			e.scale *= 1.5
			if e.has_node("Sprite2D"):
				e.get_node("Sprite2D").modulate = Color.RED

func apply_knockback(dir: Vector2, force: float) -> void:
	if is_frozen: return # frozen enemies don't get knocked back as easily, or maybe they do?
	knockback_vel = dir * force
	knockback_time = 0.2


func apply_element(type: String, dmg: float) -> void:
	if not active_auras.has(type):
		active_auras.append(type)
		_check_reactions(dmg)
		
	match type:
		"lightning":
			var jumps = 5 if GameManager.has_rune_resonance("lightning") else 2
			var chain_dmg = dmg * 0.6 if GameManager.has_rune_resonance("lightning") else dmg * 0.3
			
			var current: Node = self
			var hit_enemies = [self]
			var path = [global_position]
			
			for i in range(jumps):
				var next_target = current._get_nearest_enemy_not_in(hit_enemies)
				if next_target:
					path.append(next_target.global_position)
					hit_enemies.append(next_target)
					if next_target.has_method("take_damage"):
						next_target.take_damage(chain_dmg)
					current = next_target
				else:
					break
			
			if path.size() >= 2:
				var line = Line2D.new()
				line.set_script(load("res://scripts/LightningLine.gd"))
				line.points = path
				line.width = 3.0
				line.default_color = Color(1.0, 0.9, 0.2)
				get_tree().current_scene.add_child(line)
		"ice":
			var freeze_chance = 0.1
			if randf() < freeze_chance:
				is_frozen = true
				ice_slow_time = 1.5
			elif randf() < 0.8:
				ice_slow_time = 1.5
			color = Color(0.3, 0.6, 1.0)
			queue_redraw()
		"dark":
			var cap_hp = 100.0 if GameManager.has_rune_resonance("dark") else 50.0
			var cap_dmg = 0.4 if GameManager.has_rune_resonance("dark") else 0.2
			if GameManager.stolen_dark_hp < cap_hp:
				GameManager.stolen_dark_hp = min(cap_hp, GameManager.stolen_dark_hp + 0.5)
			if GameManager.stolen_dark_dmg < cap_dmg:
				GameManager.stolen_dark_dmg = min(cap_dmg, GameManager.stolen_dark_dmg + 0.005)
			if GameManager.player:
				GameManager.player._update_max_hp()
				
		"void":
			if GameManager.has_rune_resonance("void") and randf() < 0.001: # 0.1%
				GameManager.trigger_void_nuke()
				return
				
			if void_mark_time <= 0:
				void_mark_time = 4.0

func _check_reactions(dmg: float) -> void:
	if reaction_cooldown > 0: return
	
	var count = active_auras.size()
	if count == 4:
		# Quadruple Hit: Void Eradication
		reaction_cooldown = 5.0
		_die() # Black hole swallows them
	elif count == 3:
		# Triple Hit
		reaction_cooldown = 2.0
		take_damage(dmg * 3.0)
		_burn_dps = dmg
		_burn_time = 3.0
	elif count == 2:
		# Double Hit
		reaction_cooldown = 1.0
		take_damage(dmg * 1.5)
		var target = _get_nearest_enemy_except(self)
		if target:
			target.apply_element(active_auras[0], dmg * 0.5)





func _get_nearest_enemy_except(exclude_node: Node) -> Node:
	var best: Node = null
	var best_dist_sq := 150.0 * 150.0
	for e in GameManager.active_enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		if e == exclude_node: continue
		var d_sq: float = global_position.distance_squared_to(e.global_position)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			best = e
	return best

func _get_nearest_enemy_not_in(excludes: Array) -> Node:
	var best: Node = null
	var best_dist_sq := 150.0 * 150.0
	for e in GameManager.active_enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		if e in excludes: continue
		var d_sq: float = global_position.distance_squared_to(e.global_position)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			best = e
	return best


func _get_nearest_enemies_except(exclude_node: Node, count: int, radius: float = 150.0) -> Array:
	var pool = []
	for e in GameManager.active_enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		if e == exclude_node: continue
		var d_sq: float = global_position.distance_squared_to(e.global_position)
		if d_sq < radius * radius:
			pool.append({"node": e, "dist": d_sq})
			
	pool.sort_custom(func(a, b): return a.dist < b.dist)
	
	var result = []
	for i in range(min(count, pool.size())):
		result.append(pool[i].node)
	return result


func apply_burn(dps: float, duration: float) -> void:
	_burn_dps = dps
	_burn_time = duration


func _die() -> void:
	if is_dying: return
	is_dying = true
	
	if active_auras.has("void"):
		_trigger_void_spread()
	
	if is_instance_valid(boss_warning_line):
		boss_warning_line.queue_free()
	if enemy_type == "boss":
		for n in get_tree().current_scene.get_children():
			if n.has_meta("boss_bomb"):
				n.queue_free()
				
	GameManager.register_kill()
	
	var current_orbs = get_tree().get_nodes_in_group("xp_orbs")
	if current_orbs.size() < 250:
		var orb = XP_ORB_SCENE.instantiate()
		get_tree().current_scene.add_child(orb)
		orb.global_position = global_position
		orb.value = xp_value
	else:
		# Merge with the nearest existing orb to save memory while keeping XP accessible
		var best_orb = null
		var best_d_sq = 1e9
		for o in current_orbs:
			if o.is_queued_for_deletion(): continue
			var d_sq = global_position.distance_squared_to(o.global_position)
			if d_sq < best_d_sq:
				best_d_sq = d_sq
				best_orb = o
				
		if best_orb:
			best_orb.value += xp_value
			var s = min(3.0, 1.0 + best_orb.value * 0.02)
			best_orb.scale = Vector2(s, s)

	if enemy_type == "summoner" and sprite:
		sprite.play("death")
		var t = get_tree().create_timer(1.1) # 11 frames at 10 fps
		await t.timeout
	elif DEATH_PARTICLE:
		var p = DEATH_PARTICLE.instantiate()
		p.position = global_position
		p.modulate = color
		get_tree().current_scene.add_child(p)
		
	# Relic drop chance (1%)
	var drop_rate = 0.01
	if GameManager.active_curses.has("mong_manh"): drop_rate += 0.05
	
	if randf() < drop_rate:
		var r = Node2D.new()
		r.set_script(load("res://scripts/Relic.gd"))
		get_tree().current_scene.add_child(r)
		r.global_position = global_position

	queue_free()


func _draw() -> void:
	# Draw shadow
	draw_circle(Vector2.ZERO, hit_radius * 0.7, Color(0, 0, 0, 0.25))
	
	# Frozen ice cage visual
	if is_frozen:
		draw_rect(Rect2(-hit_radius, -hit_radius - 20, hit_radius * 2, hit_radius * 2), Color(0.5, 0.8, 1.0, 0.5), false, 2.0)
		
	# Void mark floating orb visual
	if active_auras.has("void"):
		var time = Time.get_ticks_msec() / 1000.0
		var orb_y = sin(time * 4.0) * 3.0 - hit_radius - 28.0
		draw_arc(Vector2(0, orb_y), 6.0, 0, TAU, 16, Color(0.6, 0.2, 0.8), 2.0)
		draw_circle(Vector2(0, orb_y), 2.0, Color(0.8, 0.4, 1.0))

	# Bomber fuse flash (handled via sprite modulate now, but keep HP bar hint)
	if enemy_type == "bomber" and bomber_fuse >= 0:
		var alpha = fmod(bomber_fuse * 3.14, 1.0)
		draw_circle(Vector2(0, -hit_radius - 30), 5.0, Color(1.0, 0.3, 0.0, alpha))
