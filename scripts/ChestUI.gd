class_name ChestUI
extends CanvasLayer

var panel: Panel
var main_vbox: VBoxContainer
var rewards_container: VBoxContainer
var claim_btn: Button
var reward_count: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	
	# Dim overlay
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.04, 0.90)
	add_child(dim)
	
	# Center Container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# Center Panel (Ancient Gilded Obsidian Sarcophagus)
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(560, 480)
	panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	center.add_child(panel)
	
	main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 16)
	panel.add_child(main_vbox)
	
	# Roll count: 1, 3, or 5
	var r = randf()
	if r < 0.60: reward_count = 1
	elif r < 0.90: reward_count = 3
	else: reward_count = 5 # Jackpot
	
	var title = Label.new()
	if reward_count == 5:
		title.text = "◆ DIVINE RELIC CHEST (5X BLESSINGS) ◆"
		title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.85))
	elif reward_count == 3:
		title.text = "◆ ANCIENT RELIC CHEST (3X BLESSINGS) ◆"
		title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	else:
		title.text = "◆ ANCIENT TREASURE CHEST ◆"
		title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
		
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 5)
	main_vbox.add_child(title)
	
	var sub = Label.new()
	sub.text = "Ancient relics resonate and empower your arsenal."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.72, 0.72, 0.76))
	main_vbox.add_child(sub)
	
	rewards_container = VBoxContainer.new()
	rewards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards_container.add_theme_constant_override("separation", 10)
	main_vbox.add_child(rewards_container)
	
	# Grant upgrades from GameManager
	var granted = GameManager.grant_random_upgrades(reward_count)
	for item_name in granted:
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(440, 44)
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.12, 0.16, 0.95)
		card_style.border_width_left = 2
		card_style.border_width_right = 2
		card_style.border_width_top = 2
		card_style.border_width_bottom = 3
		card_style.border_color = Color(0.85, 0.72, 0.35)
		card_style.corner_radius_top_left = 6
		card_style.corner_radius_top_right = 6
		card_style.corner_radius_bottom_right = 6
		card_style.corner_radius_bottom_left = 6
		card_style.content_margin_top = 8
		card_style.content_margin_bottom = 8
		card_style.content_margin_left = 16
		card_style.content_margin_right = 16
		card.add_theme_stylebox_override("panel", card_style)
		
		var lbl = Label.new()
		lbl.text = "✦  " + item_name.to_upper()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.7))
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 3)
		card.add_child(lbl)
		
		rewards_container.add_child(card)
		
	claim_btn = Button.new()
	UITheme.apply_button_theme(claim_btn)
	claim_btn.text = "CLAIM BLESSINGS"
	claim_btn.custom_minimum_size = Vector2(220, 44)
	claim_btn.pressed.connect(_on_claim_pressed)
	main_vbox.add_child(claim_btn)

func _on_claim_pressed() -> void:
	if not GameManager.paused_for_levelup:
		get_tree().paused = false
	queue_free()
