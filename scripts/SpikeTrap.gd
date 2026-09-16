extends Node2D
class_name SpikeTrap

var state_timer: float = 0.0
var interval: float = 2.5
var is_spikes_up: bool = false
var is_warning: bool = false

func setup(data: Dictionary) -> void:
	global_position = Vector2(data.get("x", 0), data.get("y", 0))
	interval = data.get("interval", 2.5)
	state_timer = randf() * interval

func _process(delta: float) -> void:
	state_timer += delta
	var cycle = fmod(state_timer, interval)
	
	if cycle < interval - 0.9:
		is_warning = false
		is_spikes_up = false
	elif cycle < interval - 0.4:
		is_warning = true
		is_spikes_up = false
	else:
		is_warning = false
		is_spikes_up = true
		_check_damage(delta)
		
	queue_redraw()

func _check_damage(_delta: float) -> void:
	var player = GameManager.player
	if player and is_instance_valid(player):
		if player.z_height <= 0.0:
			if global_position.distance_squared_to(player.global_position) < 26.0 * 26.0:
				player.take_damage(20.0, true)
				
	for e in GameManager.active_enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		if global_position.distance_squared_to(e.global_position) < 28.0 * 28.0:
			if e.has_method("take_damage"):
				e.take_damage(50.0)

func _draw() -> void:
	# Iron Grate Base (36x36)
	draw_rect(Rect2(-18, -18, 36, 36), Color(0.12, 0.13, 0.16))
	draw_rect(Rect2(-18, -18, 36, 36), Color(0.25, 0.28, 0.35), false, 2.0)
	
	# Holes
	for ix in [-8, 8]:
		for iy in [-8, 8]:
			draw_circle(Vector2(ix, iy), 3.0, Color.BLACK)
			
	if is_warning:
		# Red Warning Pulsing Glow
		draw_rect(Rect2(-16, -16, 32, 32), Color(1.0, 0.2, 0.1, 0.35))
	elif is_spikes_up:
		# Extended Iron Spikes
		for ix in [-8, 8]:
			for iy in [-8, 8]:
				var sp = Vector2(ix, iy)
				draw_circle(sp, 4.0, Color(0.9, 0.2, 0.2))
				draw_circle(sp, 2.0, Color.WHITE)
