extends CanvasLayer

var _current_choices: Array = []
var _is_banish_mode: bool = false

var root_control: Control
var dim_rect: ColorRect
var center_container: CenterContainer
var main_vbox: VBoxContainer
var title_label: Label
var subtitle_label: Label
var cards_container: HBoxContainer
var bottom_bar: HBoxContainer
var reroll_btn: Button
var banish_btn: Button
var skip_btn: Button

# Card Node helper class
class UpgradeCard extends PanelContainer:
	var choice_data: Dictionary = {}
	var card_index: int = 0
	var parent_screen: CanvasLayer = null
	var is_hovered: bool = false
	var target_scale: Vector2 = Vector2.ONE
	var current_scale: Vector2 = Vector2.ONE
	var border_color: Color = Color(0.3, 0.7, 0.3)
	
	func _init(p_choice: Dictionary, p_index: int, p_screen: CanvasLayer) -> void:
		choice_data = p_choice
		card_index = p_index
		parent_screen = p_screen
		custom_minimum_size = Vector2(280, 440)
		pivot_offset = Vector2(140, 220) # Center pivot for smooth hover zoom
		mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Determine theme color based on tag
		match choice_data.get("tag", ""):
			"Upgrade": border_color = Color(0.3, 0.65, 1.0) # Sky Blue
			"New Skill": border_color = Color(0.3, 0.85, 0.35) # Emerald Green
			"Imbue": border_color = Color(0.85, 0.35, 1.0) # Void Purple
			"Seal", "Crest": border_color = Color(1.0, 0.85, 0.25) # Gilded Gold
			"Recover": border_color = Color(1.0, 0.35, 0.35) # Crimson Red
			_: border_color = Color(0.4, 0.75, 0.45)
			
		_build_ui()
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		gui_input.connect(_on_gui_input)

	func _build_ui() -> void:
		# Card Panel Style (Thick glowing 3D stone rim matching reference)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.13, 0.16, 0.14, 0.96) # Dark mossy stone core
		sb.border_width_left = 6
		sb.border_width_right = 6
		sb.border_width_top = 6
		sb.border_width_bottom = 8
		sb.border_color = border_color
		sb.corner_radius_top_left = 12
		sb.corner_radius_top_right = 12
		sb.corner_radius_bottom_right = 12
		sb.corner_radius_bottom_left = 12
		sb.shadow_size = 12
		sb.shadow_color = Color(border_color.r * 0.5, border_color.g * 0.5, border_color.b * 0.5, 0.4)
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		sb.content_margin_top = 22
		sb.content_margin_bottom = 22
		add_theme_stylebox_override("panel", sb)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		vbox.add_theme_constant_override("separation", 14)
		vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(vbox)
		
		# 1. Custom Vector Icon Container
		var icon_container = Control.new()
		icon_container.custom_minimum_size = Vector2(240, 100)
		icon_container.mouse_filter = Control.MOUSE_FILTER_PASS
		
		var icon_drawer = Control.new()
		icon_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_drawer.mouse_filter = Control.MOUSE_FILTER_PASS
		var icon_id = _get_icon_id_for_choice(choice_data)
		var icon_col = border_color
		icon_drawer.draw.connect(func():
			var center = icon_drawer.size * 0.5
			UpgradeIcons.draw_icon(icon_drawer, icon_id, center, 72.0, icon_col)
		)
		icon_container.add_child(icon_drawer)
		vbox.add_child(icon_container)
		
		# 2. Tag Banner
		var tag_lbl = Label.new()
		tag_lbl.text = "[ %s ]" % choice_data.get("tag", "UPGRADE").to_upper()
		tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_lbl.add_theme_font_size_override("font_size", 12)
		tag_lbl.add_theme_color_override("font_color", border_color.lerp(Color.WHITE, 0.3))
		vbox.add_child(tag_lbl)
		
		# 3. Big Bold Title
		var title_lbl = Label.new()
		title_lbl.text = choice_data.get("title", "Upgrade").to_upper()
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.add_theme_font_size_override("font_size", 20)
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
		title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		title_lbl.add_theme_constant_override("outline_size", 4)
		vbox.add_child(title_lbl)
		
		# 4. Divider Line
		var line = ColorRect.new()
		line.custom_minimum_size = Vector2(0, 2)
		line.color = Color(border_color.r, border_color.g, border_color.b, 0.35)
		vbox.add_child(line)
		
		# 5. Description Text
		var desc_lbl = Label.new()
		desc_lbl.text = choice_data.get("desc", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.82))
		vbox.add_child(desc_lbl)

	func _process(delta: float) -> void:
		current_scale = current_scale.lerp(target_scale, delta * 15.0)
		scale = current_scale

	func _on_mouse_entered() -> void:
		is_hovered = true
		target_scale = Vector2(1.06, 1.06)
		z_index = 10

	func _on_mouse_exited() -> void:
		is_hovered = false
		target_scale = Vector2.ONE
		z_index = 0

	func _on_gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			parent_screen._on_card_pressed(card_index)

	func _get_icon_id_for_choice(choice: Dictionary) -> String:
		var raw_id = choice.get("id", "").to_lower()
		var title = choice.get("title", "").to_lower()
		var tag = choice.get("tag", "").to_lower()
		
		if "bolt" in raw_id or "bolt" in title or "piercing" in title: return "piercing_bolt"
		if "blade" in raw_id or "blade" in title or "orbit" in title: return "orbit_blade"
		if "whip" in raw_id or "whip" in title: return "magic_whip"
		if "scatter" in raw_id or "scatter" in title or "nova" in title: return "nova_scatter"
		if "guardian" in raw_id or "guardian" in title or "shield" in title: return "guardian"
		if "warden" in raw_id or "warden" in title or "sword" in title: return "warden"
		if "might" in raw_id or "might" in title: return "might"
		if "haste" in raw_id or "haste" in title or "speed" in title: return "haste"
		if "vitality" in raw_id or "vitality" in title or "health" in title or "hp" in title: return "vitality"
		if "magnet" in raw_id or "magnet" in title or "pickup" in title: return "magnet"
		if "armor" in raw_id or "armor" in title: return "armor"
		if "crit" in raw_id or "crit" in title: return "crit"
		if "cdr" in raw_id or "hourglass" in title or "cooldown" in title: return "cdr"
		if "lightning" in raw_id or "lightning" in title: return "lightning"
		if "ice" in raw_id or "ice" in title: return "ice"
		if "dark" in raw_id or "dark" in title: return "dark"
		if "void" in raw_id or "void" in title: return "void"
		return "might"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	GameManager.leveled_up_choices.connect(_on_choices)
	
	for child in get_children():
		child.queue_free()
		
	# Root full-rect container
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)
	
	# Fullscreen Dim
	dim_rect = ColorRect.new()
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.color = Color(0, 0, 0, 0.78)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(dim_rect)
	
	# Center Container ensures responsive centering on ALL resolutions
	center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(center_container)
	
	main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 20)
	center_container.add_child(main_vbox)
	
	# Header Title
	title_label = Label.new()
	title_label.text = "LEVEL UP!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 6)
	main_vbox.add_child(title_label)
	
	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.text = "CHOOSE A BLESSING"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 14)
	subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.78))
	main_vbox.add_child(subtitle_label)
	
	# 3-Card Side-by-Side Container
	cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 28)
	main_vbox.add_child(cards_container)
	
	# Bottom action bar (Reroll, Banish, Skip)
	bottom_bar = HBoxContainer.new()
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.add_theme_constant_override("separation", 18)
	main_vbox.add_child(bottom_bar)
	
	reroll_btn = Button.new()
	UITheme.apply_button_theme(reroll_btn)
	reroll_btn.custom_minimum_size = Vector2(140, 42)
	reroll_btn.pressed.connect(_on_reroll_pressed)
	bottom_bar.add_child(reroll_btn)
	
	banish_btn = Button.new()
	UITheme.apply_button_theme(banish_btn)
	banish_btn.custom_minimum_size = Vector2(140, 42)
	banish_btn.pressed.connect(_on_banish_pressed)
	bottom_bar.add_child(banish_btn)
	
	skip_btn = Button.new()
	UITheme.apply_button_theme(skip_btn)
	skip_btn.custom_minimum_size = Vector2(140, 42)
	skip_btn.text = "SKIP (+25 HP)"
	skip_btn.pressed.connect(_on_skip_pressed)
	bottom_bar.add_child(skip_btn)

