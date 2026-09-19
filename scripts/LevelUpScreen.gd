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
	var border_color: Color = Color(0.85, 0.7, 0.35)
	var glow_color: Color = Color(0.95, 0.8, 0.4)
	var anim_time: float = 0.0
	
	func _init(p_choice: Dictionary, p_index: int, p_screen: CanvasLayer) -> void:
		choice_data = p_choice
		card_index = p_index
		parent_screen = p_screen
		custom_minimum_size = Vector2(285, 450)
		pivot_offset = Vector2(142, 225) # Center pivot for smooth hover zoom
		mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Antique Post-Apocalyptic Noble Palettes (Replacing cheap fluorescent greens)
		match choice_data.get("tag", ""):
			"Upgrade":
				border_color = Color(0.94, 0.68, 0.24) # Tempered Amber Gold
				glow_color = Color(1.0, 0.82, 0.45)
			"New Skill":
				border_color = Color(0.85, 0.72, 0.38) # Ancient Relic Gold / Platinum
				glow_color = Color(0.98, 0.88, 0.55)
			"New Passive":
				border_color = Color(0.38, 0.75, 0.92) # Star Sapphire / Moonstone
				glow_color = Color(0.65, 0.9, 1.0)
			"Imbue":
				border_color = Color(0.82, 0.35, 0.98) # Imperial Void Amethyst
				glow_color = Color(0.95, 0.6, 1.0)
			"Seal", "Crest":
				border_color = Color(1.0, 0.82, 0.35) # Sunken Temple Relic Gold
				glow_color = Color(1.0, 0.92, 0.6)
			"Recover":
				border_color = Color(0.92, 0.32, 0.35) # Abyssal Crimson Garnet
				glow_color = Color(1.0, 0.55, 0.55)
			_:
				border_color = Color(0.82, 0.7, 0.42)
				glow_color = Color(0.95, 0.85, 0.55)
			
		_build_ui()
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		gui_input.connect(_on_gui_input)

	func _build_ui() -> void:
		# Card Panel Style (Ancient mossy carved stone with elemental rarity tint)
		add_theme_stylebox_override("panel", UITheme.create_stone_card(border_color))
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		vbox.add_theme_constant_override("separation", 14)
		vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(vbox)
		
		# 1. Custom Vector Icon Container with Antique Pedestal
		var icon_container = Control.new()
		icon_container.custom_minimum_size = Vector2(245, 105)
		icon_container.mouse_filter = Control.MOUSE_FILTER_PASS
		
		var icon_drawer = Control.new()
		icon_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_drawer.mouse_filter = Control.MOUSE_FILTER_PASS
		var icon_id = _get_icon_id_for_choice(choice_data)
		var icon_col = glow_color
		icon_drawer.draw.connect(func():
			var center = icon_drawer.size * 0.5
			# Runic Halo behind icon
			icon_drawer.draw_circle(center, 40.0, Color(border_color.r, border_color.g, border_color.b, 0.12))
			icon_drawer.draw_arc(center, 42.0, 0, TAU, 24, Color(border_color.r, border_color.g, border_color.b, 0.35), 1.2)
			UpgradeIcons.draw_icon(icon_drawer, icon_id, center, 68.0, icon_col)
		)
		icon_container.add_child(icon_drawer)
		vbox.add_child(icon_container)
		
		# 2. Tag Banner with Runic Bracket
		var tag_lbl = Label.new()
		tag_lbl.text = "◆  %s  ◆" % choice_data.get("tag", "UPGRADE").to_upper()
		tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_lbl.add_theme_font_size_override("font_size", 11)
		tag_lbl.add_theme_color_override("font_color", border_color.lerp(Color.WHITE, 0.25))
		vbox.add_child(tag_lbl)
		
		# 3. Big Bold Antique Title
		var title_lbl = Label.new()
		title_lbl.text = choice_data.get("title", "Upgrade").to_upper()
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.add_theme_font_size_override("font_size", 19)
		title_lbl.add_theme_color_override("font_color", Color(0.98, 0.94, 0.82))
		title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		title_lbl.add_theme_constant_override("outline_size", 5)
		vbox.add_child(title_lbl)
		
		# 4. Antique Carved Divider
		var divider = Control.new()
		divider.custom_minimum_size = Vector2(245, 8)
		divider.draw.connect(func():
			var w = divider.size.x
			var mid_y = divider.size.y * 0.5
			divider.draw_line(Vector2(20, mid_y), Vector2(w - 20, mid_y), Color(border_color.r, border_color.g, border_color.b, 0.4), 1.5)
			divider.draw_circle(Vector2(w * 0.5, mid_y), 3.0, border_color)
		)
		vbox.add_child(divider)
		
		# 5. Description Text (Warm Parchment / Ivory)
		var desc_lbl = Label.new()
		desc_lbl.text = choice_data.get("desc", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.85))
		vbox.add_child(desc_lbl)

	func _process(delta: float) -> void:
		anim_time += delta
		current_scale = current_scale.lerp(target_scale, delta * 15.0)
		scale = current_scale
		queue_redraw()

	func _draw() -> void:
		var w = size.x
		var h = size.y
		var pulse = 0.85 + sin(anim_time * 3.5) * 0.15
		var col = glow_color if is_hovered else border_color
		
		# 1. Weathered Stone Runic Corner Claws
		var c_len = 16.0
		# Top-Left
		draw_line(Vector2(4, 4), Vector2(4 + c_len, 4), col, 2.5)
		draw_line(Vector2(4, 4), Vector2(4, 4 + c_len), col, 2.5)
		# Top-Right
		draw_line(Vector2(w - 4, 4), Vector2(w - 4 - c_len, 4), col, 2.5)
		draw_line(Vector2(w - 4, 4), Vector2(w - 4, 4 + c_len), col, 2.5)
		# Bottom-Left
		draw_line(Vector2(4, h - 4), Vector2(4 + c_len, h - 4), col, 2.5)
		draw_line(Vector2(4, h - 4), Vector2(4, h - 4 - c_len), col, 2.5)
		# Bottom-Right
		draw_line(Vector2(w - 4, h - 4), Vector2(w - 4 - c_len, h - 4), col, 2.5)
		draw_line(Vector2(w - 4, h - 4), Vector2(w - 4, h - 4 - c_len), col, 2.5)
		
		# 2. Outer Shimmering Aura when hovered
		if is_hovered:
			draw_rect(Rect2(0, 0, w, h), Color(glow_color.r, glow_color.g, glow_color.b, 0.08 * pulse), false, 4.0)

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
			if parent_screen and not parent_screen._input_locked:
				accept_event()
				parent_screen._on_card_pressed(card_index)

	func _get_icon_id_for_choice(choice: Dictionary) -> String:
		var raw_id = choice.get("id", "").to_lower()
		var title = choice.get("title", "").to_lower()
		var _tag = choice.get("tag", "").to_lower()
		
		if "knife" in raw_id or "knife" in title or "dao" in title or "dagger" in title: return "throwing_knife"
		if "bolt" in raw_id or "bolt" in title or "piercing" in title: return "piercing_bolt"
		if "blade" in raw_id or "blade" in title or "orbit" in title: return "orbit_blade"
		if "whip" in raw_id or "whip" in title: return "magic_whip"
		if "scatter" in raw_id or "scatter" in title or "nova" in title: return "nova_scatter"
		if "guardian" in raw_id or "guardian" in title or "shield" in title: return "guardian"
		if "warden" in raw_id or "warden" in title or "sword" in title or "axe" in title: return "warden"
		if "might" in raw_id or "might" in title: return "might"
		if "haste" in raw_id or "haste" in title or "speed" in title: return "haste"
		if "vitality" in raw_id or "vitality" in title or "health" in title or "hp" in title: return "vitality"
		if "magnet" in raw_id or "magnet" in title: return "magnet"
		if "armor" in raw_id or "armor" in title: return "armor"
		if "crit" in raw_id or "crit" in title: return "crit"
		if "cdr" in raw_id or "cdr" in title or "hourglass" in title or "cooldown" in title: return "cdr"
		if "lightning" in raw_id or "lightning" in title: return "lightning"
		if "ice" in raw_id or "ice" in title: return "ice"
		if "dark" in raw_id or "dark" in title: return "dark"
		if "void" in raw_id or "void" in title: return "void"
		return "gem"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	
	# Root Fullscreen Control
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_control)
	
	# Background Dim Overlay
	dim_rect = ColorRect.new()
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.color = Color(0.02, 0.02, 0.04, 0.88)
	root_control.add_child(dim_rect)
	
	# CenterContainer for Dynamic Resolution Auto-Centering
	center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(center_container)
	
	# Main Content VBox
	main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 22)
	center_container.add_child(main_vbox)
	
	# Header Title (Ancient Gothic Gold)
	title_label = Label.new()
	title_label.text = "ANCIENT AWAKENING"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42))
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 6)
	main_vbox.add_child(title_label)
	
	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.text = "CHOOSE A SACRED BLESSING"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 13)
	subtitle_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.76))
	main_vbox.add_child(subtitle_label)
	
	# 3-Card Side-by-Side Container
	cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 30)
	main_vbox.add_child(cards_container)
	
	# Bottom action bar (Reroll, Banish, Skip)
	bottom_bar = HBoxContainer.new()
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.add_theme_constant_override("separation", 20)
	main_vbox.add_child(bottom_bar)
	
	reroll_btn = Button.new()
	UITheme.apply_button_theme(reroll_btn)
	reroll_btn.custom_minimum_size = Vector2(160, 48)
	reroll_btn.pressed.connect(_on_reroll_pressed)
	bottom_bar.add_child(reroll_btn)
	
	banish_btn = Button.new()
	UITheme.apply_button_theme(banish_btn)
	banish_btn.custom_minimum_size = Vector2(160, 48)
	banish_btn.pressed.connect(_on_banish_pressed)
	bottom_bar.add_child(banish_btn)
	
	skip_btn = Button.new()
	UITheme.apply_button_theme(skip_btn)
	skip_btn.custom_minimum_size = Vector2(160, 48)
	skip_btn.text = "SKIP (+25 HP)"
	skip_btn.pressed.connect(_on_skip_pressed)
	bottom_bar.add_child(skip_btn)

	GameManager.leveled_up_choices.connect(_on_choices)
