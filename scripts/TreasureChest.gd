class_name TreasureChest
extends Area2D

var float_offset: float = 0.0
var is_opened: bool = false
var anim_sparkles: float = 0.0

func _ready() -> void:
	float_offset = randf() * TAU
	add_to_group("treasure_chests")
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 32.0
	col.shape = shape
	add_child(col)
	
	collision_layer = 8
	collision_mask = 2 # Player body only (layer 2)
	
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _process(delta: float) -> void:
	if is_opened or GameManager.game_over:
		return
		
	float_offset += delta * 3.0
	anim_sparkles += delta * 5.0
	
	# Proximity Auto-Trigger when player walks over the chest
	var player = GameManager.player
	if player and is_instance_valid(player):
		var dist_sq = global_position.distance_squared_to(player.global_position)
		if dist_sq <= 42.0 * 42.0:
			_open_chest()
			return
			
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if not is_opened and (body is Player or body.name == "Player"):
		_open_chest()

func _open_chest() -> void:
	if is_opened:
		return
	is_opened = true
	set_process(false)
	visible = false
	
	# Pause and open ChestUI
	get_tree().paused = true
	var script = load("res://scripts/ChestUI.gd")
	if script:
		var ui = script.new()
		get_tree().root.add_child(ui)
		
	queue_free()

func _draw() -> void:
	if is_opened: return
	var y_off = sin(float_offset) * 3.5
	var pos = Vector2(0, y_off)
	var pulse = 0.85 + sin(anim_sparkles) * 0.15
	
	# 1. Antique Golden Divine Aura Ring
	draw_circle(pos, 28.0, Color(0.95, 0.75, 0.25, 0.18 * pulse))
	draw_arc(pos, 32.0, 0, TAU, 24, Color(1.0, 0.85, 0.38, 0.5 * pulse), 1.5)
	
	# Floating Sparkle Stars
	for i in range(4):
		var a = (TAU / 4.0) * i + anim_sparkles * 0.5
		var sp = pos + Vector2(cos(a), sin(a) * 0.7) * (36.0 + sin(anim_sparkles + i) * 4.0)
		draw_circle(sp, 2.0, Color(1.0, 0.95, 0.6, 0.8))
	
	# 2. Chest Base (Antique Ebony / Dark Iron with Gilded Filigree)
	var base_rect = Rect2(pos.x - 22, pos.y - 4, 44, 24)
	draw_rect(base_rect, Color(0.12, 0.10, 0.14), true) # Dark Obsidian Iron
	draw_rect(base_rect, Color(0.85, 0.72, 0.32), false, 2.5) # Antique Gold Trim
	
	# 3. Chest Arched Lid
	var lid_pts = PackedVector2Array([
		pos + Vector2(-24, -4),
		pos + Vector2(-18, -18),
		pos + Vector2(18, -18),
		pos + Vector2(24, -4)
	])
	draw_polygon(lid_pts, PackedColorArray([Color(0.20, 0.16, 0.22)]))
	draw_polyline(lid_pts, Color(0.95, 0.80, 0.35), 2.5)
	
	# 4. Central Relic Lock / Glowing Sigil Gem
	draw_circle(pos + Vector2(0, 4), 5.5, Color(1.0, 0.85, 0.35))
