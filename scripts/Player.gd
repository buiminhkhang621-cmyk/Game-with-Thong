class_name Player
extends CharacterBody2D

@export var move_speed: float = 170.0
@export var base_max_hp: float = 100.0

var hp: float
var hit_radius: float = 12.0

var _effective_max_hp: float
var _shake_intensity: float = 0.0

var _dark_state_timer: float = 0.0
var in_dark_state: bool = false
var _dark_state_duration: float = 0.0

var external_force: Vector2 = Vector2.ZERO

var z_height: float = 0.0
var z_velocity: float = 0.0
const GRAVITY: float = 800.0
const JUMP_FORCE: float = 250.0

@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $Sprite2D




func _ready() -> void:
	setup_class(GameManager.current_class)
	GameManager.register_player(self)
	GameManager.level_changed.connect(_on_level_changed)
	
	apply_skin(GameManager.selected_skin)

func setup_class(class_id: String) -> void:
	set_physics_process(true)
	set_process(true)
	z_height = 0.0
	z_velocity = 0.0
	external_force = Vector2.ZERO
	_hurt_timer = 0.0
	_landing_i_frames = 0.0
	_damage_i_frames = 0.0
	_jump_cooldown = 0.0
	in_dark_state = false
	
	match class_id:
		"vanguard":
			base_max_hp = 185.0 # Tank Archetype: Massive Health Pool
			move_speed = 160.0
		"assassin":
			base_max_hp = 75.0  # Poke Archetype: Fragile Glass Cannon
			move_speed = 215.0  # Swift kiting speed
		"void_mage":
			base_max_hp = 85.0  # Mage Archetype: Arcane Cloth Caster
			move_speed = 170.0
		"berserker":
			base_max_hp = 130.0 # Bruiser Archetype: Resilient Frontliner
			move_speed = 180.0
		_:
			base_max_hp = 100.0
			move_speed = 170.0
			
	hp = base_max_hp
	_effective_max_hp = base_max_hp
	if sprite:
		sprite.play("idle")
	if GameManager:
		GameManager.hp_changed.emit(hp, _effective_max_hp)
	
	apply_skin(GameManager.selected_skin)

func apply_skin(skin_id: String) -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if not sprite:
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames_path = "res://Sprite/Player/PlayerFrames.tres"
	if skin_id == "purple_mage":
		frames_path = "res://Sprite/Player/PurpleMage/PurpleMageFrames.tres"
	var sf = load(frames_path)
	if sf:
		sprite.sprite_frames = sf
		sprite.play("idle")

	# Only add collision shape once (prevents stacking on restart)
	if not has_node("PlayerCollision"):
		var col = CollisionShape2D.new()
		col.name = "PlayerCollision"
		var shape = CircleShape2D.new()
		shape.radius = hit_radius * 0.8
		col.shape = shape
		add_child(col)

	# Only add rune aura once
	if not has_node("RunePossessionAura"):
		var rune_aura = RunePossessionAura.new()
		rune_aura.name = "RunePossessionAura"
		add_child(rune_aura)

	collision_layer = 2
	collision_mask = 1

	queue_redraw()
	GameManager.hp_changed.emit(hp, _effective_max_hp)


var _berserker_time: float = 0.0
var berserker_dmg_buff: float = 0.0

var _jump_cooldown: float = 0.0
var _landing_i_frames: float = 0.0
var _hurt_timer: float = 0.0
var _ice_aura_timer: float = 0.0
var _damage_i_frames: float = 0.0
var _bg_ref: Node2D = null

func _get_bg() -> Node2D:
	if not _bg_ref or not is_instance_valid(_bg_ref):
		if get_parent() and get_parent().has_node("Background"):
			_bg_ref = get_parent().get_node("Background")
		elif get_tree() and get_tree().current_scene:
			_bg_ref = get_tree().current_scene.find_child("Background", true, false)
	return _bg_ref

var _hp_update_timer: float = 0.0

