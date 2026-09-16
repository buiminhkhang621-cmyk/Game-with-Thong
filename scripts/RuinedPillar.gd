class_name RuinedPillar
extends StaticBody2D

var pillar_height: float = 38.0
var pillar_radius: float = 22.0
var pillar_type: int = 0
var rune_tint: Color = Color(0.95, 0.85, 0.5)

func _ready() -> void:
	pillar_type = randi() % 3
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = pillar_radius
	col.shape = shape
	col.position = Vector2(0, 10)
	add_child(col)
	
	collision_layer = 1 # Obstacle layer
	collision_mask = 0
	queue_redraw()

func _draw() -> void:
	var r = pillar_radius
	var h = pillar_height
	
	# 1. Cast Shadow onto ground
	draw_circle(Vector2(4, 14), r * 1.15, Color(0.02, 0.02, 0.05, 0.45))
	
	# 2. Base Pedestal (Layered Carved Stone)
	var base_pts = PackedVector2Array([
		Vector2(-r * 1.1, 14),
		Vector2(r * 1.1, 14),
		Vector2(r * 0.9, -h + 10),
		Vector2(-r * 0.9, -h + 10)
	])
	draw_polygon(base_pts, PackedColorArray([Color(0.18, 0.20, 0.25)]))
	
	# 3. Column Body Fluting (Vertical Stone Highlights & Grooves)
	draw_rect(Rect2(-r * 0.85, -h + 8, r * 1.7, h), Color(0.24, 0.26, 0.32))
	draw_line(Vector2(-r * 0.4, -h + 8), Vector2(-r * 0.4, 8), Color(0.14, 0.16, 0.20), 2.0)
	draw_line(Vector2(0, -h + 8), Vector2(0, 8), Color(0.35, 0.38, 0.45), 2.5) # Light catch
	draw_line(Vector2(r * 0.4, -h + 8), Vector2(r * 0.4, 8), Color(0.14, 0.16, 0.20), 2.0)
	
	# 4. Weathered Cracks & Ruined Fractures
	draw_line(Vector2(-r * 0.3, -h * 0.5), Vector2(r * 0.2, -h * 0.3), Color(0.08, 0.08, 0.12), 1.5)
	draw_line(Vector2(r * 0.2, -h * 0.3), Vector2(r * 0.1, -h * 0.1), Color(0.08, 0.08, 0.12), 1.5)
	
	# 5. Glowing Runic Engraving (Carved ancient sigil)
	if pillar_type == 0:
		draw_arc(Vector2(0, -h * 0.4), 6.0, 0, TAU, 12, Color(rune_tint.r, rune_tint.g, rune_tint.b, 0.55), 1.5)
		draw_circle(Vector2(0, -h * 0.4), 2.0, rune_tint)
	elif pillar_type == 1:
		draw_line(Vector2(0, -h * 0.6), Vector2(0, -h * 0.2), Color(rune_tint.r, rune_tint.g, rune_tint.b, 0.55), 1.5)
		draw_line(Vector2(-4, -h * 0.4), Vector2(4, -h * 0.4), Color(rune_tint.r, rune_tint.g, rune_tint.b, 0.55), 1.5)
		
	# 6. Capital / Top Cap
	draw_rect(Rect2(-r * 1.0, -h, r * 2.0, 8), Color(0.28, 0.30, 0.38))
	draw_rect(Rect2(-r * 1.0, -h, r * 2.0, 2), Color(0.45, 0.48, 0.56)) # Top rim highlight
