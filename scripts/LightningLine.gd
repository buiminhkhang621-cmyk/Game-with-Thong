extends Line2D

var time = 0.2

func _process(delta: float) -> void:
	time -= delta
	if time <= 0:
		queue_free()
	else:
		modulate.a = time / 0.2
