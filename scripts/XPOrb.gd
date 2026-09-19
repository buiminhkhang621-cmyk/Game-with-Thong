class_name XPOrb
extends Node2D

static var all_orbs: Array = []
const MAX_ORBS: int = 90

@export var value: int = 1
var pickup_radius_base: float = 55.0
var is_attracted: bool = false
var _check_timer: float = 0.0

func _enter_tree() -> void:
	all_orbs.append(self)

func _exit_tree() -> void:
	all_orbs.erase(self)

func _ready() -> void:
	add_to_group("xp_orbs")
	queue_redraw()

func add_value(amount: int) -> void:
	value += amount
	var s = clampf(1.0 + float(value) * 0.03, 1.0, 2.5)
	scale = Vector2(s, s)
	queue_redraw()

func _process(delta: float) -> void:
	var player = GameManager.player
	if player == null or GameManager.game_over or GameManager.paused_for_levelup:
		return

	if not is_attracted:
		_check_timer -= delta
		if _check_timer > 0.0:
			return
		_check_timer = 0.12 # Check ~8 times per second when idle
		
		var pr: float = pickup_radius_base * (1.0 + GameManager.passive_value("pickup"))
		var dist_sq: float = global_position.distance_squared_to(player.global_position)
		if dist_sq < pr * pr:
			is_attracted = true
	else:
		var to_p = player.global_position - global_position
		var dist_sq = to_p.length_squared()
		if dist_sq < 22.0 * 22.0:
			GameManager.grant_xp(value)
			GameManager.add_score(value * 5)
			queue_free()
		else:
			var move_speed = 360.0
			global_position += to_p.normalized() * move_speed * delta

func _draw() -> void:
	var col = Color(0.4, 0.9, 0.5)
	var radius = 4.0
	if value >= 20:
		col = Color(1.0, 0.88, 0.25)
		radius = 5.5
	elif value >= 5:
		col = Color(0.3, 0.75, 1.0)
		radius = 4.8
	draw_circle(Vector2.ZERO, radius, col)
	draw_circle(Vector2.ZERO, radius * 0.5, Color.WHITE)

static func spawn_or_merge(pos: Vector2, val: int, parent: Node, orb_scene: PackedScene) -> void:
	# 1. If an orb already exists nearby (< 55px), merge immediately into it!
	var check_count = min(30, all_orbs.size())
	for i in range(all_orbs.size() - 1, all_orbs.size() - 1 - check_count, -1):
		if i < 0: break
		var o = all_orbs[i]
		if is_instance_valid(o) and not o.is_queued_for_deletion():
			if pos.distance_squared_to(o.global_position) < 55.0 * 55.0:
				o.add_value(val)
				return

	# 2. If at or above max capacity, merge with the closest existing orb
	if all_orbs.size() >= MAX_ORBS:
		var best_orb = null
		var best_dist_sq = 1e9
		for o in all_orbs:
			if is_instance_valid(o) and not o.is_queued_for_deletion():
				var d_sq = pos.distance_squared_to(o.global_position)
				if d_sq < best_dist_sq:
					best_dist_sq = d_sq
					best_orb = o
		if best_orb:
			best_orb.add_value(val)
			return

	# 3. Otherwise spawn new orb
	if orb_scene and parent:
		var orb = orb_scene.instantiate()
		parent.add_child(orb)
		orb.global_position = pos
		orb.value = val
		orb.queue_redraw()
