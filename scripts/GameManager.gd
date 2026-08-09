extends Node

var setting_fullscreen: bool = false
var setting_vsync: bool = true
var setting_master_vol: float = 1.0
var setting_music_vol: float = 1.0
var setting_sfx_vol: float = 1.0
var setting_screen_shake: bool = true

const SETTINGS_FILE = "user://settings.cfg"
signal hp_changed(current: float, max_hp: float)
signal xp_changed(current: int, needed: int)
signal level_changed(new_level: int)
signal kill_count_changed(count: int)
signal run_time_changed(seconds: float)
signal leveled_up_choices(choices: Array)
signal player_died
signal score_changed(new_score: int)
signal quest_completed(quest_id: String, title: String)

const MAX_ACTIVE_SLOTS := 3
const MAX_PASSIVE_SLOTS := 3

const SAVE_FILE = "user://savegame.cfg"

var total_kills: int = 0
var quests = {
	"q_kill_100": {"title": "First Blood", "desc": "Defeat 100 enemies.", "target": 100, "current": 0, "completed": false, "type": "total_kills"},
	"q_survive_5m": {"title": "Abyss Walker", "desc": "Survive for 5 minutes.", "target": 300, "current": 0, "completed": false, "type": "time"},
	"q_reach_lv15": {"title": "Awakened Power", "desc": "Reach Level 15 in a run.", "target": 15, "current": 0, "completed": false, "type": "level"},
	"q_craft_spell": {"title": "Spell Weaver", "desc": "Weave your first Spell.", "target": 1, "current": 0, "completed": false, "type": "craft_spell"},
	"q_cursed_soul": {"title": "Cursed Soul", "desc": "Survive 5 minutes with a Curse.", "target": 300, "current": 0, "completed": false, "type": "curse_time"}
}

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

var active_curses: Array = []
var active_relics: Array = []

var collected_vong: Array = []
var collected_net: Array = []
var crafted_spells: Array = []
var unlocked_runes: Array = []

var available_vong: Array = ["Guardian", "Warden"]
var available_net: Array = ["Split", "Chase"]

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
	load("res://resources/passives/armor_up.tres"),
	load("res://resources/passives/crit_chance_up.tres"),
]


func _process(delta: float) -> void:
	if game_over or paused_for_levelup:
		return
	run_time += delta
	run_time_changed.emit(run_time)
	
	_check_quest("time", run_time)
	if active_curses.size() > 0:
		_check_quest("curse_time", run_time)


func register_player(p: Node) -> void:
	player = p


var current_class: String = ""
var current_map_tier: int = 1

func start_run_with_class_and_map(class_id: String, map_tier: int) -> void:
	current_class = class_id
	current_map_tier = map_tier
	
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
	stolen_dark_hp = 0.0
	stolen_dark_dmg = 0.0
	
	if player:
		player.hp = player.base_max_hp
		player._effective_max_hp = player.base_max_hp
		hp_changed.emit(player.hp, player._effective_max_hp)

	unlocked_runes.clear()

	get_tree().paused = false
		
	var start_weapon_path = ""
	match class_id:
		"berserker": start_weapon_path = "res://resources/skills/throwing_axe.tres"
		"vanguard": start_weapon_path = "res://resources/skills/orbit_blade.tres"
		"assassin": start_weapon_path = "res://resources/skills/piercing_bolt.tres"
		"void_mage": start_weapon_path = "res://resources/skills/elemental_orbs.tres"
		
	if start_weapon_path != "":
		var w = load(start_weapon_path)
		if w:
			var max_runes = 2
			active_skills.append({"data": w, "level": 1, "runes": [], "max_runes": max_runes})
			
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
	_check_quest("level", level)


func register_kill() -> void:
	kills += 1
	total_kills += 1
	kill_count_changed.emit(kills)
	add_score(10)
	_check_quest("total_kills", total_kills)


func add_score(amount: int) -> void:
	if game_over:
		return
	score += amount
	score_changed.emit(score)


func on_player_died() -> void:
	game_over = true
	save_game()
	player_died.emit()


func passive_value(stat: String) -> float:
	var total := 0.0
	var total_levels := 0
	for id in passive_levels.keys():
		var data := _find_passive(id)
		if data and data.stat == stat:
			total += data.value_per_level * passive_levels[id]
		total_levels += passive_levels[id]
			
	if stat == "cooldown":
		if current_class == "assassin":
			total += 0.20
		if total_levels >= 5:
			total += 0.03 # Tier 1
		if has_rune_resonance("lightning"):
			total += 0.20
			
	if stat == "movespeed":
		if has_rune_resonance("lightning"):
			total += 0.20
		
	if stat == "damage":
		if current_class == "berserker" and player:
			total += player.berserker_dmg_buff
		total += stolen_dark_dmg
			
	if stat == "maxhp":
		total += stolen_dark_hp
		
	return total

