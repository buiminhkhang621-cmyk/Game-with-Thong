extends CanvasLayer

@onready var hp_bar: ProgressBar = $HPBar
@onready var xp_bar: ProgressBar = $XPBar
@onready var info_label: Label = $InfoLabel

var spell_info_label: Label = null
var fps_label: Label = null
var combo_label: Label = null
var combo_tween: Tween = null

var _level: int = 1
var _kills: int = 0
var _score: int = 0
var _time: float = 0.0


func _ready() -> void:
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.kill_count_changed.connect(_on_kill_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.run_time_changed.connect(_on_time_changed)
	GameManager.combo_updated.connect(_on_combo_updated)
	GameManager.combo_reset.connect(_on_combo_reset)
	GameManager.boss_spawned.connect(_on_boss_spawned)
	GameManager.wave_event_triggered.connect(_on_wave_event_triggered)
	GameManager.blood_moon_state_changed.connect(_on_blood_moon_changed)
	GameManager.abyssal_fog_state_changed.connect(_on_abyssal_fog_changed)
	
	_setup_blood_moon_vignette()
	_setup_abyssal_fog_vignette()
	_setup_damage_flash()
	
	var rune_radar = RuneRadar.new()
	add_child(rune_radar)
	
	var arsenal_hud = ArsenalHUD.new()
	add_child(arsenal_hud)
	
	if xp_bar:
		xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
		xp_bar.offset_left = 0
		xp_bar.offset_top = 0
		xp_bar.offset_right = 0
		xp_bar.offset_bottom = 8
	
	runes_display = Control.new()
	runes_display.position = Vector2(10, 92)
	runes_display.custom_minimum_size = Vector2(250, 42)
	runes_display.draw.connect(func():
		var time = Time.get_ticks_msec() / 1000.0
		var pulse = 0.85 + sin(time * 3.0) * 0.15
		var unlocked = GameManager.unlocked_runes
		for i in range(unlocked.size()):
			var r_id = unlocked[i]
			var center = Vector2(22 + i * 46, 20)
			# Background runic medallion plate
			runes_display.draw_circle(center, 18.0, Color(0.1, 0.12, 0.15, 0.8))
			runes_display.draw_arc(center, 18.0, 0, TAU, 24, Color(0.3, 0.35, 0.45, 0.6), 1.5)
			UpgradeIcons.draw_mythic_rune_glyph(runes_display, r_id, center, 12.0, Color.WHITE, pulse)
	)
	add_child(runes_display)

	spell_info_label = Label.new()
	spell_info_label.position = Vector2(10, 140)
	spell_info_label.add_theme_font_size_override("font_size", 13)
	add_child(spell_info_label)
	
	shield_display = Control.new()
	shield_display.position = Vector2(235, 18)
	shield_display.custom_minimum_size = Vector2(90, 24)
	shield_display.draw.connect(func():
		var armor_val = min(0.75, GameManager.passive_value("armor")) + GameManager.elixir_armor_bonus
		if armor_val > 0.01:
			var s_tex = UITheme.load_texture("res://Sprite/weapon/shield.png")
			if s_tex:
				var sz = Vector2(14, 21)
				shield_display.draw_texture_rect(s_tex, Rect2(0, 0, sz.x, sz.y), false, Color.WHITE)
			var font = ThemeDB.fallback_font
			if font:
				shield_display.draw_string(font, Vector2(18, 15), "%d%% DEF" % int(armor_val * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.95, 0.85, 0.55))
	)
	add_child(shield_display)
	
	fps_label = Label.new()
	add_child(fps_label)
	fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fps_label.offset_left = -100
	fps_label.offset_top = 10
	fps_label.offset_right = -10
	fps_label.offset_bottom = 30
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps_label.add_theme_font_size_override("font_size", 16)
	fps_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	
	combo_label = Label.new()
	add_child(combo_label)
	combo_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	combo_label.offset_left = -300
	combo_label.offset_top = 40
	combo_label.offset_right = -10
	combo_label.offset_bottom = 100
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combo_label.add_theme_font_size_override("font_size", 24)
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	combo_label.add_theme_color_override("font_outline_color", Color.BLACK)
	combo_label.add_theme_constant_override("outline_size", 4)
	combo_label.pivot_offset = Vector2(290, 30) # Right center pivot (width is ~290, height is ~60)
	combo_label.hide()
	
	_on_hp_changed(GameManager.player.hp if GameManager.player else 100, GameManager.player._effective_max_hp if GameManager.player else 100)
	_on_xp_changed(GameManager.xp, GameManager.xp_to_next)
	_on_level_changed(GameManager.level)
	_on_kill_changed(GameManager.kills)
	_on_score_changed(GameManager.score)
	_on_time_changed(GameManager.run_time)
	
	_refresh()

var runes_display: Control = null
var shield_display: Control = null

func _process(_delta: float) -> void:
	if fps_label:
		fps_label.visible = GameManager.setting_show_fps
		if fps_label.visible:
			fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	if runes_display:
		runes_display.queue_redraw()
	if shield_display:
		shield_display.queue_redraw()


var damage_flash_rect: ColorRect = null
var _last_hp: float = 100.0

func _setup_damage_flash() -> void:
	damage_flash_rect = ColorRect.new()
	damage_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash_rect.color = Color(0.95, 0.05, 0.05, 0.0)
	damage_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_flash_rect)

