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
	back_btn.custom_minimum_size = Vector2(120, 38)
	UITheme.apply_button_theme(back_btn)
	back_btn.position = Vector2(40, 38)
	back_btn.pressed.connect(_on_back_pressed)
	root.add_child(back_btn)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center_container)
	
	var hbox = HBoxContainer.new()
	center_container.add_child(hbox)
	hbox.add_theme_constant_override("separation", 30)
	
	_add_map_card(hbox, "PAST", "Easy\nWeak enemies, slow pace.", 1, Color(0.6, 0.5, 0.3))
	_add_map_card(hbox, "PRESENT", "Normal\nStandard survival.", 2, Color(0.3, 0.6, 0.3))
	_add_map_card(hbox, "FUTURE", "Hard\nCrowded, elite enemies.", 3, Color(0.2, 0.3, 0.7))

func _add_map_card(parent: Control, title: String, desc: String, tier: int, c: Color) -> void:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(150, 250)
	parent.add_child(panel)
	
	var bg = ColorRect.new()
	bg.color = c
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)
	
	var l_title = Label.new()
	l_title.text = title
	l_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	l_title.position.y = 10
	panel.add_child(l_title)
	
	var l_desc = Label.new()
	l_desc.text = desc
	l_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_desc.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	l_desc.position.y = -60
	panel.add_child(l_desc)
	
	var btn = Button.new()
	btn.text = "SELECT"
	btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	btn.pressed.connect(func(): _on_map_selected(tier))
	panel.add_child(btn)

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
