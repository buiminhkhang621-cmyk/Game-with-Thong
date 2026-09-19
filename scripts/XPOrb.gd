class_name XPOrb
extends Node2D

static var all_orbs: Array = []
const MAX_ORBS: int = 80

@export var value: int = 1
var pickup_radius_base: float = 75.0 # Enhanced base pickup radius so orbs are never missed
var is_attracted: bool = false
var is_collected: bool = false
var _check_timer: float = 0.0

func _enter_tree() -> void:
	all_orbs.append(self)

func _exit_tree() -> void:
	all_orbs.erase(self)

func _ready() -> void:
	add_to_group("xp_orbs")
	queue_redraw()

func add_value(amount: int) -> void:
	value = min(value + amount, 50)
	var s = clampf(1.0 + float(value) * 0.04, 1.0, 1.8)
	scale = Vector2(s, s)
	queue_redraw()

func _process(delta: float) -> void:
	if is_collected:
		return
		
	var player = GameManager.player
	if player == null or not is_instance_valid(player) or GameManager.game_over or GameManager.paused_for_levelup:
		return

	if not is_attracted:
		_check_timer -= delta
		if _check_timer > 0.0:
			return
		_check_timer = 0.06 # Responsive check ~16 times per second
		
		var pr: float = pickup_radius_base * (1.0 + GameManager.passive_value("pickup"))
		var dist_sq: float = global_position.distance_squared_to(player.global_position)
		if dist_sq < pr * pr:
			is_attracted = true
	else:
		var to_p = player.global_position - global_position
		var dist = to_p.length()
		if dist < 32.0:
			# Collect immediately - prevent any double-trigger
			if is_collected: return
			is_collected = true
			set_process(false)
			all_orbs.erase(self)
			visible = false
			GameManager.grant_xp(value)
			GameManager.add_score(value * 5)
			queue_free()
			return
		else:
			# Dynamic acceleration: orb speed scales with distance so it ALWAYS overtakes the player
			var move_speed = max(480.0, dist * 4.5 + 250.0)
			global_position += (to_p / max(1.0, dist)) * (move_speed * delta)

func _draw() -> void:
	if is_collected: return
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
	# 1. If an active uncollected orb already exists nearby (< 50px) and has room, merge!
	var check_count = min(25, all_orbs.size())
	for i in range(all_orbs.size() - 1, all_orbs.size() - 1 - check_count, -1):
		if i < 0: break
		var o = all_orbs[i]
		if is_instance_valid(o) and not o.is_queued_for_deletion() and not o.is_collected:
			if o.value < 50 and pos.distance_squared_to(o.global_position) < 50.0 * 50.0:
				o.add_value(val)
				return

	# 2. If at or above max capacity, merge with the closest active orb
	if all_orbs.size() >= MAX_ORBS:
		var best_orb = null
		var best_dist_sq = 1e9
		for o in all_orbs:
			if is_instance_valid(o) and not o.is_queued_for_deletion() and not o.is_collected:
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
		orb.value = min(val, 50)
		orb.queue_redraw()
