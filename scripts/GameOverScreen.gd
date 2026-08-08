extends CanvasLayer

@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel


func _ready() -> void:
	visible = false
	GameManager.player_died.connect(_on_player_died)


func _on_player_died() -> void:
	var m := int(GameManager.run_time / 60.0)
	var s := int(GameManager.run_time) % 60
	stats_label.text = "Time Survived: %d:%02d\nEnemies Defeated: %d\nLevel Reached: %d" \
		% [m, s, GameManager.kills, GameManager.level]
	visible = true


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