func get_total_passive_levels() -> int:
	var total = 0
	for id in passive_levels.keys():
		total += passive_levels[id]
	return total

var stolen_dark_hp: float = 0.0
var stolen_dark_dmg: float = 0.0

func get_active_resonances() -> Array:
	var res = []
	if active_skills.size() < MAX_ACTIVE_SLOTS:
		return res
	for type in ["lightning", "ice", "dark", "void"]:
		var has_all = true
		for s in active_skills:
			if not s.has("runes") or not s.runes.has(type):
				has_all = false
				break
		if has_all:
			res.append(type)
	return res

func has_rune_resonance(rune_type: String) -> bool:
	var res = get_active_resonances()
	if res.size() > 0:
		return res[0] == rune_type
	return false
	
func get_total_spells() -> int:
	var res = get_active_resonances()
	var res_count = 1 if res.size() > 0 else 0
	return crafted_spells.size() + res_count

func trigger_void_nuke() -> void:
	if player:
		player._shake_intensity = 30.0
	
	# Visual flash
	var rect = ColorRect.new()
	rect.color = Color.WHITE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(rect)
	get_tree().root.add_child(canvas)
	
	var tween = get_tree().create_tween()
	tween.tween_property(rect, "color", Color(1, 1, 1, 0), 1.0)
	tween.tween_callback(canvas.queue_free)
	
	var count = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("_die"):
			e._die()
			count += 1
	print("VOID NUKE TRIGGERED! Erased ", count, " enemies.")

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
				"tag": "Upgrade",
				"title": "%s Lv%d→%d" % [s.data.display_name, s.level, s.level + 1],
				"desc": "Increases active skill stats.",
			})
			
		if s.runes.size() < s.max_runes:
			for rune in unlocked_runes:
				if not s.runes.has(rune):
					pool.append({
						"weight": 2, "type": "equip_rune", "skill_id": s.data.id, "rune_type": rune,
						"tag": "Imbue", "title": s.data.display_name + " + " + rune.capitalize(),
						"desc": "Imbue " + rune.capitalize() + " into " + s.data.display_name
					})

	if active_skills.size() < MAX_ACTIVE_SLOTS:
		for data in available_active_skills:
			if not _has_active(data.id):
				pool.append({
					"weight": 2, "type": "new_active", "skill_id": data.id,
					"tag": "New Skill", "title": data.display_name,
					"desc": "Learn a new active skill.",
				})
		
		# Ensure new weapons are also added to available_active_skills pool dynamically if they are not there
		var extra_skills = ["res://resources/skills/throwing_axe.tres", "res://resources/skills/elemental_orbs.tres", "res://resources/skills/whip.tres"]
		for path in extra_skills:
			var data = load(path)
			if data and not _has_active(data.id) and not available_active_skills.has(data):
				pool.append({
					"weight": 2, "type": "new_active", "skill_id": data.id,
					"tag": "New Skill", "title": data.display_name,
					"desc": "Learn a new active skill.",
				})

	for id in passive_levels.keys():
		var lvl: int = passive_levels[id]
		var data := _find_passive(id)
		if data and lvl < data.max_level:
			pool.append({
				"weight": 3, "type": "upgrade_passive", "passive_id": id,
				"tag": "Upgrade",
				"title": "%s Lv%d→%d" % [data.display_name, lvl, lvl + 1],
				"desc": data.display_name,
			})

	if passive_levels.size() < MAX_PASSIVE_SLOTS:
		for data in available_passive_skills:
			if not passive_levels.has(data.id):
				pool.append({
					"weight": 2, "type": "new_passive", "passive_id": data.id,
					"tag": "New Passive", "title": data.display_name,
					"desc": "Learn a new passive skill.",
				})

	# Spell crafting choices
	var max_spells = 1
	if level >= 15: max_spells = 2
	
	var current_total_spells = get_total_spells()
	
	if current_total_spells < max_spells:
		# If missing Vong
		if collected_vong.size() <= crafted_spells.size():
			for v in available_vong:
				if not collected_vong.has(v):
					pool.append({
						"weight": 2, "type": "new_vong", "vong_id": v,
						"tag": "Seal", "title": v,
						"desc": "Collect Seals to weave spells.",
					})
		
		# If missing Net
		if collected_net.size() <= crafted_spells.size():
			for n in available_net:
				if not collected_net.has(n):
					pool.append({
						"weight": 2, "type": "new_net", "net_id": n,
						"tag": "Crest", "title": n,
						"desc": "Collect Crests to weave spells.",
					})

	pool.append({
		"weight": 1, "type": "heal",
		"tag": "Recover", "title": "Heal 25 HP",
		"desc": "Instantly recover health.",
	})

	return _weighted_pick_unique(pool, 3)


