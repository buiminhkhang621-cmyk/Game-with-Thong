class_name UITheme
extends RefCounted

static func create_stone_panel() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.border_color = Color(0.25, 0.25, 0.28)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_right = 2
	sb.corner_radius_bottom_left = 2
	sb.shadow_size = 4
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_offset = Vector2(2, 2)
	return sb

static func create_stone_button_normal() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.15, 0.18, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 4
	sb.border_color = Color(0.3, 0.3, 0.33)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 15
	sb.content_margin_right = 15
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

static func create_stone_button_hover() -> StyleBoxFlat:
	var sb = create_stone_button_normal()
	sb.bg_color = Color(0.22, 0.22, 0.25, 1.0)
	sb.border_color = Color(0.4, 0.4, 0.45)
	return sb

static func create_stone_button_pressed() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.12, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 4
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.2, 0.2, 0.23)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 15
	sb.content_margin_right = 15
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

static func apply_button_theme(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", create_stone_button_normal())
	btn.add_theme_stylebox_override("hover", create_stone_button_hover())
	btn.add_theme_stylebox_override("pressed", create_stone_button_pressed())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
