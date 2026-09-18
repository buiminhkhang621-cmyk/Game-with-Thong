extends CanvasLayer

var current_class: String = "berserker"
var current_skin: String = "default" # "default" (Hooded Hunter) or "purple_mage" (Purple Nether Mage)
var user_manually_switched_skin: bool = false
var anim_time: float = 0.0

var class_info = {
	"berserker": {
		"name": "BERSERKER",
		"desc": "-10% Max HP.\nDamage increases during combat.\nWields the blood-forged throwing axe.",
		"color": Color(0.9, 0.2, 0.2),
		"accessory": "axe"
	},
	"vanguard": {
		"name": "VANGUARD",
		"desc": "Reduces damage taken by 20%.\nHealing reduced by 30%.\nGuarded by the ancient runic shield.",
		"color": Color(0.95, 0.8, 0.3),
		"accessory": "shield"
	},
	"assassin": {
		"name": "ASSASSIN",
		"desc": "Fast movement, high critical damage.\nHurls razor-sharp throwing knives at foes.",
		"color": Color(0.35, 0.45, 0.95),
		"accessory": "knife"
	},
	"void_mage": {
		"name": "VOID MAGE",
		"desc": "-10% Max HP.\nSpecializes in AoE damage and crowd control.\nCommands orbiting cosmic void spheres.",
		"color": Color(0.75, 0.25, 0.95),
		"accessory": "magic_balls"
	}
}

var info_title: Label
var info_desc: Label

# Center character showcase nodes
var center_panel: Control
var pedestal_draw: Control
var char_sprite: AnimatedSprite2D
var axe_sprite: Sprite2D
var shield_sprite: Sprite2D
var knife_sprite: Sprite2D
var magic_balls: Array[Sprite2D] = []
var aura_particles: CPUParticles2D
var skin_btn_red: Button
var skin_btn_purple: Button

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and "selected_skin" in gm and gm.selected_skin != "":
		current_skin = gm.selected_skin
	else:
		current_skin = "default"
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.05, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Ambient drifting embers
	var bg_particles = CPUParticles2D.new()
	bg_particles.position = Vector2(600, 720)
	bg_particles.amount = 45
	bg_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	bg_particles.emission_rect_extents = Vector2(800, 1)
	bg_particles.direction = Vector2(0, -1)
	bg_particles.spread = 15.0
	bg_particles.gravity = Vector2(0, -6)
	bg_particles.initial_velocity_min = 12.0
	bg_particles.initial_velocity_max = 26.0
	bg_particles.scale_amount_min = 1.5
	bg_particles.scale_amount_max = 3.5
	bg_particles.color = Color(0.5, 0.45, 0.6, 0.25)
	bg_particles.lifetime = 10.0
	add_child(bg_particles)
	
	# Title Header
	var title = Label.new()
	title.text = "CHOOSE YOUR AVATAR"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 4)
	
	var title_margin = MarginContainer.new()
	title_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_margin.add_theme_constant_override("margin_left", 60)
	title_margin.add_theme_constant_override("margin_top", 35)
	title_margin.add_child(title)
	add_child(title_margin)
	
	var back_btn = Button.new()
	back_btn.text = "⮌ BACK"
	back_btn.custom_minimum_size = Vector2(120, 38)
	UITheme.apply_button_theme(back_btn)
	back_btn.position = Vector2(1100, 38)
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)
	
	# Main Layout HBox
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_CENTER)
	hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	hbox.custom_minimum_size = Vector2(1040, 470)
	hbox.position = Vector2(60, 105)
	hbox.add_theme_constant_override("separation", 35)
	add_child(hbox)
	
	# --- Left Panel: Class Buttons ---
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(280, 420)
	left_vbox.add_theme_constant_override("separation", 18)
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(left_vbox)
	
	_add_class_btn(left_vbox, "Berserker", "berserker")
	_add_class_btn(left_vbox, "Vanguard", "vanguard")
	_add_class_btn(left_vbox, "Assassin", "assassin")
	_add_class_btn(left_vbox, "Void Mage", "void_mage")
	
	# --- Center Panel: Animated Hero Showcase on Altar ---
	center_panel = Control.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.custom_minimum_size = Vector2(360, 420)
	hbox.add_child(center_panel)
	_setup_character_preview(center_panel)
	
	# --- Right Panel: Characteristics Info and Manifest Button ---
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(330, 420)
	right_panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	hbox.add_child(right_panel)
	
	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 26)
	right_margin.add_theme_constant_override("margin_right", 26)
	right_margin.add_theme_constant_override("margin_top", 24)
	right_margin.add_theme_constant_override("margin_bottom", 24)
	right_panel.add_child(right_margin)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 18)
	right_margin.add_child(right_vbox)
	
	var info_header = Label.new()
	info_header.text = "CHARACTERISTICS"
	info_header.add_theme_font_size_override("font_size", 16)
	info_header.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
	right_vbox.add_child(info_header)
	
	info_title = Label.new()
	info_title.add_theme_font_size_override("font_size", 26)
	info_title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	info_title.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_vbox.add_child(info_title)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.35, 0.3, 0.25, 0.6)
	right_vbox.add_child(divider)
	
	info_desc = Label.new()
	info_desc.add_theme_font_size_override("font_size", 15)
	info_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.90))
	info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_vbox.add_child(info_desc)
	
	var space = Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(space)
	
	var confirm_btn = Button.new()
	confirm_btn.text = "MANIFEST"
	confirm_btn.custom_minimum_size = Vector2(0, 52)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	UITheme.apply_button_theme(confirm_btn)
	confirm_btn.pressed.connect(_on_confirm)
	right_vbox.add_child(confirm_btn)
	
	_select_class("berserker", false)

