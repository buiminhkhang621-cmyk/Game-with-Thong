extends Node2D

var current_ui: Node = null

func _ready() -> void:
	$DevPanel.hide()
	y_sort_enabled = true
	# Hide player/gameplay initially
	get_tree().paused = true
	_show_main_menu()

func _show_main_menu() -> void:
	if current_ui: current_ui.queue_free()
	
	var script = load("res://scripts/MainMenuUI.gd")
	if script:
		current_ui = script.new()
		get_tree().root.call_deferred("add_child", current_ui)

func _show_class_selection() -> void:
	if current_ui: current_ui.queue_free()
	
	var script = load("res://scripts/ClassSelectionUI.gd")
	if script:
		current_ui = script.new()
		get_tree().root.call_deferred("add_child", current_ui)

func _show_quests() -> void:
	if current_ui: current_ui.queue_free()
	
	var script = load("res://scripts/QuestsUI.gd")
	if script:
		current_ui = script.new()
		get_tree().root.call_deferred("add_child", current_ui)

func _show_settings() -> void:
	if current_ui: current_ui.queue_free()
	
	var script = load("res://scripts/SettingsUI.gd")
	if script:
		current_ui = script.new()
		get_tree().root.call_deferred("add_child", current_ui)

func _show_codex() -> void:
	if current_ui: current_ui.queue_free()
	
	var script = load("res://scripts/CodexUI.gd")
	if script:
		current_ui = script.new()
		get_tree().root.call_deferred("add_child", current_ui)
		
func _show_map_selection(class_id: String) -> void:
	if current_ui: current_ui.queue_free()
	
	var script = load("res://scripts/MapSelectionUI.gd")
	if script:
		current_ui = script.new()
		current_ui.selected_class = class_id
		get_tree().root.call_deferred("add_child", current_ui)

func start_game(class_id: String, map_tier: int) -> void:
	if current_ui: current_ui.queue_free()
	current_ui = null
	
	if has_node("DevPanel"):
		$DevPanel.show()
	
	GameManager.start_run_with_class_and_map(class_id, map_tier)
