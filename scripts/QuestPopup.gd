extends CanvasLayer

var queue: Array = []
var is_showing: bool = false
var panel: PanelContainer
var title_label: Label
var glow: ColorRect

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_END
	panel.position = Vector2(-20, 20)
	panel.modulate.a = 0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	
	glow = ColorRect.new()
	glow.color = Color(1, 0.8, 0.2, 0.2)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(glow)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var header = Label.new()
	header.text = "QUEST COMPLETED"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)
	
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	GameManager.quest_completed.connect(_on_quest_completed)

func _on_quest_completed(_id: String, title: String) -> void:
	queue.append(title)
	if not is_showing:
		_show_next()

func _show_next() -> void:
	if queue.size() == 0:
		is_showing = false
		return
		
	is_showing = true
	var title = queue.pop_front()
	title_label.text = title
	
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(glow, "color:a", 0.0, 0.5).set_delay(0.1)
	tween.tween_interval(2.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_show_next)
	
	glow.color.a = 0.4
