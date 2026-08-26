class_name RuneFountain
extends Area2D

var rune_type: String = ""
var used: bool = false
var radius: float = 34.0
var anim_time: float = 0.0

var label: Label = null

func _ready() -> void:
	add_to_group("rune_fountains")
	add_to_group("destructibles")
	
	if rune_type == "":
		var types = ["lightning", "ice", "dark", "void"]
		rune_type = types[randi() % types.size()]
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius + 8.0
	col.shape = shape
	add_child(col)
	
	collision_layer = 4
	collision_mask = 3 # Player and Attacks
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	label = Label.new()
	label.text = rune_type.to_upper() + " SHRINE"
	label.position = Vector2(-60, -56)
	label.size = Vector2(120, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)

func _process(delta: float) -> void:
	anim_time += delta
	if not used:
		# 100% Guaranteed Proximity Trigger
		var player = GameManager.player
		if player and is_instance_valid(player):
			var dist_sq = global_position.distance_squared_to(player.global_position)
			if dist_sq <= 50.0 * 50.0:
				_unlock()
				return
	queue_redraw()

func take_damage(_amount: float) -> void:
	if not used:
		_unlock()

func _on_body_entered(_body: Node2D) -> void:
	if not used:
		_unlock()

func _on_area_entered(_area: Area2D) -> void:
	if not used:
		_unlock()

func _unlock() -> void:
	if used: return
	used = true
	
	if not GameManager.unlocked_runes.has(rune_type):
		GameManager.unlocked_runes.append(rune_type)
		GameManager.wave_event_triggered.emit("SACRED RUNE AWAKENED", "Possessed the power of " + rune_type.capitalize() + "!")
		
	if label:
		label.text = "◆ AWAKENED ◆"
		label.add_theme_color_override("font_color", Color(0.65, 0.85, 0.65))
	queue_redraw()

func _draw() -> void:
	var pulse = 0.85 + sin(anim_time * 3.5) * 0.15
	var r_col = Color(0.85, 0.75, 0.35)
	match rune_type:
		"lightning": r_col = Color(1.0, 0.88, 0.25)
		"ice": r_col = Color(0.35, 0.85, 1.0)
		"dark": r_col = Color(0.75, 0.25, 0.95)
		"void": r_col = Color(0.95, 0.3, 1.0)
		
	if used:
		# Extinguished Ancient Stone Base
		draw_circle(Vector2.ZERO, radius, Color(0.12, 0.12, 0.15))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 24, Color(0.35, 0.35, 0.4), 2.0)
		draw_circle(Vector2.ZERO, 10.0, Color(0.2, 0.2, 0.25))
	else:
		# 1. Glowing Runic Ground Dais
		draw_circle(Vector2.ZERO, radius + 6.0, Color(r_col.r, r_col.g, r_col.b, 0.18 * pulse))
		draw_arc(Vector2.ZERO, radius + 4.0, 0, TAU, 32, Color(r_col.r, r_col.g, r_col.b, 0.6 * pulse), 2.0)
		
		# 2. Carved Obsidian Octagon Plinth
		draw_circle(Vector2.ZERO, radius, Color(0.10, 0.09, 0.12))
		draw_arc(Vector2.ZERO, radius - 4.0, 0, TAU, 24, Color(0.4, 0.35, 0.25), 1.5)
		
		# 3. Floating Mythic Rune Glyph hovering above altar
		var float_y = sin(anim_time * 2.5) * 4.0 - 18.0
		var rune_center = Vector2(0, float_y)
		
		# Sacred aura behind glyph
		draw_circle(rune_center, 18.0, Color(r_col.r, r_col.g, r_col.b, 0.25 * pulse))
		draw_arc(rune_center, 18.0, 0, TAU, 24, Color(r_col.r, r_col.g, r_col.b, 0.7 * pulse), 1.5)
		
		UpgradeIcons.draw_mythic_rune_glyph(self, rune_type, rune_center, 12.0, r_col, pulse)
