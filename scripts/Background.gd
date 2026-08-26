extends Node2D

var bg_layer: CanvasLayer
var bg_rect: ColorRect
var bg_material: ShaderMaterial

const OBSTACLE_SCENE = preload("res://scenes/Obstacle.tscn")

const GRID_SHADER = """
shader_type canvas_item;

uniform vec2 player_pos = vec2(0.0);
uniform float grid_size = 64.0;
uniform vec4 bg_color : source_color = vec4(0.05, 0.05, 0.08, 1.0);
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.07);

void fragment() {
	vec2 screen_res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 world_pos = (SCREEN_UV - 0.5) * screen_res + player_pos;
	vec2 grid = abs(fract(world_pos / grid_size - 0.5) - 0.5) / max(fwidth(world_pos / grid_size), vec2(0.001));
	float line_val = min(grid.x, grid.y);
	float c = clamp(1.0 - line_val, 0.0, 1.0);
	COLOR = mix(bg_color, line_color, c);
}
"""

func _ready() -> void:
	z_index = -100
	
	bg_layer = CanvasLayer.new()
	bg_layer.layer = -100
	add_child(bg_layer)
	
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader = Shader.new()
	shader.code = GRID_SHADER
	bg_material = ShaderMaterial.new()
	bg_material.shader = shader
	bg_rect.material = bg_material
	bg_layer.add_child(bg_rect)
	
	for i in range(200):
		var obs = OBSTACLE_SCENE.instantiate()
		obs.global_position = Vector2(randf_range(-2500, 2500), randf_range(-2500, 2500))
		if obs.global_position.length() < 200.0:
			obs.queue_free()
			continue
		obs.radius = randf_range(15.0, 45.0)
		obs.color = Color(randf_range(0.1, 0.3), randf_range(0.3, 0.6), randf_range(0.1, 0.3))
		add_child(obs)

	# Spawn Destructible Props (Urns / Crates)
	var prop_script = load("res://scripts/DestructibleProp.gd")
	for i in range(45):
		var prop = Area2D.new()
		prop.set_script(prop_script)
		prop.global_position = Vector2(randf_range(-2200, 2200), randf_range(-2200, 2200))
		if prop.global_position.length() < 150.0:
			prop.queue_free()
			continue
		add_child(prop)

	# Spawn exact 4 Rune Fountains
	var elements = ["lightning", "ice", "dark", "void"]
	for i in range(4):
		var fountain = Area2D.new()
		fountain.set_script(load("res://scripts/RuneFountain.gd"))
		fountain.rune_type = elements[i]
		
		# Spread across 4 quadrants
		var angle_offset = (PI / 2.0) * i + randf_range(-0.3, 0.3)
		var r = randf_range(900, 1800)
		fountain.global_position = Vector2(cos(angle_offset) * r, sin(angle_offset) * r)
		add_child(fountain)

func _process(_delta: float) -> void:
	if GameManager.player and bg_material:
		bg_material.set_shader_parameter("player_pos", GameManager.player.global_position)
