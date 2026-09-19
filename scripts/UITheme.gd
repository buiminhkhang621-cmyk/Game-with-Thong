class_name UITheme
extends RefCounted

# Ancient Dark Fantasy & Mossy Stone Carved Pixel Art Theme

static func create_stone_panel() -> StyleBox:
	var tex = load_texture("res://Sprite/Main Screen/stone_panel_frame.png")
	if tex:
		var sbt = StyleBoxTexture.new()
		sbt.texture = tex
		sbt.texture_margin_left = 70
		sbt.texture_margin_right = 70
		sbt.texture_margin_top = 48
		sbt.texture_margin_bottom = 48
		sbt.content_margin_left = 42
		sbt.content_margin_right = 42
		sbt.content_margin_top = 36
		sbt.content_margin_bottom = 36
		return sbt
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.07, 0.96)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 4
	sb.border_color = Color(0.55, 0.42, 0.24)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	return sb

static func create_stone_button_normal() -> StyleBox:
	var tex = load_texture("res://Sprite/Main Screen/stone_button_normal.png")
	if tex:
		var sbt = StyleBoxTexture.new()
		sbt.texture = tex
		sbt.texture_margin_left = 38
		sbt.texture_margin_right = 44
		sbt.texture_margin_top = 18
		sbt.texture_margin_bottom = 16
		sbt.content_margin_left = 22
		sbt.content_margin_right = 22
		sbt.content_margin_top = 8
		sbt.content_margin_bottom = 8
		return sbt
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.12, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 3
	sb.border_color = Color(0.45, 0.36, 0.22)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	return sb

static func create_stone_button_hover() -> StyleBox:
	var tex = load_texture("res://Sprite/Main Screen/stone_button_hover.png")
	if tex:
		var sbt = StyleBoxTexture.new()
		sbt.texture = tex
		sbt.texture_margin_left = 38
		sbt.texture_margin_right = 44
		sbt.texture_margin_top = 18
		sbt.texture_margin_bottom = 16
		sbt.content_margin_left = 22
		sbt.content_margin_right = 22
		sbt.content_margin_top = 8
		sbt.content_margin_bottom = 8
		return sbt
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.14, 0.21, 1.0)
	sb.border_color = Color(0.95, 0.78, 0.35)
	return sb

static func create_stone_button_pressed() -> StyleBox:
	var tex = load_texture("res://Sprite/Main Screen/stone_button_pressed.png")
	if tex:
		var sbt = StyleBoxTexture.new()
		sbt.texture = tex
		sbt.texture_margin_left = 38
		sbt.texture_margin_right = 44
		sbt.texture_margin_top = 18
		sbt.texture_margin_bottom = 16
		sbt.content_margin_left = 22
		sbt.content_margin_right = 22
		sbt.content_margin_top = 10
		sbt.content_margin_bottom = 6
		return sbt
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.07, 1.0)
	sb.border_color = Color(0.35, 0.28, 0.16)
	return sb

static func create_stone_card(border_color: Color = Color.WHITE) -> StyleBox:
	var tex = load_texture("res://Sprite/Main Screen/stone_card_frame.png")
	if tex:
		var sbt = StyleBoxTexture.new()
		sbt.texture = tex
		sbt.texture_margin_left = 40
		sbt.texture_margin_right = 40
		sbt.texture_margin_top = 50
		sbt.texture_margin_bottom = 50
		sbt.content_margin_left = 20
		sbt.content_margin_right = 20
		sbt.content_margin_top = 26
		sbt.content_margin_bottom = 26
		if border_color != Color.WHITE:
			sbt.modulate_color = Color(1.0, 1.0, 1.0).lerp(border_color, 0.25)
		return sbt
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.11, 0.97)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 5
	sb.border_color = border_color
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	return sb

static func create_stone_slot(tint: Color = Color.WHITE) -> StyleBox:
	var tex = load_texture("res://Sprite/Main Screen/stone_slot_frame.png")
	if tex:
		var sbt = StyleBoxTexture.new()
		sbt.texture = tex
		sbt.texture_margin_left = 14
		sbt.texture_margin_right = 14
		sbt.texture_margin_top = 14
		sbt.texture_margin_bottom = 14
		sbt.content_margin_left = 4
		sbt.content_margin_right = 4
		sbt.content_margin_top = 4
		sbt.content_margin_bottom = 4
		if tint != Color.WHITE:
			sbt.modulate_color = Color(1.0, 1.0, 1.0).lerp(tint, 0.35)
		return sbt
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.11, 0.95)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 3
	sb.border_color = tint
	return sb

static func apply_button_theme(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", create_stone_button_normal())
	btn.add_theme_stylebox_override("hover", create_stone_button_hover())
	btn.add_theme_stylebox_override("pressed", create_stone_button_pressed())
	var empty = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_color_override("font_color", Color(0.98, 0.94, 0.82))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.70))
	btn.add_theme_color_override("font_pressed_color", Color(0.80, 0.76, 0.65))
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 0.95))
	btn.add_theme_constant_override("outline_size", 4)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

static func load_texture(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var res = load(res_path)
		if res is Texture2D:
			return res
	var global_path = ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(global_path):
		var img = Image.load_from_file(global_path)
		if img:
			return ImageTexture.create_from_image(img)
	return null
