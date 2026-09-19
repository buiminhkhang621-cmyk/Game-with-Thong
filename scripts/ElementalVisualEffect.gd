extends Node2D
class_name ElementalVisualEffect

static var active_count: int = 0
const MAX_ACTIVE: int = 14

var effect_type: String = "lightning"
var life_time: float = 0.0
var max_life: float = 0.35
var data: Dictionary = {}

func _enter_tree() -> void:
	active_count += 1
	if active_count > MAX_ACTIVE:
		queue_free()

func _exit_tree() -> void:
	active_count = max(0, active_count - 1)

# 1. Base Elemental Setups
func setup_lightning(start_pos: Vector2, target_pos: Vector2, chain_count: int = 1) -> void:
	effect_type = "lightning"
	z_index = 25
	global_position = start_pos
	max_life = 0.18
	var target = target_pos - start_pos
	data["target"] = target
	data["chains"] = chain_count
	
	# Precalculate jagged main bolt
	var pts = PackedVector2Array([Vector2.ZERO])
	var dist = target.length()
	var segs = clamp(int(dist / 22.0), 6, 16)
	var normal = Vector2(-target.y, target.x).normalized()
	for i in range(1, segs):
		var base_p = (target / float(segs)) * i
		var offset = normal * randf_range(-18.0, 18.0)
		pts.append(base_p + offset)
	pts.append(target)
	data["main_pts"] = pts
	
	# Precalculate 2-3 electric fork branches
	var branches = []
	var num_branches = randi_range(2, 3)
	for b in range(num_branches):
		if segs < 3: break
		var fork_idx = randi_range(1, segs - 2)
		var fork_start = pts[fork_idx]
		var branch_pts = PackedVector2Array([fork_start])
		var branch_dir = (target.normalized().rotated(randf_range(-0.7, 0.7)) + normal * randf_range(-0.8, 0.8)).normalized()
		var branch_len = randf_range(dist * 0.25, dist * 0.45)
		var b_segs = randi_range(3, 5)
		for j in range(1, b_segs + 1):
			var step_p = fork_start + branch_dir * (branch_len * (float(j) / b_segs))
			var b_offset = Vector2(-branch_dir.y, branch_dir.x).normalized() * randf_range(-10.0, 10.0)
			branch_pts.append(step_p + b_offset)
		branches.append(branch_pts)
	data["branches"] = branches
	queue_redraw()

func setup_ice_shatter(pos: Vector2, radius: float = 45.0) -> void:
	effect_type = "ice"
	global_position = pos
	max_life = 0.50
	data["radius"] = radius
	queue_redraw()

func setup_dark_siphon(start_pos: Vector2, player_pos: Vector2) -> void:
	effect_type = "dark"
	global_position = start_pos
	max_life = 0.60
	data["player_start"] = player_pos
	data["start_pos"] = start_pos
	queue_redraw()

func setup_elemental_burst(pos: Vector2, element: String) -> void:
	effect_type = "burst"
	global_position = pos
	max_life = 0.40
	data["element"] = element
	queue_redraw()

# 2. Double Reaction Setups
func setup_superconductor(pos: Vector2) -> void:
	effect_type = "superconductor"
	global_position = pos
	max_life = 0.55
	queue_redraw()

func setup_shadow_smite(pos: Vector2) -> void:
	effect_type = "shadow_smite"
	global_position = pos
	max_life = 0.50
	queue_redraw()

func setup_void_discharge(pos: Vector2) -> void:
	effect_type = "void_discharge"
	global_position = pos
	max_life = 0.55
	queue_redraw()

func setup_black_ice_tomb(pos: Vector2) -> void:
	effect_type = "black_ice_tomb"
	global_position = pos
	max_life = 0.60
	queue_redraw()

func setup_absolute_zero(pos: Vector2) -> void:
	effect_type = "absolute_zero"
	global_position = pos
	max_life = 0.60
	queue_redraw()

func setup_abyssal_vortex(pos: Vector2) -> void:
	effect_type = "abyssal_vortex"
	global_position = pos
	max_life = 0.65
	queue_redraw()

# 3. Triple & Quadruple Setups
func setup_triple_tempest(pos: Vector2) -> void:
	effect_type = "triple_tempest"
	global_position = pos
	max_life = 0.75
	queue_redraw()

func setup_genesis_collapse(pos: Vector2) -> void:
	effect_type = "genesis_collapse"
	global_position = pos
	max_life = 1.10
	queue_redraw()

