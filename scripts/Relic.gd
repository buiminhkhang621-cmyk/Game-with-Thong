extends Node2D
class_name Relic

var relic_id: String = ""
var is_picked_up: bool = false
var float_offset: float = 0.0

const RELIC_POOL = ["greed_ring", "ancient_censer", "broken_mirror"]

func _ready() -> void:
	relic_id = RELIC_POOL[randi() % RELIC_POOL.size()]

func _process(delta: float) -> void:
	if is_picked_up or GameManager.game_over:
		return
		
	float_offset += delta * 2.0

	
	if GameManager.player:
		var dist = global_position.distance_to(GameManager.player.global_position)
		if dist < 30.0:
			_pickup()
	
	queue_redraw()

func _pickup() -> void:
	is_picked_up = true
	GameManager.active_relics.append(relic_id)
	
	# Apply instant effects if any
	if relic_id == "greed_ring":
		# -10% Max HP
		if GameManager.player:
			GameManager.player.base_max_hp *= 0.9
			GameManager.player._effective_max_hp *= 0.9
			GameManager.player.hp = min(GameManager.player.hp, GameManager.player._effective_max_hp)
	
	queue_free()

func _draw() -> void:
	if not is_picked_up:
		var y_off = sin(float_offset) * 5.0
		var pos = Vector2(0, y_off)
		
		# Draw a glowing diamond for relic
		draw_circle(pos, 12, Color(1.0, 0.8, 0.0, 0.3))
		var pts = PackedVector2Array([
			pos + Vector2(0, -8),
			pos + Vector2(8, 0),
			pos + Vector2(0, 8),
			pos + Vector2(-8, 0)
		])
		draw_polygon(pts, PackedColorArray([Color(1.0, 0.9, 0.2)]))
