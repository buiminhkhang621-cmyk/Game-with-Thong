extends CanvasLayer

var relics_info = {
	"greed_ring": {
		"name": "Greed Ring",
		"desc": "A ring found in a cursed hoard. It grants great insight from death, but saps the bearer's life force. Its glint promises power and ruin.\n\nThe path of knowledge demands sacrifice.",
		"stats": "+30% EXP GAINED\n-10% MAX HP",
		"color": Color(0.2, 0.8, 0.2)
	},
	"ancient_censer": {
		"name": "Ancient Censer",
		"desc": "An old censer that still emits a faint, sweet-smelling smoke. It calms the mind and body.",
		"stats": "+10% Healing Received\n+5% Move Speed",
		"color": Color(0.8, 0.6, 0.2)
	},
	"broken_mirror": {
		"name": "Broken Mirror",
		"desc": "A shattered piece of a magical mirror. It occasionally reflects attacks back at the sender.",
		"stats": "+5% Dodge Chance\n+10% Damage Reflection",
		"color": Color(0.4, 0.6, 0.9)
	}
}

var current_relic: String = "greed_ring"
var info_title: Label
var info_stats: Label
var info_desc: Label
var draw_node: Control

func _ready() -> void:
	layer = 101
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.04, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Particles (Magic Dust)
	var particles = CPUParticles2D.new()
	particles.position = Vector2(600, 700)
	particles.amount = 60
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(800, 1)
	particles.direction = Vector2(0, -1)
	particles.spread = 20.0
	particles.gravity = Vector2(0, -8)
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 25.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 3.0
	particles.color = Color(0.6, 0.8, 1.0, 0.2)
	particles.lifetime = 15.0
	add_child(particles)
	
	var title = Label.new()
	title.text = "SPELL-WEAVING WORKSHOP"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.grow_horizontal = Control.GROW_DIRECTION_END
	title.grow_vertical = Control.GROW_DIRECTION_END
	title.position.y = 30
	add_child(title)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_CENTER)
	hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	hbox.custom_minimum_size = Vector2(1000, 450)
	hbox.position = Vector2(76, 100)
	hbox.add_theme_constant_override("separation", 20)
	add_child(hbox)
	
	# --- Left Panel: Relics List ---
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(300, 450)
	left_panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	hbox.add_child(left_panel)
	
	var left_scroll = ScrollContainer.new()
	var scroll_margin = MarginContainer.new()
	scroll_margin.add_theme_constant_override("margin_left", 15)
	scroll_margin.add_theme_constant_override("margin_right", 15)
	scroll_margin.add_theme_constant_override("margin_top", 15)
	scroll_margin.add_theme_constant_override("margin_bottom", 15)
	left_panel.add_child(scroll_margin)
	
	scroll_margin.add_child(left_scroll)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 10)
	left_scroll.add_child(left_vbox)
	
	_add_relic_btn(left_vbox, "Greed Ring", "greed_ring")
	_add_relic_btn(left_vbox, "Ancient Censer", "ancient_censer")
	_add_relic_btn(left_vbox, "Broken Mirror", "broken_mirror")
	
	# --- Center Panel: Graphic (Ancient Seal Grid) ---
	var center_panel = Control.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.custom_minimum_size = Vector2(350, 450)
	hbox.add_child(center_panel)
	
	draw_node = Control.new()
	draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_node.draw.connect(_on_draw_node_draw)
	center_panel.add_child(draw_node)
	
	# --- Right Panel: Info ---
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(320, 450)
	right_panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	hbox.add_child(right_panel)
	
	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 20)
	right_margin.add_theme_constant_override("margin_right", 20)
	right_margin.add_theme_constant_override("margin_top", 20)
	right_margin.add_theme_constant_override("margin_bottom", 20)
	right_panel.add_child(right_margin)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 15)
	right_margin.add_child(right_vbox)
	
	info_title = Label.new()
	info_title.add_theme_font_size_override("font_size", 24)
	info_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	right_vbox.add_child(info_title)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.3, 0.3, 0.35)
	right_vbox.add_child(divider)
	
	info_stats = Label.new()
	info_stats.add_theme_font_size_override("font_size", 18)
	right_vbox.add_child(info_stats)
	
	info_desc = Label.new()
	info_desc.add_theme_font_size_override("font_size", 15)
	info_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_vbox.add_child(info_desc)
	
	var space = Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(space)
	
	var back_btn = Button.new()
	back_btn.text = "RETURN"
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.add_theme_font_size_override("font_size", 18)
	UITheme.apply_button_theme(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	right_vbox.add_child(back_btn)
	
	_update_info()

func _add_relic_btn(parent: Control, text: String, id: String) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 55)
	btn.add_theme_font_size_override("font_size", 18)
	UITheme.apply_button_theme(btn)
	
	btn.pressed.connect(func():
		current_relic = id
		_update_info()
		draw_node.queue_redraw()
	)
	parent.add_child(btn)

