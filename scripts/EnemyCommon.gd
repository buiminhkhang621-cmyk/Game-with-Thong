class_name EnemyCommon
extends CharacterBody2D

@export var max_hp: float = 16.0
@export var speed: float = 75.0
@export var contact_dps: float = 18.0
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
var _redraw_timer: float = 0.0

var _void_proc_cooldown: float = 0.0
var is_void_infected: bool = false
var void_infection_timer: float = 0.0
var void_infected_dmg: float = 0.0
var ice_slow_time: float = 0.0
var is_frozen: bool = false

var active_auras: Array = []
var reaction_cooldown: float = 0.0
var _hurt_timer: float = 0.0
var _attack_timer: float = 0.0
var is_dying: bool = false

var knockback_vel: Vector2 = Vector2.ZERO
var knockback_time: float = 0.0

var enemy_type: String = "normal"
var armor: float = 0.0

var evolution_tier: int = 0
var sniper_cooldown: float = 0.0
var bomber_fuse: float = -1.0
var teleport_cooldown: float = 0.0
var summon_cooldown: float = 0.0
var mega_summon_timer: float = 0.0
var _contact_cooldown: float = 0.0
var _bg_ref: Node2D = null

func _get_bg() -> Node2D:
	if not _bg_ref or not is_instance_valid(_bg_ref):
		if get_parent() and get_parent().has_node("Background"):
			_bg_ref = get_parent().get_node("Background")
		elif get_tree() and get_tree().current_scene:
			_bg_ref = get_tree().current_scene.find_child("Background", true, false)
	return _bg_ref

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
			speed *= 0.95
			max_hp *= 14.0
			hit_radius *= 3.0
			contact_dps *= 3.5
			armor = 0.50
			boss_phase = 1
			boss_state = "idle"
			boss_attack_cooldown = 2.8
		"swarm":
			speed *= 1.85
			max_hp *= 0.45
			hit_radius *= 0.6
			contact_dps *= 1.2
			armor = 0.0
		"tank_blue", "tank":
			speed *= 0.80
			max_hp *= 7.0
			hit_radius *= 2.5
			contact_dps *= 2.5
			armor = 0.65 # 65% Armor Heavy Executioner
		"tank_yellow":
			speed *= 0.92
			max_hp *= 4.5
			hit_radius *= 2.0
			contact_dps *= 1.8
			armor = 0.52 # 52% Armor Golem
		"sniper":
			speed *= 1.15
			max_hp *= 1.4
			contact_dps *= 1.6
			armor = 0.30
			sniper_cooldown = randf_range(0.7, 1.2)
		"bomber":
			speed *= 1.65
			max_hp *= 1.8
			contact_dps *= 1.2
			armor = 0.25
		"teleporter":
			speed *= 1.55
			max_hp *= 1.7
			contact_dps *= 1.8
			armor = 0.32
			teleport_cooldown = randf_range(1.4, 2.4)
		"summoner":
			speed *= 1.3
			max_hp *= 5.0
			contact_dps *= 1.5
			armor = 0.45
			summon_cooldown = randf_range(1.8, 2.8)
			mega_summon_timer = randf_range(16.0, 22.0)
		"golden_goblin":
			speed *= 1.75
			max_hp *= 3.5
			contact_dps = 0.0 # Harmless treasure creature
			armor = 0.15
			xp_value = 100
			color = Color(1.0, 0.85, 0.1)
			if sprite:
				sprite.modulate = Color(1.0, 0.9, 0.2)
		_:
			armor = 0.22 # Base 22% Armor for normal
			speed *= 1.15
			
	# ======== EXPONENTIAL SCALING (ABSOLUTE NIGHTMARE) ========
	# Early game (0-3 min): gentle ramp so player can get skills
	# Mid game (3-6 min): noticeable pressure increase
	# Late game (6-8 min): brutal, enemies become deadly walls of stats
	# End game (8+ min): near-impossible, only perfect builds survive
	var t_minutes = GameManager.run_time / 60.0
	
	# Base exponential curves (steeper than before)
	var hp_base = 1.0 + pow(t_minutes, 1.65) * 0.55
	var dmg_base = 1.0 + pow(t_minutes, 1.55) * 0.50
	var spd_base = 1.0 + min(1.10, pow(t_minutes, 1.2) * 0.18)
	
	# Breakpoint multipliers - sudden difficulty spikes at key moments
	var breakpoint_hp = 1.0
	var breakpoint_dmg = 1.0
	if t_minutes >= 3.0: breakpoint_hp *= 1.35; breakpoint_dmg *= 1.25  # 3 min spike
	if t_minutes >= 5.0: breakpoint_hp *= 1.60; breakpoint_dmg *= 1.50  # 5 min wall
	if t_minutes >= 7.0: breakpoint_hp *= 2.00; breakpoint_dmg *= 1.80  # 7 min nightmare
	if t_minutes >= 9.0: breakpoint_hp *= 2.80; breakpoint_dmg *= 2.50  # 9 min impossible
	
	var hp_mult = hp_base * breakpoint_hp
	var dmg_mult = dmg_base * breakpoint_dmg
	var spd_mult = spd_base
	
	max_hp *= hp_mult
	contact_dps *= dmg_mult
	speed *= spd_mult
	# Armor scales faster: enemies get tanky fast in late game
	armor = min(0.88, armor + t_minutes * 0.028)
	
	hp = max_hp
	_original_color = color
	
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