func _setup_character_preview(parent: Control) -> void:
	# 1. Carved Pedestal & Aura Canvas
	pedestal_draw = Control.new()
	pedestal_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	pedestal_draw.draw.connect(_on_pedestal_draw)
	parent.add_child(pedestal_draw)
	
	# 2. Altar Rising Ember Particles
	aura_particles = CPUParticles2D.new()
	aura_particles.position = Vector2(180, 260)
	aura_particles.amount = 28
	aura_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	aura_particles.emission_rect_extents = Vector2(65, 8)
	aura_particles.direction = Vector2(0, -1)
	aura_particles.spread = 20.0
	aura_particles.gravity = Vector2(0, -18)
	aura_particles.initial_velocity_min = 25.0
	aura_particles.initial_velocity_max = 60.0
	aura_particles.scale_amount_min = 2.0
	aura_particles.scale_amount_max = 4.0
	aura_particles.color = Color(0.9, 0.2, 0.2, 0.5)
	aura_particles.lifetime = 2.5
	parent.add_child(aura_particles)
	
	# 3. Main Animated Character Sprite
	char_sprite = AnimatedSprite2D.new()
	char_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	char_sprite.scale = Vector2(5.5, 5.5)
	char_sprite.position = Vector2(180, 180)
	parent.add_child(char_sprite)
	
	# 4. Class Accessories & Weapons
	# Axe for Berserker
	axe_sprite = Sprite2D.new()
	axe_sprite.texture = UITheme.load_texture("res://Sprite/weapon/axe.png")
	axe_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	axe_sprite.scale = Vector2(2.6, 2.6)
	axe_sprite.visible = false
	parent.add_child(axe_sprite)
	
	# Shield for Vanguard
	shield_sprite = Sprite2D.new()
	shield_sprite.texture = UITheme.load_texture("res://Sprite/weapon/shield.png")
	shield_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shield_sprite.scale = Vector2(2.5, 2.5)
	shield_sprite.visible = false
	parent.add_child(shield_sprite)
	
	# Knife for Assassin
	knife_sprite = Sprite2D.new()
	knife_sprite.texture = UITheme.load_texture("res://Sprite/weapon/knife.png")
	knife_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	knife_sprite.scale = Vector2(1.5, 1.5)
	knife_sprite.visible = false
	parent.add_child(knife_sprite)
	
	# Orbiting Magic Balls for Void Mage
	magic_balls.clear()
	var ball_tex = UITheme.load_texture("res://Sprite/weapon/Magic-ball.png")
	for i in range(3):
		var mb = Sprite2D.new()
		mb.texture = ball_tex
		mb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mb.scale = Vector2(2.4, 2.4)
		mb.modulate = Color(0.85, 0.35, 1.0)
		mb.visible = false
		parent.add_child(mb)
		magic_balls.append(mb)
		
	# 5. Skin Selector Buttons Under Altar
	var skin_header = Label.new()
	skin_header.text = "HERO SKIN"
	skin_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skin_header.add_theme_font_size_override("font_size", 11)
	skin_header.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75, 0.8))
	skin_header.position = Vector2(0, 346)
	skin_header.custom_minimum_size = Vector2(360, 16)
	parent.add_child(skin_header)

	var btn_row = HBoxContainer.new()
	btn_row.position = Vector2(25, 368)
	btn_row.custom_minimum_size = Vector2(310, 38)
	btn_row.add_theme_constant_override("separation", 10)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(btn_row)

	skin_btn_red = Button.new()
	skin_btn_red.text = "🔴 RED HUNTER"
	skin_btn_red.custom_minimum_size = Vector2(148, 38)
	skin_btn_red.add_theme_font_size_override("font_size", 12)
	UITheme.apply_button_theme(skin_btn_red)
	skin_btn_red.pressed.connect(func(): _set_skin("default"))
	btn_row.add_child(skin_btn_red)

	skin_btn_purple = Button.new()
	skin_btn_purple.text = "🟣 PURPLE MAGE"
	skin_btn_purple.custom_minimum_size = Vector2(148, 38)
	skin_btn_purple.add_theme_font_size_override("font_size", 12)
	UITheme.apply_button_theme(skin_btn_purple)
	skin_btn_purple.pressed.connect(func(): _set_skin("purple_mage"))
	btn_row.add_child(skin_btn_purple)

