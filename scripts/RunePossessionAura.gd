extends Node2D
class_name RunePossessionAura

var rot_angle: float = 0.0
var pulse_time: float = 0.0

const RUNES_LIST = ["lightning", "ice", "dark", "void"]
const RUNE_COLORS = {
	"lightning": Color(1.0, 0.88, 0.25),
	"ice": Color(0.35, 0.85, 1.0),
	"dark": Color(0.75, 0.25, 0.95),
	"void": Color(0.95, 0.3, 1.0)
}

func _ready() -> void:
	z_index = -1 # Render behind player sprite like a sacred halo
	queue_redraw()

func _process(delta: float) -> void:
	rot_angle += delta * 0.75
	pulse_time += delta * 3.0
	queue_redraw()

func _draw() -> void:
	var unlocked = GameManager.unlocked_runes
	if unlocked.size() == 0 and GameManager.resonance_active == "":
		return
		
	var pulse = 0.85 + sin(pulse_time) * 0.15
	var time_sec = Time.get_ticks_msec() / 1000.0
	
	# 1. Divine Cosmic Halo Ring behind player
	var halo_radius = 42.0 + sin(pulse_time * 0.7) * 3.0
	var halo_color = Color(0.8, 0.7, 1.0, 0.25 * pulse)
	
	if GameManager.resonance_active != "":
		halo_color = RUNE_COLORS.get(GameManager.resonance_active, halo_color)
		halo_color.a = 0.45 * pulse
		
	# Outer celestial ring
	draw_arc(Vector2.ZERO, halo_radius, 0, TAU, 32, halo_color, 1.5)
	# Inner breathing halo glow
	draw_circle(Vector2.ZERO, halo_radius * 0.85, Color(halo_color.r, halo_color.g, halo_color.b, 0.08 * pulse))
	
	# 2. Celestial Orbiting Mythological Runic Glyphs
	var active_list = []
	for r in unlocked:
		if not active_list.has(r):
			active_list.append(r)
			
	var count = active_list.size()
	if count > 0:
		for i in range(count):
			var rune_id = active_list[i]
			var angle = rot_angle + (TAU / count) * i
			var orbit_dist = 52.0 + sin(time_sec * 2.0 + i) * 4.0
			var rune_pos = Vector2(cos(angle), sin(angle) * 0.65) * orbit_dist # Elliptical cosmic orbit
			
			# Ethereal trailing aura
			var col = RUNE_COLORS.get(rune_id, Color.WHITE)
			draw_circle(rune_pos, 16.0, Color(col.r, col.g, col.b, 0.2 * pulse))
			draw_arc(rune_pos, 14.0, 0, TAU, 16, Color(col.r, col.g, col.b, 0.6 * pulse), 1.2)
			
			# Draw the divine mythological rune glyph!
			UpgradeIcons.draw_mythic_rune_glyph(self, rune_id, rune_pos, 10.0, col, pulse)
			
			# Cosmic starlight connection beam to player
			draw_line(Vector2.ZERO, rune_pos * 0.6, Color(col.r, col.g, col.b, 0.15 * pulse), 1.0)
