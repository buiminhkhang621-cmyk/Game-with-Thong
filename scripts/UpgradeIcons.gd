class_name UpgradeIcons
extends RefCounted

# Draw procedural vector icon silhouettes for all skills, passives, relics, and elements
static func draw_icon(canvas: CanvasItem, id: String, center: Vector2, size: float, color: Color) -> void:
	var s = size * 0.5
	match id:
		# --- WEAPONS ---
		"piercing_bolt", "bolt":
			# Crossbow Bolt / Piercing Arrow
			var pts = PackedVector2Array([
				center + Vector2(0, -s),
				center + Vector2(s * 0.4, -s * 0.2),
				center + Vector2(s * 0.15, -s * 0.2),
				center + Vector2(s * 0.15, s * 0.7),
				center + Vector2(s * 0.4, s * 0.9),
				center + Vector2(0, s * 0.6),
				center + Vector2(-s * 0.4, s * 0.9),
				center + Vector2(-s * 0.15, s * 0.7),
				center + Vector2(-s * 0.15, -s * 0.2),
				center + Vector2(-s * 0.4, -s * 0.2)
			])
			canvas.draw_polygon(pts, PackedColorArray([color]))
			canvas.draw_polyline(pts, Color.WHITE, 1.5)
			
		"throwing_knife", "knife", "orbit_blade", "blade":
			var tex = UITheme.load_texture("res://Sprite/weapon/knife.png")
			if tex:
				var sz = Vector2(s * 0.85, s * 1.05)
				canvas.draw_texture_rect(tex, Rect2(center - sz * 0.5, sz), false, color)
			else:
				for i in range(3):
					var a = (TAU / 3.0) * i
					var p1 = center + Vector2(cos(a), sin(a)) * s * 0.3
					var p2 = center + Vector2(cos(a + 0.4), sin(a + 0.4)) * (s * 0.65)
					var p3 = center + Vector2(cos(a + 0.8), sin(a + 0.8)) * s
					canvas.draw_polygon(PackedVector2Array([center, p1, p2, p3]), PackedColorArray([color]))
				canvas.draw_circle(center, s * 0.25, Color.WHITE)

			
		"magic_whip", "whip":
			# Curved Energy Whip / Slash
			var pts = PackedVector2Array([
				center + Vector2(-s * 0.8, s * 0.7),
				center + Vector2(-s * 0.4, s * 0.3),
				center + Vector2(0, -s * 0.2),
				center + Vector2(s * 0.5, -s * 0.7),
				center + Vector2(s * 0.85, -s * 0.85),
				center + Vector2(s * 0.6, -s * 0.4),
				center + Vector2(0.1, 0),
				center + Vector2(-s * 0.3, s * 0.5)
			])
			canvas.draw_polygon(pts, PackedColorArray([color]))
			canvas.draw_circle(center + Vector2(s * 0.85, -s * 0.85), 3.0, Color.WHITE)
			
		"nova_scatter", "scatter":
			# 5-Way Explosive Scatter Bullets
			for i in range(5):
				var a = -PI * 0.8 + (PI * 0.6 / 4.0) * i
				var p = center + Vector2(cos(a), sin(a)) * s * 0.8
				canvas.draw_circle(p, s * 0.18, color)
				canvas.draw_line(center + Vector2(0, s * 0.4), p, Color(color.r, color.g, color.b, 0.5), 2.0)
				
		"guardian", "shield":
			var tex = UITheme.load_texture("res://Sprite/weapon/shield.png")
			if tex:
				var sz = Vector2(s * 1.4, s * 1.9)
				canvas.draw_texture_rect(tex, Rect2(center - sz * 0.5, sz), false, color)
			else:
				var pts = PackedVector2Array([
					center + Vector2(-s * 0.7, -s * 0.7),
					center + Vector2(s * 0.7, -s * 0.7),
					center + Vector2(s * 0.7, s * 0.1),
					center + Vector2(0, s * 0.85),
					center + Vector2(-s * 0.7, s * 0.1)
				])
				canvas.draw_polygon(pts, PackedColorArray([color]))
				canvas.draw_polyline(pts, Color.WHITE, 1.5)
				canvas.draw_line(center + Vector2(0, -s * 0.4), center + Vector2(0, s * 0.4), Color.WHITE, 2.0)


		"warden", "greatsword":
			# Upright Broadsword
			var pts = PackedVector2Array([
				center + Vector2(0, -s * 0.9),
				center + Vector2(s * 0.25, -s * 0.6),
				center + Vector2(s * 0.2, s * 0.3),
				center + Vector2(s * 0.5, s * 0.35),
				center + Vector2(s * 0.5, s * 0.45),
				center + Vector2(s * 0.1, s * 0.45),
				center + Vector2(s * 0.1, s * 0.8),
				center + Vector2(-s * 0.1, s * 0.8),
				center + Vector2(-s * 0.1, s * 0.45),
				center + Vector2(-s * 0.5, s * 0.45),
				center + Vector2(-s * 0.5, s * 0.35),
				center + Vector2(-s * 0.2, s * 0.3),
				center + Vector2(-s * 0.25, -s * 0.6)
			])
			canvas.draw_polygon(pts, PackedColorArray([color]))
			canvas.draw_polyline(pts, Color.WHITE, 1.5)

		"throwing_axe", "axe":
			var tex = UITheme.load_texture("res://Sprite/weapon/axe.png")
			if tex:
				var sz = Vector2(s * 1.6, s * 1.9)
				canvas.draw_texture_rect(tex, Rect2(center - sz * 0.5, sz), false, color)
			else:
				var pts = PackedVector2Array([
					center + Vector2(0, -s * 0.85),
					center + Vector2(s * 0.6, -s * 0.6),
					center + Vector2(s * 0.5, -s * 0.1),
					center + Vector2(s * 0.15, -s * 0.2),
					center + Vector2(s * 0.1, s * 0.85),
					center + Vector2(-s * 0.1, s * 0.85),
					center + Vector2(-s * 0.15, -s * 0.2),
					center + Vector2(-s * 0.5, -s * 0.1),
					center + Vector2(-s * 0.6, -s * 0.6)
				])
				canvas.draw_polygon(pts, PackedColorArray([color]))
				canvas.draw_polyline(pts, Color.WHITE, 1.5)

		"elemental_orbs", "orbs":
			var tex = UITheme.load_texture("res://Sprite/weapon/Magic-ball.png")
			if tex:
				var sz = Vector2(s * 1.6, s * 1.65)
				canvas.draw_texture_rect(tex, Rect2(center - sz * 0.5, sz), false, color)
			else:
				for i in range(3):
					var a = (TAU / 3.0) * i
					var p = center + Vector2(cos(a), sin(a)) * (s * 0.6)
					canvas.draw_circle(p, s * 0.25, color)
					canvas.draw_circle(p, s * 0.1, Color.WHITE)
				canvas.draw_arc(center, s * 0.6, 0, TAU, 16, Color(color.r, color.g, color.b, 0.4), 1.5)
				
		"chain_lightning", "lightning":
			# Electric lightning bolt zigzag
			var pts = PackedVector2Array([
				center + Vector2(s * 0.15, -s * 0.85),
				center + Vector2(-s * 0.45, -s * 0.05),
				center + Vector2(-s * 0.05, -s * 0.05),
				center + Vector2(-s * 0.35, s * 0.85),
				center + Vector2(s * 0.45, s * 0.0),
				center + Vector2(s * 0.05, s * 0.0)
			])
			canvas.draw_polygon(pts, PackedColorArray([color]))
			canvas.draw_polyline(pts, Color.WHITE, 1.5)
			# Outer electric spark arcs
			canvas.draw_arc(center, s * 0.7, 0.2, 1.2, 6, Color(1.0, 1.0, 0.7, 0.8), 2.0)
			canvas.draw_arc(center, s * 0.7, 3.2, 4.2, 6, Color(1.0, 1.0, 0.7, 0.8), 2.0)


		# --- PASSIVES & STATS ---
		"might":
			var pts = PackedVector2Array([
				center + Vector2(0, -s * 0.85),
				center + Vector2(s * 0.3, -s * 0.3),
				center + Vector2(s * 0.15, s * 0.3),
				center + Vector2(s * 0.4, s * 0.4),
				center + Vector2(0, s * 0.75),
				center + Vector2(-s * 0.4, s * 0.4),
				center + Vector2(-s * 0.15, s * 0.3),
				center + Vector2(-s * 0.3, -s * 0.3)
			])
			canvas.draw_polygon(pts, PackedColorArray([color]))

		"haste":
			canvas.draw_arc(center + Vector2(0, s * 0.2), s * 0.7, -PI * 0.85, PI * -0.15, 16, color, 3.5)
			canvas.draw_line(center + Vector2(0, s * 0.2), center + Vector2(s * 0.4, -s * 0.35), Color.WHITE, 3.0)
			canvas.draw_circle(center + Vector2(0, s * 0.2), 4.0, Color.WHITE)

		"vitality":
			var pts = PackedVector2Array([
				center + Vector2(0, s * 0.8),
				center + Vector2(-s * 0.75, s * 0.1),
				center + Vector2(-s * 0.7, -s * 0.5),
				center + Vector2(-s * 0.3, -s * 0.75),
				center + Vector2(0, -s * 0.35),
				center + Vector2(s * 0.3, -s * 0.75),
				center + Vector2(s * 0.7, -s * 0.5),
				center + Vector2(s * 0.75, s * 0.1)
			])
			canvas.draw_polygon(pts, PackedColorArray([color]))
			canvas.draw_polyline(pts, Color.WHITE, 1.5)

		"magnet":
			var pts = PackedVector2Array([
				center + Vector2(-s * 0.7, s * 0.6),
				center + Vector2(-s * 0.7, -s * 0.3),
				center + Vector2(0, -s * 0.8),
				center + Vector2(s * 0.7, -s * 0.3),
				center + Vector2(s * 0.7, s * 0.6),
				center + Vector2(s * 0.35, s * 0.6),
				center + Vector2(s * 0.35, -s * 0.2),
				center + Vector2(0, -s * 0.45),
				center + Vector2(-s * 0.35, -s * 0.2),
				center + Vector2(-s * 0.35, s * 0.6)
			])
			canvas.draw_polygon(pts, PackedColorArray([color]))

		"armor":
			var tex = UITheme.load_texture("res://Sprite/weapon/shield.png")
			if tex:
				var sz = Vector2(s * 1.4, s * 1.9)
				canvas.draw_texture_rect(tex, Rect2(center - sz * 0.5, sz), false, color)
			else:
				var pts = PackedVector2Array([
					center + Vector2(-s * 0.6, -s * 0.7),
					center + Vector2(0, -s * 0.4),
					center + Vector2(s * 0.6, -s * 0.7),
					center + Vector2(s * 0.8, -s * 0.2),
					center + Vector2(s * 0.5, s * 0.65),
					center + Vector2(0, s * 0.85),
					center + Vector2(-s * 0.5, s * 0.65),
					center + Vector2(-s * 0.8, -s * 0.2)
				])
				canvas.draw_polygon(pts, PackedColorArray([color]))
				canvas.draw_polyline(pts, Color.WHITE, 1.5)


		"crit":
			var pts = PackedVector2Array([
				center + Vector2(0, -s * 0.9),
				center + Vector2(s * 0.35, -s * 0.1),
				center + Vector2(s * 0.1, s * 0.7),
				center + Vector2(0, s * 0.5),
				center + Vector2(-s * 0.1, s * 0.7),
				center + Vector2(-s * 0.35, -s * 0.1)
			])
			canvas.draw_polygon(pts, PackedColorArray([color]))
			canvas.draw_circle(center + Vector2(0, -s * 0.1), 3.0, Color.WHITE)

		"cdr", "hourglass":
			var pts = PackedVector2Array([
				center + Vector2(-s * 0.6, -s * 0.7),
				center + Vector2(s * 0.6, -s * 0.7),
				center + Vector2(s * 0.1, 0),
				center + Vector2(s * 0.6, s * 0.7),
				center + Vector2(-s * 0.6, s * 0.7),
				center + Vector2(-s * 0.1, 0)
			])
			canvas.draw_polygon(pts, PackedColorArray([color]))
			canvas.draw_polyline(pts, Color.WHITE, 1.5)

		# --- 10 UNIQUE CURSED RELICS (DARK FANTASY / DEADLY ARTIFACTS) ---
		"death_scythe_shard", "reaper_scythe":
			# Grim Reaper Crescent Scythe
			var scythe = PackedVector2Array([
				center + Vector2(-s * 0.7, s * 0.85),
				center + Vector2(s * 0.3, -s * 0.4),
				center + Vector2(s * 0.85, -s * 0.85),
				center + Vector2(s * 0.2, -s * 0.8),
				center + Vector2(-s * 0.4, -s * 0.3),
				center + Vector2(s * 0.15, -s * 0.3)
			])
			canvas.draw_polyline(scythe, Color(0.85, 0.25, 0.95), 3.5)
			canvas.draw_circle(center + Vector2(0.2 * s, -0.4 * s), 4.0, Color.WHITE) # Skull gem

		"blood_pact_blade":
			# Demonic Sacrificial Dagger
			var dagger = PackedVector2Array([
				center + Vector2(0, -s * 0.9),
				center + Vector2(s * 0.3, -s * 0.3),
				center + Vector2(s * 0.15, s * 0.4),
				center + Vector2(s * 0.4, s * 0.45),
				center + Vector2(0, s * 0.85),
				center + Vector2(-s * 0.4, s * 0.45),
				center + Vector2(-s * 0.15, s * 0.4),
				center + Vector2(-s * 0.3, -s * 0.3)
			])
			canvas.draw_polygon(dagger, PackedColorArray([Color(0.95, 0.15, 0.2)]))
			canvas.draw_circle(center + Vector2(0, s * 0.1), 3.0, Color.WHITE)

		"chronos_hourglass", "doomglass":
			# Chronos Doomglass (Gilded Sand Timer)
			var pts = PackedVector2Array([
				center + Vector2(-s * 0.7, -s * 0.8),
				center + Vector2(s * 0.7, -s * 0.8),
				center + Vector2(s * 0.1, 0),
				center + Vector2(s * 0.7, s * 0.8),
				center + Vector2(-s * 0.7, s * 0.8),
				center + Vector2(-s * 0.1, 0)
			])
			canvas.draw_polygon(pts, PackedColorArray([Color(0.3, 0.85, 1.0)]))
			canvas.draw_polyline(pts, Color.WHITE, 1.5)

		"vampiric_chalice":
			# Gothic Blood Chalice
			var chalice = PackedVector2Array([
				center + Vector2(-s * 0.6, -s * 0.7),
				center + Vector2(s * 0.6, -s * 0.7),
				center + Vector2(s * 0.45, 0),
				center + Vector2(s * 0.15, s * 0.4),
				center + Vector2(s * 0.4, s * 0.8),
				center + Vector2(-s * 0.4, s * 0.8),
				center + Vector2(-s * 0.15, s * 0.4),
				center + Vector2(-s * 0.45, 0)
			])
			canvas.draw_polygon(chalice, PackedColorArray([Color(0.85, 0.1, 0.35)]))
			canvas.draw_circle(center + Vector2(0, -s * 0.3), 5.0, Color.WHITE)

		"greed_ring", "midas_coin":
			# Skull Ring of Midas
			canvas.draw_arc(center, s * 0.7, 0, TAU, 24, Color(1.0, 0.85, 0.2), 3.5)
			canvas.draw_circle(center + Vector2(0, -s * 0.4), 6.0, Color(0.95, 0.2, 0.2)) # Ruby Gem

		"titan_aegis", "sarcophagus":
			# Titan Obsidian Sarcophagus
			var sarc = PackedVector2Array([
				center + Vector2(-s * 0.6, -s * 0.85),
				center + Vector2(s * 0.6, -s * 0.85),
				center + Vector2(s * 0.7, 0),
				center + Vector2(s * 0.45, s * 0.85),
				center + Vector2(-s * 0.45, s * 0.85),
				center + Vector2(-s * 0.7, 0)
			])
			canvas.draw_polygon(sarc, PackedColorArray([Color(0.2, 0.3, 0.45)]))
			canvas.draw_polyline(sarc, Color(0.9, 0.75, 0.3), 2.0)

		"void_prism":
			# Hexagonal Cosmic Crystal Prism
			for i in range(6):
				var a = (TAU / 6.0) * i
				var p = center + Vector2(cos(a), sin(a)) * s * 0.8
				canvas.draw_line(center, p, Color(0.95, 0.3, 1.0), 2.5)
			canvas.draw_circle(center, s * 0.3, Color.WHITE)

		"ancient_censer":
			# Gothic Hanging Incense Burner
			canvas.draw_circle(center + Vector2(0, s * 0.2), s * 0.5, Color(0.95, 0.75, 0.25))
			canvas.draw_line(center + Vector2(0, -s * 0.8), center + Vector2(0, -s * 0.3), Color.WHITE, 2.0)
			canvas.draw_circle(center + Vector2(0, -s * 0.8), 3.0, Color.WHITE)

		"shadow_boots":
			# Winged Phantom Greaves
			var boot = PackedVector2Array([
				center + Vector2(-s * 0.4, -s * 0.7),
				center + Vector2(s * 0.2, -s * 0.7),
				center + Vector2(s * 0.2, s * 0.2),
				center + Vector2(s * 0.7, s * 0.6),
				center + Vector2(s * 0.5, s * 0.8),
				center + Vector2(-s * 0.5, s * 0.8),
				center + Vector2(-s * 0.4, s * 0.1)
			])
			canvas.draw_polygon(boot, PackedColorArray([Color(0.2, 0.85, 0.6)]))
			canvas.draw_polyline(boot, Color.WHITE, 1.5)

		"heart_of_the_abyss":
			# Pulsating Eldritch Eye-Heart
			var heart = PackedVector2Array([
				center + Vector2(0, s * 0.85),
				center + Vector2(-s * 0.8, 0),
				center + Vector2(-s * 0.6, -s * 0.65),
				center + Vector2(0, -s * 0.25),
				center + Vector2(s * 0.6, -s * 0.65),
				center + Vector2(s * 0.8, 0)
			])
			canvas.draw_polygon(heart, PackedColorArray([Color(0.85, 0.15, 0.4)]))
			canvas.draw_circle(center + Vector2(0, -s * 0.1), 4.0, Color(0.95, 0.8, 1.0))

		# --- RUNES / ELEMENTS ---
		"lightning", "ice", "dark", "void":
			draw_mythic_rune_glyph(canvas, id, center, s, color)

		# Fallback Gem
		_:
			var pts = PackedVector2Array([
				center + Vector2(0, -s * 0.75),
				center + Vector2(s * 0.75, 0),
				center + Vector2(0, s * 0.75),
				center + Vector2(-s * 0.75, 0)
			])
			canvas.draw_polygon(pts, PackedColorArray([color]))
			canvas.draw_polyline(pts, Color.WHITE, 1.5)


