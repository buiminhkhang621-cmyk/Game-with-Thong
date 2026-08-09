class_name Player
extends CharacterBody2D

@export var move_speed: float = 170.0
@export var base_max_hp: float = 100.0

var hp: float
var hit_radius: float = 12.0
var god_mode: bool = false

var _effective_max_hp: float
var _shake_intensity: float = 0.0

var _dark_state_timer: float = 0.0
var in_dark_state: bool = false
var _dark_state_duration: float = 0.0

var z_height: float = 0.0
var z_velocity: float = 0.0
const GRAVITY: float = 800.0
const JUMP_FORCE: float = 250.0

@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	hp = base_max_hp
	
	match GameManager.current_class:
		"berserker": hp *= 0.9 # -10% HP
		"void_mage": hp *= 0.9 # -10% HP
		
	base_max_hp = hp
	_effective_max_hp = base_max_hp
	GameManager.register_player(self)
	GameManager.level_changed.connect(_on_level_changed)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = hit_radius * 0.8
	col.shape = shape
	add_child(col)

	collision_layer = 2
	collision_mask = 1

	queue_redraw()
	GameManager.hp_changed.emit(hp, _effective_max_hp)


var _berserker_time: float = 0.0
var berserker_dmg_buff: float = 0.0

var _landing_i_frames: float = 0.0

func _physics_process(delta: float) -> void:
	_update_max_hp()
	
	if _landing_i_frames > 0.0:
		_landing_i_frames -= delta
	
	if GameManager.current_class == "berserker":
		_berserker_time += delta
		if _berserker_time >= 2.0:
			_berserker_time = 0.0
			berserker_dmg_buff = min(0.3, berserker_dmg_buff + 0.01)
	
	if z_height > 0.0 or z_velocity != 0.0:
		z_velocity -= GRAVITY * delta
		z_height += z_velocity * delta
		if z_height <= 0.0:
			z_height = 0.0
			z_velocity = 0.0
			_apply_landing_knockback()
			_landing_i_frames = 0.25 # Invulnerable to ground attacks while enemies are pushed back
	if z_height > 15.0:
		set_collision_mask_value(1, false) # Disable obstacle collision
		z_index = 10
	else:
		set_collision_mask_value(1, true)
		z_index = 0
		
	# Ice Resonance Aura
	if GameManager.has_rune_resonance("ice"):
		var ice_radius = 150.0
		var dmg_per_sec = 20.0 * (1.0 + GameManager.passive_value("damage"))
		for e in get_tree().get_nodes_in_group("enemies"):
			if global_position.distance_to(e.global_position) <= ice_radius:
				if e.has_method("take_damage"):
					e.take_damage(dmg_per_sec * delta)
				if e.has_method("apply_element"):
					e.ice_slow_time = max(e.ice_slow_time, 0.5)
					e.color = Color(0.3, 0.6, 1.0)
					if not e.is_frozen and randf() < 0.05 * delta:
						e.is_frozen = true
					e.queue_redraw()
				
	# Dark Resonance
	if GameManager.has_rune_resonance("dark"):
		_dark_state_timer += delta
		if _dark_state_timer >= 10.0:
			_dark_state_timer = 0.0
			if randf() < 0.1:
				in_dark_state = true
				_dark_state_duration = 3.0
				
	if in_dark_state:
		_dark_state_duration -= delta
		heal(_effective_max_hp * 0.05 * delta) # Heal 5% per sec
		if _dark_state_duration <= 0.0:
			in_dark_state = false

	queue_redraw()

	if _shake_intensity > 0.0:
		_shake_intensity = lerpf(_shake_intensity, 0.0, delta * 10.0)
		if GameManager.setting_screen_shake:
			camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_intensity
		else:
			camera.offset = Vector2.ZERO
	else:
		camera.offset = Vector2.ZERO

	if GameManager.game_over or GameManager.paused_for_levelup:
		return

	var dir := Vector2.ZERO
	dir.x = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) \
		- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	dir.y = float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) \
		- float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	if dir.length() > 0.0:
		dir = dir.normalized()

	var speed_mult := move_speed * (1.0 + GameManager.passive_value("movespeed"))
	if in_dark_state:
		speed_mult *= 1.5 # +50% speed
		
	velocity = dir * speed_mult
	move_and_slide()

	if Input.is_key_pressed(KEY_SPACE) and z_height == 0.0:
		z_velocity = JUMP_FORCE


func _update_max_hp() -> void:
	var new_max := base_max_hp + GameManager.passive_value("maxhp")
	if new_max != _effective_max_hp:
		hp += (new_max - _effective_max_hp)
		_effective_max_hp = new_max
		hp = min(hp, _effective_max_hp)
		GameManager.hp_changed.emit(hp, _effective_max_hp)

