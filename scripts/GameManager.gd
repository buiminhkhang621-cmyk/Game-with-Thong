extends Node

signal hp_changed(current: float, max_hp: float)
signal xp_changed(current: int, needed: int)
signal level_changed(new_level: int)
signal kill_count_changed(count: int)
signal run_time_changed(seconds: float)
signal leveled_up_choices(choices: Array)
signal player_died
signal score_changed(new_score: int)

const MAX_ACTIVE_SLOTS := 6
const MAX_PASSIVE_SLOTS := 6

var player: Node = null

var level: int = 1
var xp: int = 0
var xp_to_next: int = 8
var kills: int = 0
var score: int = 0
var run_time: float = 0.0
var game_over: bool = false
var paused_for_levelup: bool = false
var pending_level_ups: int = 0

var active_skills: Array = []
var passive_levels: Dictionary = {}

var available_active_skills: Array = [
	load("res://resources/skills/orbit_blade.tres"),
	load("res://resources/skills/piercing_bolt.tres"),
	load("res://resources/skills/nova.tres"),
	load("res://resources/skills/aoe_pulse.tres"),
]
var available_passive_skills: Array = [
	load("res://resources/passives/damage_up.tres"),
	load("res://resources/passives/cooldown_down.tres"),
	load("res://resources/passives/max_hp_up.tres"),
	load("res://resources/passives/move_speed_up.tres"),
	load("res://resources/passives/pickup_range_up.tres"),
]


func _process(delta: float) -> void:
	if game_over or paused_for_levelup:
		return
	run_time += delta
	run_time_changed.emit(run_time)


func register_player(p: Node) -> void:
	player = p


func start_run() -> void:
	level = 1
	xp = 0
	xp_to_next = 8
	kills = 0
	score = 0
	run_time = 0.0
	game_over = false
	paused_for_levelup = false
	pending_level_ups = 0
	active_skills.clear()
	passive_levels.clear()
	if available_active_skills.size() > 0:
		active_skills.append({"data": available_active_skills[0], "level": 1})
	level_changed.emit(level)
	kill_count_changed.emit(kills)
	score_changed.emit(score)


func grant_xp(amount: int) -> void:
	if game_over:
		return
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = 8 + level * 5
		level_changed.emit(level)
		pending_level_ups += 1

	if pending_level_ups > 0 and not paused_for_levelup:
		_trigger_level_up()

	xp_changed.emit(xp, xp_to_next)


func register_kill() -> void:
	kills += 1
	kill_count_changed.emit(kills)
	add_score(10)


func add_score(amount: int) -> void:
	if game_over:
		return
	score += amount
	score_changed.emit(score)


func on_player_died() -> void:
	game_over = true
	player_died.emit()


func passive_value(stat: String) -> float:
	var total := 0.0
	for id in passive_levels.keys():
		var data := _find_passive(id)
		if data and data.stat == stat:
			total += data.value_per_level * passive_levels[id]
	return total


func _trigger_level_up() -> void:
	if pending_level_ups <= 0:
		return
	pending_level_ups -= 1
	paused_for_levelup = true
	leveled_up_choices.emit(_build_level_up_choices())


func _build_level_up_choices() -> Array:
	var pool: Array = []

	for s in active_skills:
		if s.level < s.data.max_level:
			pool.append({
				"weight": 3, "type": "upgrade_active", "skill_id": s.data.id,
				"tag": "Nâng Cấp",
				"title": "%s Lv%d→%d" % [s.data.display_name, s.level, s.level + 1],
				"desc": "Tăng chỉ số kỹ năng chủ động.",
			})

	if active_skills.size() < MAX_ACTIVE_SLOTS:
		for data in available_active_skills:
			if not _has_active(data.id):
				pool.append({
					"weight": 2, "type": "new_active", "skill_id": data.id,
					"tag": "Kỹ Năng Mới", "title": data.display_name,
					"desc": "Học kỹ năng chủ động mới.",
				})

	for id in passive_levels.keys():
		var lvl: int = passive_levels[id]
		var data := _find_passive(id)
		if data and lvl < data.max_level:
			pool.append({
				"weight": 3, "type": "upgrade_passive", "passive_id": id,
				"tag": "Nâng Cấp",
				"title": "%s Lv%d→%d" % [data.display_name, lvl, lvl + 1],
				"desc": data.display_name,
			})

	if passive_levels.size() < MAX_PASSIVE_SLOTS:
		for data in available_passive_skills:
			if not passive_levels.has(data.id):
				pool.append({
					"weight": 2, "type": "new_passive", "passive_id": data.id,
					"tag": "Bị Động Mới", "title": data.display_name,
					"desc": "Học kỹ năng bị động mới.",
				})

	pool.append({
		"weight": 1, "type": "heal",
		"tag": "Hồi Phục", "title": "Hồi 25 Máu",
		"desc": "Hồi phục sinh lực ngay lập tức.",
	})

	return _weighted_pick_unique(pool, 3)


func apply_choice(choice: Dictionary) -> void:
	match choice.type:
		"upgrade_active":
			for s in active_skills:
				if s.data.id == choice.skill_id:
					s.level += 1
		"new_active":
			var data := _find_active(choice.skill_id)
			if data:
				active_skills.append({"data": data, "level": 1})
		"upgrade_passive":
			passive_levels[choice.passive_id] = passive_levels.get(choice.passive_id, 0) + 1
		"new_passive":
			passive_levels[choice.passive_id] = 1
		"heal":
			if player:
				player.heal(25.0)

	if pending_level_ups > 0:
		_trigger_level_up()
	else:
		paused_for_levelup = false


func _has_active(id: String) -> bool:
	for s in active_skills:
		if s.data.id == id:
			return true
	return false


func _find_active(id: String) -> SkillData:
	for d in available_active_skills:
		if d.id == id:
			return d
	return null


func _find_passive(id: String) -> PassiveData:
	for d in available_passive_skills:
		if d.id == id:
			return d
	return null


func _weighted_pick_unique(pool: Array, n: int) -> Array:
	var expanded: Array = []
	for i in range(pool.size()):
		for k in range(int(pool[i].weight)):
			expanded.append(i)
	expanded.shuffle()
	var chosen_idx: Array = []
	for idx in expanded:
		if not chosen_idx.has(idx):
			chosen_idx.append(idx)
		if chosen_idx.size() >= n:
			break
	var result: Array = []
	for idx in chosen_idx:
		result.append(pool[idx])
	return result