func _physics_process(delta: float) -> void:
	# Rate-limit expensive HP recalculation to 2x per second
	_hp_update_timer -= delta
	if _hp_update_timer <= 0.0:
		_hp_update_timer = 0.5
		_update_max_hp()
	
	if _jump_cooldown > 0.0:
		_jump_cooldown -= delta
	
	if _landing_i_frames > 0.0:
		_landing_i_frames -= delta

	if _damage_i_frames > 0.0:
		_damage_i_frames -= delta

	if GameManager.current_class == "berserker":
		_berserker_time += delta
		if _berserker_time >= 1.2:
			_berserker_time = 0.0
			berserker_dmg_buff = min(0.35, berserker_dmg_buff + 0.02)
	elif GameManager.current_class == "vanguard" and not GameManager.game_over and hp > 0.0 and hp < _effective_max_hp:
		# Tank Archetype: Runic Bastion (1.5 HP/s Passive Regeneration)
		heal(1.5 * delta)
	
	if z_height > 0.0 or z_velocity != 0.0:
		z_velocity -= GRAVITY * delta
		z_height += z_velocity * delta
		if z_height <= 0.0:
			z_height = 0.0
			z_velocity = 0.0
			_apply_landing_knockback()
			_landing_i_frames = 0.25 # Invulnerable to ground attacks while enemies are pushed back

	# Maintain Layer 1 collision (Walls and Abyss boundary)
	set_collision_mask_value(1, true)
	if z_height > 15.0:
		z_index = 10
	else:
		z_index = 0

	# Ice Resonance Aura
	if GameManager.has_rune_resonance("ice"):
		_ice_aura_timer -= delta
		if _ice_aura_timer <= 0.0:
			_ice_aura_timer = 0.25 # Tick 4 times a second
			var ice_radius_sq = 150.0 * 150.0
			var tick_dmg = 20.0 * 0.25 * (1.0 + GameManager.passive_value("damage"))
			for e in GameManager.active_enemies:
				if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
				if global_position.distance_squared_to(e.global_position) <= ice_radius_sq:
					if e.has_method("take_damage"):
						e.take_damage(tick_dmg)
					if e.has_method("apply_element"):
						e.ice_slow_time = max(e.ice_slow_time, 0.5)
						e.color = Color(0.3, 0.6, 1.0)
						if not e.is_frozen and randf() < 0.05 * 0.25:
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

	if GameManager.game_over:
		if sprite.animation != "death":
			sprite.play("death")
		_update_sprite_visuals()
		return
		
	if GameManager.paused_for_levelup:
		_update_sprite_visuals()
		return
		
	if hp <= 0:
		if sprite.animation != "death":
			sprite.play("death")
		_update_sprite_visuals()
		return

	var dir := Vector2.ZERO
	var right = Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right")
	var left = Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left")
	var down = Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("ui_down")
	var up = Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("ui_up")
	
	dir.x = float(right) - float(left)
	dir.y = float(down) - float(up)
	
	var joy_vec = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if joy_vec.length() > 0.1 and dir.length() == 0.0:
		dir = joy_vec
		
	if dir.length() > 0.0:
		dir = dir.normalized()

	var speed_mult: float = move_speed * (1.0 + GameManager.passive_value("movespeed"))
	if in_dark_state:
		speed_mult *= 1.5
	if GameManager.weapons_disabled:
		speed_mult *= 1.5 # +50% speed during silence trial!
		
	velocity = dir * speed_mult + external_force
	move_and_slide()
	external_force = external_force.move_toward(Vector2.ZERO, 350.0 * delta)

	# Jump logic: layer 1 collision barrier stops player from jumping into the void
	var jump_pressed = Input.is_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_action_pressed("ui_accept")
	if jump_pressed and z_height == 0.0 and _jump_cooldown <= 0.0:
		z_velocity = JUMP_FORCE
		_jump_cooldown = 0.8
		_shake_intensity = 4.0
		
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		if sprite.animation != "hurt":
			sprite.play("hurt")
	else:
		# Update sprite flip and animation
		if velocity.length() > 0.1:
			sprite.flip_h = velocity.x < 0
			if z_height == 0.0:
				sprite.play("move")
		else:
			if z_height == 0.0:
				sprite.play("idle")
				
		if z_height > 0.0:
			if z_velocity > 0.0:
				sprite.play("jumping")
			else:
				sprite.play("falling")
			
	_update_sprite_visuals()




