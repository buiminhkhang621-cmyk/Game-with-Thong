class_name Obstacle
extends StaticBody2D

var radius: float = 20.0
var color: Color = Color(0.2, 0.4, 0.2)

func _ready() -> void:
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	add_child(col)
	collision_layer = 1
	collision_mask = 0
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
