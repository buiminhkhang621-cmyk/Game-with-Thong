class_name EnemyCommon
extends CharacterBody2D

@export var max_hp: float = 14.0
@export var speed: float = 65.0
@export var contact_dps: float = 10.0
@export var xp_value: int = 1
@export var hit_radius: float = 10.0
@export var color: Color = Color(0.77, 0.33, 0.30, 1.0)
@export var _is_flashing: bool = false
var _flash_timer: float = 0.0
var _original_color: Color
var _burn_dps: float = 0.0
var _burn_time: float = 0.0

var hp: float

const XP_ORB_SCENE := preload("res://scenes/XPOrb.tscn")
const DEATH_PARTICLE := preload("res://scenes/DeathParticle.tscn")


func _ready() -> void:
	hp = max_hp
	_original_color = color
	add_to_group("enemies")

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = hit_radius * 0.8
	col.shape = shape
	add_child(col)
	collision_layer = 4
	collision_mask = 1

	queue_redraw()


func _physics_process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
	var player = GameManager.player
	if player == null:
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()
	if dist > 0.001:
		velocity = (to_player / dist) * speed
		move_and_slide()

	if _burn_time > 0:
		_burn_time -= delta
		hp -= _burn_dps * delta
		if not _is_flashing:
			color = _original_color.lerp(Color(1.0, 0.4, 0.0), 0.5)
			queue_redraw()
		if hp <= 0:
			_die()

	if dist < hit_radius + player.hit_radius:
		player.take_damage(contact_dps * delta)


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		_die()


func apply_burn(dps: float, duration: float) -> void:
	_burn_dps = dps
	_burn_time = duration


func _die() -> void:
	GameManager.register_kill()
	var orb = XP_ORB_SCENE.instantiate()
	get_tree().current_scene.add_child(orb)
	orb.global_position = global_position
	orb.value = xp_value

	if DEATH_PARTICLE:
		var p = DEATH_PARTICLE.instantiate()
		get_tree().current_scene.add_child(p)
		p.global_position = global_position
		p.modulate = color

	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, hit_radius, color)
