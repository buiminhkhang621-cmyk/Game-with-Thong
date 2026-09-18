class_name EnemyProjectile
extends Node2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 15.0
var life: float = 2.0
var _color: Color = Color(0.2, 0.6, 1.0)

func setup(vel: Vector2, dmg: float, c: Color = Color(1.0, 0.2, 0.2)) -> void:
	velocity = vel
	damage = dmg
	_color = c
	rotation = velocity.angle()

func _ready() -> void:
	add_to_group("enemy_projectiles")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Sprite/NPC/sniper_projectile.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup:
		return
		
	life -= delta
	if life <= 0.0:
		queue_free()
		return

	global_position += velocity * delta

	var player = GameManager.player
	if player:
		var r_sq = (6.0 + player.hit_radius) * (6.0 + player.hit_radius)
		if global_position.distance_squared_to(player.global_position) < r_sq:
			player.take_damage(damage, true) # true means ground attack, so jumping dodges it
			queue_free()

func _draw() -> void:
	pass