func setup_evolution(time_sec: float, tier_mult: float = 1.0) -> void:
	if time_sec < 120.0:
		evolution_tier = 0
		max_hp *= 1.0 * tier_mult
		_original_color = Color.WHITE
	elif time_sec < 300.0:
		evolution_tier = 1
		max_hp *= 1.8 * tier_mult
		contact_dps *= 1.45
		armor = min(0.80, armor + 0.12)
		speed *= 1.12
		_original_color = Color(1.0, 0.78, 0.78)
	elif time_sec < 480.0:
		evolution_tier = 2
		max_hp *= 3.5 * tier_mult
		contact_dps *= 2.2
		armor = min(0.82, armor + 0.20)
		speed *= 1.22
		scale *= 1.18
		_original_color = Color(0.85, 0.65, 1.0)
	else:
		evolution_tier = 3
		max_hp *= 6.0 * tier_mult
		contact_dps *= 3.2
		armor = min(0.85, armor + 0.30)
		speed *= 1.35
		scale *= 1.30
		_original_color = Color(1.0, 0.85, 0.45)
		
	hp = max_hp
	color = _original_color
	if sprite:
		sprite.modulate = color
	
func _ready() -> void:
	hp = max_hp
	_original_color = color
	add_to_group("enemies")
	GameManager.register_enemy(self)
	
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = hit_radius * 0.8
	col.shape = shape
	add_child(col)
	collision_layer = 4
	collision_mask = 1 # 1 (Obstacles only - removes enemy-vs-enemy physics collision bottleneck)

	queue_redraw()

func _exit_tree() -> void:
	GameManager.unregister_enemy(self)


