extends CanvasLayer

@onready var choices_box: VBoxContainer = $Choices

var _current_choices: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameManager.leveled_up_choices.connect(_on_choices)


func _on_choices(choices: Array) -> void:
	_current_choices = choices
	for c in choices_box.get_children():
		c.queue_free()

	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = "[%s]\n%s\n%s" % [choice.tag, choice.title, choice.desc]
		btn.custom_minimum_size = Vector2(360, 70)
		btn.pressed.connect(_on_picked.bind(i))
		choices_box.add_child(btn)

	visible = true


func _on_picked(index: int) -> void:
	GameManager.apply_choice(_current_choices[index])
	visible = false
