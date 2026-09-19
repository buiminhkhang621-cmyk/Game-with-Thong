extends CanvasLayer

var selected_class: String = ""

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.06, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	
	# Atmospheric background particles
	var p = CPUParticles2D.new()
	p.position = Vector2(640, 720)
	p.amount = 45
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700, 5)
	p.direction = Vector2(0, -1)
	p.spread = 20.0
	p.gravity = Vector2(0, -10)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 45.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.4, 0.6, 0.7, 0.35)
	p.lifetime = 8.0
	root.add_child(p)
	
	var title = Label.new()
	title.text = "✦ SELECT REALM ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.5))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 35
	root.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Map order: 1. Ruin ➔ 2. Forest ➔ 3. Village. Survive 10 minutes or slay the Boss to unlock the next realm!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.position.y = 75
	root.add_child(subtitle)
	
	var back_btn = Button.new()
	back_btn.text = "⮌ BACK"
	back_btn.custom_minimum_size = Vector2(150, 48)
	UITheme.apply_button_theme(back_btn)
	back_btn.position = Vector2(40, 36)
	back_btn.pressed.connect(_on_back_pressed)
	root.add_child(back_btn)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center_container)
	
	var hbox = HBoxContainer.new()
	center_container.add_child(hbox)
	hbox.add_theme_constant_override("separation", 35)
	
	var is_map1_unlocked = true
	var is_map2_unlocked = GameManager.unlocked_map_tiers.has(2)
	var is_map3_unlocked = GameManager.unlocked_map_tiers.has(3)
	
	_add_map_card(
		hbox,
		"1. RUIN",
		"ANCIENT RUIN",
		"✦ Ancient stone crypts, blood-stained pillars and thousand-year tombs.\n✦ Bottomless chasms and blazing fire altars.\n\n[UNLOCKED BY DEFAULT]",
		1,
		Color(0.75, 0.55, 0.35),
		is_map1_unlocked,
		""
	)
	
	_add_map_card(
		hbox,
		"2. FOREST",
		"DARK FOREST",
		"✦ Ancient towering trees, gnarled roots and bioluminescent mushroom groves.\n✦ Mystical marshlands, ferocious monster storms.\n\n[UNLOCKED]" if is_map2_unlocked else "🔒 LOCKED\n\nUnlock Condition:\nSurvive 10:00 or defeat the Boss in Map 1 (Ruin)!",
		2,
		Color(0.3, 0.75, 0.45) if is_map2_unlocked else Color(0.3, 0.35, 0.3),
		is_map2_unlocked,
		"Survive 10:00 or defeat Boss in Map 1 (Ruin)"
	)
	
	_add_map_card(
		hbox,
		"3. VILLAGE",
		"ABANDONED VILLAGE",
		"✦ Crumbling stone roads, collapsed wooden huts, ancient wells and thorn fences.\n✦ The ultimate nightmare of the dark legion.\n\n[UNLOCKED]" if is_map3_unlocked else "🔒 LOCKED\n\nUnlock Condition:\nSurvive 10:00 or defeat the Boss in Map 2 (Forest)!",
		3,
		Color(0.85, 0.45, 0.35) if is_map3_unlocked else Color(0.35, 0.28, 0.28),
		is_map3_unlocked,
		"Survive 10:00 or defeat Boss in Map 2 (Forest)"
	)

func _add_map_card(parent: Control, title_str: String, subtitle_str: String, desc: String, tier: int, c: Color, is_unlocked: bool, lock_hint: String) -> void:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(280, 420)
	panel.add_theme_stylebox_override("panel", UITheme.create_stone_card(c if is_unlocked else Color(0.2, 0.22, 0.25)))
	parent.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(top_spacer)
	
	# Status Badge
	var badge = Label.new()
	badge.text = "✦ UNLOCKED ✦" if is_unlocked else "🔒 LOCKED"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5) if is_unlocked else Color(0.9, 0.4, 0.4))
	badge.add_theme_color_override("font_outline_color", Color.BLACK)
	badge.add_theme_constant_override("outline_size", 3)
	vbox.add_child(badge)
	
	var l_title = Label.new()
	l_title.text = title_str
	l_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_title.add_theme_font_size_override("font_size", 22)
	l_title.add_theme_color_override("font_color", c.lerp(Color.WHITE, 0.6) if is_unlocked else Color(0.6, 0.6, 0.65))
	l_title.add_theme_color_override("font_outline_color", Color.BLACK)
	l_title.add_theme_constant_override("outline_size", 4)
	vbox.add_child(l_title)
	
	var l_sub = Label.new()
	l_sub.text = subtitle_str
	l_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_sub.add_theme_font_size_override("font_size", 13)
	l_sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85) if is_unlocked else Color(0.5, 0.5, 0.55))
	vbox.add_child(l_sub)
	
	var l_desc = Label.new()
	l_desc.text = desc
	l_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_desc.add_theme_font_size_override("font_size", 13)
	l_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9) if is_unlocked else Color(0.75, 0.55, 0.55))
	l_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(l_desc)
	
	var btn = Button.new()
	if is_unlocked:
		btn.text = "✦ ENTER REALM ✦"
		btn.custom_minimum_size = Vector2(200, 48)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		UITheme.apply_button_theme(btn)
		btn.pressed.connect(func(): _on_map_selected(tier))
	else:
		btn.text = "🔒 LOCKED"
		btn.custom_minimum_size = Vector2(200, 48)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.disabled = true
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		
	vbox.add_child(btn)
	
	var bot_spacer = Control.new()
	bot_spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(bot_spacer)

func _on_map_selected(tier: int) -> void:
	if not GameManager.unlocked_map_tiers.has(tier):
		return
	var main = get_tree().current_scene
	if main and main.has_method("start_game"):
		main.start_game(selected_class, tier)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_back_pressed()

func _on_back_pressed() -> void:
	var main = get_tree().current_scene
	if main and main.has_method("_show_class_selection"):
		main._show_class_selection()
		queue_free()
