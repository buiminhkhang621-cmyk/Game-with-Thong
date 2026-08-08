extends CanvasLayer

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15, 0.95)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	
	var title = Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 40
	root.add_child(title)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center_container)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(500, 400)
	center_container.add_child(vbox)
	vbox.add_theme_constant_override("separation", 20)
	
	_add_section_title(vbox, "--- VIDEO ---")
	
	var chk_fs = CheckButton.new()
	chk_fs.text = "Fullscreen"
	chk_fs.button_pressed = GameManager.setting_fullscreen
	chk_fs.toggled.connect(func(t):
		GameManager.setting_fullscreen = t
	)
	vbox.add_child(chk_fs)
	
	var chk_vsync = CheckButton.new()
	chk_vsync.text = "VSync"
	chk_vsync.button_pressed = GameManager.setting_vsync
	chk_vsync.toggled.connect(func(t):
		GameManager.setting_vsync = t
	)
	vbox.add_child(chk_vsync)
	
	_add_section_title(vbox, "--- AUDIO ---")
	_add_slider(vbox, "Master Volume", GameManager.setting_master_vol, func(v): GameManager.setting_master_vol = v)
	_add_slider(vbox, "Music Volume", GameManager.setting_music_vol, func(v): GameManager.setting_music_vol = v)
	_add_slider(vbox, "SFX Volume", GameManager.setting_sfx_vol, func(v): GameManager.setting_sfx_vol = v)
	
	_add_section_title(vbox, "--- GAMEPLAY ---")
	
	var chk_shake = CheckButton.new()
	chk_shake.text = "Screen Shake"
	chk_shake.button_pressed = GameManager.setting_screen_shake
	chk_shake.toggled.connect(func(t):
		GameManager.setting_screen_shake = t
	)
	vbox.add_child(chk_shake)
	
	var back_btn = Button.new()
	back_btn.text = "SAVE AND BACK"
	back_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	back_btn.offset_left = -200
	back_btn.offset_top = -100
	back_btn.offset_right = -50
	back_btn.offset_bottom = -50
	back_btn.custom_minimum_size = Vector2(150, 50)
	back_btn.pressed.connect(_on_back_pressed)
	root.add_child(back_btn)

func _add_section_title(parent: Control, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.modulate = Color(0.6, 0.6, 0.6)
	parent.add_child(lbl)

func _add_slider(parent: Control, text: String, value: float, callback: Callable) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(lbl)
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	hbox.add_child(slider)
	
	parent.add_child(hbox)

func _on_back_pressed() -> void:
	GameManager.save_settings()
	var main = get_tree().current_scene
	var script = load("res://scripts/MainMenuUI.gd")
	if script:
		var main_menu = script.new()
		get_tree().root.add_child(main_menu)
		if main and "current_ui" in main:
			main.current_ui = main_menu
	if main.has_method("_show_main_menu"):
		main._show_main_menu()
	queue_free()
