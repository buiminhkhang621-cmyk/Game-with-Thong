extends Node2D
class_name ElementalVisualEffect

var effect_type: String = "lightning"
var life_time: float = 0.0
var max_life: float = 0.45
var data: Dictionary = {}

func setup_lightning(start_pos: Vector2, target_pos: Vector2, chain_count: int = 1) -> void:
	effect_type = "lightning"
	global_position = start_pos
	max_life = 0.35
	data["target"] = target_pos - start_pos
	data["chains"] = chain_count
	queue_redraw()

func setup_ice_shatter(pos: Vector2, radius: float = 45.0) -> void:
	effect_type = "ice"
	global_position = pos
	max_life = 0.50
	data["radius"] = radius
	queue_redraw()

func setup_dark_siphon(start_pos: Vector2, player_pos: Vector2) -> void:
	effect_type = "dark"
	global_position = start_pos
	max_life = 0.60
	data["player_start"] = player_pos
	data["start_pos"] = start_pos
	queue_redraw()

func setup_elemental_burst(pos: Vector2, element: String) -> void:
	effect_type = "burst"
	global_position = pos
	max_life = 0.40
	data["element"] = element
	queue_redraw()

func _process(delta: float) -> void:
	life_time += delta
	if life_time >= max_life:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress = life_time / max_life
	var alpha = (1.0 - progress)
	
	match effect_type:
		"lightning":
			# Jagged Branching Tesla Arc
			var target = data.get("target", Vector2(60, 0))
			var col = Color(1.0, 0.92, 0.35, alpha)
			var pts = PackedVector2Array([Vector2.ZERO])
			var segs = 6
			for i in range(1, segs):
				var base_p = (target / float(segs)) * i
				var normal = Vector2(-target.y, target.x).normalized()
				var offset = normal * randf_range(-14.0, 14.0) * (1.0 - progress * 0.5)
				pts.append(base_p + offset)
			pts.append(target)
			
			draw_polyline(pts, Color(1.0, 0.85, 0.2, alpha * 0.5), 6.0)
			draw_polyline(pts, col, 3.0)
			draw_polyline(pts, Color(1.0, 1.0, 1.0, alpha), 1.5)
			
			# Electric plasma nodes
			for p in pts:
				draw_circle(p, 3.0 * (1.0 - progress), Color.WHITE)

		"ice":
			# Glacial Frost Shatter & Crystal Shards
			var r = data.get("radius", 45.0) * (0.6 + progress * 0.6)
			var col = Color(0.4, 0.85, 1.0, alpha)
			draw_arc(Vector2.ZERO, r, 0, TAU, 24, col, 2.5)
			draw_circle(Vector2.ZERO, r * 0.4, Color(0.5, 0.9, 1.0, alpha * 0.3))
			
			# 6 Expanding Diamond Ice Needles
			for i in range(6):
				var a = (TAU / 6.0) * i + progress * 0.5
				var p1 = Vector2(cos(a), sin(a)) * (r * 0.3)
				var p2 = Vector2(cos(a), sin(a)) * r
				draw_line(p1, p2, Color(0.7, 0.95, 1.0, alpha), 2.5)
				draw_circle(p2, 3.5 * (1.0 - progress), Color.WHITE)

		"dark":
			# Necrotic Siphon Wisps Homing to Player
			var player = GameManager.player
			var dest = (player.global_position - global_position) if (player and is_instance_valid(player)) else Vector2(0, -60)
			var cur_p = Vector2.ZERO.lerp(dest, progress)
			
			# Shadow skull wisp trail
			draw_circle(cur_p, 8.0 * (1.0 - progress * 0.5), Color(0.65, 0.15, 0.85, alpha))
			draw_circle(cur_p, 4.0 * (1.0 - progress * 0.5), Color(1.0, 0.4, 1.0, alpha))
			draw_line(Vector2.ZERO, cur_p, Color(0.5, 0.1, 0.7, alpha * 0.4), 2.5)

		"burst":
			# Elemental Reaction Combustion Ring
			var elem = data.get("element", "void")
			var elem_col = Color(1.0, 0.85, 0.2)
			match elem:
				"ice": elem_col = Color(0.35, 0.85, 1.0)
				"dark": elem_col = Color(0.8, 0.25, 0.95)
				"void": elem_col = Color(0.95, 0.3, 1.0)
			var rad = 65.0 * progress
			draw_arc(Vector2.ZERO, rad, 0, TAU, 24, Color(elem_col.r, elem_col.g, elem_col.b, alpha), 3.0)
			draw_circle(Vector2.ZERO, rad * 0.6, Color(elem_col.r, elem_col.g, elem_col.b, alpha * 0.25))