func _process(delta: float) -> void:
	life_time += delta
	if life_time >= max_life:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress = life_time / max_life
	var alpha = (1.0 - progress)
	
	match effect_type:
		# --- BASE ELEMENTS ---
		"lightning":
			var target = data.get("target", Vector2(60, 0))
			var main_pts: PackedVector2Array = data.get("main_pts", PackedVector2Array([Vector2.ZERO, target]))
			var branches: Array = data.get("branches", [])
			
			# 1. Outer Cyan / Electric Aura Glow
			draw_polyline(main_pts, Color(0.15, 0.75, 1.0, alpha * 0.5), 10.0)
			# 2. Mid Vibrant Electric Yellow / Amber
			draw_polyline(main_pts, Color(1.0, 0.95, 0.35, alpha * 0.9), 4.5)
			# 3. Inner Blinding Plasma White Core
			draw_polyline(main_pts, Color(1.0, 1.0, 1.0, alpha), 2.0)
			
			# Draw Branches
			for b_pts in branches:
				if b_pts.size() >= 2:
					draw_polyline(b_pts, Color(0.2, 0.8, 1.0, alpha * 0.4), 6.0)
					draw_polyline(b_pts, Color(1.0, 0.95, 0.4, alpha * 0.8), 2.5)
					draw_polyline(b_pts, Color.WHITE, 1.2)
			
			# Arc flash nodes along vertices
			for p in main_pts:
				draw_circle(p, 3.5 * (1.0 - progress), Color.WHITE)
				
			# Target impact spark and shockwave ring
			var hit_r = 8.0 + progress * 28.0
			draw_arc(target, hit_r, 0, TAU, 20, Color(1.0, 0.9, 0.3, alpha * 0.9), 2.5)
			draw_arc(target, hit_r * 0.6, 0, TAU, 16, Color(0.4, 0.9, 1.0, alpha * 0.6), 2.0)
			draw_circle(target, 7.0 * (1.0 - progress), Color.WHITE)
			
			# Start point spark burst
			draw_circle(Vector2.ZERO, 5.0 * (1.0 - progress), Color(1.0, 1.0, 0.7, alpha))

		"ice":
			var r = data.get("radius", 45.0) * (0.6 + progress * 0.6)
			var col = Color(0.4, 0.85, 1.0, alpha)
			draw_arc(Vector2.ZERO, r, 0, TAU, 24, col, 2.5)
			draw_circle(Vector2.ZERO, r * 0.4, Color(0.5, 0.9, 1.0, alpha * 0.3))
			for i in range(6):
				var a = (TAU / 6.0) * i + progress * 0.5
				var p1 = Vector2(cos(a), sin(a)) * (r * 0.3)
				var p2 = Vector2(cos(a), sin(a)) * r
				draw_line(p1, p2, Color(0.7, 0.95, 1.0, alpha), 2.5)
				draw_circle(p2, 3.5 * (1.0 - progress), Color.WHITE)

		"dark":
			var player = GameManager.player
			var dest = (player.global_position - global_position) if (player and is_instance_valid(player)) else Vector2(0, -60)
			var cur_p = Vector2.ZERO.lerp(dest, progress)
			draw_circle(cur_p, 8.0 * (1.0 - progress * 0.5), Color(0.65, 0.15, 0.85, alpha))
			draw_circle(cur_p, 4.0 * (1.0 - progress * 0.5), Color(1.0, 0.4, 1.0, alpha))
			draw_line(Vector2.ZERO, cur_p, Color(0.5, 0.1, 0.7, alpha * 0.4), 2.5)

		"burst":
			var elem = data.get("element", "void")
			var elem_col = Color(1.0, 0.85, 0.2)
			match elem:
				"ice": elem_col = Color(0.35, 0.85, 1.0)
				"dark": elem_col = Color(0.8, 0.25, 0.95)
				"void": elem_col = Color(0.95, 0.3, 1.0)
			var rad = 65.0 * progress
			draw_arc(Vector2.ZERO, rad, 0, TAU, 24, Color(elem_col.r, elem_col.g, elem_col.b, alpha), 3.0)
			draw_circle(Vector2.ZERO, rad * 0.6, Color(elem_col.r, elem_col.g, elem_col.b, alpha * 0.25))

		# --- DOUBLE REACTIONS ---
		"superconductor": # Sét + Băng (Siêu Dẫn Băng Lôi)
			var r = 120.0 * progress
			# Electric frost ring
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(0.3, 0.95, 1.0, alpha), 3.5)
			draw_arc(Vector2.ZERO, r * 0.85, 0, TAU, 24, Color(1.0, 0.95, 0.4, alpha * 0.8), 2.0)
			for i in range(8):
				var a = (TAU / 8.0) * i + progress * 0.8
				var p1 = Vector2(cos(a), sin(a)) * (r * 0.4)
				var p2 = Vector2(cos(a + 0.2), sin(a + 0.2)) * r
				draw_line(p1, p2, Color(0.6, 1.0, 0.9, alpha), 2.5)

		"shadow_smite": # Sét + Bóng Tối (Lôi Hồn Hắc Ám)
			var smite_h = 300.0 * (1.0 - progress)
			# Vertical lightning bolt from sky
			draw_line(Vector2(0, -smite_h), Vector2(0, 0), Color(0.85, 0.25, 1.0, alpha), 5.0)
			draw_line(Vector2(0, -smite_h), Vector2(0, 0), Color.WHITE, 2.0)
			draw_circle(Vector2.ZERO, 55.0 * progress, Color(0.7, 0.1, 0.9, alpha * 0.4))
			draw_arc(Vector2.ZERO, 70.0 * progress, 0, TAU, 20, Color(0.9, 0.3, 1.0, alpha), 3.0)

		"void_discharge": # Sét + Hư Vô (Xung Hư Vô Quá Tải)
			var r = 110.0 * progress
			draw_circle(Vector2.ZERO, r * 0.5, Color(0.1, 0.0, 0.2, alpha * 0.8))
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(0.95, 0.3, 1.0, alpha), 3.5)
			for i in range(5):
				var a = (TAU / 5.0) * i + progress * 2.0
				var p = Vector2(cos(a), sin(a)) * r
				draw_line(Vector2.ZERO, p, Color(1.0, 0.85, 0.3, alpha), 2.5)

		"black_ice_tomb": # Băng + Bóng Tối (Mộ Băng Hắc Ám)
			var r = 60.0 * (1.0 + progress * 0.3)
			# Obsidian ice coffin crystal
			var oct = PackedVector2Array([
				Vector2(0, -r),
				Vector2(r * 0.6, -r * 0.5),
				Vector2(r * 0.6, r * 0.5),
				Vector2(0, r),
				Vector2(-r * 0.6, r * 0.5),
				Vector2(-r * 0.6, -r * 0.5)
			])
			draw_polygon(oct, PackedColorArray([Color(0.12, 0.18, 0.32, alpha * 0.85)]))
			draw_polyline(oct, Color(0.5, 0.85, 1.0, alpha), 2.5)
			# 8 shattering dark ice shards
			for i in range(8):
				var a = (TAU / 8.0) * i
				var sp = Vector2(cos(a), sin(a)) * (r * 1.5 * progress)
				draw_circle(sp, 3.5 * (1.0 - progress), Color(0.7, 0.3, 0.9, alpha))

		"absolute_zero": # Băng + Hư Vô (Điểm Không Tuyệt Đối)
			var r = 130.0 * progress
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(0.4, 0.9, 1.0, alpha), 3.0)
			draw_circle(Vector2.ZERO, 35.0 * (1.0 - progress), Color(0.05, 0.0, 0.1, alpha))
			# Spatial fracture lines
			for i in range(6):
				var a = (TAU / 6.0) * i
				var p1 = Vector2(cos(a), sin(a)) * (r * 0.2)
				var p2 = Vector2(cos(a), sin(a)) * r
				draw_line(p1, p2, Color.WHITE, 2.0)

		"abyssal_vortex": # Bóng Tối + Hư Vô (Hố Đen Vực Thẳm)
			var r = 140.0 * progress
			draw_circle(Vector2.ZERO, r * 0.7, Color(0.08, 0.0, 0.15, alpha * 0.85))
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(0.85, 0.2, 0.95, alpha), 3.5)
			for i in range(4):
				var a = (TAU / 4.0) * i + progress * 3.0
				var p1 = Vector2(cos(a), sin(a)) * (r * 0.2)
				var p2 = Vector2(cos(a + 1.2), sin(a + 1.2)) * (r * 0.9)
				draw_line(p1, p2, Color(1.0, 0.4, 1.0, alpha), 2.5)

		# --- TRIPLE & QUADRUPLE REACTIONS ---
		"triple_tempest": # Tam Trùng Nguyên Tố (Bão Tố Tam Giác Nguyên Tố)
			var r = 180.0 * progress
			# Expanding elemental triad rings
			draw_arc(Vector2.ZERO, r, 0, TAU, 36, Color(1.0, 0.85, 0.3, alpha), 3.0) # Sét
			draw_arc(Vector2.ZERO, r * 0.8, 0, TAU, 32, Color(0.35, 0.85, 1.0, alpha), 3.0) # Băng
			draw_arc(Vector2.ZERO, r * 0.6, 0, TAU, 28, Color(0.85, 0.25, 0.95, alpha), 3.0) # Tối
			# Tri-force elemental star rays
			for i in range(3):
				var a = (TAU / 3.0) * i + progress * 2.0
				var p = Vector2(cos(a), sin(a)) * r
				draw_line(Vector2.ZERO, p, Color.WHITE, 3.5)
				draw_circle(p, 6.0 * (1.0 - progress), Color.WHITE)

		"genesis_collapse": # Tứ Trùng Nguyên Tố (ĐẠI HỦY DIỆT SƠ KHAI)
			var r = 260.0 * progress
			draw_circle(Vector2.ZERO, r * 0.8, Color(1.0, 1.0, 1.0, alpha * 0.4))
			draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(1.0, 0.85, 0.3, alpha), 5.0)
			draw_arc(Vector2.ZERO, r * 0.85, 0, TAU, 40, Color(0.9, 0.3, 1.0, alpha), 4.0)
			draw_arc(Vector2.ZERO, r * 0.7, 0, TAU, 36, Color(0.35, 0.95, 1.0, alpha), 4.0)
			for i in range(8):
				var a = (TAU / 8.0) * i + progress * 4.0
				var p1 = Vector2(cos(a), sin(a)) * (r * 0.3)
				var p2 = Vector2(cos(a + 0.8), sin(a + 0.8)) * r
				draw_line(p1, p2, Color.WHITE, 4.0)
