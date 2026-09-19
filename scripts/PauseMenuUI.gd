class_name PauseMenuUI
extends CanvasLayer

var panel: Panel
var content_container: HBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	
	# Dim overlay
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.75)
	add_child(dim)
	
	# Center Container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# Main Window Panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(900, 560)
	panel.size = Vector2(900, 560)
	panel.add_theme_stylebox_override("panel", UITheme.create_stone_panel())
	center.add_child(panel)
	
	# Header
	var title = Label.new()
	title.text = "GAME PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 20)
	title.size = Vector2(900, 40)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	panel.add_child(title)
	
	var sub = Label.new()
	var m = int(GameManager.run_time / 60.0)
	var s = int(GameManager.run_time) % 60
	sub.text = "%s | Tier %d | Time: %d:%02d | Kills: %d" % [
		GameManager.current_class.capitalize(),
		GameManager.current_map_tier,
		m, s, GameManager.kills
	]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 60)
	sub.size = Vector2(900, 25)
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	panel.add_child(sub)
	
	# 3 Column Layout
	content_container = HBoxContainer.new()
	content_container.position = Vector2(30, 95)
	content_container.size = Vector2(840, 380)
	content_container.add_theme_constant_override("separation", 20)
	panel.add_child(content_container)
	
	_build_stats_column()
	_build_equipment_column()
	_build_relics_spells_column()
	
	# Bottom Buttons Bar
	var btn_bar = HBoxContainer.new()
	btn_bar.position = Vector2(30, 490)
	btn_bar.size = Vector2(840, 52)
	btn_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_bar.add_theme_constant_override("separation", 30)
	panel.add_child(btn_bar)
	
	var resume_btn = Button.new()
	UITheme.apply_button_theme(resume_btn)
	resume_btn.text = "RESUME"
	resume_btn.custom_minimum_size = Vector2(180, 48)
	resume_btn.pressed.connect(_on_resume_pressed)
	btn_bar.add_child(resume_btn)
	
	var settings_btn = Button.new()
	UITheme.apply_button_theme(settings_btn)
	settings_btn.text = "SETTINGS"
	settings_btn.custom_minimum_size = Vector2(180, 48)
	settings_btn.pressed.connect(_on_settings_pressed)
	btn_bar.add_child(settings_btn)
	
	var quit_btn = Button.new()
	UITheme.apply_button_theme(quit_btn)
	quit_btn.text = "ABANDON RUN"
	quit_btn.custom_minimum_size = Vector2(180, 48)
	quit_btn.pressed.connect(_on_quit_pressed)
	btn_bar.add_child(quit_btn)

func _build_stats_column() -> void:
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	content_container.add_child(col)
	
	var h = Label.new()
	h.text = "ATTRIBUTES"
	h.add_theme_font_size_override("font_size", 16)
	h.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	col.add_child(h)
	
	var player = GameManager.player
	var cur_hp = player.hp if player else 100.0
	var max_hp = player._effective_max_hp if player else 100.0
	var armor = min(0.75, GameManager.passive_value("armor")) * 100.0
	var dmg = GameManager.passive_value("damage") * 100.0
	var cdr = GameManager.passive_value("cooldown") * 100.0
	var spd = GameManager.passive_value("movespeed") * 100.0
	var crit = GameManager.passive_value("crit") * 100.0
	var pickup = GameManager.passive_value("pickup") * 100.0
	
	var stats = [
		["Health", "%.0f / %.0f" % [cur_hp, max_hp]],
		["Damage Bonus", "+%.1f%%" % dmg],
		["Cooldown Reduction", "-%.1f%%" % cdr],
		["Armor Reduction", "%.1f%%" % armor],
		["Critical Chance", "%.1f%%" % crit],
		["Movement Speed", "+%.1f%%" % spd],
		["Magnet Range", "+%.1f%%" % pickup],
		["Rerolls Remaining", str(GameManager.rerolls_left)],
		["Banishes Remaining", str(GameManager.banishes_left)]
	]
	
	for st in stats:
		var row = HBoxContainer.new()
		var lbl_name = Label.new()
		lbl_name.text = st[0]
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_name.add_theme_font_size_override("font_size", 13)
		lbl_name.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		
		var lbl_val = Label.new()
		lbl_val.text = st[1]
		lbl_val.add_theme_font_size_override("font_size", 13)
		lbl_val.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		
		row.add_child(lbl_name)
		row.add_child(lbl_val)
		col.add_child(row)

