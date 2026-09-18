extends Node2D
class_name MeteorStrike

var timer: float = 0.9 # 0.9s telegraph
var exploded: bool = false
var anim_timer: float = 0.0
const BLAST_RADIUS: float = 90.0

func _ready() -> void:
	z_index = 25
	add_to_group("temporary_effects")
	add_to_group("event_entities")
	queue_redraw()

func _process(delta: float) -> void:
	if not exploded:
		timer -= delta
		if timer <= 0.0:
			_explode()
	else:
		anim_timer += delta
		if anim_timer >= 0.45:
			queue_free()
			return
	queue_redraw()

func _explode() -> void:
	exploded = true
	var r_sq = BLAST_RADIUS * BLAST_RADIUS
	
	# Damage enemies (safely iterate over duplicate)
	for e in GameManager.active_enemies.duplicate():
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		if global_position.distance_squared_to(e.global_position) <= r_sq:
			if e.has_method("take_damage"):
				e.take_damage(160.0)
			if e.has_method("apply_knockback"):
				var dir = (e.global_position - global_position).normalized()
				if dir.length() < 0.1: dir = Vector2.UP
				e.apply_knockback(dir, 380.0)
				
	# Damage player if in epicenter (dodged by jumping or walking out)
	var player = GameManager.player
	if player and is_instance_valid(player):
		if global_position.distance_squared_to(player.global_position) <= (BLAST_RADIUS * 0.75) * (BLAST_RADIUS * 0.75):
			player.take_damage(18.0, true) # Ground explosion - dodged with jump!
			player._shake_intensity = max(player._shake_intensity, 16.0)

func _draw() -> void:
	if not exploded:
		var progress = clampf(1.0 - (timer / 0.9), 0.0, 1.0)
		
		# 1. Subtle semi-transparent danger ground disc
		draw_circle(Vector2.ZERO, BLAST_RADIUS, Color(0.9, 0.25, 0.05, 0.08 + progress * 0.12))
		# Outer boundary ring
		draw_arc(Vector2.ZERO, BLAST_RADIUS, 0, TAU, 32, Color(1.0, 0.45, 0.1, 0.6 + progress * 0.4), 2.0)
		
		# 2. Contracting inner countdown ring that meets boundary on impact
		var r_contract = BLAST_RADIUS * (1.0 - progress)
		if r_contract > 2.0:
			draw_arc(Vector2.ZERO, r_contract, 0, TAU, 24, Color(1.0, 0.85, 0.25, 0.85), 2.0)
			
		# 3. Reticle crosshairs
		draw_line(Vector2(-12, 0), Vector2(12, 0), Color(1.0, 0.5, 0.1, 0.7), 1.5)
		draw_line(Vector2(0, -12), Vector2(0, 12), Color(1.0, 0.5, 0.1, 0.7), 1.5)
		
		# 4. Falling meteor streak descending from sky
		var meteor_start = Vector2(110, -260)
		var curr_pos = meteor_start * (1.0 - progress)
		# Fiery meteor tail
		draw_line(curr_pos + Vector2(25, -60), curr_pos, Color(1.0, 0.35, 0.05, 0.7), 4.0)
		draw_line(curr_pos + Vector2(12, -30), curr_pos, Color(1.0, 0.85, 0.2, 0.9), 2.5)
		# Molten rock core
		draw_circle(curr_pos, 7.0 + progress * 2.0, Color(0.25, 0.1, 0.05))
		draw_circle(curr_pos, 5.0, Color(1.0, 0.6, 0.1))
	else:
		# Fiery Meteor Impact Explosion & Shockwave
		var t = anim_timer / 0.45
		var r = BLAST_RADIUS * (0.6 + t * 0.7)
		var alpha = 1.0 - t
		
		# Outer shockwave
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.35, 0.05, alpha * 0.35))
		draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 0.85, 0.2, alpha * 0.6))
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1.0, 0.6, 0.1, alpha), 3.0)
		
		# Ground scorch mark
		draw_circle(Vector2.ZERO, BLAST_RADIUS * 0.35, Color(0.12, 0.06, 0.02, alpha * 0.5))
