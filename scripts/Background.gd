extends Node2D

var grid_size := 64.0
var line_color := Color(1.0, 1.0, 1.0, 0.05)
var bg_color := Color(0.05, 0.05, 0.08, 1.0)

const OBSTACLE_SCENE = preload("res://scenes/Obstacle.tscn")

func _ready() -> void:
	z_index = -100
	for i in range(200):
		var obs = OBSTACLE_SCENE.instantiate()
		obs.global_position = Vector2(randf_range(-2500, 2500), randf_range(-2500, 2500))
		if obs.global_position.length() < 200.0:
			obs.queue_free()
			continue
		obs.radius = randf_range(15.0, 45.0)
		obs.color = Color(randf_range(0.1, 0.3), randf_range(0.3, 0.6), randf_range(0.1, 0.3))
		add_child(obs)

	# Spawn exact 4 Rune Fountains
	var elements = ["lightning", "ice", "dark", "void"]
	for i in range(4):
		var fountain = Area2D.new()
		fountain.set_script(load("res://scripts/RuneFountain.gd"))
		
		# Ensure they are somewhat spread out and not too close to center
		var r = randf_range(800, 2000)
		var a = randf_range(0, TAU)
		fountain.global_position = Vector2(cos(a) * r, sin(a) * r)
		
		fountain.rune_type = elements[i]
		add_child(fountain)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not GameManager.player:
		return

	var cam_pos = GameManager.player.global_position
	var screen_size = get_viewport_rect().size

	var rect = Rect2(cam_pos - screen_size, screen_size * 2)
	draw_rect(rect, bg_color)

	var start_x = floor((cam_pos.x - screen_size.x) / grid_size) * grid_size
	var end_x = start_x + screen_size.x * 2
	var start_y = floor((cam_pos.y - screen_size.y) / grid_size) * grid_size
	var end_y = start_y + screen_size.y * 2

	var x = start_x
	while x <= end_x:
		draw_line(Vector2(x, start_y), Vector2(x, end_y), line_color, 1.0)
		x += grid_size

	var y = start_y
	while y <= end_y:
		draw_line(Vector2(start_x, y), Vector2(end_x, y), line_color, 1.0)
		y += grid_size
