class_name XPOrb
extends Node2D

@export var value: int = 1
var pickup_radius_base: float = 55.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	var player = GameManager.player
	if player == null or GameManager.game_over:
		return

	var pr: float = pickup_radius_base * (1.0 + GameManager.passive_value("pickup"))
	var dist: float = global_position.distance_to(player.global_position)

	if dist < pr:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		global_position += dir * 280.0 * delta

	if dist < 14.0:
		GameManager.grant_xp(value)
		GameManager.add_score(value * 5)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(0.5, 0.88, 0.54, 1.0))
