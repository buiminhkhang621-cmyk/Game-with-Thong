extends CanvasLayer

var goo_color: Color = Color(0.8, 0.2, 0.2)
var current_class: String = "berserker"
var draw_node: Control

var class_info = {
	"berserker": {
		"name": "BERSERKER",
		"desc": "-10% Max HP.\nDamage increases during combat.",
		"color": Color(0.8, 0.2, 0.2)
	},
	"vanguard": {
		"name": "VANGUARD",
		"desc": "Reduces damage taken by 20%.\nHealing reduced by 30%.",
		"color": Color(0.9, 0.8, 0.3)
	},
	"assassin": {
		"name": "ASSASSIN",
		"desc": "Fast movement, high critical damage.",
		"color": Color(0.3, 0.3, 0.8)
	},
	"void_mage": {
		"name": "VOID MAGE",
		"desc": "-10% Max HP.\nSpecializes in AoE damage and crowd control.",
		"color": Color(0.6, 0.2, 0.8)
	}
}

var info_title: Label
var info_desc: Label

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.06, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Particles
	var particles = CPUParticles2D.new()
	particles.position = Vector2(600, 700)
	particles.amount = 40
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(800, 1)
	particles.direction = Vector2(0, -1)
	particles.spread = 15.0
	particles.gravity = Vector2(0, -5)
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 20.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 3.0
	particles.color = Color(0.5, 0.5, 0.6, 0.2)
	particles.lifetime = 12.0
	add_child(particles)
	
	# Title
	var title = Label.new()
	title.text = "CLASS MANIFESTATION"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	
	var title_margin = MarginContainer.new()
	title_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_margin.grow_horizontal = Control.GROW_DIRECTION_END
	title_margin.grow_vertical = Control.GROW_DIRECTION_END
	title_margin.add_theme_constant_override("margin_left", 60)
	title_margin.add_theme_constant_override("margin_top", 40)
	title_margin.add_child(title)
	add_child(title_margin)
	
	# Main Layout HBox
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_CENTER)
	hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	hbox.custom_minimum_size = Vector2(1000, 450)
	hbox.position = Vector2(76, 120) # Center offset roughly
	hbox.add_theme_constant_override("separation", 40)
	add_child(hbox)
	
	# --- Left Panel: Class Buttons ---
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(280, 400)
	left_vbox.add_theme_constant_override("separation", 20)
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(left_vbox)
	
	_add_class_btn(left_vbox, "Berserker", "berserker")
	_add_class_btn(left_vbox, "Vanguard", "vanguard")
	_add_class_btn(left_vbox, "Assassin", "assassin")
	_add_class_btn(left_vbox, "Void Mage", "void_mage")
	
	# --- Center Panel: Goo Drawing on Stone Pedestal ---
	var center_panel = Control.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.custom_minimum_size = Vector2(350, 400)
	hbox.add_child(center_panel)
	
	draw_node = Control.new()
	draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_node.draw.connect(_on_draw_node_draw)
	center_panel.add_child(draw_node)
	
	# --- Right Panel: Info and Manifest Button ---
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(320, 400)
	right_panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	hbox.add_child(right_panel)
	
	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 25)
	right_margin.add_theme_constant_override("margin_right", 25)
	right_margin.add_theme_constant_override("margin_top", 25)
	right_margin.add_theme_constant_override("margin_bottom", 25)
	right_panel.add_child(right_margin)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 20)
	right_margin.add_child(right_vbox)
	
	var info_header = Label.new()
	info_header.text = "CHARACTERISTICS"
	info_header.add_theme_font_size_override("font_size", 18)
	info_header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	right_vbox.add_child(info_header)
	
	info_title = Label.new()
	info_title.add_theme_font_size_override("font_size", 24)
	info_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	info_title.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_vbox.add_child(info_title)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.3, 0.3, 0.35)
	right_vbox.add_child(divider)
	
	info_desc = Label.new()
	info_desc.add_theme_font_size_override("font_size", 16)
	info_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_vbox.add_child(info_desc)
	
	var space = Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(space)
	
	var confirm_btn = Button.new()
	confirm_btn.text = "MANIFEST"
	confirm_btn.custom_minimum_size = Vector2(0, 50)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	UITheme.apply_button_theme(confirm_btn)
	
	confirm_btn.pressed.connect(_on_confirm)
	right_vbox.add_child(confirm_btn)
	
	_update_info()

func _add_class_btn(parent: Control, text: String, id: String) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 60)
	btn.add_theme_font_size_override("font_size", 20)
	UITheme.apply_button_theme(btn)
	
	btn.pressed.connect(func():
		current_class = id
		goo_color = class_info[id]["color"]
		_update_info()
		draw_node.queue_redraw()
	)
	parent.add_child(btn)

func _update_info() -> void:
	var info = class_info[current_class]
	info_title.text = info["name"]
	info_desc.text = info["desc"]

func _on_confirm() -> void:
	var main = get_tree().current_scene
	if main.has_method("_show_map_selection"):
		main._show_map_selection(current_class)

func _on_draw_node_draw() -> void:
	var center = Vector2(175, 200) # center of 350x400
	
	# Draw Stone Pedestal
	draw_node.draw_rect(Rect2(center.x - 80, center.y + 40, 160, 20), Color(0.15, 0.15, 0.18))
	draw_node.draw_rect(Rect2(center.x - 90, center.y + 60, 180, 10), Color(0.1, 0.1, 0.12))
	
	# Glow effect
	draw_node.draw_circle(center, 70, Color(goo_color.r, goo_color.g, goo_color.b, 0.15))
	
	# Body
	draw_node.draw_circle(center, 40, goo_color)
	draw_node.draw_circle(center + Vector2(-15, -10), 8, Color.WHITE)
	draw_node.draw_circle(center + Vector2(15, -10), 8, Color.WHITE)
	draw_node.draw_circle(center + Vector2(-15, -10), 3, Color.BLACK)
	draw_node.draw_circle(center + Vector2(15, -10), 3, Color.BLACK)
	
	match current_class:
		"berserker":
			draw_node.draw_line(center + Vector2(30, 0), center + Vector2(50, -30), Color(0.3, 0.2, 0.1), 6)
			draw_node.draw_circle(center + Vector2(50, -30), 12, Color(0.7, 0.1, 0.1))
		"vanguard":
			draw_node.draw_rect(Rect2(center.x - 50, center.y - 10, 20, 40), Color(0.6, 0.6, 0.65), false, 4)
		"assassin":
			draw_node.draw_line(center + Vector2(20, 10), center + Vector2(40, 20), Color(0.2, 0.2, 0.25), 4)
		"void_mage":
			draw_node.draw_circle(center + Vector2(-50, -20), 8, Color.PURPLE)
			draw_node.draw_circle(center + Vector2(50, -20), 8, Color.PURPLE)
