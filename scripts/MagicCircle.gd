extends Sprite2D

var _timer: float = 0.0
var fps: float = 30.0
var total_frames: int = 1

func setup(type: String) -> void:
	z_index = -1
	if type == "small":
		texture = load("res://Sprite/Environment/espantalho_summon-Sheet.png")
		hframes = 78
		vframes = 1
		total_frames = 78
		fps = 78.0 / 0.5 # Play in 0.5 seconds
		scale = Vector2(0.4, 0.4)
		modulate.a = 0.8
	elif type == "big":
		texture = load("res://Sprite/Environment/blue_doom-Sheet.png")
		hframes = 36
		vframes = 1
		total_frames = 36
		fps = 36.0 / 1.0 # Play in 1 second
		scale = Vector2(2.5, 2.5)
		modulate.a = 0.8
		
	frame = 0

func _process(delta: float) -> void:
	_timer += delta
	var next_frame = int(_timer * fps)
	if next_frame >= total_frames:
		queue_free()
	else:
		frame = next_frame
