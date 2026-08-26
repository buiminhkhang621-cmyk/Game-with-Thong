extends CanvasLayer

var root_control: Control
var dim_rect: ColorRect
var center_container: CenterContainer
var panel: Panel
var stats_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	GameManager.player_died.connect(_on_player_died)
	
	# Clear static scene nodes
	for c in get_children():
		c.queue_free()
		
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)
	
	dim_rect = ColorRect.new()
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.color = Color(0, 0, 0, 0.8)
	root_control.add_child(dim_rect)
	
	center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(center_container)
	
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(500, 420)
	panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	center_container.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "DEFEAT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	vbox.add_child(title)
	
	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	vbox.add_child(stats_label)
	
	var btn = Button.new()
	UITheme.apply_button_theme(btn)
	btn.text = "PLAY AGAIN"
	btn.custom_minimum_size = Vector2(200, 45)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(btn)

func _on_player_died() -> void:
	var m := int(GameManager.run_time / 60.0)
	var s := int(GameManager.run_time) % 60
	stats_label.text = "Time Survived: %d:%02d\n\nEnemies Defeated: %d\n\nLevel Reached: %d" \
		% [m, s, GameManager.kills, GameManager.level]
	visible = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.game_over = false
	get_tree().reload_current_scene()