func _build_equipment_column() -> void:
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	content_container.add_child(col)
	
	var h = Label.new()
	h.text = "ARSENAL"
	h.add_theme_font_size_override("font_size", 16)
	h.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	col.add_child(h)
	
	var sub_w = Label.new()
	sub_w.text = "Active Weapons:"
	sub_w.add_theme_font_size_override("font_size", 12)
	sub_w.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	col.add_child(sub_w)
	
	for s in GameManager.active_skills:
		var txt = "%s (Lv %d)" % [s.data.display_name, s.level]
		if s.runes.size() > 0:
			var runes_str = ", ".join(s.runes).capitalize()
			txt += " [%s]" % runes_str
		var l = Label.new()
		l.text = "• " + txt
		l.add_theme_font_size_override("font_size", 12)
		col.add_child(l)
		
	if GameManager.active_skills.size() == 0:
		var l = Label.new()
		l.text = "None"
		l.add_theme_font_size_override("font_size", 12)
		col.add_child(l)
		
	var sub_p = Label.new()
	sub_p.text = "Passive Enhancements:"
	sub_p.add_theme_font_size_override("font_size", 12)
	sub_p.add_theme_color_override("font_color", Color(0.5, 0.9, 0.6))
	col.add_child(sub_p)
	
	for id in GameManager.passive_levels.keys():
		var data = GameManager._find_passive(id)
		var lvl = GameManager.passive_levels[id]
		var l = Label.new()
		l.text = "• %s (Lv %d)" % [data.display_name if data else id, lvl]
		l.add_theme_font_size_override("font_size", 12)
		col.add_child(l)
		
	if GameManager.passive_levels.size() == 0:
		var l = Label.new()
		l.text = "None"
		l.add_theme_font_size_override("font_size", 12)
		col.add_child(l)

func _build_relics_spells_column() -> void:
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	content_container.add_child(col)
	
	var h = Label.new()
	h.text = "SPELLS & RELICS"
	h.add_theme_font_size_override("font_size", 16)
	h.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	col.add_child(h)
	
	# Resonance
	var res = GameManager.get_active_resonances()
	var res_lbl = Label.new()
	res_lbl.text = "Resonance: " + (", ".join(res).capitalize() if res.size() > 0 else "None")
	res_lbl.add_theme_font_size_override("font_size", 13)
	res_lbl.add_theme_color_override("font_color", Color(0.9, 0.5, 1.0))
	col.add_child(res_lbl)
	
	# Crafted Spells
	var sp_hdr = Label.new()
	sp_hdr.text = "Weaved Spells:"
	sp_hdr.add_theme_font_size_override("font_size", 12)
	sp_hdr.add_theme_color_override("font_color", Color(0.8, 0.6, 0.9))
	col.add_child(sp_hdr)
	
	for sp in GameManager.crafted_spells:
		var l = Label.new()
		l.text = "• %s + %s" % [sp.vong, sp.net]
		l.add_theme_font_size_override("font_size", 12)
		col.add_child(l)
	if GameManager.crafted_spells.size() == 0:
		var l = Label.new()
		l.text = "None"
		l.add_theme_font_size_override("font_size", 12)
		col.add_child(l)
		
	# Relics
	var r_hdr = Label.new()
	r_hdr.text = "Active Relics:"
	r_hdr.add_theme_font_size_override("font_size", 12)
	r_hdr.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	col.add_child(r_hdr)
	
	var relic_counts: Dictionary = {}
	for r in GameManager.active_relics:
		relic_counts[r] = relic_counts.get(r, 0) + 1
		
	for r in relic_counts.keys():
		var count = relic_counts[r]
		var l = Label.new()
		var name_str = r.replace("_", " ").capitalize()
		l.text = "• %s (x%d)" % [name_str, count] if count > 1 else "• %s" % name_str
		l.add_theme_font_size_override("font_size", 12)
		col.add_child(l)
	if GameManager.active_relics.size() == 0:
		var l = Label.new()
		l.text = "None"
		l.add_theme_font_size_override("font_size", 12)
		col.add_child(l)

func _on_resume_pressed() -> void:
	get_tree().paused = false
	queue_free()

func _on_settings_pressed() -> void:
	var script = load("res://scripts/SettingsUI.gd")
	if script:
		var s = script.new()
		s.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(s)

func _on_quit_pressed() -> void:
	get_tree().paused = false
	GameManager.game_over = false
	GameManager.stop_all_audio()
	GameManager.restart_run_on_ready = false
	get_tree().reload_current_scene()
