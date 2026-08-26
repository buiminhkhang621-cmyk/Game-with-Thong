extends Control
class_name ArsenalHUD

var weapons_container: HBoxContainer
var passives_container: GridContainer
var _refresh_timer: float = 0.0

const ELEMENT_COLORS = {
	"lightning": Color(1.0, 0.88, 0.25),
	"ice": Color(0.35, 0.85, 1.0),
	"dark": Color(0.75, 0.25, 0.95),
	"void": Color(0.95, 0.3, 1.0)
}

func _ready() -> void:
	# Bottom Left HUD
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	position = Vector2(16, -110) # Offset from bottom left
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_vbox)
	
	# Row 1: Weapons & Active Skills
	weapons_container = HBoxContainer.new()
	weapons_container.add_theme_constant_override("separation", 8)
	weapons_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(weapons_container)
	
	# Row 2: Collected Passives & Relics (Grid 8 columns)
	passives_container = GridContainer.new()
	passives_container.columns = 8
	passives_container.add_theme_constant_override("h_separation", 6)
	passives_container.add_theme_constant_override("v_separation", 6)
	passives_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(passives_container)
	
	refresh()

func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.4
		refresh()

func refresh() -> void:
	_update_weapons()
	_update_passives_and_relics()

func _update_weapons() -> void:
	for c in weapons_container.get_children():
		c.queue_free()
		
	for s in GameManager.active_skills:
		if s == null or not s.has("data") or s.data == null:
			continue
		var skill_id: String = s.data.id
		var level: int = s.level
		var rune: String = s.runes[0] if s.has("runes") and s.runes.size() > 0 else ""
		
		var slot = _create_weapon_slot(skill_id, level, rune)
		weapons_container.add_child(slot)

func _create_weapon_slot(skill_id: String, level: int, rune: String) -> Control:
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(48, 48)
	
	# Antique Gilded Obsidian Slot
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.11, 0.95)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 3
	
	var border_col = Color(0.65, 0.52, 0.28) # Antique Gold default
	if rune != "" and ELEMENT_COLORS.has(rune):
		border_col = ELEMENT_COLORS[rune]
	sb.border_color = border_col
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	sb.shadow_size = 6
	sb.shadow_color = Color(border_col.r * 0.4, border_col.g * 0.4, border_col.b * 0.4, 0.4)
	slot.add_theme_stylebox_override("panel", sb)
	
	# Icon drawer
	var icon = Control.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	var icon_color = Color(0.95, 0.92, 0.82)
	if rune != "" and ELEMENT_COLORS.has(rune):
		icon_color = ELEMENT_COLORS[rune].lerp(Color.WHITE, 0.35)
	icon.draw.connect(func():
		UpgradeIcons.draw_icon(icon, skill_id, Vector2(24, 24), 28.0, icon_color)
	)
	slot.add_child(icon)
	
	# Level badge
	var lvl_lbl = Label.new()
	lvl_lbl.text = "Lv%d" % level
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lvl_lbl.position = Vector2(0, 32)
	lvl_lbl.size = Vector2(44, 16)
	lvl_lbl.add_theme_font_size_override("font_size", 9)
	lvl_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42))
	lvl_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lvl_lbl.add_theme_constant_override("outline_size", 3)
	slot.add_child(lvl_lbl)
	
	# Rune emblem indicator
	if rune != "":
		var rune_dot = ColorRect.new()
		rune_dot.position = Vector2(4, 4)
		rune_dot.size = Vector2(8, 8)
		rune_dot.color = ELEMENT_COLORS.get(rune, Color.WHITE)
		slot.add_child(rune_dot)
		
	return slot

func _update_passives_and_relics() -> void:
	for c in passives_container.get_children():
		c.queue_free()
		
	# 1. Passive Buffs
	for passive_id in GameManager.passive_levels.keys():
		var lvl = GameManager.passive_levels[passive_id]
		if lvl > 0:
			var tile = _create_passive_tile(passive_id, lvl, Color(0.28, 0.55, 0.68)) # Star Sapphire
			passives_container.add_child(tile)
			
	# 2. Unique Relics
	var relic_counts = {}
	for r in GameManager.active_relics:
		relic_counts[r] = relic_counts.get(r, 0) + 1
		
	for relic_id in relic_counts.keys():
		var count = relic_counts[relic_id]
		var tile = _create_passive_tile(relic_id, count, Color(0.65, 0.28, 0.85)) # Imperial Void Relic
		passives_container.add_child(tile)

func _create_passive_tile(id: String, count: int, bg_base_col: Color) -> Control:
	var tile = Panel.new()
	tile.custom_minimum_size = Vector2(32, 32)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.11, 0.95)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 2
	sb.border_color = bg_base_col
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	tile.add_theme_stylebox_override("panel", sb)
	
	# Icon
	var icon = Control.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	var icon_color = bg_base_col.lerp(Color.WHITE, 0.45)
	icon.draw.connect(func():
		UpgradeIcons.draw_icon(icon, id, Vector2(16, 16), 18.0, icon_color)
	)
	tile.add_child(icon)
	
	# Stack count
	if count > 1:
		var cnt_lbl = Label.new()
		cnt_lbl.text = "%d" % count
		cnt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt_lbl.position = Vector2(0, 16)
		cnt_lbl.size = Vector2(30, 14)
		cnt_lbl.add_theme_font_size_override("font_size", 9)
		cnt_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
		cnt_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		cnt_lbl.add_theme_constant_override("outline_size", 2)
		tile.add_child(cnt_lbl)
		
	return tile