func _flash_damage_vignette() -> void:
	if not damage_flash_rect: return
	damage_flash_rect.color = Color(0.9, 0.0, 0.0, 0.38)
	var tween = get_tree().create_tween()
	tween.tween_property(damage_flash_rect, "color:a", 0.0, 0.3)

func _on_hp_changed(cur: float, max_hp: float) -> void:
	if _last_hp > cur and (_last_hp - cur) >= 12.0:
		_flash_damage_vignette()
	_last_hp = cur
	hp_bar.max_value = max_hp
	hp_bar.value = cur


func _on_xp_changed(cur: int, needed: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = cur


func _on_level_changed(l: int) -> void:
	_level = l
	_refresh()


func _on_kill_changed(k: int) -> void:
	_kills = k
	_refresh()


func _on_time_changed(t: float) -> void:
	_time = t
	_refresh()


func _on_score_changed(s: int) -> void:
	_score = s
	_refresh()


func _on_combo_updated(total_damage: float, hits: int) -> void:
	if not combo_label:
		return
	combo_label.modulate.a = 1.0
	combo_label.show()
	combo_label.text = "%d Hits!\n%.1f Dmg" % [hits, total_damage]
	
	# Animate bounce
	if combo_tween:
		combo_tween.kill()
	combo_tween = create_tween()
	combo_label.scale = Vector2(1.5, 1.5)
	combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)


func _on_combo_reset() -> void:
	if combo_label and combo_label.visible:
		if combo_tween:
			combo_tween.kill()
		combo_tween = get_tree().create_tween()
		combo_tween.tween_property(combo_label, "modulate:a", 0.0, 0.5)
		combo_tween.tween_callback(func():
			combo_label.hide()
			combo_label.modulate.a = 1.0
		)

var blood_moon_rect: ColorRect = null
var abyssal_fog_rect: ColorRect = null
var active_banner_node: Node = null

func _setup_blood_moon_vignette() -> void:
	blood_moon_rect = ColorRect.new()
	blood_moon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	blood_moon_rect.color = Color(0.85, 0.05, 0.05, 0.0)
	blood_moon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(blood_moon_rect)

func _setup_abyssal_fog_vignette() -> void:
	abyssal_fog_rect = ColorRect.new()
	abyssal_fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	abyssal_fog_rect.color = Color(0.05, 0.02, 0.1, 0.0) # Deep dark eerie fog
	abyssal_fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(abyssal_fog_rect)

func _on_blood_moon_changed(active: bool) -> void:
	if not blood_moon_rect: return
	var tween = get_tree().create_tween()
	if active:
		tween.tween_property(blood_moon_rect, "color:a", 0.18, 1.5)
	else:
		tween.tween_property(blood_moon_rect, "color:a", 0.0, 1.5)

func _on_abyssal_fog_changed(active: bool) -> void:
	if not abyssal_fog_rect: return
	var tween = get_tree().create_tween()
	if active:
		tween.tween_property(abyssal_fog_rect, "color:a", 0.45, 1.8)
	else:
		tween.tween_property(abyssal_fog_rect, "color:a", 0.0, 1.5)

func _on_wave_event_triggered(title_text: String, subtitle_text: String) -> void:
	if is_instance_valid(active_banner_node):
		active_banner_node.queue_free()
		
	var banner = PanelContainer.new()
	active_banner_node = banner
	var v_width = get_viewport().get_visible_rect().size.x
	var banner_w = min(600.0, v_width - 40.0)
	banner.position = Vector2((v_width - banner_w) * 0.5, -100)
	banner.size = Vector2(banner_w, 70)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.1, 0.95)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 2
	sb.border_width_bottom = 3
	sb.border_color = Color(0.9, 0.25, 0.25)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	banner.add_theme_stylebox_override("panel", sb)
	add_child(banner)
	
	var vbox = VBoxContainer.new()
	banner.add_child(vbox)
	
	var t_lbl = Label.new()
	t_lbl.text = title_text
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lbl.add_theme_font_size_override("font_size", 18)
	t_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	t_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	t_lbl.add_theme_constant_override("outline_size", 4)
	vbox.add_child(t_lbl)
	
	var s_lbl = Label.new()
	s_lbl.text = subtitle_text
	s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s_lbl.add_theme_font_size_override("font_size", 12)
	s_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	vbox.add_child(s_lbl)
	
	var tween = get_tree().create_tween()
	tween.tween_property(banner, "position:y", 25.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(3.2)
	tween.tween_property(banner, "position:y", -110.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(banner.queue_free)

func _on_boss_spawned() -> void:
	pass


func _refresh() -> void:
	var m := int(_time / 60.0)
	var s := int(_time) % 60
	info_label.text = "Lv %d  |  %d:%02d  |  %d  |  %d" % [_level, m, s, _kills, _score]
	
	if spell_info_label:
		var lines = []
		var spells = []
		for sp in GameManager.crafted_spells:
			spells.append("✦ SPELL: %s + %s" % [sp.vong.to_upper(), sp.net.to_upper()])
		if spells.size() > 0:
			lines.append("\n".join(spells))
		
		var active_res = []
		var types = ["lightning", "ice", "dark", "void"]
		for t in types:
			if GameManager.has_rune_resonance(t):
				active_res.append("✦ RESONANCE: " + t.to_upper())
		if active_res.size() > 0:
			lines.append("\n".join(active_res))
			
		spell_info_label.text = "\n".join(lines)
		spell_info_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
		spell_info_label.add_theme_color_override("font_outline_color", Color.BLACK)
		spell_info_label.add_theme_constant_override("outline_size", 3)
