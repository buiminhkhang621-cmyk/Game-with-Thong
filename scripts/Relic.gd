extends Node2D
class_name Relic

var relic_id: String = ""
var is_picked_up: bool = false
var float_offset: float = 0.0

const RELIC_POOL = [
	"heart_of_the_abyss",
	"blood_pact_blade",
	"chronos_hourglass",
	"vampiric_chalice",
	"greed_ring",
	"titan_aegis",
	"death_scythe_shard",
	"shadow_boots",
	"void_prism",
	"ancient_censer"
]

const RELIC_COLORS = {
	"heart_of_the_abyss": Color(0.9, 0.1, 0.3),
	"blood_pact_blade": Color(1.0, 0.2, 0.1),
	"chronos_hourglass": Color(0.3, 0.8, 1.0),
	"vampiric_chalice": Color(0.8, 0.1, 0.4),
	"greed_ring": Color(1.0, 0.85, 0.1),
	"titan_aegis": Color(0.4, 0.6, 0.9),
	"death_scythe_shard": Color(0.7, 0.2, 0.9),
	"shadow_boots": Color(0.3, 0.9, 0.6),
	"void_prism": Color(0.8, 0.3, 1.0),
	"ancient_censer": Color(0.95, 0.75, 0.3)
}

func _ready() -> void:
	if relic_id == "":
		relic_id = RELIC_POOL[randi() % RELIC_POOL.size()]

func _process(delta: float) -> void:
	if is_picked_up or GameManager.game_over:
		return
		
	float_offset += delta * 2.5
	
	if GameManager.player:
		var dist_sq = global_position.distance_squared_to(GameManager.player.global_position)
		if dist_sq < 120.0 * 120.0:
			var dir = (GameManager.player.global_position - global_position).normalized()
			global_position += dir * 420.0 * delta
			if dist_sq < 28.0 * 28.0:
				_pickup()
	
	queue_redraw()

func _pickup() -> void:
	is_picked_up = true
	GameManager.active_relics.append(relic_id)
	
	# Show pickup text
	var dn = load("res://scenes/DamageNumber.tscn").instantiate()
	get_tree().current_scene.add_child(dn)
	dn.global_position = global_position
	dn.setup(1.0, true, RELIC_COLORS.get(relic_id, Color.GOLD))
	
	if GameManager.player:
		GameManager.player._update_max_hp()
		if relic_id == "heart_of_the_abyss":
			GameManager.player.heal(100.0)
	
	queue_free()

func _draw() -> void:
	if not is_picked_up:
		var y_off = sin(float_offset) * 5.0
		var pos = Vector2(0, y_off)
		var col = RELIC_COLORS.get(relic_id, Color.GOLD)
		
		# Glowing aura
		draw_circle(pos, 14.0, Color(col.r, col.g, col.b, 0.35))
		
		# Relic Diamond shape
		var pts = PackedVector2Array([
			pos + Vector2(0, -10),
			pos + Vector2(9, 0),
			pos + Vector2(0, 10),
			pos + Vector2(-9, 0)
		])
		draw_polygon(pts, PackedColorArray([col]))
		draw_polyline(pts, Color.WHITE, 1.5)
