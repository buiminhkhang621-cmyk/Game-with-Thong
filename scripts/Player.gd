class_name Player
extends CharacterBody2D

@export var move_speed: float = 170.0
@export var base_max_hp: float = 100.0

var hp: float
var hit_radius: float = 12.0

var _effective_max_hp: float
var _shake_intensity: float = 0.0

@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	hp = base_max_hp
	_effective_max_hp = base_max_hp
	GameManager.register_player(self)
	GameManager.level_changed.connect(_on_level_changed)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = hit_radius * 0.8
	col.shape = shape
	add_child(col)

	collision_layer = 2
	collision_mask = 1

	queue_redraw()
	GameManager.hp_changed.emit(hp, _effective_max_hp)


func _physics_process(delta: float) -> void:
	_update_max_hp()

	if _shake_intensity > 0.0:
		_shake_intensity = lerpf(_shake_intensity, 0.0, delta * 10.0)
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_intensity
	else:
		camera.offset = Vector2.ZERO

	if GameManager.game_over or GameManager.paused_for_levelup:
		return

	var dir := Vector2.ZERO
	dir.x = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) \
		- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	dir.y = float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) \
		- float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	if dir.length() > 0.0:
		dir = dir.normalized()

	var speed_mult := move_speed * (1.0 + GameManager.passive_value("movespeed"))
	velocity = dir * speed_mult
	move_and_slide()


func _update_max_hp() -> void:
	var new_max := base_max_hp + GameManager.passive_value("maxhp")
	if new_max != _effective_max_hp:
		hp += (new_max - _effective_max_hp)
		_effective_max_hp = new_max
		hp = min(hp, _effective_max_hp)
		GameManager.hp_changed.emit(hp, _effective_max_hp)


func take_damage(amount: float) -> void:
	if GameManager.game_over:
		return
	hp -= amount
	_shake_intensity = 15.0
	GameManager.hp_changed.emit(hp, _effective_max_hp)
	if hp <= 0.0:
		hp = 0.0
		GameManager.on_player_died()


func heal(amount: float) -> void:
	hp = min(_effective_max_hp, hp + amount)
	GameManager.hp_changed.emit(hp, _effective_max_hp)


func _on_level_changed(_new_level: int) -> void:
	heal(8.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, hit_radius, Color(0.94, 0.79, 0.37, 1.0))
