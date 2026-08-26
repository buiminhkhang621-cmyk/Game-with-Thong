class_name XPOrb
extends Node2D

@export var value: int = 1
var pickup_radius_base: float = 55.0


func _ready() -> void:
	add_to_group("xp_orbs")
	queue_redraw()


var is_attracted: bool = false
var _check_timer: float = 0.0

func _process(delta: float) -> void:
	var player = GameManager.player
	if player == null or GameManager.game_over or GameManager.paused_for_levelup:
		return

	if not is_attracted:
		_check_timer -= delta
		if _check_timer > 0.0:
			return
		_check_timer = 0.15 # Check 6-7 times per second when idle
		
		var pr: float = pickup_radius_base * (1.0 + GameManager.passive_value("pickup"))
		var dist_sq: float = global_position.distance_squared_to(player.global_position)
		if dist_sq < pr * pr:
			is_attracted = true
	else:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		global_position += dir * 320.0 * delta
		var dist_sq: float = global_position.distance_squared_to(player.global_position)
		if dist_sq < 16.0 * 16.0:
			GameManager.grant_xp(value)
			GameManager.add_score(value * 5)
			queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(0.5, 0.88, 0.54, 1.0))