func _process(delta: float) -> void:
	anim_time += delta
	
	# Smooth hover bobbing for the hero
	if char_sprite:
		char_sprite.position.y = 180.0 + sin(anim_time * 3.2) * 5.5
		
	# Accessories dynamic motion
	var center = char_sprite.position if char_sprite else Vector2(180, 180)
	
	match current_class:
		"berserker":
			if axe_sprite:
				axe_sprite.position = center + Vector2(58, -12 + sin(anim_time * 2.8) * 4.0)
				axe_sprite.rotation = sin(anim_time * 2.0) * 0.15
		"vanguard":
			if shield_sprite:
				shield_sprite.position = center + Vector2(-54, 6 + sin(anim_time * 2.4) * 3.5)
				shield_sprite.scale = Vector2(2.5, 2.5) * (1.0 + sin(anim_time * 3.0) * 0.04)
		"assassin":
			if knife_sprite:
				knife_sprite.position = center + Vector2(48, 14 + sin(anim_time * 3.6) * 4.0)
				knife_sprite.rotation = 0.45 + sin(anim_time * 3.2) * 0.12
		"void_mage":
			# Orbiting magic balls in 3D ellipse around the mage
			for i in range(magic_balls.size()):
				var ball = magic_balls[i]
				var ang = anim_time * 2.2 + (TAU / 3.0) * i
				var rx = cos(ang) * 72.0
				var ry = sin(ang) * 26.0
				ball.position = center + Vector2(rx, ry - 6.0)
				ball.rotation += delta * 3.5
				ball.scale = Vector2(2.4, 2.4) * (0.85 + (sin(ang) + 1.0) * 0.2)
				# 3D depth layering: behind character if in back arc
				ball.z_index = -1 if sin(ang) < -0.1 else 1

	if pedestal_draw:
		pedestal_draw.queue_redraw()

func _on_pedestal_draw() -> void:
	var center = Vector2(180, 200)
	var cl_col = class_info[current_class]["color"]
	
	# Shadow under altar
	pedestal_draw.draw_colored_polygon(PackedVector2Array([
		Vector2(center.x - 110, center.y + 70),
		Vector2(center.x + 110, center.y + 70),
		Vector2(center.x + 130, center.y + 90),
		Vector2(center.x - 130, center.y + 90)
	]), Color(0.01, 0.01, 0.02, 0.6))
	
	# Lower stone step
	var step2 = Rect2(center.x - 105, center.y + 55, 210, 16)
	pedestal_draw.draw_rect(step2, Color(0.12, 0.12, 0.15))
	pedestal_draw.draw_rect(step2, Color(0.24, 0.22, 0.25), false, 2.0)
	
	# Upper stone altar
	var step1 = Rect2(center.x - 85, center.y + 35, 170, 22)
	pedestal_draw.draw_rect(step1, Color(0.16, 0.16, 0.20))
	pedestal_draw.draw_rect(step1, Color(0.32, 0.30, 0.35), false, 2.0)
	
	# Class Runic Ring on Altar surface
	var pulse = 0.65 + sin(anim_time * 3.0) * 0.25
	var runic_col = Color(cl_col.r, cl_col.g, cl_col.b, pulse * 0.4)
	pedestal_draw.draw_circle(Vector2(center.x, center.y + 36), 65, Color(cl_col.r, cl_col.g, cl_col.b, 0.12))
	pedestal_draw.draw_arc(Vector2(center.x, center.y + 36), 60, 0, TAU, 28, runic_col, 2.5)
	
	# Soft grounding shadow right under character feet
	pedestal_draw.draw_circle(Vector2(center.x, center.y + 30), 28, Color(0.02, 0.02, 0.03, 0.5))

