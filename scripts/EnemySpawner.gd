extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval_start: float = 1.0
@export var spawn_interval_min: float = 0.1
@export var max_enemies: int = 250
@export var spawn_radius: float = 400.0

const ENEMY_FAST = preload("res://scenes/EnemyFast.tscn")
const ENEMY_TANK = preload("res://scenes/EnemyTank.tscn")
const ENEMY_RANGED = preload("res://scenes/EnemyRanged.tscn")

var _timer: float = 0.0

func _process(delta: float) -> void:
	if GameManager.game_over or GameManager.paused_for_levelup or GameManager.player == null:
		return
	if enemy_scene == null:
		return

	_timer += delta
	var interval: float = max(spawn_interval_min, spawn_interval_start - GameManager.run_time * 0.005)

	if _timer >= interval and get_tree().get_nodes_in_group("enemies").size() < max_enemies:
		_timer = 0.0
		var batch_size = 1 + int(GameManager.run_time / 60.0) * 2
		for i in range(batch_size):
			if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
				break
			_spawn()

func _spawn() -> void:
	var angle := randf() * TAU
	var pos: Vector2 = GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius

	var scene_to_spawn = enemy_scene
	var r = randf()
	if r < 0.2:
		scene_to_spawn = ENEMY_FAST
	elif r < 0.4:
		scene_to_spawn = ENEMY_RANGED
	elif r < 0.55:
		scene_to_spawn = ENEMY_TANK

	var e = scene_to_spawn.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	e.max_hp += floor(GameManager.run_time / 30.0) * 3.0
	e.hp = e.max_hp
