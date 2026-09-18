extends CanvasLayer

enum Tab { ACTIVE, PASSIVE, RELIC, CURSE }
var current_tab: Tab = Tab.ACTIVE
var current_item_id: String = ""

var curses_info = {
	"mong_manh": {
		"name": "Fragile",
		"desc": "+25% Damage taken.\n+5% Relic drop rate.",
		"color": Color(0.9, 0.3, 0.3)
	}
}

var relics_info = {
	"greed_ring": {
		"name": "Greed Ring",
		"desc": "A ring found in a cursed hoard. It grants great insight from death, but saps the bearer's life force.\n\nThe path of knowledge demands sacrifice.",
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

var list_vbox: VBoxContainer
var info_title: Label
var info_stats: Label
var info_desc: Label
var draw_node: Control
var action_btn: Button

func _ready() -> void:
	layer = 101
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.04, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
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
	particles.color = Color(0.6, 0.6, 0.8, 0.2)
	particles.lifetime = 15.0
	add_child(particles)
	
	var title = Label.new()
	title.text = "THE CODEX"
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
	hbox.custom_minimum_size = Vector2(1000, 480)
	hbox.position = Vector2(76, 80)
	hbox.add_theme_constant_override("separation", 20)
	add_child(hbox)
	
	# --- Left Panel: Tabs ---
	var tabs_vbox = VBoxContainer.new()
	tabs_vbox.custom_minimum_size = Vector2(200, 480)
	tabs_vbox.add_theme_constant_override("separation", 15)
	hbox.add_child(tabs_vbox)
	
	_add_tab_btn(tabs_vbox, "ACTIVE SKILLS", Tab.ACTIVE)
	_add_tab_btn(tabs_vbox, "PASSIVE SKILLS", Tab.PASSIVE)
	_add_tab_btn(tabs_vbox, "RELICS & SEALS", Tab.RELIC)
	_add_tab_btn(tabs_vbox, "CURSES", Tab.CURSE)
	
	var space_tabs = Control.new()
	space_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs_vbox.add_child(space_tabs)
	
	var back_btn = Button.new()
	back_btn.text = "RETURN"
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.add_theme_font_size_override("font_size", 18)
	UITheme.apply_button_theme(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	tabs_vbox.add_child(back_btn)
	
	# --- Mid-Left Panel: Item List ---
	var list_panel = PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(250, 480)
	list_panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	hbox.add_child(list_panel)
	
	var scroll = ScrollContainer.new()
	var scroll_margin = MarginContainer.new()
	scroll_margin.add_theme_constant_override("margin_left", 10)
	scroll_margin.add_theme_constant_override("margin_right", 10)
	scroll_margin.add_theme_constant_override("margin_top", 10)
	scroll_margin.add_theme_constant_override("margin_bottom", 10)
	list_panel.add_child(scroll_margin)
	
	scroll_margin.add_child(scroll)
	
	list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(list_vbox)
	
	# --- Mid-Right Panel: Graphic / Animation ---
	var center_panel = Control.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.custom_minimum_size = Vector2(250, 480)
	hbox.add_child(center_panel)
	
	draw_node = Control.new()
	draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_node.draw.connect(_on_draw_node_draw)
	center_panel.add_child(draw_node)
	
	# --- Right Panel: Info ---
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(260, 480)
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
	info_title.add_theme_font_size_override("font_size", 22)
	info_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	right_vbox.add_child(info_title)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.3, 0.3, 0.35)
	right_vbox.add_child(divider)
	
	info_stats = Label.new()
	info_stats.add_theme_font_size_override("font_size", 16)
	right_vbox.add_child(info_stats)
	
	info_desc = Label.new()
	info_desc.add_theme_font_size_override("font_size", 14)
	info_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_vbox.add_child(info_desc)
	
	var space_info = Control.new()
	space_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(space_info)
	
	action_btn = Button.new()
	action_btn.custom_minimum_size = Vector2(0, 50)
	action_btn.add_theme_font_size_override("font_size", 18)
	UITheme.apply_button_theme(action_btn)
	action_btn.pressed.connect(_on_action_pressed)
	right_vbox.add_child(action_btn)
	
	_populate_list()

func _add_tab_btn(parent: Control, text: String, tab: Tab) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 55)
	btn.add_theme_font_size_override("font_size", 18)
	UITheme.apply_button_theme(btn)
	
	btn.pressed.connect(func():
		current_tab = tab
		current_item_id = ""
		_populate_list()
	)
	parent.add_child(btn)

func _populate_list() -> void:
	for c in list_vbox.get_children():
		c.queue_free()
	
	var items = []
	match current_tab:
		Tab.ACTIVE:
			for data in GameManager.available_active_skills:
				items.append({"id": data.id, "name": data.display_name, "data": data})
			var extra_skills = ["res://resources/skills/throwing_knife.tres", "res://resources/skills/throwing_axe.tres", "res://resources/skills/elemental_orbs.tres", "res://resources/skills/whip.tres", "res://resources/skills/chain_lightning.tres"]
			for path in extra_skills:
				var data = load(path)
				if data and not _contains_id(items, data.id):
					items.append({"id": data.id, "name": data.display_name, "data": data})
		Tab.PASSIVE:
			for data in GameManager.available_passive_skills:
				items.append({"id": data.id, "name": data.display_name, "data": data})
		Tab.RELIC:
			for id in relics_info.keys():
				items.append({"id": id, "name": relics_info[id]["name"], "data": relics_info[id]})
		Tab.CURSE:
			for id in curses_info.keys():
				items.append({"id": id, "name": curses_info[id]["name"], "data": curses_info[id]})
	
	for item in items:
		var btn = Button.new()
		btn.text = item["name"]
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_size_override("font_size", 16)
		UITheme.apply_button_theme(btn)
		
		btn.pressed.connect(func():
			current_item_id = item["id"]
			_update_info()
		)
		list_vbox.add_child(btn)
	
	if items.size() > 0:
		current_item_id = items[0]["id"]
	else:
		current_item_id = ""
		
	_update_info()

func _contains_id(arr: Array, id: String) -> bool:
	for item in arr:
		if item["id"] == id:
			return true
	return false

func _update_info() -> void:
	draw_node.queue_redraw()
	
	if current_item_id == "":
		info_title.text = ""
		info_stats.text = ""
		info_desc.text = ""
		action_btn.hide()
		return
		
	action_btn.hide()
	info_stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	match current_tab:
		Tab.ACTIVE:
			var data = _get_active_data(current_item_id)
			if data:
				info_title.text = data.display_name
				info_stats.text = "Type: " + data.skill_type.capitalize() + "\nMax Lvl: " + str(data.max_level)
				info_desc.text = "Base Dmg: " + str(data.base_damage) + "\nGrowth: +" + str(data.damage_per_level) + "/lvl"
				info_stats.add_theme_color_override("font_color", data.color)
		Tab.PASSIVE:
			var data = _get_passive_data(current_item_id)
			if data:
				info_title.text = data.display_name
				info_stats.text = "Max Lvl: " + str(data.max_level)
				info_desc.text = "Stat: " + data.stat.capitalize() + "\nGrowth: +" + str(data.value_per_level) + "/lvl"
				info_stats.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
		Tab.RELIC:
			var info = relics_info[current_item_id]
			info_title.text = info["name"]
			info_stats.text = info["stats"]
			info_stats.add_theme_color_override("font_color", info["color"])
			info_desc.text = info["desc"]
		Tab.CURSE:
			var info = curses_info[current_item_id]
			info_title.text = info["name"]
			info_stats.text = "Effect:"
			info_stats.add_theme_color_override("font_color", info["color"])
			info_desc.text = info["desc"]
			
			action_btn.show()
			if GameManager.active_curses.has(current_item_id):
				action_btn.text = "DEACTIVATE"
				action_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			else:
				action_btn.text = "ACTIVATE"
				action_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

func _get_active_data(id: String) -> Resource:
	for d in GameManager.available_active_skills:
		if d.id == id: return d
	var extra_skills = ["res://resources/skills/throwing_knife.tres", "res://resources/skills/throwing_axe.tres", "res://resources/skills/elemental_orbs.tres", "res://resources/skills/whip.tres"]
	for p in extra_skills:
		var d = load(p)
		if d and d.id == id: return d
	return null

func _get_passive_data(id: String) -> Resource:
	for d in GameManager.available_passive_skills:
		if d.id == id: return d
	return null

func _on_action_pressed() -> void:
	if current_tab == Tab.CURSE and current_item_id != "":
		if GameManager.active_curses.has(current_item_id):
			GameManager.active_curses.erase(current_item_id)
		else:
			GameManager.active_curses.append(current_item_id)
		_update_info() # refresh button text

func _on_back_pressed() -> void:
	var main = get_tree().current_scene
	var script = load("res://scripts/MainMenuUI.gd")
	if script:
		var main_menu = script.new()
		get_tree().root.add_child(main_menu)
		if main and "current_ui" in main:
			main.current_ui = main_menu
		queue_free()

func _on_draw_node_draw() -> void:
	var center = Vector2(125, 240)
	
	if current_item_id == "": return
	
	if current_tab == Tab.RELIC:
		# Draw Ancient Circular Grid
		draw_node.draw_circle(center, 100, Color(0.1, 0.1, 0.12))
		draw_node.draw_arc(center, 100, 0, TAU, 64, Color(0.3, 0.3, 0.35), 4.0)
		draw_node.draw_arc(center, 90, 0, TAU, 64, Color(0.2, 0.2, 0.25), 2.0)
		draw_node.draw_arc(center, 50, 0, TAU, 32, Color(0.25, 0.25, 0.3), 2.0)
		
		# Draw connecting lines for the grid
		for i in range(8):
			var ang = TAU / 8.0 * i
			var p1 = center + Vector2(cos(ang), sin(ang)) * 50
			var p2 = center + Vector2(cos(ang), sin(ang)) * 100
			draw_node.draw_line(p1, p2, Color(0.25, 0.25, 0.3), 2.0)
			
			var p3 = center + Vector2(cos(ang), sin(ang)) * 75
			draw_node.draw_circle(p3, 8, Color(0.05, 0.05, 0.07))
			draw_node.draw_arc(p3, 8, 0, TAU, 16, Color(0.4, 0.4, 0.45), 2.0)
		
		var info = relics_info[current_item_id]
		var c = info["color"]
		draw_node.draw_circle(center, 40, Color(c.r, c.g, c.b, 0.25))
		
		match current_item_id:
			"greed_ring":
				draw_node.draw_arc(center, 30, 0, TAU, 32, Color(0.8, 0.8, 0.3), 6.0)
				draw_node.draw_circle(center + Vector2(0, -30), 8, Color(0.2, 0.8, 0.2))
			"ancient_censer":
				draw_node.draw_rect(Rect2(center.x - 15, center.y - 10, 30, 20), Color(0.6, 0.5, 0.2), true)
				draw_node.draw_circle(center + Vector2(0, -10), 15, Color(0.7, 0.6, 0.3))
			"broken_mirror":
				var pts = PackedVector2Array([
					center + Vector2(-15, -30), center + Vector2(25, -20),
					center + Vector2(30, 15), center + Vector2(0, 40), center + Vector2(-25, 10)
				])
				draw_node.draw_polygon(pts, PackedColorArray([Color(0.6, 0.8, 1.0, 0.8)]))
				draw_node.draw_polyline(pts, Color(0.3, 0.5, 0.8), 3.0)
				
	elif current_tab == Tab.CURSE:
		var c = curses_info[current_item_id]["color"]
		draw_node.draw_circle(center, 70, Color(c.r, c.g, c.b, 0.15))
		
		# Draw a skull or cursed mark
		draw_node.draw_circle(center + Vector2(0, -10), 30, Color(0.8, 0.2, 0.2)) # Skull head
		draw_node.draw_rect(Rect2(center.x - 15, center.y + 10, 30, 20), Color(0.8, 0.2, 0.2)) # Skull jaw
		draw_node.draw_circle(center + Vector2(-12, -15), 8, Color.BLACK) # Left eye
		draw_node.draw_circle(center + Vector2(12, -15), 8, Color.BLACK) # Right eye
		
	elif current_tab == Tab.ACTIVE:
		var data = _get_active_data(current_item_id)
		var c = data.color if data else Color(0.7, 0.7, 0.7)
		draw_node.draw_circle(center, 70, Color(c.r, c.g, c.b, 0.2))
		
		# Draw a generic magic orb for Active Skill
		draw_node.draw_circle(center, 30, c)
		draw_node.draw_circle(center + Vector2(-10, -10), 10, Color(1, 1, 1, 0.8))
		draw_node.draw_arc(center, 45, 0, TAU, 32, c, 3.0)
		draw_node.draw_arc(center, 55, PI/4, 3*PI/4, 16, c, 2.0)
		draw_node.draw_arc(center, 55, 5*PI/4, 7*PI/4, 16, c, 2.0)
		
	elif current_tab == Tab.PASSIVE:
		draw_node.draw_circle(center, 70, Color(0.2, 0.6, 0.2, 0.15))
		# Draw a generic stat icon (e.g. an arrow up)
		var pts = PackedVector2Array([
			center + Vector2(0, -40),
			center + Vector2(30, 10),
			center + Vector2(15, 10),
			center + Vector2(15, 40),
			center + Vector2(-15, 40),
			center + Vector2(-15, 10),
			center + Vector2(-30, 10)
		])
		draw_node.draw_polygon(pts, PackedColorArray([Color(0.3, 0.8, 0.3)]))
		draw_node.draw_polyline(pts, Color(0.1, 0.4, 0.1), 3.0)
