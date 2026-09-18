extends CanvasLayer

var title_container: Control = null
var aura_rect: TextureRect = null

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 1. Scenic Mountain Vista Pixel Art Background
	var bg = TextureRect.new()
	bg.texture = UITheme.load_texture("res://Sprite/Main Screen/main_menu_bg.png")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(bg)
	
	# 2. Ambient Drifting Mountain Mist & Fluffy Clouds
	var mist = CPUParticles2D.new()
	mist.position = Vector2(0, 320)
	mist.amount = 32
	mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mist.emission_rect_extents = Vector2(10, 180)
	mist.direction = Vector2(1, 0.04)
	mist.spread = 10.0
	mist.gravity = Vector2(2, -1)
	mist.initial_velocity_min = 14.0
	mist.initial_velocity_max = 28.0
	mist.scale_amount_min = 8.0
	mist.scale_amount_max = 16.0
	mist.color = Color(0.85, 0.92, 1.0, 0.12) # Translucent mountain fog
	mist.lifetime = 45.0
	add_child(mist)
	
	# Ethereal floating motes / sun sparks over the valley
	var motes = CPUParticles2D.new()
	motes.position = Vector2(640, 700)
	motes.amount = 30
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(640, 40)
	motes.direction = Vector2(0.2, -1.0)
	motes.spread = 25.0
	motes.gravity = Vector2(0, -6)
	motes.initial_velocity_min = 12.0
	motes.initial_velocity_max = 30.0
	motes.scale_amount_min = 1.8
	motes.scale_amount_max = 3.6
	motes.color = Color(1.0, 0.88, 0.55, 0.35) # Golden sunlight motes
	motes.lifetime = 14.0
	add_child(motes)
	
	# 3. Wizard Staff Orb Glow & Sparks (at staff position Vector2(755, 475))
	var orb_glow = TextureRect.new()
	orb_glow.texture = UITheme.load_texture("res://Sprite/Main Screen/staff_orb_glow.png")
	orb_glow.custom_minimum_size = Vector2(100, 100)
	orb_glow.size = Vector2(100, 100)
	orb_glow.position = Vector2(705, 425) # Centered at (755, 475)
	orb_glow.pivot_offset = Vector2(50, 50)
	orb_glow.modulate = Color(1.0, 0.62, 0.18, 0.70)
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	orb_glow.material = mat
	add_child(orb_glow)
	
	# Staff orb pulsing tween
	var tw_orb = create_tween().set_loops()
	tw_orb.tween_property(orb_glow, "scale", Vector2(1.28, 1.28), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_orb.parallel().tween_property(orb_glow, "modulate:a", 0.90, 1.6)
	tw_orb.tween_property(orb_glow, "scale", Vector2(0.85, 0.85), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_orb.parallel().tween_property(orb_glow, "modulate:a", 0.45, 1.6)
	
	# Staff floating magical sparks
	var sparks = CPUParticles2D.new()
	sparks.position = Vector2(755, 475)
	sparks.amount = 7
	sparks.direction = Vector2(0.2, -1.0)
	sparks.spread = 45.0
	sparks.gravity = Vector2(0, -12)
	sparks.initial_velocity_min = 10.0
	sparks.initial_velocity_max = 24.0
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 3.5
	sparks.color = Color(1.0, 0.82, 0.35, 0.75)
	sparks.lifetime = 2.0
	add_child(sparks)
	
	# 4. Soft Left UI Vignette (ensures flawless contrast for title & menu)
	var vignette = TextureRect.new()
	vignette.texture = UITheme.load_texture("res://Sprite/Main Screen/left_vignette.png")
	vignette.position = Vector2(0, 0)
	vignette.size = Vector2(620, 720)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	
	# 5. Prominent Signature "ABYSSIA" Title
	title_container = Control.new()
	title_container.position = Vector2(40, 20)
	title_container.size = Vector2(764, 280)
	add_child(title_container)
	
	# Title Layer 1: Deep Ambient Drop Shadow
	var shadow_tex = UITheme.load_texture("res://Sprite/Main Screen/title_shadow.png")
	if shadow_tex:
		var shadow_rect = TextureRect.new()
		shadow_rect.texture = shadow_tex
		shadow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shadow_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shadow_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		shadow_rect.size = Vector2(764, 280)
		shadow_rect.modulate = Color(0.0, 0.0, 0.0, 0.95)
		title_container.add_child(shadow_rect)
		
	# Title Layer 2: Radiant Golden/Crimson Abyssal Aura
	var aura_tex = UITheme.load_texture("res://Sprite/Main Screen/title_glow_aura.png")
	if aura_tex:
		aura_rect = TextureRect.new()
		aura_rect.texture = aura_tex
		aura_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		aura_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		aura_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		aura_rect.size = Vector2(764, 280)
		aura_rect.modulate = Color(1.0, 0.75, 0.25, 0.70)
		var aura_mat = CanvasItemMaterial.new()
		aura_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		aura_rect.material = aura_mat
		title_container.add_child(aura_rect)
		
		# Pulsing glow animation on title aura
		var tw_aura = create_tween().set_loops()
		tw_aura.tween_property(aura_rect, "modulate:a", 0.95, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_aura.tween_property(aura_rect, "modulate:a", 0.40, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# Title Layer 3: Crisp High-Def Stone Letters
	var title_tex = UITheme.load_texture("res://Sprite/Main Screen/title_standalone.png")
	if not title_tex:
		title_tex = UITheme.load_texture("res://Sprite/Main Screen/Main title.png")
	if title_tex:
		var title_rect = TextureRect.new()
		title_rect.texture = title_tex
		title_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		title_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		title_rect.size = Vector2(764, 280)
		title_container.add_child(title_rect)
		
	# Subtle floating breathing tween for the entire signature title
	var tw_float = create_tween().set_loops()
	tw_float.tween_property(title_container, "position:y", 16.0, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_float.tween_property(title_container, "position:y", 24.0, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Atmospheric Subtitle Banner
	var subtitle = Label.new()
	subtitle.text = "✦ SURVIVE THE ENDLESS CATACLYSM ✦"
	subtitle.position = Vector2(65, 275)
	subtitle.size = Vector2(580, 26)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.90, 0.58))
	subtitle.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.06))
	subtitle.add_theme_constant_override("outline_size", 2)
	add_child(subtitle)

	# 6. Main Navigation Menu Buttons (Ancient Mossy Stone Pedestals with Ivy)
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(65, 308)
	vbox.custom_minimum_size = Vector2(340, 334)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	
	_add_pedestal_button(vbox, "play", "P L A Y", _on_play_pressed)
	_add_pedestal_button(vbox, "quests", "Q U E S T S", _on_quests_pressed)
	_add_pedestal_button(vbox, "codex", "C O D E X", _on_codex_pressed)
	_add_pedestal_button(vbox, "settings", "S E T T I N G S", _on_settings_pressed)

	# 7. Bottom Version & Control Info
	var ver = Label.new()
	ver.text = "v1.3.0 • SHATTERED ABYSS • NIGHTMARE HORDE"
	ver.position = Vector2(85, 676)
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", Color(0.72, 0.70, 0.65))
	ver.add_theme_color_override("font_outline_color", Color.BLACK)
	ver.add_theme_constant_override("outline_size", 3)
	add_child(ver)

func _add_pedestal_button(parent: Control, id: String, text: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(340, 76)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.flat = true
	
	# Load ancient stone pedestal slab textures with climbing ivy
	var normal_tex = UITheme.load_texture("res://Sprite/Main Screen/pedestal_" + id + "_normal.png")
	var hover_tex = UITheme.load_texture("res://Sprite/Main Screen/pedestal_" + id + "_hover.png")
	var pressed_tex = UITheme.load_texture("res://Sprite/Main Screen/pedestal_" + id + "_pressed.png")
	
	# Empty styleboxes so button is completely clean
	var empty_sb = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	btn.add_theme_stylebox_override("focus", empty_sb)
	parent.add_child(btn)
	
	# Background TextureRect for the ancient stone slab
	var bg_rect = TextureRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bg_rect.texture = normal_tex
	btn.add_child(bg_rect)
	
	# Centered Carved Tablet Typography
	var lbl = Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.08))
	lbl.add_theme_constant_override("outline_size", 2)
	btn.add_child(lbl)
	
	# Subtle gliding chevron indicator on hover
	var arrow = Label.new()
	arrow.text = "▶"
	arrow.position = Vector2(285, 27)
	arrow.size = Vector2(30, 24)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.add_theme_font_size_override("font_size", 14)
	arrow.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	arrow.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.08))
	arrow.add_theme_constant_override("outline_size", 2)
	arrow.modulate.a = 0.0 # Hidden until hover
	btn.add_child(arrow)
	
	btn.pressed.connect(callback)
	
	# Smooth dynamic hover feedback
	btn.mouse_entered.connect(func():
		if hover_tex:
			bg_rect.texture = hover_tex
		var tw = btn.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "position:x", 12.0, 0.2)
		tw.tween_property(lbl, "theme_override_colors/font_color", Color(1.0, 0.96, 0.72), 0.15)
		tw.tween_property(arrow, "modulate:a", 1.0, 0.15)
		tw.tween_property(arrow, "position:x", 296.0, 0.2)
	)
	btn.mouse_exited.connect(func():
		if normal_tex:
			bg_rect.texture = normal_tex
		var tw = btn.create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "position:x", 0.0, 0.22)
		tw.tween_property(lbl, "theme_override_colors/font_color", Color(0.93, 0.90, 0.82), 0.2)
		tw.tween_property(arrow, "modulate:a", 0.0, 0.18)
		tw.tween_property(arrow, "position:x", 285.0, 0.22)
	)
	btn.button_down.connect(func():
		if pressed_tex:
			bg_rect.texture = pressed_tex
	)
	btn.button_up.connect(func():
		if btn.is_hovered():
			if hover_tex: bg_rect.texture = hover_tex
		else:
			if normal_tex: bg_rect.texture = normal_tex
	)

func _on_play_pressed() -> void:
	var main = get_tree().current_scene
	if main.has_method("_show_class_selection"):
		main._show_class_selection()

func _on_quests_pressed() -> void:
	var main = get_tree().current_scene
	if main.has_method("_show_quests"):
		main._show_quests()

func _on_settings_pressed() -> void:
	var main = get_tree().current_scene
	if main.has_method("_show_settings"):
		main._show_settings()

func _on_codex_pressed() -> void:
	var main = get_tree().current_scene
	if main.has_method("_show_codex"):
		main._show_codex()


