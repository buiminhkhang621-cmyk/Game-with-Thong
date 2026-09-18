class_name ThrowingKnife
extends Node2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 9.0
var life: float = 1.6
var is_crit: bool = false
var runes: Array = []
var pierce_left: int = 1
var hit_enemies: Array[int] = []

static var _knife_tex: Texture2D = null

static func get_knife_texture() -> Texture2D:
	if _knife_tex == null:
		_knife_tex = UITheme.load_texture("res://Sprite/weapon/knife.png")
	return _knife_tex

func setup(vel: Vector2, dmg: float, crit: bool, pierce: int = 1, r: Array = []) -> void:
	velocity = vel
	damage = dmg
	is_crit = crit
	pierce_left = pierce
	runes = r
	if is_crit:
		damage *= 2.2
	
	# Rotate knife so tip points directly along movement vector
	# In knife.png, the tip is at -52.3° from center
	rotation = velocity.angle() + deg_to_rad(52.3)
	queue_redraw()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 2
	add_to_group("projectiles")

func _process(delta: float) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and (gm.game_over or gm.paused_for_levelup):
		return
		
	life -= delta
	if life <= 0.0:
		queue_free()
		return
		
	global_position += velocity * delta
	
	# Range cleanup if far from player
	if gm and gm.player and global_position.distance_squared_to(gm.player.global_position) > 750.0 * 750.0:
		queue_free()
		return

	# Collision against enemies
	var enemies = gm.active_enemies if gm else []
	for e in enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			continue
		var id = e.get_instance_id()
		if hit_enemies.has(id):
			continue
			
		var r = 16.0 + e.hit_radius
		if global_position.distance_squared_to(e.global_position) <= r * r:
			hit_enemies.append(id)
			
			# Apply runes FIRST so elemental effects (e.g. void infection) attach even on lethal hits
			for ru in runes:
				if ru != "damage" and e.has_method("apply_element"):
					e.apply_element(ru, damage * 0.5)
			
			e.take_damage(damage)
			
			# Visual spark impact
			_spawn_hit_spark(e.global_position)
					
			pierce_left -= 1
			if pierce_left <= 0:
				queue_free()
				return

func _spawn_hit_spark(pos: Vector2) -> void:
	# Subtle slash impact juice
	var gm = get_node_or_null("/root/GameManager")
	if is_crit and gm and gm.player:
		gm.player._shake_intensity = max(gm.player._shake_intensity, 2.5)

func _draw() -> void:
	var tex = get_knife_texture()
	var col = Color(1.0, 0.95, 0.7) if is_crit else Color(0.92, 0.96, 1.0)
	
	# Blade motion speed trail behind the knife
	var back_dir = -Vector2(cos(rotation - deg_to_rad(52.3)), sin(rotation - deg_to_rad(52.3)))
	var trail_p1 = back_dir * 12.0
	var trail_p2 = back_dir * 6.0
	var trail_col = Color(1.0, 0.85, 0.3, 0.6) if is_crit else Color(0.4, 0.8, 1.0, 0.45)
	draw_line(trail_p1, Vector2.ZERO, trail_col, 1.8)
	draw_line(trail_p2, Vector2.ZERO, Color(1.0, 1.0, 1.0, 0.7), 1.0)
	
	if tex:
		# Draw knife texture with compact dagger proportions
		var sz = tex.get_size() * 0.35
		draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false, col)
	else:
		draw_circle(Vector2.ZERO, 8.0, col)
