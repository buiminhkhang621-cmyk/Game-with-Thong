class_name DestructibleProp
extends Area2D

@export var max_hp: float = 12.0
var hp: float = 12.0
var hit_radius: float = 14.0
var _flash_timer: float = 0.0

const DEATH_PARTICLE = preload("res://scenes/DeathParticle.tscn")
const XP_ORB_SCENE = preload("res://scenes/XPOrb.tscn")

func _ready() -> void:
	hp = max_hp
	add_to_group("destructibles")
	add_to_group("enemies") # Allows skills like Orbit, Whip, AoE, Projectile to target it naturally
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = hit_radius
	col.shape = shape
	add_child(col)
	
	collision_layer = 4
	collision_mask = 2 # Player & weapons
	
	queue_redraw()

func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			queue_redraw()

func take_damage(amount: float) -> void:
	hp -= amount
	_flash_timer = 0.12
	queue_redraw()
	
	if hp <= 0.0:
		_break()

func apply_element(_elem: String, _dmg: float) -> void:
	pass

func apply_knockback(_dir: Vector2, _force: float) -> void:
	pass

func _break() -> void:
	# Spawn particles
	if DEATH_PARTICLE:
		var p = DEATH_PARTICLE.instantiate()
		p.position = global_position
		p.modulate = Color(0.7, 0.55, 0.35)
		get_tree().current_scene.add_child(p)
		
	# 60% chance for Floor Drop, otherwise XP
	if randf() < 0.60:
		var drop_types = ["blood_vial", "blood_vial", "void_magnet", "cataclysm_nuke", "time_stasis"]
		var selected_type = drop_types[randi() % drop_types.size()]
		
		var pickup = load("res://scripts/FloorPickup.gd").new()
		get_tree().current_scene.add_child(pickup)
		pickup.global_position = global_position
		pickup.setup(selected_type)
	else:
		var orb = XP_ORB_SCENE.instantiate()
		get_tree().current_scene.add_child(orb)
		orb.global_position = global_position
		orb.value = randi_range(3, 8)
		
	queue_free()

func _draw() -> void:
	var body_color = Color(0.55, 0.42, 0.28) if _flash_timer <= 0.0 else Color.WHITE
	var rim_color = Color(0.35, 0.25, 0.15)
	
	# Shadow
	draw_circle(Vector2(0, 4), hit_radius * 0.8, Color(0, 0, 0, 0.3))
	
	# Urn / Crate Body
	var pts = PackedVector2Array([
		Vector2(-9, -10),
		Vector2(9, -10),
		Vector2(12, 2),
		Vector2(7, 10),
		Vector2(-7, 10),
		Vector2(-12, 2)
	])
	draw_polygon(pts, PackedColorArray([body_color]))
	draw_polyline(pts, rim_color, 2.0)
	
	# Golden rune carving on prop
	draw_line(Vector2(0, -6), Vector2(0, 6), Color(0.8, 0.7, 0.3, 0.8), 2.0)
	draw_line(Vector2(-4, -1), Vector2(4, -1), Color(0.8, 0.7, 0.3, 0.8), 2.0)
