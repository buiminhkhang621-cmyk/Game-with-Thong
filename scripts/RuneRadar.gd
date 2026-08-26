class_name RuneRadar
extends Control

var cached_fountains: Array = []
var _refresh_timer: float = 0.0

const ELEMENT_COLORS = {
	"lightning": Color(1.0, 0.85, 0.2),
	"ice": Color(0.3, 0.85, 1.0),
	"dark": Color(0.68, 0.25, 0.95),
	"void": Color(0.95, 0.3, 1.0)
}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_fountains_list()

func _update_fountains_list() -> void:
	cached_fountains = get_tree().get_nodes_in_group("rune_fountains")

func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
		
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.5
		_update_fountains_list()
		
	queue_redraw()

func _draw() -> void:
	var player = GameManager.player
	if not player:
		return
		
	var v_size = get_viewport_rect().size
	var center = v_size * 0.5
	var margin = 50.0
	var half_w = (v_size.x * 0.5) - margin
	var half_h = (v_size.y * 0.5) - margin
	
	var time = Time.get_ticks_msec() / 1000.0
	var pulse = sin(time * 6.0) * 3.0
	
	for fountain in cached_fountains:
		if not is_instance_valid(fountain) or fountain.is_queued_for_deletion():
			continue
			
		var rune = fountain.get("rune_type")
		if not rune or rune == "":
			continue
			
		var is_used = fountain.get("used")
		# If unlocked, don't show
		if is_used:
			continue
			
		var color = ELEMENT_COLORS.get(rune, Color.WHITE)
		
		var delta_pos = fountain.global_position - player.global_position
		var dist = delta_pos.length()
		
		# Check if fountain is on-screen
		var screen_pos = center + delta_pos
		var is_on_screen = (screen_pos.x >= margin and screen_pos.x <= v_size.x - margin and screen_pos.y >= margin and screen_pos.y <= v_size.y - margin)
		
		if is_on_screen:
			# Draw pulsating beacon over fountain
			draw_circle(screen_pos, 22.0 + pulse, Color(color.r, color.g, color.b, 0.2))
			draw_arc(screen_pos, 18.0, 0, TAU, 24, color, 2.0)
			continue
			
		# Off-screen: compute border intersection
		var dir = delta_pos.normalized()
		
		# Ray-box intersection from center
		var edge_pos = Vector2.ZERO
		if abs(dir.x) * half_h > abs(dir.y) * half_w:
			# Hits left or right border
			var sign_x = sign(dir.x)
			edge_pos.x = sign_x * half_w
			edge_pos.y = (dir.y / abs(dir.x)) * half_w
		else:
			# Hits top or bottom border
			var sign_y = sign(dir.y)
			edge_pos.y = sign_y * half_h
			edge_pos.x = (dir.x / abs(dir.y)) * half_h
			
		var target_pos = center + edge_pos
		
		# Draw pointer arrow
		var arrow_size = 14.0
		var tip = target_pos + dir * (arrow_size + pulse)
		var left_wing = target_pos + dir.rotated(2.4) * arrow_size
		var right_wing = target_pos + dir.rotated(-2.4) * arrow_size
		
		# Draw glowing background pill / circle
		draw_circle(target_pos, 18.0, Color(0.1, 0.1, 0.14, 0.85))
		draw_arc(target_pos, 18.0, 0, TAU, 20, color, 2.0)
		
		# Draw arrow head
		draw_colored_polygon(PackedVector2Array([tip, left_wing, right_wing]), color)
		
		# Draw distance label
		var dist_meters = int(dist / 10.0)
		var font = ThemeDB.fallback_font
		var label_str = "%s %dm" % [rune.capitalize(), dist_meters]
		var text_size = font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		
		var text_pos = target_pos - dir * 28.0 - Vector2(text_size.x * 0.5, -text_size.y * 0.3)
		# Draw background rect for text
		var bg_rect = Rect2(text_pos.x - 4, text_pos.y - text_size.y + 2, text_size.x + 8, text_size.y + 4)
		draw_rect(bg_rect, Color(0, 0, 0, 0.75), true)
		draw_rect(bg_rect, color, false, 1.0)
		
		draw_string(font, text_pos, label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