func _apply_landing_knockback() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("apply_knockback"):
			var dist = global_position.distance_to(e.global_position)
			if dist < hit_radius + e.hit_radius + 40.0:
				var dir = (e.global_position - global_position).normalized()
				if dir.length() < 0.1:
					dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				e.apply_knockback(dir, 200.0)
				# Also deal a small amount of damage on landing?
				if e.has_method("take_damage"):
					e.take_damage(5.0)


func take_damage(amount: float, is_ground_attack: bool = true) -> void:
	if GameManager.game_over or in_dark_state or god_mode:
		return
	if is_ground_attack and (z_height > 0.0 or _landing_i_frames > 0.0):
		return # Dodged by jumping or landing i-frames
		
	# Tier 2 Passive: 8% dodge chance
	if GameManager.get_total_passive_levels() >= 10:
		if randf() < 0.08:
			return # Dodged by passive
		
	var dmg = amount
	
	# Apply armor (max 75% reduction)
	var armor = min(0.75, GameManager.passive_value("armor"))
	dmg *= (1.0 - armor)
	
	if GameManager.current_class == "vanguard":
		dmg *= 0.8
		
	if GameManager.active_curses.has("mong_manh"):
		dmg *= 1.25
		
	if GameManager.current_class == "berserker":
		_berserker_time = 0.0
		berserker_dmg_buff = 0.0
		
	hp -= dmg
	_shake_intensity = 15.0
	
	if dmg >= 1.0:
		var dn = load("res://scenes/DamageNumber.tscn").instantiate()
		get_tree().current_scene.add_child(dn)
		dn.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 0))
		dn.setup(dmg, false, Color(1.0, 0.4, 0.4))
	
	GameManager.hp_changed.emit(hp, _effective_max_hp)
	if hp <= 0.0:
		hp = 0.0
		GameManager.on_player_died()


func heal(amount: float) -> void:
	var amt = amount
	if GameManager.current_class == "vanguard":
		amt *= 0.7
	hp = min(_effective_max_hp, hp + amt)
	GameManager.hp_changed.emit(hp, _effective_max_hp)


func _on_level_changed(_new_level: int) -> void:
	heal(8.0)


func _draw() -> void:
	# Draw shadow always, scale down and fade out slightly when jumping
	var shadow_scale = clampf(1.0 - z_height / 100.0, 0.5, 1.0)
	draw_circle(Vector2.ZERO, hit_radius * 0.8 * shadow_scale, Color(0, 0, 0, 0.3 * shadow_scale))

	if GameManager.has_rune_resonance("ice"):
		var r = 150.0
		draw_circle(Vector2.ZERO, r, Color(0.6, 0.9, 1.0, 0.15))
		var time = Time.get_ticks_msec() / 1000.0
		for i in range(3):
			var r_anim = r * fmod(time + i * 0.33, 1.0)
			draw_arc(Vector2.ZERO, r_anim, 0, TAU, 32, Color(0.6, 0.9, 1.0, 0.4 * (1.0 - r_anim/r)), 2.0)

	var center = Vector2(0, -z_height)
	var goo_color = Color(0.1, 0.05, 0.2)
	
	if in_dark_state:
		goo_color = Color(0.0, 0.0, 0.0, 0.5) # Shadowy goo
	else:
		match GameManager.current_class:
			"berserker": goo_color = Color(0.8, 0.2, 0.2)
			"vanguard": goo_color = Color(0.9, 0.8, 0.3)
			"assassin": goo_color = Color(0.3, 0.3, 0.8)
			"void_mage": goo_color = Color(0.6, 0.2, 0.8)

	# Draw Goo Body
	draw_circle(center, hit_radius, goo_color)
	draw_circle(center + Vector2(-6, -4), 4, Color.WHITE)
	draw_circle(center + Vector2(6, -4), 4, Color.WHITE)
	draw_circle(center + Vector2(-6, -4), 1.5, Color.BLACK)
	draw_circle(center + Vector2(6, -4), 1.5, Color.BLACK)
	
	match GameManager.current_class:
		"berserker":
			draw_line(center + Vector2(10, 0), center + Vector2(25, -15), Color.BROWN, 4)
			draw_circle(center + Vector2(25, -15), 6, Color(0.8, 0.2, 0.2))
		"vanguard":
			draw_rect(Rect2(center.x - 20, center.y - 5, 10, 20), Color.LIGHT_GRAY, false, 3)
		"assassin":
			draw_line(center + Vector2(8, 5), center + Vector2(20, 10), Color.DARK_GRAY, 3)
		"void_mage":
			draw_circle(center + Vector2(-20, -10), 4, Color.PURPLE)
			draw_circle(center + Vector2(20, -10), 4, Color.PURPLE)
