class_name UITheme
extends RefCounted

# Ancient Post-Apocalyptic Eldritch & Gilded Obsidian Theme

static func create_stone_panel() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.11, 0.96)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 4
	sb.border_color = Color(0.65, 0.52, 0.28) # Weathered Ancient Gold
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	sb.shadow_size = 12
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.75)
	sb.shadow_offset = Vector2(0, 4)
	return sb

static func create_stone_button_normal() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.16, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 3
	sb.border_color = Color(0.55, 0.44, 0.25) # Antique Bronze
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_size = 4
	sb.shadow_color = Color(0, 0, 0, 0.5)
	return sb

static func create_stone_button_hover() -> StyleBoxFlat:
	var sb = create_stone_button_normal()
	sb.bg_color = Color(0.18, 0.17, 0.22, 1.0)
	sb.border_color = Color(0.95, 0.78, 0.38) # Gleaming Gold
	sb.shadow_size = 8
	sb.shadow_color = Color(0.9, 0.7, 0.2, 0.35)
	return sb

static func create_stone_button_pressed() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.10, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 3
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.4, 0.32, 0.18)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 11
	sb.content_margin_bottom = 9
	return sb

static func apply_button_theme(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", create_stone_button_normal())
	btn.add_theme_stylebox_override("hover", create_stone_button_hover())
	btn.add_theme_stylebox_override("pressed", create_stone_button_pressed())
	btn.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.65))
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 3)