func apply_choice(choice: Dictionary) -> void:
	match choice.type:
		"upgrade_active":
			for s in active_skills:
				if s.data.id == choice.skill_id:
					s.level += 1
		"equip_rune":
			for s in active_skills:
				if s.data.id == choice.skill_id:
					s.runes.append(choice.rune_type)
		"new_active":
			var data := _find_active(choice.skill_id)
			if data:
				var max_runes = 2
				active_skills.append({"data": data, "level": 1, "runes": [], "max_runes": max_runes})
		"upgrade_passive":
			passive_levels[choice.passive_id] = passive_levels.get(choice.passive_id, 0) + 1
		"new_passive":
			passive_levels[choice.passive_id] = 1
		"new_vong":
			collected_vong.append(choice.vong_id)
			_check_spell_craft()
		"new_net":
			collected_net.append(choice.net_id)
			_check_spell_craft()
		"heal":
			if player:
				player.heal(25.0)

	if choice.type == "upgrade_passive" or choice.type == "new_passive":
		var total_passives = get_total_passive_levels()
		if total_passives >= 15:
			# Tier 3: +1 Rune slot for all
			for s in active_skills:
				var base_max = 2
				s.max_runes = base_max + 1

	if pending_level_ups > 0:
		_trigger_level_up()
	else:
		paused_for_levelup = false

func _check_spell_craft() -> void:
	if collected_vong.size() > crafted_spells.size() and collected_net.size() > crafted_spells.size():
		var v = collected_vong[crafted_spells.size()]
		var n = collected_net[crafted_spells.size()]
		crafted_spells.append({"vong": v, "net": n})
		print("Weaved spell: ", v, " + ", n)
		_check_quest("craft_spell", crafted_spells.size())


func _has_active(id: String) -> bool:
	for s in active_skills:
		if s.data.id == id:
			return true
	return false


func _find_active(id: String) -> SkillData:
	for d in available_active_skills:
		if d.id == id:
			return d
	# Check extras
	var extra_skills = ["res://resources/skills/throwing_axe.tres", "res://resources/skills/elemental_orbs.tres", "res://resources/skills/whip.tres"]
	for path in extra_skills:
		var d = load(path)
		if d and d.id == id:
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

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	if err == OK:
		setting_fullscreen = config.get_value("Video", "fullscreen", false)
		setting_vsync = config.get_value("Video", "vsync", true)
		setting_master_vol = config.get_value("Audio", "master_vol", 1.0)
		setting_music_vol = config.get_value("Audio", "music_vol", 1.0)
		setting_sfx_vol = config.get_value("Audio", "sfx_vol", 1.0)
		setting_screen_shake = config.get_value("Gameplay", "screen_shake", true)
	
	_apply_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("Video", "fullscreen", setting_fullscreen)
	config.set_value("Video", "vsync", setting_vsync)
	config.set_value("Audio", "master_vol", setting_master_vol)
	config.set_value("Audio", "music_vol", setting_music_vol)
	config.set_value("Audio", "sfx_vol", setting_sfx_vol)
	config.set_value("Gameplay", "screen_shake", setting_screen_shake)
	config.save(SETTINGS_FILE)
	
	_apply_settings()

func _apply_settings() -> void:
	if setting_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	if setting_vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
	# In the future, we will set AudioServer bus volumes here

func save_game() -> void:
	var config = ConfigFile.new()
	config.set_value("Data", "total_kills", total_kills)
	for q_id in quests.keys():
		config.set_value("Quests", q_id + "_current", quests[q_id].current)
		config.set_value("Quests", q_id + "_completed", quests[q_id].completed)
	config.save(SAVE_FILE)

func load_game() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE)
	if err == OK:
		total_kills = config.get_value("Data", "total_kills", 0)
		for q_id in quests.keys():
			quests[q_id].current = config.get_value("Quests", q_id + "_current", 0)
			quests[q_id].completed = config.get_value("Quests", q_id + "_completed", false)

func _check_quest(type: String, val: float) -> void:
	for q_id in quests.keys():
		var q = quests[q_id]
		if not q.completed and q.type == type:
			if q.type == "total_kills" or q.type == "craft_spell":
				q.current = val
			else:
				q.current = max(q.current, val)
				
			if q.current >= q.target:
				q.completed = true
				q.current = q.target
				quest_completed.emit(q_id, q.title)
				save_game()
				print("QUEST COMPLETED: ", q.title)
	
func _ready() -> void:
	load_settings()
	load_game()
	
	var script = load("res://scripts/QuestPopup.gd")
	if script:
		var popup = script.new()
		get_tree().root.call_deferred("add_child", popup)