func _physics_process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
	if is_dying:
		return

	if _contact_cooldown > 0:
		_contact_cooldown -= delta

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
	
	if _void_proc_cooldown > 0:
		_void_proc_cooldown -= delta
	
	# Rate-limited redraw for dynamic visual indicators (void ring/gauge, bomber fuse, void aura)
	if is_void_infected or active_auras.has("void") or (enemy_type == "bomber" and bomber_fuse >= 0):
		_redraw_timer += delta
		if _redraw_timer >= 0.066: # ~15 FPS redraw for visual indicators
			_redraw_timer = 0.0
			queue_redraw()

	# Void Infection 1.5s countdown before collapse & 90%/10% split
	if is_void_infected and not is_dying:
		void_infection_timer -= delta
		if void_infection_timer <= 0.0:
			_trigger_void_collapse()
			if is_dying:
				return
			
	if reaction_cooldown > 0:
		reaction_cooldown -= delta

	var player = GameManager.player
	if player == null:
		return

	var target_pos: Vector2 = player.global_position
	var to_player: Vector2 = target_pos - global_position
	var dist: float = to_player.length()
	
	var current_speed = speed
	if is_frozen:
		current_speed = 0.0
	elif ice_slow_time > 0:
		current_speed *= 0.6
		
	if GameManager.is_abyssal_fog:
		current_speed *= 1.25
	if GameManager.is_blood_moon:
		current_speed *= 1.25
		
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
			if is_instance_valid(boss_warning_line) and boss_warning_line.get_point_count() > 0:
				boss_warning_line.set_point_position(0, global_position)
				
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
			if is_instance_valid(boss_warning_line) and boss_warning_line.get_point_count() > 0:
				boss_warning_line.set_point_position(0, global_position)
				
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
			
			if is_instance_valid(boss_warning_line) and boss_warning_line.get_point_count() >= 2:
				boss_warning_line.set_point_position(0, global_position)
				boss_warning_line.set_point_position(1, global_position + boss_charge_dir * 1200.0)
				
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
		if dist < 320.0:
			should_move = false
		sniper_cooldown -= delta
		if sniper_cooldown <= 0:
			sniper_cooldown = randf_range(1.2, 1.8)
			_fire_sniper_projectile(to_player.normalized())
			
	if enemy_type == "bomber":
		if bomber_fuse < 0 and dist < 85.0:
			bomber_fuse = 0.22 # Fast near-instant fuse!
			
		if bomber_fuse >= 0:
			should_move = false
			bomber_fuse -= delta
			
			# Fast blink red via sprite modulate
			if sprite:
				if int(bomber_fuse * 20) % 2 == 0:
					sprite.modulate = Color.RED
				else:
					sprite.modulate = Color(1.0, 0.6, 0.6)
			
			if bomber_fuse < 0:
				_explode_bomber()
				return
				
	if enemy_type == "teleporter":
		teleport_cooldown -= delta
		if teleport_cooldown <= 0 and dist > 90.0:
			teleport_cooldown = randf_range(1.6, 2.8)
			var angle = randf() * TAU
			global_position = player.global_position + Vector2(cos(angle), sin(angle)) * 35.0
			_attack_timer = 0.3
			
	if enemy_type == "summoner":
		if dist < 550.0:
			should_move = true
			to_player = - to_player # Run away 4x further to maintain safe artillery range!
		elif dist > 780.0:
			should_move = true
		else:
			should_move = false
		
		summon_cooldown -= delta
		mega_summon_timer -= delta
		
		if summon_cooldown <= 0:
			summon_cooldown = randf_range(2.0, 3.2) # 2x faster summon!
			_attack_timer = 0.4
			
			var mc = Sprite2D.new()
			mc.set_script(load("res://scripts/MagicCircle.gd"))
			get_tree().current_scene.add_child(mc)
			mc.global_position = global_position
			mc.setup("small")
			
			# Summon 3-5 Elemental Elite Minions
			var elite_types = ["tank_blue", "tank_yellow", "sniper", "bomber", "teleporter", "swarm"]
			var elements = ["void", "lightning", "ice", "dark"]
			var count = randi_range(3, 5)
			for i in range(count):
				if GameManager.active_enemies.size() >= 160: break
				var e = load("res://scenes/EnemyCommon.tscn").instantiate()
				get_tree().current_scene.add_child(e)
				e.global_position = global_position + Vector2(randf_range(-140, 140), randf_range(-140, 140))
				var chosen_type = elite_types[randi() % elite_types.size()]
				var chosen_element = elements[randi() % elements.size()]
				if e.has_method("setup_type"): e.setup_type(chosen_type)
				e.max_hp *= 2.2
				e.hp = e.max_hp
				e.speed *= 1.25
				e.armor = min(0.75, e.armor + 0.15)
				if e.has_method("apply_element"): e.apply_element(chosen_element, 0.0)
				
		if mega_summon_timer <= 0:
			mega_summon_timer = randf_range(18.0, 26.0)
			_attack_timer = 0.8
			
			# 50% chance to trigger map-wide mega swarm
			if randf() < 0.50:
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
		var dir_to_player = to_player / dist
		if enemy_type == "golden_goblin":
			dir_to_player = -dir_to_player # Runs away from player!
		# Flocking lateral dispersion: prevents single-file conga lines and fans out the horde!
		var perp = Vector2(-dir_to_player.y, dir_to_player.x)
		var lateral_offset = sin(float(get_instance_id() % 31) * 1.3 + wobble_time * 2.2) * 0.32
		var move_dir = (dir_to_player + perp * lateral_offset).normalized()
		velocity = move_dir * current_speed
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
		if is_void_infected:
			var pulse_val = (sin(Time.get_ticks_msec() / 1000.0 * 10.0) + 1.0) * 0.5
			target_color = _original_color.lerp(Color(0.85, 0.25, 1.0), 0.5 + pulse_val * 0.35)
		elif ice_slow_time > 0:
			target_color = Color(0.3, 0.6, 1.0)
		elif _burn_time > 0:
			target_color = _original_color.lerp(Color(1.0, 0.4, 0.0), 0.5)
		elif active_auras.has("dark"):
			var drain_ratio = min(1.0, GameManager.stolen_dark_hp / 100.0)
			target_color = _original_color.lerp(Color.BLACK, 0.3 + drain_ratio * 0.5)
		elif GameManager.is_abyssal_fog:
			target_color = _original_color.lerp(Color(0.45, 0.25, 0.65), 0.4)
		
		if color != target_color:
			color = target_color
			if sprite:
				sprite.modulate = color

	var effective_enemy_r = max(10.0, hit_radius * 0.75)
	var effective_player_r = 12.0
	var touch_r = effective_enemy_r + effective_player_r
	var actual_dist_to_player: float = global_position.distance_squared_to(player.global_position)
	if actual_dist_to_player < touch_r * touch_r and _contact_cooldown <= 0.0:
		var base_strike_dmg = 34.0
		var strike_cd = 0.45
		
		match enemy_type:
			"swarm":
				base_strike_dmg = 22.0
				strike_cd = 0.35
			"tank_yellow":
				base_strike_dmg = 52.0
				strike_cd = 0.55
			"tank_blue", "tank":
				base_strike_dmg = 75.0 # Massive Executioner strike (~75% HP!)
				strike_cd = 0.65
			"sniper":
				base_strike_dmg = 30.0
				strike_cd = 0.5
			"teleporter":
				base_strike_dmg = 40.0
				strike_cd = 0.4
			"summoner":
				base_strike_dmg = 32.0
				strike_cd = 0.5
			"mini_boss":
				base_strike_dmg = 85.0
				strike_cd = 0.65
			"boss":
				base_strike_dmg = 100.0
				strike_cd = 0.75
			_:
				base_strike_dmg = 34.0
				strike_cd = 0.45
				
		var t_mins = GameManager.run_time / 60.0
		# Contact damage scales HARD in late game - getting touched should be terrifying
		var time_scaling = 1.0 + pow(t_mins, 1.5) * 0.45
		if t_mins >= 5.0: time_scaling *= 1.4  # 5 min contact spike
		if t_mins >= 8.0: time_scaling *= 1.8  # 8 min one-shot territory
		var final_strike_dmg = base_strike_dmg * time_scaling
		
		_contact_cooldown = strike_cd
		_attack_timer = 0.3
		player.take_damage(final_strike_dmg, true)
		
		# Violent physical impact push
		if player is CharacterBody2D:
			var push_dir = (player.global_position - global_position).normalized()
			if push_dir.length() < 0.1: push_dir = Vector2.UP
			if "external_force" in player:
				player.external_force += push_dir * 160.0
			else:
				player.velocity += push_dir * 180.0

