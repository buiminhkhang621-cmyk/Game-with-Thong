extends CanvasLayer

var title_rect: TextureRect = null

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 1. Dark Atmospheric Background
	var bg = ColorRect.new()
	bg.color = Color(0.025, 0.02, 0.035, 1.0) # Obsidian Abyss
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Creeping Abyssal Fog / Ember particles
	var particles = CPUParticles2D.new()
	particles.position = Vector2(640, 740)
	particles.amount = 65
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(700, 1)
	particles.direction = Vector2(0, -1)
	particles.spread = 25.0
	particles.gravity = Vector2(0, -8)
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 40.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.5
	particles.color = Color(0.55, 0.15, 0.18, 0.35) # Dark crimson & ash
	particles.lifetime = 9.0
	add_child(particles)
	
	var dust = CPUParticles2D.new()
	dust.position = Vector2(640, 740)
	dust.amount = 35
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(700, 1)
	dust.direction = Vector2(0, -1)
	dust.spread = 15.0
	dust.gravity = Vector2(0, -4)
	dust.initial_velocity_min = 8.0
	dust.initial_velocity_max = 22.0
	dust.scale_amount_min = 1.5
	dust.scale_amount_max = 3.0
	dust.color = Color(0.35, 0.3, 0.5, 0.25) # Eerie spectral dust
	dust.lifetime = 12.0
	add_child(dust)

	# 2. Main Title Logo (Main title.png)
	var title_tex = UITheme.load_texture("res://Sprite/Main Screen/Main title.png")
	if title_tex:
		title_rect = TextureRect.new()
		title_rect.texture = title_tex
		title_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		title_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		title_rect.custom_minimum_size = Vector2(560, 248)
		title_rect.size = Vector2(560, 248)
		title_rect.position = Vector2(60, 90)
		add_child(title_rect)
		
		# Sinister breathing floating animation
		var t = create_tween().set_loops()
		t.tween_property(title_rect, "position:y", 84.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(title_rect, "position:y", 96.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Atmospheric subtitle
		var subtitle = Label.new()
		subtitle.text = "✦ SURVIVE THE ENDLESS CATACLYSM OF THE ABYSS ✦"
		subtitle.position = Vector2(65, 345)
		subtitle.size = Vector2(550, 30)
		subtitle.add_theme_font_size_override("font_size", 13)
		subtitle.add_theme_color_override("font_color", Color(0.65, 0.55, 0.35))
		subtitle.add_theme_color_override("font_outline_color", Color.BLACK)
		subtitle.add_theme_constant_override("outline_size", 3)
		add_child(subtitle)

	# 3. Main Menu Panel (Right Side)
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	
	var panel_margin = MarginContainer.new()
	panel_margin.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel_margin.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel_margin.add_theme_constant_override("margin_right", 70)
	panel_margin.add_child(panel)
	add_child(panel_margin)
	
	var inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 24)
	inner_margin.add_theme_constant_override("margin_right", 24)
	inner_margin.add_theme_constant_override("margin_top", 28)
	inner_margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(inner_margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	inner_margin.add_child(vbox)
	
	# Load sprite sheet with the 4 pixel icons (64x32 -> 4 slices of 16x32)
	var icons_sheet = UITheme.load_texture("res://Sprite/Main Screen/Play-QUest-Codex-Setting.png")
	
	_add_pixel_button(vbox, icons_sheet, 0, "PLAY", _on_play_pressed)
	_add_pixel_button(vbox, icons_sheet, 1, "QUESTS", _on_quests_pressed)
	_add_pixel_button(vbox, icons_sheet, 2, "CODEX", _on_codex_pressed)
	_add_pixel_button(vbox, icons_sheet, 3, "SETTINGS", _on_settings_pressed)

	# Bottom version info
	var ver = Label.new()
	ver.text = "v1.3.0 • SHATTERED ABYSS • NIGHTMARE HORDE"
	ver.position = Vector2(65, 675)
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", Color(0.45, 0.42, 0.48))
	add_child(ver)

func _add_pixel_button(parent: Control, sheet: Texture2D, col_idx: int, text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(310, 56)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.apply_button_theme(btn)
	parent.add_child(btn)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 16)
	btn.add_child(hbox)
	
	# Spacer margin left
	var sp1 = Control.new()
	sp1.custom_minimum_size = Vector2(6, 0)
	sp1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(sp1)
	
	# Pixel icon slice from Play-QUest-Codex-Setting.png (16x32 per icon)
	var icon_rect = TextureRect.new()
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(22, 44)
	
	if sheet:
		var atlas = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(col_idx * 16, 0, 16, 32)
		icon_rect.texture = atlas
	hbox.add_child(icon_rect)
	
	# Text Label
	var lbl = Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)
	
	# Chevron indicator
	var arrow = Label.new()
	arrow.text = "▶"
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.add_theme_font_size_override("font_size", 14)
	arrow.add_theme_color_override("font_color", Color(0.65, 0.52, 0.3))
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(arrow)
	
	var sp2 = Control.new()
	sp2.custom_minimum_size = Vector2(10, 0)
	sp2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(sp2)
	
	# Interactive Slide & Glow on Hover
	btn.mouse_entered.connect(func():
		var tw = btn.create_tween().set_parallel(true)
		tw.tween_property(hbox, "position:x", 10.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(icon_rect, "modulate", Color(1.3, 1.25, 0.7), 0.15)
		tw.tween_property(lbl, "theme_override_colors/font_color", Color(1.0, 0.95, 0.65), 0.15)
		tw.tween_property(arrow, "theme_override_colors/font_color", Color(1.0, 0.85, 0.3), 0.15)
	)
	btn.mouse_exited.connect(func():
		var tw = btn.create_tween().set_parallel(true)
		tw.tween_property(hbox, "position:x", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(icon_rect, "modulate", Color.WHITE, 0.15)
		tw.tween_property(lbl, "theme_override_colors/font_color", Color(0.90, 0.86, 0.76), 0.15)
		tw.tween_property(arrow, "theme_override_colors/font_color", Color(0.65, 0.52, 0.3), 0.15)
	)
	
	btn.pressed.connect(callback)

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
