class_name EnemyProjectile
extends Node2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 15.0
var life: float = 2.0
var _color: Color = Color(0.2, 0.6, 1.0)

func setup(vel: Vector2, dmg: float, c: Color) -> void:
	velocity = vel
	damage = dmg
	_color = c
	queue_redraw()

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return

	global_position += velocity * delta

	var player = GameManager.player
	if player:
		if global_position.distance_to(player.global_position) < 6.0 + player.hit_radius:
			player.take_damage(damage)
			queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, _color)
