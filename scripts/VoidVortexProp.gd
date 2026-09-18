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
	var base_r = 350.0
	
	# 1. Outer dark cosmic gravity well
	draw_circle(Vector2.ZERO, base_r, Color(0.08, 0.0, 0.16, 0.18))
	draw_circle(Vector2.ZERO, base_r * 0.65, Color(0.12, 0.0, 0.22, 0.15))
	
	# 2. Inward-contracting gravitational suction rings
	for i in range(6):
		var phase = fmod(time * 0.6 + i * (1.0 / 6.0), 1.0)
		var r_wave = base_r * (1.0 - phase) # Contracts from edge inward to core
		var alpha = sin(phase * PI) * 0.45
		draw_arc(Vector2.ZERO, r_wave, 0, TAU, 36, Color(0.85, 0.25, 1.0, alpha), 2.2)
		
	# 3. Swirling accretion spiral arms
	for i in range(8):
		var a = (TAU / 8.0) * i + time * 2.6
		var p1 = Vector2(cos(a), sin(a)) * 36.0
		var p2 = Vector2(cos(a + 1.4), sin(a + 1.4)) * (base_r * 0.9)
		draw_line(p1, p2, Color(0.8, 0.35, 1.0, 0.32), 2.0)

	# 4. Event Horizon Danger Ring (Crushing Zone, Radius 75px)
	var danger_pulse = 0.6 + sin(time * 6.0) * 0.25
	draw_circle(Vector2.ZERO, 75.0, Color(0.3, 0.0, 0.45, 0.28))
	draw_arc(Vector2.ZERO, 75.0, 0, TAU, 32, Color(1.0, 0.25, 0.85, danger_pulse * 0.8), 2.5)

	# 5. Core Black Hole Singularity
	draw_circle(Vector2.ZERO, 36.0, Color(0.02, 0.0, 0.05, 0.98))
	# Blazing ultraviolet corona
	draw_arc(Vector2.ZERO, 36.0, 0, TAU, 28, Color(1.0, 0.75, 1.0, 0.95), 2.8)
	draw_arc(Vector2.ZERO, 38.0, 0, TAU, 28, Color(0.85, 0.4, 1.0, 0.5), 1.5)