func take_damage(amount: float) -> void:
	if is_dying: return
	
	var eff_armor = clampf(armor, 0.0, 0.75)
	var final_dmg = amount * (1.0 - eff_armor)

	
	# Critical hit deals x2 damage and pierces 50% of armor!
	if randf() < GameManager.passive_value("crit"):
		final_dmg = amount * (1.0 - eff_armor * 0.5) * 2.0
		color = Color.WHITE
		_is_flashing = true
		_flash_timer = 0.15
		if sprite:
			sprite.modulate = Color.WHITE
	
	hp -= final_dmg
	
	# Combo system hit
	GameManager.register_hit(final_dmg)
	
	if hp <= 0.0:
		_die()
		
func _fire_sniper_projectile(dir: Vector2) -> void:
	var proj = Node2D.new()
	proj.set_script(load("res://scripts/EnemyProjectile.gd"))
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	var t_mins = GameManager.run_time / 60.0
	var dmg = 52.0 * (1.0 + t_mins * 0.25)
	proj.setup(dir * 320.0, dmg)
	
func _explode_bomber() -> void:
	var blast_radius = 85.0
	var blast_r_sq = blast_radius * blast_radius
	var player = GameManager.player
	
	# Damage Player if in blast zone (Heavy Lethal Burst: 70 - 115 HP!)
	if player and is_instance_valid(player):
		var d_sq = global_position.distance_squared_to(player.global_position)
		if d_sq < blast_r_sq:
			var ratio = 1.0 - sqrt(d_sq) / blast_radius
			var dmg = 70.0 + 45.0 * ratio
			player.take_damage(dmg, true)
			player._shake_intensity = 28.0
	
	# Splash damage to surrounding enemies / props
	for e in GameManager.active_enemies:
		if not is_instance_valid(e) or e == self or e.is_queued_for_deletion(): continue
		if global_position.distance_squared_to(e.global_position) < blast_r_sq:
			if e.has_method("take_damage"):
				e.take_damage(85.0)
			if e.has_method("apply_knockback"):
				var dir = (e.global_position - global_position).normalized()
				e.apply_knockback(dir, 350.0)

	# Explosion visual effect
	var p = DEATH_PARTICLE.instantiate()
	if p:
		p.position = global_position
		p.modulate = Color(1.0, 0.25, 0.1)
		p.scale = Vector2(5.0, 5.0)
		get_tree().current_scene.add_child(p)

	queue_free()

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
			if e.has_node("AnimatedSprite2D"):
				e.get_node("AnimatedSprite2D").modulate = Color.RED

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
			var jumps = 3 if GameManager.has_rune_resonance("lightning") else 2
			var chain_dmg = dmg * 0.5 if GameManager.has_rune_resonance("lightning") else dmg * 0.3
			
			var current: Node = self
			var hit_enemies = [self]
			
			for i in range(jumps):
				var next_target = current._get_nearest_enemy_not_in(hit_enemies)
				if next_target:
					hit_enemies.append(next_target)
					if next_target.has_method("take_damage"):
						next_target.take_damage(chain_dmg)
						
					if ElementalVisualEffect.active_count < 12:
						var fx = ElementalVisualEffect.new()
						get_tree().current_scene.add_child(fx)
						fx.setup_lightning(current.global_position, next_target.global_position)
					current = next_target
				else:
					break
		"ice":
			var freeze_chance = 0.1
			if randf() < freeze_chance:
				is_frozen = true
				ice_slow_time = 1.5
			elif randf() < 0.8:
				ice_slow_time = 1.5
			color = Color(0.3, 0.6, 1.0)
			
			var fx = ElementalVisualEffect.new()
			get_tree().current_scene.add_child(fx)
			fx.setup_ice_shatter(global_position)
			queue_redraw()
		"dark":
			var cap_hp = 50.0 if GameManager.has_rune_resonance("dark") else 25.0
			var cap_dmg = 0.25 if GameManager.has_rune_resonance("dark") else 0.15
			if GameManager.stolen_dark_hp < cap_hp:
				GameManager.stolen_dark_hp = min(cap_hp, GameManager.stolen_dark_hp + 0.1)
			if GameManager.stolen_dark_dmg < cap_dmg:
				GameManager.stolen_dark_dmg = min(cap_dmg, GameManager.stolen_dark_dmg + 0.001)
			if GameManager.player:
				GameManager.player._update_max_hp()
				var fx = ElementalVisualEffect.new()
				get_tree().current_scene.add_child(fx)
				fx.setup_dark_siphon(global_position, GameManager.player.global_position)
				
		"void":
			if GameManager.has_rune_resonance("void") and randf() < 0.002: # 0.2%
				GameManager.trigger_void_nuke()
				return
				
			_infect_void(dmg)

