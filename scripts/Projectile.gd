class_name Projectile
extends Node2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 5.0
var life: float = 1.1
var _color: Color = Color.WHITE
var runes: Array = []

func setup(vel: Vector2, dmg: float, c: Color, r: Array = []) -> void:
	velocity = vel
	damage = dmg
	_color = c
	runes = r
	queue_redraw()


func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
		
	life -= delta
	if life <= 0.0:
		queue_free()
		return

	global_position += velocity * delta

	for e in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(e.global_position) < 4.0 + e.hit_radius:
			e.take_damage(damage)
			for r in runes:
				if r != "damage" and e.has_method("apply_element"):
					e.apply_element(r, damage * 0.5)
			queue_free()
			return


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, _color)
