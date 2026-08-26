class_name FloorPickup
extends Node2D

@export var pickup_type: String = "blood_vial" # blood_vial, void_magnet, cataclysm_nuke, time_stasis

var is_attracted: bool = false
var float_offset: float = 0.0
var life_timer: float = 45.0 # Despawns after 45s if untouched

const COLOR_MAP = {
	"blood_vial": Color(1.0, 0.2, 0.25),
	"void_magnet": Color(0.3, 0.8, 1.0),
	"cataclysm_nuke": Color(1.0, 0.65, 0.1),
	"time_stasis": Color(0.4, 0.95, 0.85)
}

func setup(type: String) -> void:
	pickup_type = type
	float_offset = randf() * TAU

func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
		
	float_offset += delta * 3.0
	life_timer -= delta
	if life_timer <= 0.0:
		queue_free()
		return
		
	var player = GameManager.player
	if not player:
		return
		
	var dist_sq = global_position.distance_squared_to(player.global_position)
	var pickup_r = 70.0 * (1.0 + GameManager.passive_value("pickup"))
	
	if not is_attracted:
		if dist_sq < pickup_r * pickup_r:
			is_attracted = true
	else:
		var dir = (player.global_position - global_position).normalized()
		global_position += dir * 420.0 * delta
		if dist_sq < 20.0 * 20.0:
			_apply_pickup_effect()
			queue_free()
			
	queue_redraw()

func _apply_pickup_effect() -> void:
	var player = GameManager.player
	var dn = load("res://scenes/DamageNumber.tscn").instantiate()
	get_tree().current_scene.add_child(dn)
	dn.global_position = global_position
	
	match pickup_type:
		"blood_vial":
			if player: player.heal(30.0)
			dn.setup(30.0, false, Color(0.2, 1.0, 0.3))
		"void_magnet":
			GameManager.trigger_void_magnet()
			dn.setup(1.0, false, Color(0.3, 0.8, 1.0))
		"cataclysm_nuke":
			GameManager.trigger_cataclysm_nuke()
			dn.setup(999.0, true, Color(1.0, 0.6, 0.1))
		"time_stasis":
			GameManager.trigger_time_stasis(4.5)
			dn.setup(0.0, false, Color(0.4, 0.9, 0.9))

func _draw() -> void:
	var color = COLOR_MAP.get(pickup_type, Color.WHITE)
	var y_off = sin(float_offset) * 4.0
	var pos = Vector2(0, y_off)
	
	# Glow aura
	draw_circle(pos, 14.0, Color(color.r, color.g, color.b, 0.25))
	
	match pickup_type:
		"blood_vial":
			# Crimson Diamond
			var pts = PackedVector2Array([
				pos + Vector2(0, -9),
				pos + Vector2(8, 0),
				pos + Vector2(0, 9),
				pos + Vector2(-8, 0)
			])
			draw_polygon(pts, PackedColorArray([color]))
			draw_polyline(pts, Color.WHITE, 1.5)
		"void_magnet":
			# Magnet Horseshoe Arc
			draw_arc(pos, 8.0, PI * 0.7, PI * 2.3, 16, color, 3.5)
			draw_circle(pos + Vector2(-6, 4), 2.5, Color.WHITE)
			draw_circle(pos + Vector2(6, 4), 2.5, Color.WHITE)
		"cataclysm_nuke":
			# 8-Point Star
			var r_out = 9.0
			var r_in = 4.0
			var pts = PackedVector2Array()
			for i in range(8):
				var a1 = (TAU / 8.0) * i
				var a2 = a1 + (TAU / 16.0)
				pts.append(pos + Vector2(cos(a1), sin(a1)) * r_out)
				pts.append(pos + Vector2(cos(a2), sin(a2)) * r_in)
			draw_polygon(pts, PackedColorArray([color]))
			draw_circle(pos, 3.0, Color.WHITE)
		"time_stasis":
			# Stasis Clock Ring
			draw_arc(pos, 8.0, 0, TAU, 20, color, 2.5)
			draw_line(pos, pos + Vector2(0, -5), Color.WHITE, 2.0)
			draw_line(pos, pos + Vector2(4, 0), Color.WHITE, 2.0)
