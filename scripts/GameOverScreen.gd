extends CanvasLayer

@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel


func _ready() -> void:
	visible = false
	GameManager.player_died.connect(_on_player_died)


func _on_player_died() -> void:
	var m := int(GameManager.run_time / 60.0)
	var s := int(GameManager.run_time) % 60
	stats_label.text = "Thời gian sống sót: %d:%02d\nSố quái hạ gục: %d\nCấp độ đạt được: %d" \
		% [m, s, GameManager.kills, GameManager.level]
	visible = true


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
