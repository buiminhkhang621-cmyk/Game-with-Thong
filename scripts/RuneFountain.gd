class_name RuneFountain
extends Area2D

var rune_type: String = "lightning"
var used: bool = false
var radius: float = 30.0

var label: Label = null

func _ready() -> void:
	var types = ["lightning", "ice", "dark", "void"]
	rune_type = types[randi() % types.size()]
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	add_child(col)
	
	collision_layer = 0
	collision_mask = 2 # Player is layer 2
	
	body_entered.connect(_on_body_entered)
	
	label = Label.new()
	label.text = rune_type.capitalize()
	label.position = Vector2(-20, -45)
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)

func _on_body_entered(body: Node2D) -> void:
	if used or not body is Player:
		return
		
	if not GameManager.unlocked_runes.has(rune_type):
		GameManager.unlocked_runes.append(rune_type)
		print("Unlocked rune element: ", rune_type)
		used = true
		queue_redraw()
		label.text = "Empty"

func _draw() -> void:
	if used:
		draw_circle(Vector2.ZERO, radius, Color(0.3, 0.3, 0.3))
		draw_circle(Vector2.ZERO, radius - 4, Color(0.1, 0.1, 0.1))
	else:
		var c = Color.WHITE
		match rune_type:
			"lightning": c = Color.YELLOW
			"ice": c = Color(0.3, 0.6, 1.0)
			"dark": c = Color(0.4, 0.0, 0.4)
			"void": c = Color(0.6, 0.2, 0.8)
			
		# Glow
		draw_circle(Vector2.ZERO, radius + 5, c * Color(1, 1, 1, 0.3))
		draw_circle(Vector2.ZERO, radius, Color(0.2, 0.2, 0.2))
		draw_circle(Vector2.ZERO, radius - 4, c)
