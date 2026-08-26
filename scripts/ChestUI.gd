class_name ChestUI
extends CanvasLayer

var panel: Panel
var rewards_container: VBoxContainer
var claim_btn: Button
var reward_count: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	
	# Dim overlay
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.8)
	add_child(dim)
	
	# Center Container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# Center Panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(560, 480)
	panel.size = Vector2(560, 480)
	panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	center.add_child(panel)
	
	# Roll count: 1, 3, or 5
	var r = randf()
	if r < 0.65: reward_count = 1
	elif r < 0.92: reward_count = 3
	else: reward_count = 5 # Jackpot
	
	var title = Label.new()
	if reward_count == 5:
		title.text = "DIVINE TREASURE (5X BLESSING!)"
		title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.8))
	elif reward_count == 3:
		title.text = "ANCIENT TREASURE (3X BLESSING)"
		title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		title.text = "RELIC CHEST"
		title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 24)
	title.size = Vector2(560, 40)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	panel.add_child(title)
	
	var sub = Label.new()
	sub.text = "Arcane energies infuse your arsenal."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 64)
	sub.size = Vector2(560, 24)
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	panel.add_child(sub)
	
	rewards_container = VBoxContainer.new()
	rewards_container.position = Vector2(50, 105)
	rewards_container.size = Vector2(460, 280)
	rewards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards_container.add_theme_constant_override("separation", 14)
	panel.add_child(rewards_container)
	
	# Grant upgrades from GameManager
	var granted = GameManager.grant_random_upgrades(reward_count)
	for item_name in granted:
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.18, 0.18, 0.22, 0.95)
		card_style.border_width_left = 2
		card_style.border_width_right = 2
		card_style.border_width_top = 2
		card_style.border_width_bottom = 2
		card_style.border_color = Color(0.9, 0.75, 0.3)
		card_style.corner_radius_top_left = 4
		card_style.corner_radius_top_right = 4
		card_style.corner_radius_bottom_right = 4
		card_style.corner_radius_bottom_left = 4
		card_style.content_margin_top = 10
		card_style.content_margin_bottom = 10
		card_style.content_margin_left = 15
		card_style.content_margin_right = 15
		card.add_theme_stylebox_override("panel", card_style)
		
		var lbl = Label.new()
		lbl.text = "★  " + item_name.to_upper()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 4)
		card.add_child(lbl)
		
		rewards_container.add_child(card)
		
	claim_btn = Button.new()
	UITheme.apply_button_theme(claim_btn)
	claim_btn.text = "CLAIM BLESSINGS"
	claim_btn.custom_minimum_size = Vector2(200, 42)
	claim_btn.position = Vector2(180, 410)
	claim_btn.pressed.connect(_on_claim_pressed)
	panel.add_child(claim_btn)

func _on_claim_pressed() -> void:
	get_tree().paused = false
	queue_free()
