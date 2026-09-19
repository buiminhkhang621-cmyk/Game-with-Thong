extends CanvasLayer

var root_control: Control
var dim_rect: ColorRect
var game_over_rect: TextureRect
var again_btn: TextureButton
var stats_panel: PanelContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 250
	visible = false
	GameManager.player_died.connect(_on_player_died)
	
	# Clear static scene nodes
	for c in get_children():
		c.queue_free()
		
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)
	
	# 1. 100% Solid Pitch Black Backdrop (Completely covers background)
	dim_rect = ColorRect.new()
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.color = Color(0.0, 0.0, 0.0, 1.0) # Completely solid black - 0% transparency
	root_control.add_child(dim_rect)
	
	# Floating blood ash & embers
	var particles = CPUParticles2D.new()
	particles.position = Vector2(640, 740)
	particles.amount = 55
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(700, 1)
	particles.direction = Vector2(0, -1)
	particles.spread = 20.0
	particles.gravity = Vector2(0, -12)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(0.7, 0.12, 0.15, 0.45) # Dark crimson blood embers
	particles.lifetime = 8.0
	root_control.add_child(particles)
	
	# Main Center Container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(center)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 18)
	center.add_child(main_vbox)
	
	# 2. GAME-OVER.png Title Header
	var go_tex = UITheme.load_texture("res://Sprite/Death Scene/GAME-OVER.png")
	if go_tex:
		game_over_rect = TextureRect.new()
		game_over_rect.texture = go_tex
		game_over_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		game_over_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		game_over_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		game_over_rect.custom_minimum_size = Vector2(460, 271)
		game_over_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		game_over_rect.pivot_offset = Vector2(230, 135)
		main_vbox.add_child(game_over_rect)

	# 3. Gothic Carved Tombstone Stats Slab
	stats_panel = PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	stats_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(stats_panel)
	
	var slab_margin = MarginContainer.new()
	slab_margin.add_theme_constant_override("margin_left", 36)
	slab_margin.add_theme_constant_override("margin_right", 36)
	slab_margin.add_theme_constant_override("margin_top", 16)
	slab_margin.add_theme_constant_override("margin_bottom", 16)
	stats_panel.add_child(slab_margin)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	slab_margin.add_child(stats_vbox)
	
	# Stats header
	var slab_title = Label.new()
	slab_title.text = "✦ MORTAL VESSEL SHATTERED ✦"
	slab_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slab_title.add_theme_font_size_override("font_size", 13)
	slab_title.add_theme_color_override("font_color", Color(0.75, 0.45, 0.45))
	slab_title.add_theme_color_override("font_outline_color", Color.BLACK)
	slab_title.add_theme_constant_override("outline_size", 3)
	stats_vbox.add_child(slab_title)
	
	# Grid of run stats
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 35)
	grid.add_theme_constant_override("v_separation", 6)
	stats_vbox.add_child(grid)
	
	_add_stat_row(grid, "⏳ TIME SURVIVED:", "stat_time")
	_add_stat_row(grid, "💀 SOULS SLAIN:", "stat_kills")
	_add_stat_row(grid, "✦ LEVEL REACHED:", "stat_level")
	_add_stat_row(grid, "🏆 FINAL SCORE:", "stat_score")
	
	# 4. Action Buttons Container
	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox.add_theme_constant_override("separation", 12)
	main_vbox.add_child(btn_vbox)

	var again_tex = UITheme.load_texture("res://Sprite/Death Scene/AGAIN.png")
	if again_tex:
		again_btn = TextureButton.new()
		again_btn.texture_normal = again_tex
		again_btn.ignore_texture_size = true
		again_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		again_btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		again_btn.custom_minimum_size = Vector2(260, 78)
		again_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		again_btn.pivot_offset = Vector2(130, 39)
		again_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		again_btn.pressed.connect(_on_restart_pressed)
		btn_vbox.add_child(again_btn)
		
		# Interactive Spring Scale & Runic Glow on Hover
		again_btn.mouse_entered.connect(func():
			var tw = again_btn.create_tween().set_parallel(true)
			tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(again_btn, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
			tw.tween_property(again_btn, "modulate", Color(1.3, 0.95, 0.95), 0.15)
		)
		again_btn.mouse_exited.connect(func():
			var tw = again_btn.create_tween().set_parallel(true)
			tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(again_btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(again_btn, "modulate", Color.WHITE, 0.15)
		)
		again_btn.button_down.connect(func():
			again_btn.scale = Vector2(0.94, 0.94)
		)
		again_btn.button_up.connect(func():
			again_btn.scale = Vector2(1.05, 1.05)
		)
		
	var menu_btn = Button.new()
	menu_btn.text = "✦ RETURN TO MENU ✦"
	menu_btn.custom_minimum_size = Vector2(260, 52)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.add_theme_font_size_override("font_size", 16)
	UITheme.apply_button_theme(menu_btn)
	menu_btn.pressed.connect(_on_main_menu_pressed)
	btn_vbox.add_child(menu_btn)

func _add_stat_row(parent: Control, label_text: String, meta_key: String) -> void:
	var l = Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.70, 0.68, 0.74))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	parent.add_child(l)
	
	var v = Label.new()
	v.text = "0"
	v.set_meta("stat_id", meta_key)
	v.add_theme_font_size_override("font_size", 16)
	v.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45)) # Antique Gold
	v.add_theme_color_override("font_outline_color", Color.BLACK)
	v.add_theme_constant_override("outline_size", 3)
	parent.add_child(v)

func _on_player_died() -> void:
	get_tree().paused = true
	GameManager.stop_all_audio()
	
	# Explicitly hide all underlying UI so nothing bleeds through
	var cur_scene = get_tree().current_scene
	if cur_scene:
		for ui_name in ["LevelUpScreen", "HUD", "PauseMenuUI", "ChestUI", "QuestsUI"]:
			var n = cur_scene.find_child(ui_name, true, false)
			if n: n.visible = false
	
	var m := int(GameManager.run_time / 60.0)
	var s := int(GameManager.run_time) % 60
	
	for node in get_tree().get_nodes_in_group("stat_labels"):
		pass
	
	# Update all stat values
	if stats_panel:
		for child in stats_panel.find_children("", "Label", true, false):
			if child.has_meta("stat_id"):
				match child.get_meta("stat_id"):
					"stat_time":
						child.text = "%02d:%02d" % [m, s]
					"stat_kills":
						child.text = str(GameManager.kills)
					"stat_level":
						child.text = str(GameManager.level)
					"stat_score":
						child.text = str(GameManager.score)
						
	visible = true
	
	# Dramatic entrance animation for GAME-OVER.png
	if game_over_rect:
		game_over_rect.scale = Vector2(1.25, 1.25)
		game_over_rect.modulate.a = 0.0
		var tw = create_tween().set_parallel(true)
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(game_over_rect, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(game_over_rect, "modulate:a", 1.0, 0.35)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.game_over = false
	GameManager.stop_all_audio()
	GameManager.restart_run_on_ready = true
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.game_over = false
	GameManager.stop_all_audio()
	GameManager.restart_run_on_ready = false
	get_tree().reload_current_scene()
