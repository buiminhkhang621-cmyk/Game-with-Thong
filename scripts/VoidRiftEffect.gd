extends Node2D
class_name VoidRiftEffect

var target_pos: Vector2 = Vector2.ZERO
var start_pos: Vector2 = Vector2.ZERO
var progress: float = 0.0
var duration: float = 0.25
var is_eradication: bool = false
var curve_offset: Vector2 = Vector2.ZERO

func setup_split(from: Vector2, to: Vector2) -> void:
	start_pos = from
	target_pos = to
	global_position = from
	var dir = (to - from)
	var perp = Vector2(-dir.y, dir.x).normalized()
	curve_offset = perp * randf_range(-40.0, 40.0)

func setup_eradication(pos: Vector2) -> void:
	is_eradication = true
	global_position = pos
	duration = 0.4

func _process(delta: float) -> void:
	progress += delta / duration
	if progress >= 1.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if is_eradication:
		# Imploding Black Hole Singularity
		var r = (1.0 - progress) * 28.0
		# Dark void outer glow
		draw_circle(Vector2.ZERO, r * 1.5, Color(0.4, 0.05, 0.6, (1.0 - progress) * 0.7))
		# Inner black hole core
		draw_circle(Vector2.ZERO, r, Color(0.08, 0.0, 0.15, 0.95))
		# Cosmic event horizon ring
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(0.9, 0.3, 1.0, 1.0 - progress), 2.5)
	else:
		# Flying Void Projectile / Tendril Orb
		var t = clampf(progress, 0.0, 1.0)
		# Quadratic bezier curve
		var mid = (start_pos + target_pos) * 0.5 + curve_offset
		var current_pos = (1.0 - t) * (1.0 - t) * start_pos + 2.0 * (1.0 - t) * t * mid + t * t * target_pos
		var local_p = current_pos - global_position
		
		# Glowing Void Spore Orb
		draw_circle(local_p, 9.0, Color(0.5, 0.1, 0.8, 0.4))
		draw_circle(local_p, 5.0, Color(0.85, 0.25, 1.0, 0.9))
		draw_circle(local_p, 2.5, Color(1.0, 0.8, 1.0, 1.0))
		
		# Distortion ring around orb
		draw_arc(local_p, 10.0 + sin(t * 15.0) * 3.0, 0, TAU, 12, Color(0.7, 0.2, 0.95, 0.6), 1.5)
