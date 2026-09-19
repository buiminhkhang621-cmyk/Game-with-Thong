extends CanvasLayer

var selected_class: String = ""

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.05, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	
	var title = Label.new()
	title.text = "SELECT TIMELINE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 40
	root.add_child(title)
	
	var back_btn = Button.new()
	back_btn.text = "⮌ BACK"
	back_btn.custom_minimum_size = Vector2(140, 48)
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
	
	_add_map_card(hbox, "PAST", "Tier 1: Sanctuary\nFragile souls, steady pace.\nAncient stone crypts.", 1, Color(0.6, 0.5, 0.3))
	_add_map_card(hbox, "PRESENT", "Tier 2: Labyrinth\nSurging hordes, cursed halls.\nStandard survival.", 2, Color(0.3, 0.65, 0.45))
	_add_map_card(hbox, "FUTURE", "Tier 3: Void Cataclysm\nRelentless champions & elites.\nTrue Nightmare.", 3, Color(0.65, 0.3, 0.85))

func _add_map_card(parent: Control, title: String, desc: String, tier: int, c: Color) -> void:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(250, 360)
	panel.add_theme_stylebox_override("panel", UITheme.create_stone_card(c))
	parent.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(top_spacer)
	
	var l_title = Label.new()
	l_title.text = title
	l_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_title.add_theme_font_size_override("font_size", 22)
	l_title.add_theme_color_override("font_color", c.lerp(Color.WHITE, 0.6))
	l_title.add_theme_color_override("font_outline_color", Color.BLACK)
	l_title.add_theme_constant_override("outline_size", 4)
	vbox.add_child(l_title)
	
	var l_desc = Label.new()
	l_desc.text = desc
	l_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_desc.add_theme_font_size_override("font_size", 14)
	l_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	l_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(l_desc)
	
	var btn = Button.new()
	btn.text = "MANIFEST"
	btn.custom_minimum_size = Vector2(180, 48)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.apply_button_theme(btn)
	btn.pressed.connect(func(): _on_map_selected(tier))
	vbox.add_child(btn)
	
	var bot_spacer = Control.new()
	bot_spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(bot_spacer)

func _on_map_selected(tier: int) -> void:
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
