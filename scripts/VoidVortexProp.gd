extends Node2D
class_name VoidVortexProp

var life_time: float = 0.0

func _ready() -> void:
	z_index = -2

func _process(delta: float) -> void:
	life_time += delta
	queue_redraw()

func _draw() -> void:
	var time = life_time
	var base_r = 180.0
	
	# Swirling event horizon suction rings
	for i in range(4):
		var r_wave = base_r * fmod(time * 0.8 + i * 0.25, 1.0)
		var alpha = (1.0 - r_wave / base_r) * 0.5
		draw_arc(Vector2.ZERO, r_wave, 0, TAU, 32, Color(0.85, 0.2, 1.0, alpha), 2.5)
		
	# Outer dark gravity well
	draw_circle(Vector2.ZERO, base_r, Color(0.12, 0.0, 0.22, 0.18))
	
	# Swirling accretion spirals
	for i in range(6):
		var a = (TAU / 6.0) * i + time * 3.0
		var p1 = Vector2(cos(a), sin(a)) * 25.0
		var p2 = Vector2(cos(a + 1.2), sin(a + 1.2)) * (base_r * 0.85)
		draw_line(p1, p2, Color(0.9, 0.4, 1.0, 0.4), 2.0)
		
	# Core black hole singularity
	draw_circle(Vector2.ZERO, 32.0, Color(0.04, 0.0, 0.08, 0.95))
	draw_arc(Vector2.ZERO, 32.0, 0, TAU, 24, Color(1.0, 0.8, 1.0, 0.9), 2.0)
