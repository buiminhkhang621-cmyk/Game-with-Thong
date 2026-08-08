extends CanvasLayer

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
	particles.amount = 40
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(800, 1)
	particles.direction = Vector2(0, -1)
	particles.spread = 20.0
	particles.gravity = Vector2(0, -5)
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 20.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = Color(0.9, 0.8, 0.4, 0.3)
	particles.lifetime = 15.0
	add_child(particles)
	
	var title = Label.new()
	title.text = "QUESTS & ACHIEVEMENTS"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.grow_horizontal = Control.GROW_DIRECTION_END
	title.grow_vertical = Control.GROW_DIRECTION_END
	title.position.y = 30
	add_child(title)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(800, 480)
	main_panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	center_container.add_child(main_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	main_panel.add_child(margin)
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(vbox)
	
	for q_id in GameManager.quests.keys():
		var q = GameManager.quests[q_id]
		_add_quest_entry(vbox, q)
		
	var back_btn = Button.new()
	back_btn.text = "RETURN"
	back_btn.custom_minimum_size = Vector2(200, 50)
	back_btn.add_theme_font_size_override("font_size", 18)
	UITheme.apply_button_theme(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	
	var btn_margin = MarginContainer.new()
	btn_margin.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	btn_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	btn_margin.add_theme_constant_override("margin_right", 60)
	btn_margin.add_theme_constant_override("margin_bottom", 60)
	btn_margin.add_child(back_btn)
	add_child(btn_margin)

func _add_quest_entry(parent: Control, q: Dictionary) -> void:
	var entry = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.35) if not q.completed else Color(0.8, 0.7, 0.2)
	style.corner_radius_top_left = 8
	style.corner_radius_bottom_right = 8
	entry.add_theme_stylebox_override("panel", style)
	parent.add_child(entry)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	entry.add_child(margin)
	margin.add_child(hbox)
	
	# Icon/Status
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if q.completed:
		icon.color = Color(0.9, 0.8, 0.2) # Gold for completed
	else:
		icon.color = Color(0.3, 0.3, 0.35) # Gray for incomplete
	hbox.add_child(icon)
	
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)
	
	var title = Label.new()
	title.text = q.title
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE if not q.completed else Color(1.0, 0.9, 0.4))
	text_vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = q.desc
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	text_vbox.add_child(desc)
	
	var progress_vbox = VBoxContainer.new()
	progress_vbox.custom_minimum_size = Vector2(200, 0)
	progress_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(progress_vbox)
	
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 20)
	progress_bar.max_value = q.target
	progress_bar.value = q.current
	progress_bar.show_percentage = false
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.05, 0.05)
	progress_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.6, 0.8) if not q.completed else Color(0.8, 0.7, 0.2)
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	progress_vbox.add_child(progress_bar)
	
	var progress_text = Label.new()
	
	var c_val = q.current
	var t_val = q.target
	if q.type == "time" or q.type == "curse_time":
		c_val = int(q.current / 60.0)
		t_val = int(q.target / 60.0)
		progress_text.text = "%d / %d mins" % [c_val, t_val]
	else:
		progress_text.text = "%d / %d" % [c_val, t_val]
		
	progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_text.add_theme_font_size_override("font_size", 12)
	progress_vbox.add_child(progress_text)

func _on_back_pressed() -> void:
	var main = get_tree().current_scene
	if main.has_method("_show_main_menu"):
		main._show_main_menu()
	queue_free()
