extends CanvasLayer

@onready var god_mode_check = $MarginContainer/VBoxContainer/GodModeCheck
@onready var level_up_btn = $MarginContainer/VBoxContainer/LevelUpBtn

func _ready() -> void:
	god_mode_check.toggled.connect(_on_god_mode_toggled)
	level_up_btn.pressed.connect(_on_level_up_pressed)

func _on_god_mode_toggled(button_pressed: bool) -> void:
	if GameManager.player:
		GameManager.player.god_mode = button_pressed

func _on_level_up_pressed() -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
	GameManager.grant_xp(GameManager.xp_to_next)
