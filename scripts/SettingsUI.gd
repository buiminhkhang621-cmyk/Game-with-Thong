extends CanvasLayer

var panel: PanelContainer
var test_shake_tween: Tween

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08, 0.94)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center_container)
	
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 600)
	panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	center_container.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "— SETTINGS & PREFERENCES —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	vbox.add_child(title)
	
	# Scroll container for comfortable layout on any resolution
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 440)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 14)
	scroll.add_child(content_vbox)
	
	# ================= VIDEO SECTION =================
	_add_section_title(content_vbox, "DISPLAY & VIDEO")
	
	var chk_fs = CheckButton.new()
	chk_fs.text = "Fullscreen Mode"
	chk_fs.button_pressed = GameManager.setting_fullscreen
	chk_fs.toggled.connect(func(t):
		GameManager.setting_fullscreen = t
		GameManager._apply_settings()
	)
	content_vbox.add_child(chk_fs)
	
	var chk_vsync = CheckButton.new()
	chk_vsync.text = "Vertical Sync (VSync)"
	chk_vsync.button_pressed = GameManager.setting_vsync
	chk_vsync.toggled.connect(func(t):
		GameManager.setting_vsync = t
		GameManager._apply_settings()
	)
	content_vbox.add_child(chk_vsync)
	
	var res_hbox = HBoxContainer.new()
	var res_lbl = Label.new()
	res_lbl.text = "Window Preset:"
	res_lbl.custom_minimum_size = Vector2(170, 0)
	res_lbl.modulate = Color(0.85, 0.85, 0.9)
	res_hbox.add_child(res_lbl)
	
	for res in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		var b = Button.new()
		b.text = "%dx%d" % [res.x, res.y]
		b.custom_minimum_size = Vector2(105, 38)
		UITheme.apply_button_theme(b)
		var target_res = res
		b.pressed.connect(func():
			if GameManager.setting_fullscreen:
				GameManager.setting_fullscreen = false
				chk_fs.button_pressed = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(target_res)
			var screen_size = DisplayServer.screen_get_size()
			DisplayServer.window_set_position((screen_size - target_res) / 2)
			GameManager._apply_settings()
		)
		res_hbox.add_child(b)
	content_vbox.add_child(res_hbox)
	
	# ================= AUDIO SECTION =================
	_add_section_title(content_vbox, "AUDIO & SOUND")
	_add_slider(content_vbox, "Master Volume", GameManager.setting_master_vol, func(v):
		GameManager.setting_master_vol = v
		GameManager._apply_settings()
	)
	_add_slider(content_vbox, "Music Volume", GameManager.setting_music_vol, func(v):
		GameManager.setting_music_vol = v
		GameManager._apply_settings()
	)
	
	var _sfx_slider = _add_slider(content_vbox, "SFX Volume", GameManager.setting_sfx_vol, func(v):
		GameManager.setting_sfx_vol = v
		GameManager._apply_settings()
	)
	
	# Test SFX Button
	var sfx_btn_row = HBoxContainer.new()
	var sfx_spacer = Control.new()
	sfx_spacer.custom_minimum_size = Vector2(170, 0)
	sfx_btn_row.add_child(sfx_spacer)
	
	var test_sfx_btn = Button.new()
	test_sfx_btn.text = "Test Sound (Electric Shock)"
	test_sfx_btn.custom_minimum_size = Vector2(210, 38)
	UITheme.apply_button_theme(test_sfx_btn)
	test_sfx_btn.pressed.connect(func():
		GameManager.play_sfx(GameManager.sfx_electric_shock, randf_range(0.95, 1.05))
	)
	sfx_btn_row.add_child(test_sfx_btn)
	content_vbox.add_child(sfx_btn_row)
	
	# ================= GAMEPLAY SECTION =================
	_add_section_title(content_vbox, "GAMEPLAY & VISUALS")
	
	var shake_row = HBoxContainer.new()
	var chk_shake = CheckButton.new()
	chk_shake.text = "Screen Shake"
	chk_shake.button_pressed = GameManager.setting_screen_shake
	chk_shake.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chk_shake.toggled.connect(func(t):
		GameManager.setting_screen_shake = t
		GameManager._apply_settings()
	)
	shake_row.add_child(chk_shake)
	
	var test_shake_btn = Button.new()
	test_shake_btn.text = "Test Shake"
	test_shake_btn.custom_minimum_size = Vector2(120, 38)
	UITheme.apply_button_theme(test_shake_btn)
	test_shake_btn.pressed.connect(_on_test_shake)
	shake_row.add_child(test_shake_btn)
	content_vbox.add_child(shake_row)
	
	var chk_dmg = CheckButton.new()
	chk_dmg.text = "Damage Numbers"
	chk_dmg.button_pressed = GameManager.setting_damage_numbers
	chk_dmg.toggled.connect(func(t):
		GameManager.setting_damage_numbers = t
		GameManager._apply_settings()
	)
	content_vbox.add_child(chk_dmg)
	
	var chk_fps = CheckButton.new()
	chk_fps.text = "Show FPS Counter"
	chk_fps.button_pressed = GameManager.setting_show_fps
	chk_fps.toggled.connect(func(t):
		GameManager.setting_show_fps = t
		GameManager._apply_settings()
	)
	content_vbox.add_child(chk_fps)
	
	# ================= DATA MANAGEMENT =================
	_add_section_title(content_vbox, "DATA & SAVE MANAGEMENT")
	
	var reset_row = HBoxContainer.new()
	var reset_lbl = Label.new()
	reset_lbl.text = "Reset Progress (Maps & Quests):"
	reset_lbl.custom_minimum_size = Vector2(230, 0)
	reset_lbl.modulate = Color(0.9, 0.75, 0.75)
	reset_row.add_child(reset_lbl)
	
	var reset_btn = Button.new()
	reset_btn.text = "RESET ALL DATA"
	reset_btn.custom_minimum_size = Vector2(200, 38)
	UITheme.apply_button_theme(reset_btn)
	reset_btn.modulate = Color(1.0, 0.65, 0.65)
	reset_btn.pressed.connect(func():
		GameManager.reset_save_data()
		reset_btn.text = "✓ DATA RESET TO DEFAULT"
		reset_btn.disabled = true
		reset_btn.modulate = Color(0.6, 1.0, 0.6)
		GameManager.play_sfx(GameManager.sfx_click)
	)
	reset_row.add_child(reset_btn)
	content_vbox.add_child(reset_row)
	
	# ================= BOTTOM BAR =================
	var bottom_row = HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(bottom_row)
	
	var back_btn = Button.new()
	back_btn.text = "SAVE & RETURN"
	back_btn.custom_minimum_size = Vector2(190, 48)
	UITheme.apply_button_theme(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	bottom_row.add_child(back_btn)

func _add_section_title(parent: Control, text: String) -> void:
	var sep = HSeparator.new()
	sep.modulate = Color(0.35, 0.4, 0.55, 0.7)
	parent.add_child(sep)
	
	var lbl = Label.new()
	lbl.text = "◈ " + text + " ◈"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.modulate = Color(0.9, 0.75, 0.35)
	lbl.add_theme_font_size_override("font_size", 14)
	parent.add_child(lbl)

func _add_slider(parent: Control, text: String, value: float, callback: Callable) -> HSlider:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(170, 0)
	lbl.modulate = Color(0.9, 0.9, 0.95)
	hbox.add_child(lbl)
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(slider)
	
	var val_lbl = Label.new()
	val_lbl.custom_minimum_size = Vector2(55, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.modulate = Color(0.75, 0.85, 1.0)
	val_lbl.text = _format_vol(value)
	hbox.add_child(val_lbl)
	
	slider.value_changed.connect(func(v):
		val_lbl.text = _format_vol(v)
		callback.call(v)
	)
	
	parent.add_child(hbox)
	return slider

func _format_vol(v: float) -> String:
	if v <= 0.01:
		return "MUTE"
	return "%d%%" % int(round(v * 100.0))

func _on_test_shake() -> void:
	if not GameManager.setting_screen_shake: return
	if GameManager.player and is_instance_valid(GameManager.player):
		GameManager.player._shake_intensity = 16.0
	elif panel:
		if test_shake_tween: test_shake_tween.kill()
		test_shake_tween = create_tween()
		var orig = panel.position
		for i in range(6):
			var shake_offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))
			test_shake_tween.tween_property(panel, "position", orig + shake_offset, 0.03)
		test_shake_tween.tween_property(panel, "position", orig, 0.05)

func _on_back_pressed() -> void:
	GameManager.save_settings()
	if get_parent() == get_tree().root:
		var main = get_tree().current_scene
		if main and main.has_method("_show_main_menu"):
			main._show_main_menu()
	queue_free()
