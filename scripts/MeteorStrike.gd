extends Node2D
class_name MeteorStrike

var timer: float = 0.55 # 0.55s telegraph, then explosion
var exploded: bool = false
var anim_timer: float = 0.0

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	if not exploded:
		timer -= delta
		if timer <= 0.0:
			_explode()
	else:
		anim_timer += delta
		if anim_timer >= 0.35:
			queue_free()
	queue_redraw()

func _explode() -> void:
	exploded = true
	
	# Blast radius: 130px
	var radius = 130.0
	var r_sq = radius * radius
	
	# Damage enemies
	for e in GameManager.active_enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		if global_position.distance_squared_to(e.global_position) <= r_sq:
			if e.has_method("take_damage"):
				e.take_damage(140.0)
			if e.has_method("apply_knockback"):
				var dir = (e.global_position - global_position).normalized()
				e.apply_knockback(dir, 350.0)
				
	# Damage player slightly if in direct epicenter (< 45px)
	var player = GameManager.player
	if player and is_instance_valid(player):
		if global_position.distance_squared_to(player.global_position) <= 45.0 * 45.0:
			player.take_damage(16.0, true)

func _draw() -> void:
	if not exploded:
		# Telegraph warning circle
		var progress = 1.0 - (timer / 0.55)
		draw_circle(Vector2.ZERO, 130.0 * progress, Color(1.0, 0.2, 0.1, 0.25))
		draw_arc(Vector2.ZERO, 130.0, 0, TAU, 24, Color(1.0, 0.4, 0.1, 0.8), 2.5)
	else:
		# Fiery Meteor Impact Explosion
		var t = anim_timer / 0.35
		var r = 130.0 * (0.8 + t * 0.4)
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.4, 0.05, (1.0 - t) * 0.6))
		draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 0.9, 0.2, (1.0 - t) * 0.8))
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1.0, 0.6, 0.1, (1.0 - t)), 3.0)
