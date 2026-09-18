extends Node2D
class_name VoidRiftEffect

var target_pos: Vector2 = Vector2.ZERO
var start_pos: Vector2 = Vector2.ZERO
var target_node: Node = null
var split_damage: float = 0.0
var progress: float = 0.0
var duration: float = 0.26
var is_eradication: bool = false
var curve_offset: Vector2 = Vector2.ZERO

func setup_split(from: Vector2, to: Vector2, target: Node = null, dmg: float = 0.0) -> void:
	start_pos = from
	target_pos = to
	target_node = target
	split_damage = dmg
	global_position = from
	var dir = (to - from)
	var perp = Vector2(-dir.y, dir.x).normalized()
	curve_offset = perp * randf_range(-45.0, 45.0)
	duration = randf_range(0.22, 0.32)

func setup_eradication(pos: Vector2) -> void:
	is_eradication = true
	global_position = pos
	duration = 0.35

func _process(delta: float) -> void:
	if not is_eradication and target_node and is_instance_valid(target_node) and not target_node.is_queued_for_deletion():
		target_pos = target_node.global_position
	progress += delta / duration
	if progress >= 1.0:
		_on_impact()
		queue_free()
		return
	queue_redraw()

func _on_impact() -> void:
	if is_eradication: return
	
	var actual_target = target_node
	if not (actual_target and is_instance_valid(actual_target) and not actual_target.is_queued_for_deletion() and ("hp" not in actual_target or actual_target.hp > 0)):
		# Target died while spore was traveling, seek another nearby living enemy
		var best_node: Node = null
		var best_dist_sq = 250.0 * 250.0
		for e in GameManager.active_enemies:
			if is_instance_valid(e) and not e.is_queued_for_deletion() and ("hp" not in e or e.hp > 0):
				var d_sq = target_pos.distance_squared_to(e.global_position)
				if d_sq < best_dist_sq:
					best_dist_sq = d_sq
					best_node = e
		actual_target = best_node

	if actual_target and is_instance_valid(actual_target) and not actual_target.is_queued_for_deletion():
		# Auto-infect with void element first for continuous chain reaction
		if actual_target.has_method("apply_element"):
			actual_target.apply_element("void", split_damage)
		elif "active_auras" in actual_target:
			if not actual_target.active_auras.has("void"):
				actual_target.active_auras.append("void")

		if actual_target.has_method("take_damage"):
			actual_target.take_damage(split_damage * 0.25)
		
		# Micro purple void burst impact
		var fx = ElementalVisualEffect.new()
		get_tree().current_scene.add_child(fx)
		fx.setup_elemental_burst(actual_target.global_position, "void")

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