func _add_class_btn(parent: Control, text: String, id: String) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 62)
	btn.add_theme_font_size_override("font_size", 20)
	UITheme.apply_button_theme(btn)
	btn.pressed.connect(func():
		_select_class(id, true)
	)
	parent.add_child(btn)

func _select_class(id: String, user_clicked: bool = true) -> void:
	current_class = id
	var info = class_info[id]
	info_title.text = info["name"]
	info_desc.text = info["desc"]
	
	_refresh_character_skin()
	_update_accessories()
	
	if aura_particles:
		var c = info["color"]
		aura_particles.color = Color(c.r, c.g, c.b, 0.65)
		
	# Snappy bounce animation on character when selecting
	if char_sprite and user_clicked:
		char_sprite.scale = Vector2(4.2, 7.0)
		var tw = create_tween()
		tw.tween_property(char_sprite, "scale", Vector2(5.5, 5.5), 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _refresh_character_skin() -> void:
	if not char_sprite: return
	
	var frames_path = "res://Sprite/Player/PlayerFrames.tres"
	if current_skin == "purple_mage":
		frames_path = "res://Sprite/Player/PurpleMage/PurpleMageFrames.tres"
			
	var sf = load(frames_path)
	if sf:
		char_sprite.sprite_frames = sf
		char_sprite.play("idle")
	_update_skin_buttons()

func _update_skin_buttons() -> void:
	if not skin_btn_red or not skin_btn_purple: return
	
	if current_skin == "default":
		skin_btn_red.modulate = Color(1.2, 1.2, 1.2)
		skin_btn_red.text = "✔ 🔴 RED HUNTER"
		skin_btn_purple.modulate = Color(0.6, 0.6, 0.65)
		skin_btn_purple.text = "🟣 PURPLE MAGE"
	else:
		skin_btn_purple.modulate = Color(1.25, 1.05, 1.3)
		skin_btn_purple.text = "✔ 🟣 PURPLE MAGE"
		skin_btn_red.modulate = Color(0.6, 0.6, 0.65)
		skin_btn_red.text = "🔴 RED HUNTER"

func _set_skin(skin_id: String) -> void:
	current_skin = skin_id
	user_manually_switched_skin = true
	var gm = get_node_or_null("/root/GameManager")
	if gm and "selected_skin" in gm:
		gm.selected_skin = current_skin
	if gm and gm.player and gm.player.has_method("apply_skin"):
		gm.player.apply_skin(current_skin)
		
	_refresh_character_skin()
	
	# Flash and hop animation on selection
	if char_sprite:
		char_sprite.scale = Vector2(3.8, 7.2)
		char_sprite.modulate = Color(2.0, 2.0, 2.0)
		var tw = create_tween().set_parallel(true)
		tw.tween_property(char_sprite, "scale", Vector2(5.5, 5.5), 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(char_sprite, "modulate", Color.WHITE, 0.25)

func _update_accessories() -> void:
	if axe_sprite: axe_sprite.visible = (current_class == "berserker")
	if shield_sprite: shield_sprite.visible = (current_class == "vanguard")
	if knife_sprite: knife_sprite.visible = (current_class == "assassin")
	for ball in magic_balls:
		ball.visible = (current_class == "void_mage")

func _on_confirm() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and "selected_skin" in gm:
		gm.selected_skin = current_skin
	if gm and gm.player and gm.player.has_method("apply_skin"):
		gm.player.apply_skin(current_skin)
	var main = get_tree().current_scene
	if main and main.has_method("_show_map_selection"):
		main._show_map_selection(current_class)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_back_pressed()

func _on_back_pressed() -> void:
	var main = get_tree().current_scene
	if main and main.has_method("_show_main_menu"):
		main._show_main_menu()
		queue_free()
