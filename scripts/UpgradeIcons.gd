class_name UpgradeIcons
extends RefCounted

# Draw procedural vector icon silhouettes for all skills, passives, and elements
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
			
		"orbit_blade", "blade":
			# Curved Spinning Chakram / Tri-Blade
			for i in range(3):
				var a = (TAU / 3.0) * i
				var p1 = center + Vector2(cos(a), sin(a)) * s * 0.3
				var p2 = center + Vector2(cos(a + 0.8), sin(a + 0.8)) * s
				var p3 = center + Vector2(cos(a + 0.4), sin(a + 0.4)) * (s * 0.6)
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
			# Aegis Tower Shield
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
			canvas.draw_line(center + Vector2(-s * 0.35, -s * 0.1), center + Vector2(s * 0.35, -s * 0.1), Color.WHITE, 2.0)

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
			canvas.draw_line(center + Vector2(-s * 0.6, s * 0.7), center + Vector2(-s * 0.2, s * 0.2), color, 3.0)
			canvas.draw_line(center + Vector2(s * 0.6, s * 0.7), center + Vector2(s * 0.2, s * 0.2), color, 3.0)

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
			canvas.draw_rect(Rect2(center.x - s * 0.7, center.y + s * 0.35, s * 0.35, s * 0.25), Color.WHITE)
			canvas.draw_rect(Rect2(center.x + s * 0.35, center.y + s * 0.35, s * 0.35, s * 0.25), Color.WHITE)

		"armor":
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

		# --- RUNES / ELEMENTS (MYTHOLOGICAL GLYPHS) ---
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
# 1. Lightning: Nordic Elder Futhark (Sowilo / Sigel & Thurisaz)
# 2. Ice: Archaic Oriental Seal / 冰 Hieroglyphic Glacial Seal
# 3. Dark: Egyptian Netherworld / Eye of Horus & Ankh of Osiris
# 4. Void: Cosmic Singularity / Eldritch Primordial Ouroboros Seal
# -------------------------------------------------------------
static func draw_mythic_rune_glyph(canvas: CanvasItem, rune_type: String, center: Vector2, radius: float, base_color: Color, pulse: float = 1.0) -> void:
	var r = radius
	
	match rune_type:
		"lightning":
			# --- 1. NORDIC ELDER FUTHARK THUNDER RUNE (SOWILO & THURISAZ) ---
			var col = Color(1.0, 0.88, 0.25)
			# Outer Nordic Runic Ring with 8 Cardinal Runes
			canvas.draw_arc(center, r * 0.95, 0, TAU, 32, Color(col.r, col.g, col.b, 0.4 * pulse), 1.5)
			canvas.draw_arc(center, r * 0.82, 0, TAU, 32, Color(col.r, col.g, col.b, 0.6 * pulse), 1.0)
			for i in range(8):
				var a = (TAU / 8.0) * i
				var p_out = center + Vector2(cos(a), sin(a)) * (r * 0.95)
				var p_in = center + Vector2(cos(a), sin(a)) * (r * 0.82)
				canvas.draw_line(p_in, p_out, col, 1.5)
				
			# Central Sowilo Jagged Lightning Sigil
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
			
			# Flanking Thurisaz Thorns
			canvas.draw_line(center + Vector2(-r * 0.55, -r * 0.4), center + Vector2(-r * 0.55, r * 0.4), col, 2.0)
			canvas.draw_line(center + Vector2(-r * 0.55, -r * 0.1), center + Vector2(-r * 0.35, 0), col, 2.0)
			canvas.draw_line(center + Vector2(-r * 0.35, 0), center + Vector2(-r * 0.55, r * 0.1), col, 2.0)

		"ice":
			# --- 2. ARCHAIC ORIENTAL SEAL / 冰 HIEROGLYPHIC GLACIAL SEAL ---
			var col = Color(0.35, 0.85, 1.0)
			# Diamond Runic Frame
			var diamond = PackedVector2Array([
				center + Vector2(0, -r * 0.95),
				center + Vector2(r * 0.95, 0),
				center + Vector2(0, r * 0.95),
				center + Vector2(-r * 0.95, 0),
				center + Vector2(0, -r * 0.95)
			])
			canvas.draw_polyline(diamond, Color(col.r, col.g, col.b, 0.5 * pulse), 1.5)
			
			# 4 Corner Glacial Needles
			for i in range(4):
				var a = (TAU / 4.0) * i + PI * 0.25
				var p1 = center + Vector2(cos(a), sin(a)) * (r * 0.4)
				var p2 = center + Vector2(cos(a), sin(a)) * (r * 0.85)
				canvas.draw_line(p1, p2, col, 2.0)
				canvas.draw_circle(p2, 2.5, Color.WHITE)
				
			# Archaic 'Bing' (冰) Crystalline Brush Sigil
			# Left twin frost dots (Two upward sweeping ice hooks)
			canvas.draw_line(center + Vector2(-r * 0.5, -r * 0.4), center + Vector2(-r * 0.25, -r * 0.2), col, 3.0)
			canvas.draw_line(center + Vector2(-r * 0.55, r * 0.35), center + Vector2(-r * 0.2, r * 0.05), col, 3.0)
			
			# Right Water/Spire Radical (Vertical hook + sweeping strokes)
			canvas.draw_line(center + Vector2(r * 0.15, -r * 0.65), center + Vector2(r * 0.15, r * 0.65), col, 3.5)
			canvas.draw_line(center + Vector2(r * 0.15, r * 0.65), center + Vector2(0, r * 0.45), col, 2.5)
			canvas.draw_line(center + Vector2(r * 0.15, -r * 0.15), center + Vector2(-r * 0.1, -r * 0.35), col, 2.5)
			canvas.draw_line(center + Vector2(r * 0.15, 0), center + Vector2(r * 0.55, r * 0.45), col, 3.0)
			canvas.draw_circle(center + Vector2(r * 0.15, 0), 3.0, Color.WHITE)

		"dark":
			# --- 3. EGYPTIAN NETHERWORLD / EYE OF HORUS & ANKH OF OSIRIS ---
			var col = Color(0.75, 0.25, 0.95)
			# Top Sacred Ankh Loop
			canvas.draw_arc(center + Vector2(0, -r * 0.5), r * 0.28, 0, TAU, 24, col, 2.5)
			canvas.draw_line(center + Vector2(-r * 0.6, -r * 0.22), center + Vector2(r * 0.6, -r * 0.22), col, 3.0)
			
			# Central Eye of Horus (Wedjat)
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
			
			# Falcon Spiral Tear Mark of Horus
			canvas.draw_line(center + Vector2(0, r * 0.18), center + Vector2(0, r * 0.75), col, 2.5)
			canvas.draw_line(center + Vector2(r * 0.2, r * 0.18), center + Vector2(r * 0.35, r * 0.5), col, 2.0)
			canvas.draw_arc(center + Vector2(r * 0.25, r * 0.5), r * 0.12, 0, PI, 12, col, 2.0)

		"void":
			# --- 4. COSMIC SINGULARITY / PRIMORDIAL ELDRITCH VOID SEAL ---
			var col = Color(0.95, 0.3, 1.0)
			# Concentric Event Horizon Distortion Rings
			canvas.draw_arc(center, r * 0.9, 0, TAU, 32, Color(col.r, col.g, col.b, 0.4 * pulse), 1.5)
			canvas.draw_arc(center, r * 0.65, 0, TAU, 32, col, 2.0)
			
			# 4 Dimensional Fracture Spikes
			for i in range(4):
				var a = (TAU / 4.0) * i
				var p1 = center + Vector2(cos(a), sin(a)) * (r * 0.5)
				var p2 = center + Vector2(cos(a), sin(a)) * (r * 0.98)
				canvas.draw_line(p1, p2, col, 3.0)
				canvas.draw_circle(p2, 3.0, Color.WHITE)
				
			# Swirling Accretion Spiral Arms
			for i in range(3):
				var a = (TAU / 3.0) * i + (pulse * 2.0)
				var p1 = center + Vector2(cos(a), sin(a)) * (r * 0.2)
				var p2 = center + Vector2(cos(a + 1.2), sin(a + 1.2)) * (r * 0.55)
				canvas.draw_line(p1, p2, Color(1.0, 0.7, 1.0, 0.8), 2.0)
				
			# Central Abyss Black Hole Pupil
			canvas.draw_circle(center, r * 0.22, Color(0.05, 0.0, 0.1))
			canvas.draw_arc(center, r * 0.22, 0, TAU, 16, Color.WHITE, 1.5)
			canvas.draw_circle(center, r * 0.08, Color.WHITE)
