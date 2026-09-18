class_name UITheme
extends RefCounted

# Ancient Dark Fantasy & Obsidian Pixel Art Theme

static func create_stone_panel() -> StyleBox:
	var tex = load_texture("res://Sprite/Main Screen/stone_panel_frame.png")
	if tex:
		var sbt = StyleBoxTexture.new()
		sbt.texture = tex
		sbt.texture_margin_left = 16
		sbt.texture_margin_right = 16
		sbt.texture_margin_top = 16
		sbt.texture_margin_bottom = 16
		sbt.content_margin_left = 22
		sbt.content_margin_right = 22
		sbt.content_margin_top = 26
		sbt.content_margin_bottom = 26
		return sbt
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.07, 0.96)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 4
	sb.border_color = Color(0.55, 0.42, 0.24)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	return sb

static func create_stone_button_normal() -> StyleBox:
	var tex = load_texture("res://Sprite/Main Screen/stone_button_normal.png")
	if tex:
		var sbt = StyleBoxTexture.new()
		sbt.texture = tex
		sbt.texture_margin_left = 12
		sbt.texture_margin_right = 12
		sbt.texture_margin_top = 10
		sbt.texture_margin_bottom = 10
		sbt.content_margin_left = 16
		sbt.content_margin_right = 16
		sbt.content_margin_top = 10
		sbt.content_margin_bottom = 10
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
		sbt.texture_margin_left = 12
		sbt.texture_margin_right = 12
		sbt.texture_margin_top = 10
		sbt.texture_margin_bottom = 10
		sbt.content_margin_left = 16
		sbt.content_margin_right = 16
		sbt.content_margin_top = 10
		sbt.content_margin_bottom = 10
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
		sbt.texture_margin_left = 12
		sbt.texture_margin_right = 12
		sbt.texture_margin_top = 10
		sbt.texture_margin_bottom = 10
		sbt.content_margin_left = 16
		sbt.content_margin_right = 16
		sbt.content_margin_top = 12
		sbt.content_margin_bottom = 8
		return sbt
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.07, 1.0)
	sb.border_color = Color(0.35, 0.28, 0.16)
	return sb


static func apply_button_theme(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", create_stone_button_normal())
	btn.add_theme_stylebox_override("hover", create_stone_button_hover())
	btn.add_theme_stylebox_override("pressed", create_stone_button_pressed())
	btn.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.65))
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 4)

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
