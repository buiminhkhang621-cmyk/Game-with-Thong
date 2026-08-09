extends CanvasLayer

@onready var hp_bar: ProgressBar = $HPBar
@onready var xp_bar: ProgressBar = $XPBar
@onready var info_label: Label = $InfoLabel

var spell_info_label: Label = null
var fps_label: Label = null

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
