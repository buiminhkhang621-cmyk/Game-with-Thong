extends Node2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 0.0
var color: Color = Color.WHITE
var element_type: String = ""

const HIT_RADIUS = 8.0

func setup(dir: Vector2, dmg: float, type: String) -> void:
	velocity = dir
	damage = dmg
	element_type = type
	
	match type:
		"lightning": color = Color(0.9, 0.9, 0.2)
		"ice": color = Color(0.2, 0.6, 1.0)
		"dark": color = Color(0.3, 0.1, 0.4)
		"void": color = Color(0.6, 0.2, 0.8)
		
	rotation = velocity.angle()

func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
		
	global_position += velocity * delta
	
	# Check collision
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) < HIT_RADIUS + enemy.hit_radius:
			if enemy.has_method("apply_element"):
				enemy.apply_element(element_type, damage)
			queue_free()
			return
			
	if GameManager.player and global_position.distance_to(GameManager.player.global_position) > 600:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, HIT_RADIUS, color)
