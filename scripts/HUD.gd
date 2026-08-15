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
	
	spell_info_label = Label.new()
	spell_info_label.position = Vector2(10, 100)
	spell_info_label.add_theme_font_size_override("font_size", 14)
	add_child(spell_info_label)
	
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

func _process(_delta: float) -> void:
	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _on_hp_changed(cur: float, max_hp: float) -> void:
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
	combo_label.show()
	combo_label.text = "%d Hits!\n%.1f Dmg" % [hits, total_damage]
	
	# Animate bounce
	if combo_tween:
		combo_tween.kill()
	combo_tween = create_tween()
	combo_label.scale = Vector2(1.5, 1.5)
	combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)


func _on_combo_reset() -> void:
	if not combo_label:
		return
	if combo_tween:
		combo_tween.kill()
	combo_tween = create_tween()
	combo_tween.tween_property(combo_label, "modulate:a", 0.0, 0.5)
	combo_tween.tween_callback(func():
		combo_label.hide()
		combo_label.modulate.a = 1.0
	)


func _refresh() -> void:
	var m := int(_time / 60.0)
	var s := int(_time) % 60
	info_label.text = "Lv %d  |  %d:%02d  |  %d  |  %d" % [_level, m, s, _kills, _score]
	
	if spell_info_label:
		var txt = ""
		if GameManager.collected_vong.size() > 0 or GameManager.collected_net.size() > 0:
			txt += "Seals: " + str(GameManager.collected_vong) + "\n"
			txt += "Crests: " + str(GameManager.collected_net) + "\n"
		
		var spells = []
		for sp in GameManager.crafted_spells:
			spells.append(sp.vong + " + " + sp.net)
		if spells.size() > 0:
			txt += "Spells: " + str(spells) + "\n"
		
		var active_res = []
		var types = ["lightning", "ice", "dark", "void"]
		for t in types:
			if GameManager.has_rune_resonance(t):
				active_res.append(t.capitalize())
		txt += "Resonance: " + (", ".join(active_res) if active_res.size() > 0 else "None")
		
		spell_info_label.text = txt
