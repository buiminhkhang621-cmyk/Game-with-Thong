extends Node2D

var current_ui: Node = null

func _ready() -> void:
	y_sort_enabled = true
	
	if GameManager.restart_run_on_ready:
		GameManager.restart_run_on_ready = false
		start_game(GameManager.current_class, GameManager.current_map_tier)
	else:
		get_tree().paused = true
		_show_main_menu()

func _show_main_menu() -> void:
	if current_ui: current_ui.queue_free()
	GameManager.stop_all_audio()
	get_tree().paused = true
	if has_node("HUD"):
		$HUD.hide()
	if has_node("GameOverScreen"):
		$GameOverScreen.hide()
	if has_node("LevelUpScreen"):
		$LevelUpScreen.hide()
		
	# Clean up any remaining entities from previous runs
	for group in ["enemies", "projectiles", "enemy_projectiles", "xp_orbs", "damage_numbers", "temporary_effects", "event_entities"]:
		for node in get_tree().get_nodes_in_group(group):
			node.queue_free()
	
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
	
	if has_node("HUD"):
		$HUD.show()
	
	if has_node("EnemySpawner"):
		$EnemySpawner.reset_spawner()
		
	GameManager.start_run_with_class_and_map(class_id, map_tier)
	
	if has_node("Background"):
		$Background.rebuild_dungeon()

var pause_menu_instance: Node = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if current_ui != null:
			return # In menu
		if GameManager.game_over or GameManager.paused_for_levelup:
			return
			
		if is_instance_valid(pause_menu_instance):
			get_tree().paused = false
			pause_menu_instance.queue_free()
			pause_menu_instance = null
		else:
			get_tree().paused = true
			var script = load("res://scripts/PauseMenuUI.gd")
			if script:
				pause_menu_instance = script.new()
				get_tree().root.add_child(pause_menu_instance)