func _update_sprite_visuals() -> void:
	if not sprite:
		return
	
	# Offset sprite upward when jumping (z-height simulation)
	sprite.position.y = -z_height
	
	# Visual tint based on game state
	if in_dark_state:
		sprite.modulate = Color(0.4, 0.1, 0.6, 0.9)  # Shadowy purple
	elif GameManager.weapons_disabled:
		sprite.modulate = Color(0.5, 0.8, 1.0) # Ethereal silence blue
	elif GameManager.is_blood_sacrifice:
		sprite.modulate = Color(1.0, 0.3, 0.3) # Crimson rage red
	else:
		sprite.modulate = Color.WHITE


func _update_max_hp() -> void:
	var flat_bonus = GameManager.relic_value("flat_hp") + GameManager.stolen_dark_hp
	var hp_mult = 1.0 + GameManager.passive_value("vitality") + GameManager.relic_value("hp_mult")
	var new_max = max(10.0, (base_max_hp + flat_bonus) * hp_mult)
	if abs(new_max - _effective_max_hp) > 0.5:
		var diff = new_max - _effective_max_hp
		_effective_max_hp = new_max
		if diff > 0:
			hp = min(_effective_max_hp, hp + diff)
		else:
			hp = min(_effective_max_hp, hp)
		GameManager.hp_changed.emit(hp, _effective_max_hp)

func _apply_landing_knockback() -> void:
	var is_silence = GameManager.weapons_disabled
	var is_tank = GameManager.current_class == "vanguard"
	var stomp_dmg = 65.0 if is_silence else (25.0 if is_tank else 5.0)
	var stomp_force = 450.0 if is_silence else (360.0 if is_tank else 200.0)
	var extra_r = 90.0 if is_silence else (60.0 if is_tank else 40.0)
	
	if is_silence:
		_shake_intensity = 15.0
	
	# Spawn landing shockwave burst visual
	var fx = ElementalVisualEffect.new()
	get_tree().current_scene.add_child(fx)
	fx.setup_elemental_burst(global_position, "ice" if is_silence else "lightning")
	
	for e in GameManager.active_enemies.duplicate():
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		if e.has_method("apply_knockback"):
			var r = hit_radius + e.hit_radius + extra_r
			var dist_sq = global_position.distance_squared_to(e.global_position)
			if dist_sq < r * r:
				var dir = (e.global_position - global_position).normalized()
				if dir.length() < 0.1:
					dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				e.apply_knockback(dir, stomp_force)
				if e.has_method("take_damage"):
					e.take_damage(stomp_dmg)


func take_damage(amount: float, is_ground_attack: bool = true) -> void:
	if GameManager.game_over or in_dark_state:
		return
	if is_ground_attack and (z_height > 0.0 or _landing_i_frames > 0.0 or _damage_i_frames > 0.0):
		return # Dodged by jumping, landing i-frames, or brief damage i-frames
	if not is_ground_attack and _damage_i_frames > 0.0:
		return
		
	# Assassin Archetype: 15% innate dodge agility
	if GameManager.current_class == "assassin" and randf() < 0.15:
		if GameManager.setting_damage_numbers:
			var dn = load("res://scenes/DamageNumber.tscn").instantiate()
			var target_parent = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
			if target_parent:
				target_parent.add_child(dn)
				dn.global_position = global_position + Vector2(0, -20)
				dn.setup(0.0, false, Color(0.4, 0.9, 1.0))
		return

	# Tier 2 Passive: 8% dodge chance
	if GameManager.get_total_passive_levels() >= 10:
		if randf() < 0.08:
			return # Dodged by passive
		
	var dmg = amount
	
	# Apply armor (max 75% reduction)
	var armor = min(0.75, GameManager.passive_value("armor"))
	dmg *= (1.0 - armor)
	
	# Vanguard: -30% flat damage mitigation (Iron Bastion)
	if GameManager.current_class == "vanguard":
		dmg *= 0.70
		
	# Berserker: Last Stand (-15% damage taken when below 40% HP)
	if GameManager.current_class == "berserker" and hp <= _effective_max_hp * 0.40:
		dmg *= 0.85
		
	if GameManager.active_curses.has("mong_manh"):
		dmg *= 1.25
		
	if GameManager.active_relics.has("death_scythe_shard"):
		dmg *= 1.15
		
	if GameManager.current_class == "berserker":
		_berserker_time = 0.0
		berserker_dmg_buff = max(0.0, berserker_dmg_buff * 0.65)
		
	hp -= dmg
	_damage_i_frames = 0.18 # 180ms reaction window against dense horde stacks
	_shake_intensity = 22.0
	_hurt_timer = 0.3 # 0.3 seconds of hurt animation
	
	# Vanguard Kinetic Thorns: Retaliatory shockwave when taking hits
	if GameManager.current_class == "vanguard" and dmg >= 4.0 and is_inside_tree():
		var fx = ElementalVisualEffect.new()
		get_tree().current_scene.add_child(fx)
		fx.setup_elemental_burst(global_position, "lightning")
		for e in GameManager.active_enemies:
			if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
			if global_position.distance_squared_to(e.global_position) < 110.0 * 110.0:
				if e.has_method("apply_knockback"):
					var kb_dir = (e.global_position - global_position).normalized()
					e.apply_knockback(kb_dir, 190.0)
				if e.has_method("take_damage"):
					e.take_damage(16.0)

	if sprite:
		sprite.modulate = Color(1.0, 0.2, 0.2)
		var tween = get_tree().create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
	if dmg >= 1.0 and GameManager.setting_damage_numbers:
		var dn = load("res://scenes/DamageNumber.tscn").instantiate()
		var target_parent = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
		if target_parent:
			target_parent.add_child(dn)
			dn.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 0))
			dn.setup(dmg, false, Color(1.0, 0.4, 0.4))
	
	GameManager.hp_changed.emit(hp, _effective_max_hp)
	
	if hp <= 0.0:
		hp = 0.0
		if sprite:
			sprite.pause()
		set_physics_process(false)
		set_process(false)
		GameManager.on_player_died()


