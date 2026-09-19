extends Area2D
class_name BloodAltar

var is_used: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	queue_redraw()

func _process(delta: float) -> void:
	if is_used: return
	pulse_time += delta
	
	# Proximity Sacrifice
	var player = GameManager.player
	if player and is_instance_valid(player):
		var d_sq = global_position.distance_squared_to(player.global_position)
		if d_sq < 42.0 * 42.0:
			_perform_sacrifice(player)
			
	queue_redraw()

func take_damage(_dmg: float) -> void:
	if not is_used:
		var player = GameManager.player
		if player: _perform_sacrifice(player)

func _perform_sacrifice(player: Node2D) -> void:
	is_used = true
	
	# Drain 25 HP
	player.take_damage(25.0, false)
	player._shake_intensity = 20.0
	
	# Grant +20% Permanent Damage & 25 XP
	GameManager.stolen_dark_dmg += 0.20
	GameManager.grant_xp(25)
	
	# Visual text
	var dn = load("res://scenes/DamageNumber.tscn").instantiate()
	get_tree().current_scene.add_child(dn)
	dn.global_position = global_position + Vector2(0, -30)
	dn.setup(0, true, Color(1.0, 0.2, 0.3))
	if dn.has_node("Label"):
		dn.get_node("Label").text = "SACRIFICE: +20% MIGHT!"
		
	queue_redraw()

func _draw() -> void:
	var pulse = 0.8 + sin(pulse_time * 4.0) * 0.2
	
	# Obsidian Stone Altar Pedestal
	draw_rect(Rect2(-24, -14, 48, 28), Color(0.12, 0.10, 0.15))
	draw_rect(Rect2(-24, -14, 48, 28), Color(0.85, 0.15, 0.3, 0.7 if not is_used else 0.2), false, 2.5)
	
	# Floating Blood Crystal Chalice
	var chalice_col = Color(0.95, 0.15, 0.25) if not is_used else Color(0.3, 0.3, 0.35)
	draw_circle(Vector2(0, -18 + sin(pulse_time * 3.0) * 3.0), 9.0 * pulse if not is_used else 6.0, chalice_col)
	if not is_used:
		draw_circle(Vector2(0, -18 + sin(pulse_time * 3.0) * 3.0), 4.0, Color.WHITE)
