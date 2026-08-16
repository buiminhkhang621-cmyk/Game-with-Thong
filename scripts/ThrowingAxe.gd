extends Node2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 0.0
var color: Color = Color.WHITE
var state: int = 0 # 0 = thrown, 1 = bouncing up, 2 = landed
var z_height: float = 0.0
var z_velocity: float = 0.0

var target_landing_pos: Vector2 = Vector2.ZERO

var rotation_speed: float = 15.0
var is_empowered: bool = false
var skill_controller: Node = null
var runes: Array = []

const HIT_RADIUS = 15.0

func setup(dir: Vector2, dmg: float, col: Color, empowered: bool, controller: Node, r: Array = []) -> void:
	velocity = dir
	damage = dmg
	color = col
	is_empowered = empowered
	skill_controller = controller
	runes = r
	
	if is_empowered:
		rotation_speed = 30.0
		color = Color(1.0, 0.2, 0.0) # Brighter red

func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
		
	if state == 0:
		# Thrown state
		global_position += velocity * delta
		rotation += rotation_speed * delta
		
		# Check collision
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var r_sq = (HIT_RADIUS + enemy.hit_radius) * (HIT_RADIUS + enemy.hit_radius)
			if global_position.distance_squared_to(enemy.global_position) < r_sq:
				enemy.take_damage(damage)
				for r in runes:
					if r != "damage" and enemy.has_method("apply_element"):
						enemy.apply_element(r, damage * 0.5)
						
				if is_empowered and GameManager.player:
					GameManager.player.heal(GameManager.player.base_max_hp * 0.03) # 3% life steal
				_start_bounce()
				break
				
		# Out of bounds check
		if GameManager.player and global_position.distance_squared_to(GameManager.player.global_position) > 600.0 * 600.0:
			queue_free()
			
	elif state == 1:
		# Bouncing up and falling
		z_velocity -= 800.0 * delta # Gravity
		z_height += z_velocity * delta
		rotation += rotation_speed * delta
		
		# Move towards landing pos
		var to_land = target_landing_pos - global_position
		if to_land.length() > 5.0:
			global_position += to_land.normalized() * 150.0 * delta
			
		if z_height <= 0:
			z_height = 0
			state = 2 # Landed
			rotation_speed = 0
			
	elif state == 2:
		# Landed, wait for player
		if GameManager.player:
			# If player is near marker
			if GameManager.player.global_position.distance_squared_to(target_landing_pos) < 25.0 * 25.0:
				if skill_controller and skill_controller.has_method("on_axe_caught"):
					skill_controller.on_axe_caught()
				queue_free()

	queue_redraw()

func _start_bounce() -> void:
	state = 1
	z_velocity = 300.0
	z_height = 10.0
	# Pick a random landing spot near player
	if GameManager.player:
		var dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		target_landing_pos = GameManager.player.global_position + dir * randf_range(50.0, 100.0)
	else:
		target_landing_pos = global_position

func _draw() -> void:
	if state == 1 or state == 2:
		# Draw landing marker
		draw_set_transform(to_local(target_landing_pos), 0, Vector2.ONE)
		draw_arc(Vector2.ZERO, 15.0, 0, TAU, 16, Color(1, 0, 0, 0.5), 2.0)
		draw_line(Vector2(-10, -10), Vector2(10, 10), Color(1, 0, 0, 0.5), 2.0)
		draw_line(Vector2(-10, 10), Vector2(10, -10), Color(1, 0, 0, 0.5), 2.0)
		draw_set_transform(Vector2.ZERO, rotation, Vector2.ONE)
	
	# Draw the axe offset by z_height
	draw_circle(Vector2(0, -z_height), 8.0, color)
	draw_line(Vector2(0, -z_height - 10), Vector2(0, -z_height + 10), Color.WHITE, 3.0)
	draw_line(Vector2(-8, -z_height), Vector2(8, -z_height), Color.WHITE, 3.0)
