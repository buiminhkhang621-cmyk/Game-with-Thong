extends Node2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 0.0
var color: Color = Color.WHITE
var element_type: String = ""

const HIT_RADIUS = 8.0

static var _ball_tex: Texture2D = null

static func get_ball_texture() -> Texture2D:
	if _ball_tex == null:
		_ball_tex = UITheme.load_texture("res://Sprite/weapon/Magic-ball.png")
	return _ball_tex

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func setup(dir: Vector2, dmg: float, type: String) -> void:
	velocity = dir
	damage = dmg
	element_type = type
	
	match type:
		"lightning": color = Color(1.0, 0.95, 0.25)
		"ice": color = Color(0.3, 0.8, 1.0)
		"dark": color = Color(0.45, 0.15, 0.6)
		"void": color = Color(0.8, 0.25, 0.95)
		"fire": color = Color(1.0, 0.35, 0.1)
		_: color = Color(0.9, 0.7, 1.0)
		
	rotation = velocity.angle()

func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
		
	global_position += velocity * delta
	
	# Check collision
	for enemy in GameManager.active_enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion(): continue
		var r_sq = (HIT_RADIUS + enemy.hit_radius) * (HIT_RADIUS + enemy.hit_radius)
		if global_position.distance_squared_to(enemy.global_position) < r_sq:
			if enemy.has_method("apply_element"):
				enemy.apply_element(element_type, damage)
			queue_free()
			return
			
	if GameManager.player and global_position.distance_squared_to(GameManager.player.global_position) > 600.0 * 600.0:
		queue_free()

func _draw() -> void:
	var tex = get_ball_texture()
	if tex:
		# Elemental outer aura halo
		draw_circle(Vector2.ZERO, HIT_RADIUS * 1.3, Color(color.r, color.g, color.b, 0.25))
		var b_size = tex.get_size() * 0.75 # ~24x25 px
		draw_texture_rect(tex, Rect2(-b_size * 0.5, b_size), false, color)
	else:
		draw_circle(Vector2.ZERO, HIT_RADIUS, color)