func _infect_void(dmg: float) -> void:
	if is_dying or hp <= 0: return
	
	if not active_auras.has("void"):
		active_auras.append("void")
		_check_reactions(dmg)
		
	if not is_void_infected:
		is_void_infected = true
		void_infection_timer = 1.5 # 1.5s delay between infection and collapse
		void_infected_dmg = max(dmg, 20.0)
		queue_redraw()
	else:
		void_infected_dmg = max(void_infected_dmg, dmg)

func _trigger_void_collapse() -> void:
	if not is_void_infected: return
	is_void_infected = false
	active_auras.erase("void")
	
	var has_prism = GameManager.active_relics.has("void_prism")
	var split_count = 3 if has_prism else 2
	var roll = randf()
	
	if roll < 0.90:
		# 90% CHANCE: Chia ra 2 con xung quanh (auto-infects them on impact)
		var targets = _get_nearest_enemies_except(self, split_count, 350.0)
		for t in targets:
			if is_instance_valid(t) and not t.is_queued_for_deletion():
				var rift = VoidRiftEffect.new()
				get_tree().current_scene.add_child(rift)
				var pass_dmg = max(void_infected_dmg * 0.85, max_hp * 0.35)
				rift.setup_split(global_position, t.global_position, t, pass_dmg)
		
		# Micro purple void burst impact fx at source
		var fx = ElementalVisualEffect.new()
		get_tree().current_scene.add_child(fx)
		fx.setup_elemental_burst(global_position, "void")
	else:
		# 10% CHANCE: Biến mất hoàn toàn (Eradication into singularity void, 0 split)
		var rift = VoidRiftEffect.new()
		get_tree().current_scene.add_child(rift)
		rift.setup_eradication(global_position)
	
	if not is_dying:
		if enemy_type == "boss":
			take_damage(max_hp * 0.25)
		else:
			_die()

