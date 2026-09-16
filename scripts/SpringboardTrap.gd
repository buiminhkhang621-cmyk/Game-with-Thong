extends Node2D
class_name SpringboardTrap

var launch_force: float = 450.0
var launch_dir: Vector2 = Vector2.UP
var bounce_anim: float = 0.0
var cooldown: float = 0.0

func setup(data: Dictionary) -> void:
	global_position = Vector2(data.get("x", 0), data.get("y", 0))
	launch_force = data.get("launch_force", 450.0)
	var angles = [0, PI * 0.5, PI, PI * 1.5, PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]
	var a = angles[randi() % angles.size()]
	launch_dir = Vector2(cos(a), sin(a))
	rotation = a

func _process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown -= delta
	if bounce_anim > 0.0:
		bounce_anim -= delta * 3.0
		
	if cooldown <= 0.0:
		# Check Player Step
		var player = GameManager.player
		if player and is_instance_valid(player):
			if player.z_height <= 0.0 and global_position.distance_squared_to(player.global_position) < 24.0 * 24.0:
				_trigger_launch(player)
				
		# Check Enemy Step
		for e in GameManager.active_enemies:
			if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
			if global_position.distance_squared_to(e.global_position) < 24.0 * 24.0:
				if e.has_method("apply_knockback"):
					e.apply_knockback(launch_dir, launch_force * 1.2)
					bounce_anim = 1.0
					cooldown = 0.6
					break
					
	queue_redraw()

func _trigger_launch(player: Node2D) -> void:
	bounce_anim = 1.0
	cooldown = 0.8
	player.global_position += launch_dir * 120.0
	player.z_height = 40.0
	player._jump_vel = 320.0
	player._shake_intensity = 15.0
	
	# Show "BOING!" popup text
	var dn = load("res://scenes/DamageNumber.tscn").instantiate()
	get_tree().current_scene.add_child(dn)
	dn.global_position = global_position
	dn.setup(0, true, Color(1.0, 0.85, 0.2))
	if dn.has_node("Label"):
		dn.get_node("Label").text = "BOING!"

func _draw() -> void:
	# Base Plate (32x32)
	draw_rect(Rect2(-16, -16, 32, 32), Color(0.18, 0.16, 0.12))
	draw_rect(Rect2(-16, -16, 32, 32), Color(0.9, 0.75, 0.25), false, 2.0)
	
	# Spring Coils
	var s_offset = sin(bounce_anim * PI) * 6.0
	draw_circle(Vector2(s_offset, 0), 9.0, Color(0.85, 0.65, 0.2))
	
	# Direction Arrow pointing in launch_dir
	var arrow = PackedVector2Array([
		Vector2(12, 0),
		Vector2(-4, -8),
		Vector2(-4, -3),
		Vector2(-12, -3),
		Vector2(-12, 3),
		Vector2(-4, 3),
		Vector2(-4, 8)
	])
	draw_polygon(arrow, PackedColorArray([Color(1.0, 0.9, 0.3)]))
