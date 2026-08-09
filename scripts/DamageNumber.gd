extends Node2D

@onready var label: Label = $Label

var amount: float = 0
var is_crit: bool = false
var float_speed: float = 50.0
var time: float = 0.8
var max_time: float = 0.8

func setup(dmg: float, crit: bool, custom_color: Color = Color.TRANSPARENT) -> void:
	amount = dmg
	is_crit = crit
	if label == null:
		await ready
	
	label.text = str(int(amount))
	
	if custom_color != Color.TRANSPARENT:
		label.add_theme_color_override("font_color", custom_color)
	elif is_crit:
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
		label.add_theme_font_size_override("font_size", 20)
		label.text = label.text + "!"
		float_speed = 70.0
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		label.add_theme_font_size_override("font_size", 14)

func _process(delta: float) -> void:
	position.y -= float_speed * delta
	time -= delta
	if time <= 0:
		queue_free()
	else:
		modulate.a = time / max_time