func _check_reactions(dmg: float) -> void:
	if reaction_cooldown > 0 or is_dying: return
	
	var count = active_auras.size()
	if count >= 4:
		# --- 1. QUADRUPLE REACTION: GENESIS ASTRAL COLLAPSE ---
		reaction_cooldown = 4.0
		var fx = ElementalVisualEffect.new()
		get_tree().current_scene.add_child(fx)
		fx.setup_genesis_collapse(global_position)
		
		armor = 0.0
		is_frozen = true
		ice_slow_time = 4.0
		if enemy_type == "boss":
			take_damage(max_hp * 0.25)
		else:
			take_damage(max_hp * 0.80)
			if hp <= max_hp * 0.80:
				_die()
				return
				
		# Screen-wide shockwave to surrounding enemies
		var nearby = _get_nearest_enemies_except(self, 8, 300.0)
		for t in nearby:
			if is_instance_valid(t) and t.has_method("take_damage"):
				t.take_damage(dmg * 2.5)
				t.armor = max(0.0, t.armor - 0.30)
				
	elif count == 3:
		# --- 2. TRIPLE REACTIONS ---
		reaction_cooldown = 2.2
		var fx = ElementalVisualEffect.new()
		get_tree().current_scene.add_child(fx)
		
		if active_auras.has("lightning") and active_auras.has("ice") and active_auras.has("dark"):
			# Tri-Elemental Tempest (Bão Tố Tam Giác)
			fx.setup_triple_tempest(global_position)
			is_frozen = true
			ice_slow_time = 2.5
			take_damage(dmg * 2.8)
			if GameManager.player: GameManager.player.heal(18.0)
			
		elif active_auras.has("lightning") and active_auras.has("ice") and active_auras.has("void"):
			# Cosmic Sub-Zero Cataclysm (Băng Lôi Vũ Trụ Sụp Đổ)
			fx.setup_genesis_collapse(global_position)
			take_damage(dmg * 3.2)
			var targets = _get_nearest_enemies_except(self, 6, 260.0)
			for t in targets:
				if is_instance_valid(t) and t.has_method("apply_element"):
					t.is_frozen = true
					t.ice_slow_time = 3.0
					t.take_damage(dmg * 1.8)
					
		elif active_auras.has("lightning") and active_auras.has("dark") and active_auras.has("void"):
			# Eldritch Void Thunder (Lôi Phạt Hư Vô Thần Diệt)
			fx.setup_shadow_smite(global_position)
			armor = max(0.0, armor - 0.50)
			take_damage(dmg * 3.5)
			
		else: # ice + dark + void
			# Frozen Abyssal Extinction (Tận Diệt Hắc Băng Vũ Trụ)
			fx.setup_black_ice_tomb(global_position)
			if hp < max_hp * 0.35 and enemy_type != "boss":
				_die()
				return
			else:
				take_damage(dmg * 3.0)
				
	elif count == 2:
		# --- 3. DOUBLE REACTIONS (6 SPECIFIC COMBINATIONS) ---
		reaction_cooldown = 1.0
		var fx = ElementalVisualEffect.new()
		get_tree().current_scene.add_child(fx)
		
		if active_auras.has("lightning") and active_auras.has("ice"):
			# ⚡ + ❄️ Superconductor (Siêu Dẫn Băng Lôi)
			fx.setup_superconductor(global_position)
			armor = max(0.0, armor - 0.50) # Strip 50% armor!
			is_frozen = true
			ice_slow_time = 2.0
			take_damage(dmg * 2.2)
			var targets = _get_nearest_enemies_except(self, 4, 180.0)
			for t in targets:
				if is_instance_valid(t) and t.has_method("take_damage"):
					t.take_damage(dmg * 1.2)
					t.is_frozen = true
					t.ice_slow_time = 1.5
					
		elif active_auras.has("lightning") and active_auras.has("dark"):
			# ⚡ + 👁️ Shadow Smite (Lôi Hồn Hắc Ám)
			fx.setup_shadow_smite(global_position)
			take_damage(dmg * 2.4)
			if GameManager.player:
				GameManager.player.heal(10.0)
				
		elif active_auras.has("lightning") and active_auras.has("void"):
			# ⚡ + 🌌 Void Singularity Discharge (Xung Hư Vô Quá Tải)
			fx.setup_void_discharge(global_position)
			take_damage(dmg * 2.6)
			var targets = _get_nearest_enemies_except(self, 4, 200.0)
			for t in targets:
				if is_instance_valid(t):
					var dir = (global_position - t.global_position).normalized()
					t.global_position += dir * 80.0
					if t.has_method("take_damage"): t.take_damage(dmg * 1.4)
					
		elif active_auras.has("ice") and active_auras.has("dark"):
			# ❄️ + 👁️ Black Ice Tomb (Mộ Băng Hắc Ám)
			fx.setup_black_ice_tomb(global_position)
			is_frozen = true
			ice_slow_time = 3.5
			apply_burn(dmg * 0.6, 3.5) # 80 DPS in tomb
			take_damage(dmg * 1.8)
			
		elif active_auras.has("ice") and active_auras.has("void"):
			# ❄️ + 🌌 Absolute Zero (Điểm Không Tuyệt Đối)
			fx.setup_absolute_zero(global_position)
			var hp_loss = max_hp * 0.30 if enemy_type != "boss" else max_hp * 0.15
			take_damage(hp_loss)
			
		elif active_auras.has("dark") and active_auras.has("void"):
			# 👁️ + 🌌 Abyssal Black Hole (Hố Đen Vực Thẳm)
			fx.setup_abyssal_vortex(global_position)
			if hp < max_hp * 0.35 and enemy_type != "boss":
				_die()
				return
			else:
				take_damage(dmg * 3.0)





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
	GameManager.unregister_enemy(self)
	
	# If this enemy died while void-infected, collapse & propagate before removal
	if is_void_infected:
		_trigger_void_collapse()
	
	if is_instance_valid(boss_warning_line):
		boss_warning_line.queue_free()
	if enemy_type == "boss":
		for n in get_tree().current_scene.get_children():
			if n.has_meta("boss_bomb"):
				n.queue_free()
				
	GameManager.register_kill()
	
	if enemy_type == "golden_goblin":
		var chest = load("res://scripts/TreasureChest.gd").new()
		chest.global_position = global_position
		get_tree().current_scene.add_child(chest)
		GameManager.wave_event_triggered.emit("GOBLIN SLAIN!", "The Golden Goblin dropped an ancient Treasure Chest!")
	
	XPOrb.spawn_or_merge(global_position, xp_value, get_tree().current_scene, XP_ORB_SCENE)

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

	# Treasure Chest drop (100% for mini-boss/boss, 15% for heavy tanks/summoners)
	var chest_chance = 0.0
	if enemy_type == "boss" or enemy_type == "mini_boss":
		chest_chance = 1.0
	elif enemy_type == "tank_blue" or enemy_type == "summoner":
		chest_chance = 0.15
		
	if randf() < chest_chance:
		var chest = Area2D.new()
		chest.set_script(load("res://scripts/TreasureChest.gd"))
		get_tree().current_scene.add_child(chest)
		chest.global_position = global_position

	queue_free()