func _on_choices(choices: Array) -> void:
	_current_choices = choices
	_is_banish_mode = false
	
	for c in cards_container.get_children():
		c.queue_free()

	if GameManager.pending_level_ups > 0:
		subtitle_label.text = "CHOOSE BLESSING (+%d PENDING)" % (GameManager.pending_level_ups + 1)
	else:
		subtitle_label.text = "CHOOSE A BLESSING"
	subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.78))
		
	_update_action_buttons()

	for i in range(choices.size()):
		var card = UpgradeCard.new(choices[i], i, self)
		cards_container.add_child(card)

	visible = true

func _update_action_buttons() -> void:
	if reroll_btn:
		reroll_btn.text = "REROLL (%d)" % GameManager.rerolls_left
		reroll_btn.disabled = (GameManager.rerolls_left <= 0 or _is_banish_mode)
		
	if banish_btn:
		if _is_banish_mode:
			banish_btn.text = "CANCEL BANISH"
		else:
			banish_btn.text = "BANISH (%d)" % GameManager.banishes_left
		banish_btn.disabled = (GameManager.banishes_left <= 0 and not _is_banish_mode)

func _on_card_pressed(index: int) -> void:
	if _is_banish_mode:
		_is_banish_mode = false
		GameManager.banish_choice(_current_choices[index])
	else:
		GameManager.apply_choice(_current_choices[index])
		visible = false

func _on_reroll_pressed() -> void:
	GameManager.reroll_choices()

func _on_banish_pressed() -> void:
	if GameManager.banishes_left <= 0 and not _is_banish_mode:
		return
	_is_banish_mode = not _is_banish_mode
	if _is_banish_mode:
		subtitle_label.text = "SELECT A CARD TO BANISH FOREVER"
		subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		subtitle_label.text = "CHOOSE A BLESSING"
		subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.78))
	_update_action_buttons()

func _on_skip_pressed() -> void:
	visible = false
	GameManager.skip_level_up()
