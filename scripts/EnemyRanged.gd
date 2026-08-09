class_name EnemyRanged
extends CharacterBody2D

@export var max_hp: float = 10.0
@export var speed: float = 85.0
@export var contact_dps: float = 5.0
@export var xp_value: int = 2
@export var hit_radius: float = 12.0
@export var color: Color = Color(0.2, 0.6, 1.0, 1.0)

@export var _is_flashing: bool = false
var _flash_timer: float = 0.0
var _original_color: Color
var _burn_dps: float = 0.0
var _burn_time: float = 0.0

@export var attack_range: float = 180.0
@export var fire_cooldown: float = 2.0

var hp: float
var _fire_timer: float = 0.0

const XP_ORB_SCENE := preload("res://scenes/XPOrb.tscn")
const DEATH_PARTICLE := preload("res://scenes/DeathParticle.tscn")
const PROJECTILE_SCENE := preload("res://scenes/EnemyProjectile.tscn")

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
	_fire_timer = randf() * fire_cooldown

func _physics_process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
	var player = GameManager.player
	if player == null:
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()

	if dist > attack_range:
		velocity = (to_player / dist) * speed
	elif dist < attack_range * 0.5:
		velocity = -(to_player / dist) * (speed * 0.5)
	else:
		velocity = Vector2.ZERO

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

	_fire_timer -= delta
	if _fire_timer <= 0.0 and dist <= attack_range + 50.0:
		_fire_timer = fire_cooldown
		_fire(to_player.normalized())

func _fire(dir: Vector2) -> void:
	if PROJECTILE_SCENE == null: return
	var proj = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.setup(dir * 180.0, 15.0, color)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		_die()

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

func apply_burn(dps: float, duration: float) -> void:
	_burn_dps = dps
	_burn_time = duration

func _draw() -> void:
	var hex = PackedVector2Array()
	for i in range(6):
		var ang = TAU / 6.0 * i
		hex.append(Vector2(cos(ang), sin(ang)) * hit_radius)
	draw_polygon(hex, PackedColorArray([color, color, color, color, color, color]))
