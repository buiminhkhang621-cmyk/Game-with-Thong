extends CanvasLayer

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.06, 1.0) # Very dark blue/gray
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Subtle dust/ember particles for atmosphere
	var particles = CPUParticles2D.new()
	particles.position = Vector2(600, 700)
	particles.amount = 50
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(800, 1)
	particles.direction = Vector2(0, -1)
	particles.spread = 20.0
	particles.gravity = Vector2(0, -10)
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 30.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(0.4, 0.4, 0.5, 0.3)
	particles.lifetime = 10.0
	add_child(particles)
	
	# Title
	var title = Label.new()
	title.text = "ABYSSIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.add_theme_constant_override("line_spacing", -5)
	
	var title_margin = MarginContainer.new()
	title_margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title_margin.grow_horizontal = Control.GROW_DIRECTION_END
	title_margin.grow_vertical = Control.GROW_DIRECTION_END
	title_margin.add_theme_constant_override("margin_left", 60)
	title_margin.add_theme_constant_override("margin_top", 60)
	title_margin.add_child(title)
	add_child(title_margin)
	
	# Menu Panel (Bottom Right)
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	
	var panel_margin = MarginContainer.new()
	panel_margin.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel_margin.add_theme_constant_override("margin_right", 60)
	panel_margin.add_theme_constant_override("margin_bottom", 60)
	panel_margin.add_child(panel)
	add_child(panel_margin)
	
	var inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 30)
	inner_margin.add_theme_constant_override("margin_right", 30)
	inner_margin.add_theme_constant_override("margin_top", 30)
	inner_margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(inner_margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	inner_margin.add_child(vbox)
	
	_add_button(vbox, "PLAY", _on_play_pressed)
	_add_button(vbox, "QUESTS", _on_quests_pressed)
	_add_button(vbox, "CODEX", _on_codex_pressed)
	_add_button(vbox, "SETTINGS", _on_settings_pressed)

func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(250, 50)
	btn.add_theme_font_size_override("font_size", 20)
	UITheme.apply_button_theme(btn)
	
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _on_play_pressed() -> void:
	var main = get_tree().current_scene
	if main.has_method("_show_class_selection"):
		main._show_class_selection()

func _on_quests_pressed() -> void:
	var main = get_tree().current_scene
	if main.has_method("_show_quests"):
		main._show_quests()

func _on_settings_pressed() -> void:
	var main = get_tree().current_scene
	if main.has_method("_show_settings"):
		main._show_settings()

func _on_codex_pressed() -> void:
	var main = get_tree().current_scene
	if main.has_method("_show_codex"):
		main._show_codex()