func _draw() -> void:
	# Draw shadow
	draw_circle(Vector2.ZERO, hit_radius * 0.7, Color(0, 0, 0, 0.25))
	
	# Frozen ice cage visual
	if is_frozen:
		draw_rect(Rect2(-hit_radius, -hit_radius - 20, hit_radius * 2, hit_radius * 2), Color(0.5, 0.8, 1.0, 0.5), false, 2.0)
		
	# Void infection visual: swirling event horizon + 1.5s countdown gauge
	if is_void_infected:
		var time = Time.get_ticks_msec() / 1000.0
		var pulse = sin(time * 10.0) * 2.5
		# Swirling void ring around enemy base
		draw_arc(Vector2.ZERO, hit_radius + 4.0 + pulse, 0, TAU, 20, Color(0.75, 0.15, 0.95, 0.7), 2.0)
		draw_circle(Vector2.ZERO, (hit_radius + 4.0 + pulse) * 0.85, Color(0.3, 0.05, 0.45, 0.25))
		
		# 1.5s countdown gauge above head
		var ratio = clampf(void_infection_timer / 1.5, 0.0, 1.0)
		var center_head = Vector2(0, -hit_radius - 26.0)
		# Background dark ring
		draw_circle(center_head, 7.0, Color(0.1, 0.0, 0.18, 0.85))
		draw_arc(center_head, 7.0, 0, TAU, 16, Color(0.3, 0.1, 0.4, 0.6), 1.5)
		# Filling/winding timer arc (shrinks down to 0)
		var arc_angle = ratio * TAU
		draw_arc(center_head, 7.0, -PI * 0.5, -PI * 0.5 + arc_angle, 16, Color(0.95, 0.35, 1.0, 0.95), 2.5)
		# Inner pulsating singularity core
		draw_circle(center_head, 3.0 + (1.0 - ratio) * 2.0, Color(0.85, 0.2, 1.0, 0.9))
	elif active_auras.has("void"):
		var time = Time.get_ticks_msec() / 1000.0
		var orb_y = sin(time * 4.0) * 3.0 - hit_radius - 28.0
		draw_arc(Vector2(0, orb_y), 6.0, 0, TAU, 16, Color(0.6, 0.2, 0.8), 2.0)
		draw_circle(Vector2(0, orb_y), 2.0, Color(0.8, 0.4, 1.0))

	# Bomber fuse flash (handled via sprite modulate now, but keep HP bar hint)
	if enemy_type == "bomber" and bomber_fuse >= 0:
		var alpha = fmod(bomber_fuse * 3.14, 1.0)
		draw_circle(Vector2(0, -hit_radius - 30), 5.0, Color(1.0, 0.3, 0.0, alpha))
