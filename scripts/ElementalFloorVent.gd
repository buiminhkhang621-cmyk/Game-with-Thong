extends Node2D
class_name ElementalFloorVent

var vent_element: String = "lightning"
var interval: float = 3.5
var timer: float = 0.0
var is_venting: bool = false

func setup(data: Dictionary) -> void:
	global_position = Vector2(data.get("x", 0), data.get("y", 0))
	vent_element = data.get("element", "lightning")
	interval = data.get("interval", 3.5)
	timer = randf() * interval

func _process(delta: float) -> void:
	timer += delta
	var cycle = fmod(timer, interval)
	
	if cycle > interval - 1.2 and cycle < interval:
		is_venting = true
		_apply_vent_damage(delta)
	else:
		is_venting = false
		
	queue_redraw()

func _apply_vent_damage(delta: float) -> void:
	var r_sq = 32.0 * 32.0
	var player = GameManager.player
	if player and is_instance_valid(player):
		if player.z_height <= 0.0 and global_position.distance_squared_to(player.global_position) < r_sq:
			player.take_damage(12.0 * delta, true)
			
	for e in GameManager.active_enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		if global_position.distance_squared_to(e.global_position) < r_sq:
			if e.has_method("apply_element"):
				e.apply_element(vent_element, 25.0 * delta)

func _draw() -> void:
	var col = Color(1.0, 0.85, 0.2)
	match vent_element:
		"ice": col = Color(0.35, 0.85, 1.0)
		"dark": col = Color(0.75, 0.25, 0.95)
		"void": col = Color(0.95, 0.3, 1.0)
		
	# Metal Grate Ring
	draw_circle(Vector2.ZERO, 20.0, Color(0.1, 0.1, 0.12))
	draw_arc(Vector2.ZERO, 20.0, 0, TAU, 20, col, 2.0)
	
	if is_venting:
		var pulse = 0.8 + sin(timer * 15.0) * 0.2
		draw_circle(Vector2.ZERO, 16.0 * pulse, Color(col.r, col.g, col.b, 0.45))
		draw_circle(Vector2.ZERO, 8.0 * pulse, Color.WHITE)
