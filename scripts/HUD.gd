extends CanvasLayer

@onready var hp_bar: ProgressBar = $HPBar
@onready var xp_bar: ProgressBar = $XPBar
@onready var info_label: Label = $InfoLabel

var spell_info_label: Label = null

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
	
	_refresh()


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
		
		var active_res = "None"
		var types = ["lightning", "ice", "dark", "void"]
		for t in types:
			if GameManager.has_rune_resonance(t):
				active_res = t.capitalize()
				break
		txt += "Resonance: " + active_res
		
		spell_info_label.text = txt
