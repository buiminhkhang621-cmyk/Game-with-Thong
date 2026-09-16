extends Node2D
class_name AbyssalChasm

var radius: float = 100.0
var has_bridge: bool = false
var bridge_width: float = 36.0

func setup(chasm_data: Dictionary) -> void:
	global_position = Vector2(chasm_data.get("x", 0), chasm_data.get("y", 0))
	radius = chasm_data.get("radius", 100.0)
	has_bridge = chasm_data.get("has_bridge", false)
	queue_redraw()

func _process(delta: float) -> void:
	var r_sq = radius * radius
	
	# Check Player Fall
	var player = GameManager.player
	if player and is_instance_valid(player):
		if player.z_height <= 0.0 and not player.in_dark_state and not player.god_mode:
			var d_sq = global_position.distance_squared_to(player.global_position)
			if d_sq < (radius * 0.85) * (radius * 0.85):
				# If has bridge, check if player is safely on bridge
				var on_bridge = false
				if has_bridge:
					var local_p = player.global_position - global_position
					if abs(local_p.y) < bridge_width * 0.5:
						on_bridge = true
				
				if not on_bridge:
					# Player falls into pit!
					player.take_damage(40.0, false)
					var push_dir = (player.global_position - global_position).normalized()
					if push_dir.length() < 0.1: push_dir = Vector2.UP
					player.global_position = global_position + push_dir * (radius + 25.0)
					player._shake_intensity = 32.0

	# Check Enemies Fall
	for e in GameManager.active_enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		var ed_sq = global_position.distance_squared_to(e.global_position)
		if ed_sq < (radius * 0.8) * (radius * 0.8):
			var on_bridge = false
			if has_bridge:
				var local_p = e.global_position - global_position
				if abs(local_p.y) < bridge_width * 0.5:
					on_bridge = true
			if not on_bridge:
				if e.has_method("_die"):
					e._die()

func _draw() -> void:
	# 1. Abyss Pit (Deep Void Darkness)
	draw_circle(Vector2.ZERO, radius, Color(0.02, 0.01, 0.04))
	draw_circle(Vector2.ZERO, radius * 0.65, Color(0.0, 0.0, 0.0))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.15, 0.18, 0.25), 3.0)
	draw_arc(Vector2.ZERO, radius * 0.9, 0, TAU, 24, Color(0.4, 0.15, 0.6, 0.35), 1.5)
	
	# 2. Narrow Stone Bridge across center
	if has_bridge:
		var half_w = bridge_width * 0.5
		var bridge_rect = Rect2(-radius * 1.1, -half_w, radius * 2.2, bridge_width)
		draw_rect(bridge_rect, Color(0.22, 0.24, 0.30))
		draw_line(Vector2(-radius * 1.1, -half_w), Vector2(radius * 1.1, -half_w), Color(0.38, 0.42, 0.50), 2.0)
		draw_line(Vector2(-radius * 1.1, half_w), Vector2(radius * 1.1, half_w), Color(0.38, 0.42, 0.50), 2.0)
		# Bridge stone slats
		for i in range(-5, 6):
			var x = (radius / 5.0) * i
			draw_line(Vector2(x, -half_w), Vector2(x, half_w), Color(0.12, 0.14, 0.18), 1.5)