func heal(amount: float) -> void:
	var amt = amount
	hp = min(_effective_max_hp, hp + amt)
	GameManager.hp_changed.emit(hp, _effective_max_hp)


func _on_level_changed(_new_level: int) -> void:
	heal(8.0)


func _draw() -> void:
	# Draw shadow on the ground (not affected by jump height)
	var shadow_scale = clampf(1.0 - z_height / 100.0, 0.5, 1.0)
	draw_circle(Vector2.ZERO, hit_radius * 0.8 * shadow_scale, Color(0, 0, 0, 0.35 * shadow_scale))

	# Ice Resonance aura ring (ground-level effect)
	if GameManager.has_rune_resonance("ice"):
		var r = 150.0
		draw_circle(Vector2.ZERO, r, Color(0.6, 0.9, 1.0, 0.12))
		var time = Time.get_ticks_msec() / 1000.0
		for i in range(3):
			var r_anim = r * fmod(time + i * 0.33, 1.0)
			draw_arc(Vector2.ZERO, r_anim, 0, TAU, 32, Color(0.6, 0.9, 1.0, 0.4 * (1.0 - r_anim/r)), 2.0)

	var center = Vector2(0, -z_height - 20.0)
	# Dark state shimmer effect around sprite
	if in_dark_state:
		var time2 = Time.get_ticks_msec() / 1000.0
		for i in range(4):
			var angle = time2 * 2.0 + i * TAU / 4.0
			var orb_pos = center + Vector2(cos(angle), sin(angle) * 0.5) * 18.0
			draw_circle(orb_pos, 3.5, Color(0.3, 0.0, 0.5, 0.8))

	# Class weapon visual (drawn relative to sprite position)
	match GameManager.current_class:
		"berserker":
			draw_line(center + Vector2(10, 4), center + Vector2(22, -8), Color(0.6, 0.2, 0.0), 3)
			draw_circle(center + Vector2(22, -8), 4, Color(0.9, 0.3, 0.1))
		"vanguard":
			draw_rect(Rect2(center.x - 18, center.y, 8, 18), Color(0.8, 0.8, 0.8, 0.9), false, 2)
		"assassin":
			draw_line(center + Vector2(8, 6), center + Vector2(20, 14), Color(0.3, 0.3, 0.4), 2)
		"void_mage":
			var t = Time.get_ticks_msec() / 1000.0
			draw_circle(center + Vector2(cos(t * 3) * 16, sin(t * 3) * 8), 3, Color(0.7, 0.3, 1.0, 0.9))
			draw_circle(center + Vector2(cos(t * 3 + PI) * 16, sin(t * 3 + PI) * 8), 3, Color(0.5, 0.1, 0.9, 0.9))
