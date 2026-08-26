class_name TreasureChest
extends Area2D

var float_offset: float = 0.0
var is_opened: bool = false

func _ready() -> void:
	float_offset = randf() * TAU
	add_to_group("treasure_chests")
	add_to_group("destructibles") # Allows attacks to hit it
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 28.0
	col.shape = shape
	add_child(col)
	
	collision_layer = 4
	collision_mask = 2 # Player and weapons
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _process(delta: float) -> void:
	if is_opened or GameManager.game_over:
		return
	float_offset += delta * 3.5
	
	# Proximity check (guarantees opening when player approaches)
	if GameManager.player:
		var dist_sq = global_position.distance_squared_to(GameManager.player.global_position)
		if dist_sq < 45.0 * 45.0:
			_open_chest()
			return
			
	queue_redraw()

func take_damage(_amount: float) -> void:
	if not is_opened:
		_open_chest()

func _on_body_entered(body: Node2D) -> void:
	if not is_opened and body is Player:
		_open_chest()

func _on_area_entered(_area: Area2D) -> void:
	if not is_opened:
		_open_chest()

func _open_chest() -> void:
	if is_opened:
		return
	is_opened = true
	
	# Open UI
	get_tree().paused = true
	var script = load("res://scripts/ChestUI.gd")
	if script:
		var ui = script.new()
		get_tree().root.add_child(ui)
		
	queue_free()

func _draw() -> void:
	var y_off = sin(float_offset) * 4.0
	var pos = Vector2(0, y_off)
	
	# Golden Aura & Pulse
	draw_circle(pos, 24.0, Color(1.0, 0.8, 0.2, 0.28))
	draw_arc(pos, 28.0, 0, TAU, 24, Color(1.0, 0.85, 0.3, 0.6), 2.5)
	
	# Chest Base (Brown & Gold trim)
	var base_rect = Rect2(pos.x - 18, pos.y - 4, 36, 22)
	draw_rect(base_rect, Color(0.45, 0.28, 0.12), true)
	draw_rect(base_rect, Color(0.95, 0.8, 0.2), false, 2.5)
	
	# Chest Lid (Curved / Angled Top)
	var lid_pts = PackedVector2Array([
		pos + Vector2(-20, -4),
		pos + Vector2(-15, -16),
		pos + Vector2(15, -16),
		pos + Vector2(20, -4)
	])
	draw_polygon(lid_pts, PackedColorArray([Color(0.58, 0.38, 0.18)]))
	draw_polyline(lid_pts, Color(1.0, 0.85, 0.25), 2.5)
	
	# Center Keyhole / Gem
	draw_circle(pos + Vector2(0, 4), 4.5, Color(1.0, 0.9, 0.3))
	draw_circle(pos + Vector2(0, 4), 2.0, Color(0.2, 0.1, 0.05))