# -------------------------------------------------------------
# MYTHOLOGICAL RUNIC SIGILS
# -------------------------------------------------------------
static func draw_mythic_rune_glyph(canvas: CanvasItem, rune_type: String, center: Vector2, radius: float, _base_color: Color = Color.WHITE, pulse: float = 1.0) -> void:
	var r = radius
	
	match rune_type:
		"lightning":
			var col = Color(1.0, 0.88, 0.25)
			canvas.draw_arc(center, r * 0.95, 0, TAU, 32, Color(col.r, col.g, col.b, 0.4 * pulse), 1.5)
			canvas.draw_arc(center, r * 0.82, 0, TAU, 32, Color(col.r, col.g, col.b, 0.6 * pulse), 1.0)
			for i in range(8):
				var a = (TAU / 8.0) * i
				var p_out = center + Vector2(cos(a), sin(a)) * (r * 0.95)
				var p_in = center + Vector2(cos(a), sin(a)) * (r * 0.82)
				canvas.draw_line(p_in, p_out, col, 1.5)
				
			var sowilo = PackedVector2Array([
				center + Vector2(r * 0.35, -r * 0.75),
				center + Vector2(-r * 0.35, -r * 0.1),
				center + Vector2(r * 0.1, -r * 0.1),
				center + Vector2(-r * 0.35, r * 0.75),
				center + Vector2(r * 0.35, 0.1),
				center + Vector2(-r * 0.1, 0.1)
			])
			canvas.draw_polyline(sowilo, col, 3.5)
			canvas.draw_polyline(sowilo, Color.WHITE, 1.5)
			
			canvas.draw_line(center + Vector2(-r * 0.55, -r * 0.4), center + Vector2(-r * 0.55, r * 0.4), col, 2.0)
			canvas.draw_line(center + Vector2(-r * 0.55, -r * 0.1), center + Vector2(-r * 0.35, 0), col, 2.0)
			canvas.draw_line(center + Vector2(-r * 0.35, 0), center + Vector2(-r * 0.55, r * 0.1), col, 2.0)

		"ice":
			var col = Color(0.35, 0.85, 1.0)
			var diamond = PackedVector2Array([
				center + Vector2(0, -r * 0.95),
				center + Vector2(r * 0.95, 0),
				center + Vector2(0, r * 0.95),
				center + Vector2(-r * 0.95, 0),
				center + Vector2(0, -r * 0.95)
			])
			canvas.draw_polyline(diamond, Color(col.r, col.g, col.b, 0.5 * pulse), 1.5)
			
			for i in range(4):
				var a = (TAU / 4.0) * i + PI * 0.25
				var p1 = center + Vector2(cos(a), sin(a)) * (r * 0.4)
				var p2 = center + Vector2(cos(a), sin(a)) * (r * 0.85)
				canvas.draw_line(p1, p2, col, 2.0)
				canvas.draw_circle(p2, 2.5, Color.WHITE)
				
			canvas.draw_line(center + Vector2(-r * 0.5, -r * 0.4), center + Vector2(-r * 0.25, -r * 0.2), col, 3.0)
			canvas.draw_line(center + Vector2(-r * 0.55, r * 0.35), center + Vector2(-r * 0.2, r * 0.05), col, 3.0)
			canvas.draw_line(center + Vector2(r * 0.15, -r * 0.65), center + Vector2(r * 0.15, r * 0.65), col, 3.5)
			canvas.draw_line(center + Vector2(r * 0.15, r * 0.65), center + Vector2(0, r * 0.45), col, 2.5)
			canvas.draw_line(center + Vector2(r * 0.15, -r * 0.15), center + Vector2(-r * 0.1, -r * 0.35), col, 2.5)
			canvas.draw_line(center + Vector2(r * 0.15, 0), center + Vector2(r * 0.55, r * 0.45), col, 3.0)
			canvas.draw_circle(center + Vector2(r * 0.15, 0), 3.0, Color.WHITE)

		"dark":
			var col = Color(0.75, 0.25, 0.95)
			canvas.draw_arc(center + Vector2(0, -r * 0.5), r * 0.28, 0, TAU, 24, col, 2.5)
			canvas.draw_line(center + Vector2(-r * 0.6, -r * 0.22), center + Vector2(r * 0.6, -r * 0.22), col, 3.0)
			
			var eye_top = PackedVector2Array([
				center + Vector2(-r * 0.5, 0),
				center + Vector2(0, -r * 0.18),
				center + Vector2(r * 0.5, 0)
			])
			var eye_bot = PackedVector2Array([
				center + Vector2(-r * 0.5, 0),
				center + Vector2(0, r * 0.18),
				center + Vector2(r * 0.5, 0)
			])
			canvas.draw_polyline(eye_top, col, 2.5)
			canvas.draw_polyline(eye_bot, col, 2.5)
			canvas.draw_circle(center, r * 0.12, Color.BLACK)
			canvas.draw_circle(center, r * 0.08, Color(1.0, 0.4, 1.0))
			
			canvas.draw_line(center + Vector2(0, r * 0.18), center + Vector2(0, r * 0.75), col, 2.5)
			canvas.draw_line(center + Vector2(r * 0.2, r * 0.18), center + Vector2(r * 0.35, r * 0.5), col, 2.0)
			canvas.draw_arc(center + Vector2(r * 0.25, r * 0.5), r * 0.12, 0, PI, 12, col, 2.0)

		"void":
			var col = Color(0.95, 0.3, 1.0)
			canvas.draw_arc(center, r * 0.9, 0, TAU, 32, Color(col.r, col.g, col.b, 0.4 * pulse), 1.5)
			canvas.draw_arc(center, r * 0.65, 0, TAU, 32, col, 2.0)
			
			for i in range(4):
				var a = (TAU / 4.0) * i
				var p1 = center + Vector2(cos(a), sin(a)) * (r * 0.5)
				var p2 = center + Vector2(cos(a), sin(a)) * (r * 0.98)
				canvas.draw_line(p1, p2, col, 3.0)
				canvas.draw_circle(p2, 3.0, Color.WHITE)
				
			for i in range(3):
				var a = (TAU / 3.0) * i + (pulse * 2.0)
				var p1 = center + Vector2(cos(a), sin(a)) * (r * 0.2)
				var p2 = center + Vector2(cos(a + 1.2), sin(a + 1.2)) * (r * 0.55)
				canvas.draw_line(p1, p2, Color(1.0, 0.7, 1.0, 0.8), 2.0)
				
			canvas.draw_circle(center, r * 0.22, Color(0.05, 0.0, 0.1))
			canvas.draw_arc(center, r * 0.22, 0, TAU, 16, Color.WHITE, 1.5)
			canvas.draw_circle(center, r * 0.08, Color.WHITE)