func _update_info() -> void:
	var info = relics_info[current_relic]
	info_title.text = info["name"]
	info_stats.text = info["stats"]
	info_stats.add_theme_color_override("font_color", info["color"])
	info_desc.text = info["desc"]

func _on_back_pressed() -> void:
	var script = load("res://scripts/MainMenuUI.gd")
	if script:
		var main_menu = script.new()
		get_tree().root.add_child(main_menu)
		queue_free()

func _on_draw_node_draw() -> void:
	var center = Vector2(175, 225)
	
	# Draw Ancient Circular Grid
	draw_node.draw_circle(center, 140, Color(0.1, 0.1, 0.12))
	draw_node.draw_arc(center, 140, 0, TAU, 64, Color(0.3, 0.3, 0.35), 4.0)
	draw_node.draw_arc(center, 130, 0, TAU, 64, Color(0.2, 0.2, 0.25), 2.0)
	draw_node.draw_arc(center, 80, 0, TAU, 32, Color(0.25, 0.25, 0.3), 2.0)
	
	# Draw connecting lines for the grid
	for i in range(8):
		var ang = TAU / 8.0 * i
		var p1 = center + Vector2(cos(ang), sin(ang)) * 80
		var p2 = center + Vector2(cos(ang), sin(ang)) * 140
		draw_node.draw_line(p1, p2, Color(0.25, 0.25, 0.3), 2.0)
		
		# Draw empty slots
		var p3 = center + Vector2(cos(ang), sin(ang)) * 110
		draw_node.draw_circle(p3, 12, Color(0.05, 0.05, 0.07))
		draw_node.draw_arc(p3, 12, 0, TAU, 16, Color(0.4, 0.4, 0.45), 2.0)
	
	var info = relics_info[current_relic]
	var c = info["color"]
	
	# Center glow
	draw_node.draw_circle(center, 60, Color(c.r, c.g, c.b, 0.25))
	
	# Draw the actual active relic in the center
	match current_relic:
		"greed_ring":
			draw_node.draw_arc(center, 40, 0, TAU, 32, Color(0.8, 0.8, 0.3), 10.0)
			draw_node.draw_circle(center + Vector2(0, -40), 12, Color(0.2, 0.8, 0.2))
		"ancient_censer":
			draw_node.draw_rect(Rect2(center.x - 20, center.y - 10, 40, 30), Color(0.6, 0.5, 0.2), true)
			draw_node.draw_circle(center + Vector2(0, -10), 20, Color(0.7, 0.6, 0.3))
			draw_node.draw_line(center + Vector2(-15, -40), center + Vector2(-5, -10), Color(0.7, 0.7, 0.7, 0.5), 3)
			draw_node.draw_line(center + Vector2(15, -50), center + Vector2(5, -10), Color(0.7, 0.7, 0.7, 0.5), 3)
		"broken_mirror":
			var pts = PackedVector2Array([
				center + Vector2(-20, -40),
				center + Vector2(30, -30),
				center + Vector2(40, 20),
				center + Vector2(0, 50),
				center + Vector2(-30, 10)
			])
			draw_node.draw_polygon(pts, PackedColorArray([Color(0.6, 0.8, 1.0, 0.8)]))
			draw_node.draw_polyline(pts, Color(0.3, 0.5, 0.8), 4.0)
			draw_node.draw_line(center + Vector2(-10, -20), center + Vector2(10, 10), Color(0.2, 0.3, 0.6), 2)