var _input_locked: bool = false

func _on_choices(choices: Array) -> void:
	_current_choices = choices
	_is_banish_mode = false
	_input_locked = true
	show()
	
	for c in cards_container.get_children():
		c.queue_free()

	if GameManager.pending_level_ups > 0:
		subtitle_label.text = "LEVEL %d  (%d CHOICE(S) REMAINING)" % [GameManager.level, GameManager.pending_level_ups]
	else:
		subtitle_label.text = "LEVEL %d — CHOOSE YOUR ANCIENT BLESSING" % GameManager.level

	var display_count = min(3, choices.size())
	for i in range(display_count):
		var choice = choices[i]
		var card = UpgradeCard.new(choice, i, self)
		cards_container.add_child(card)

	reroll_btn.text = "REROLL (%d)" % GameManager.rerolls_left
	reroll_btn.disabled = GameManager.rerolls_left <= 0

	banish_btn.text = "BANISH (%d)" % GameManager.banishes_left
	banish_btn.disabled = GameManager.banishes_left <= 0
	banish_btn.modulate = Color.WHITE

	if is_inside_tree() and get_tree():
		var t = get_tree().create_timer(0.25, true, false, true)
		await t.timeout
	_input_locked = false

func _on_card_pressed(idx: int) -> void:
	if _input_locked:
		return
	if idx >= _current_choices.size():
		return
	_input_locked = true
	var choice = _current_choices[idx]
	
	if _is_banish_mode:
		if GameManager.banishes_left > 0:
			GameManager.banishes_left -= 1
			var ban_id = choice.get("skill_id", choice.get("passive_id", choice.get("vong_id", choice.get("net_id", ""))))
			if ban_id != "":
				GameManager.banished_ids.append(ban_id)
			_is_banish_mode = false
			banish_btn.modulate = Color.WHITE
			_on_choices(GameManager._build_level_up_choices())
		return

	GameManager.apply_choice(choice)
	if not GameManager.paused_for_levelup:
		hide()

func _on_reroll_pressed() -> void:
	if _input_locked: return
	if GameManager.rerolls_left > 0:
		GameManager.rerolls_left -= 1
		_on_choices(GameManager._build_level_up_choices())

func _on_banish_pressed() -> void:
	if _input_locked: return
	if GameManager.banishes_left > 0:
		_is_banish_mode = not _is_banish_mode
		if _is_banish_mode:
			banish_btn.modulate = Color(1.0, 0.4, 0.4)
			subtitle_label.text = "SELECT AN OPTION TO BANISH FOREVER"
		else:
			banish_btn.modulate = Color.WHITE
			subtitle_label.text = "CHOOSE A SACRED BLESSING"

func _on_skip_pressed() -> void:
	if _input_locked: return
	_input_locked = true
	GameManager.skip_level_up()
	if not GameManager.paused_for_levelup:
		hide()
