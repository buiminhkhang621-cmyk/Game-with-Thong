extends CanvasLayer

@onready var hp_bar: ProgressBar = $HPBar
@onready var info_label: Label = $InfoLabel

var _level: int = 1
var _kills: int = 0
var _score: int = 0
var _time: float = 0.0


func _ready() -> void:
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.kill_count_changed.connect(_on_kill_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.run_time_changed.connect(_on_time_changed)
	_refresh()


func _on_hp_changed(cur: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = cur


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
