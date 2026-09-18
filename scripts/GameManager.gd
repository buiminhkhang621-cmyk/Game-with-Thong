extends Node

var setting_fullscreen: bool = false
var setting_vsync: bool = true
var setting_master_vol: float = 1.0
var setting_music_vol: float = 1.0
var setting_sfx_vol: float = 1.0
var setting_screen_shake: bool = true
var setting_damage_numbers: bool = true
var setting_show_fps: bool = false

const SETTINGS_FILE = "user://settings.cfg"
@warning_ignore("unused_signal")
signal hp_changed(current: float, max_hp: float)
@warning_ignore("unused_signal")
signal xp_changed(current: int, needed: int)
@warning_ignore("unused_signal")
signal level_changed(new_level: int)
@warning_ignore("unused_signal")
signal kill_count_changed(count: int)
@warning_ignore("unused_signal")
signal run_time_changed(seconds: float)
@warning_ignore("unused_signal")
signal leveled_up_choices(choices: Array)
@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal score_changed(new_score: int)
@warning_ignore("unused_signal")
signal quest_completed(quest_id: String, title: String)

@warning_ignore("unused_signal")
signal combo_updated(total_damage: float, hits: int)
@warning_ignore("unused_signal")
signal combo_reset()
@warning_ignore("unused_signal")
signal boss_spawned()
@warning_ignore("unused_signal")
signal wave_event_triggered(title: String, subtitle: String)
@warning_ignore("unused_signal")
signal blood_moon_state_changed(active: bool)
@warning_ignore("unused_signal")
signal abyssal_fog_state_changed(active: bool)
@warning_ignore("unused_signal")
signal chest_opened(rewards: Array)

var bgm_player_1: AudioStreamPlayer
var bgm_player_2: AudioStreamPlayer
var active_bgm_player: AudioStreamPlayer
var _bgm_tween: Tween = null
var is_transitioning: bool = false
var bgm_playlist: Array = []
var restart_run_on_ready: bool = false

var active_enemies: Array = []

var weapons_disabled: bool = false
var is_blood_sacrifice: bool = false
var is_abyssal_fog: bool = false

const MAX_ACTIVE_SLOTS := 4
const MAX_PASSIVE_SLOTS := 4

func register_enemy(e: Node) -> void:
	if not active_enemies.has(e):
		active_enemies.append(e)

func unregister_enemy(e: Node) -> void:
	active_enemies.erase(e)

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

var rerolls_left: int = 2
var banishes_left: int = 1
var banished_ids: Array = []
var is_blood_moon: bool = false

var active_curses: Array = []
var active_relics: Array = []

var collected_vong: Array = []
var collected_net: Array = []
var crafted_spells: Array = []
var unlocked_runes: Array = []

var available_vong: Array = ["Guardian", "Warden"]
var available_net: Array = ["Split", "Chase"]

var available_active_skills: Array = [
	load("res://resources/skills/chain_lightning.tres"),
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

var current_combo_hits: int = 0
var current_combo_dmg: float = 0.0
var _combo_decay_timer: float = 0.0
const COMBO_TIMEOUT: float = 1.8 # Combo window: resets 1.8s after last hit

func register_hit(dmg: float) -> void:
	current_combo_hits += 1
	current_combo_dmg += dmg
	_combo_decay_timer = COMBO_TIMEOUT
	combo_updated.emit(current_combo_dmg, current_combo_hits)

func reset_combo() -> void:
	if current_combo_hits > 0 or current_combo_dmg > 0.0 or _combo_decay_timer > 0.0:
		current_combo_hits = 0
		current_combo_dmg = 0.0
		_combo_decay_timer = 0.0
		combo_reset.emit()


func _process(delta: float) -> void:
	if game_over or paused_for_levelup:
		return
		
	run_time += delta
	run_time_changed.emit(run_time)
	
	_check_quest("time", run_time)
	if active_curses.size() > 0:
		_check_quest("curse_time", run_time)
		
	if _combo_decay_timer > 0.0:
		_combo_decay_timer -= delta
		if _combo_decay_timer <= 0.0:
			reset_combo()
			
	if Engine.time_scale < 1.0:
		Engine.time_scale = move_toward(Engine.time_scale, 1.0, delta * 2.0)
		
	_update_bgm()

func hit_stop(duration: float = 0.05) -> void:
	Engine.time_scale = 0.1
	await get_tree().create_timer(duration * 0.1, true, false, true).timeout
	Engine.time_scale = 1.0


func stop_all_audio() -> void:
	if _bgm_tween:
		_bgm_tween.kill()
		_bgm_tween = null
	is_transitioning = false
	if is_instance_valid(bgm_player_1):
		bgm_player_1.stop()
		bgm_player_1.stream = null
	if is_instance_valid(bgm_player_2):
		bgm_player_2.stop()
		bgm_player_2.stream = null
	if get_tree():
		for p in get_tree().get_nodes_in_group("sfx_players"):
			if is_instance_valid(p):
				p.stop()
				p.queue_free()

func _update_bgm() -> void:
	if not player or game_over or (get_tree() and get_tree().paused):
		stop_all_audio()
		return
		
	if not active_bgm_player:
		return
		
	# Start random track if nothing is playing
	if not active_bgm_player.playing and not is_transitioning:
		var stream = bgm_playlist[randi() % bgm_playlist.size()]
		active_bgm_player.stream = stream
		active_bgm_player.volume_db = 0.0
		active_bgm_player.play()
		return
		
	# Check if we are near the end of the current track
	if active_bgm_player.playing and active_bgm_player.stream:
		var pos = active_bgm_player.get_playback_position()
		var length = active_bgm_player.stream.get_length()
		
		# 2.0 seconds before the end, start crossfade
		if length - pos <= 2.0 and not is_transitioning:
			_start_random_crossfade()

func _start_random_crossfade() -> void:
	is_transitioning = true
	var next_player = bgm_player_2 if active_bgm_player == bgm_player_1 else bgm_player_1
	
	# Pick a track that is different from the current one
	var current_stream = active_bgm_player.stream
	var possible_tracks = []
	for t in bgm_playlist:
		if t != current_stream:
			possible_tracks.append(t)
			
	if possible_tracks.size() > 0:
		next_player.stream = possible_tracks[randi() % possible_tracks.size()]
	else:
		next_player.stream = current_stream
		
	next_player.volume_db = -80.0
	next_player.play()
	
	if _bgm_tween:
		_bgm_tween.kill()
		
	_bgm_tween = get_tree().create_tween()
	var old_player = active_bgm_player
	active_bgm_player = next_player
	
	_bgm_tween.tween_property(old_player, "volume_db", -80.0, 2.0)
	_bgm_tween.parallel().tween_property(next_player, "volume_db", 0.0, 2.0)
	_bgm_tween.tween_callback(func():
		old_player.stop()
		is_transitioning = false
	)


func register_player(p: Node) -> void:
	player = p


var current_class: String = ""
var current_map_tier: int = 1
var selected_skin: String = "default"



func start_run_with_class_and_map(class_id: String, map_tier: int) -> void:
	stop_all_audio()
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
	rerolls_left = 2
	banishes_left = 1
	banished_ids.clear()
	is_blood_moon = false
	weapons_disabled = false
	is_blood_sacrifice = false
	is_abyssal_fog = false
	active_relics.clear()
	reset_combo()
	
	if player:
		player.hp = player.base_max_hp
		player._effective_max_hp = player.base_max_hp
		player.global_position = Vector2.ZERO
		player.velocity = Vector2.ZERO
		if "external_force" in player:
			player.external_force = Vector2.ZERO
		if player.has_method("apply_skin"):
			player.apply_skin(selected_skin)
		hp_changed.emit(player.hp, player._effective_max_hp)

	unlocked_runes.clear()

	if get_tree():
		get_tree().paused = false
		
	var start_weapon_path = ""
	match class_id:
		"berserker": start_weapon_path = "res://resources/skills/throwing_axe.tres"
		"vanguard": start_weapon_path = "res://resources/skills/orbit_blade.tres"
		"assassin": start_weapon_path = "res://resources/skills/throwing_knife.tres"
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
	var final_xp = amount
	if active_relics.has("greed_ring"):
		final_xp = int(final_xp * 2.0)
	xp += final_xp
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(12 + level * 8 + pow(level, 1.45) * 3)
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
	
	# Death Scythe Shard: permanent Might stack per kill!
	if active_relics.has("death_scythe_shard"):
		scythe_kill_stacks += 1
		
	# Vampiric Chalice Relic: Heal on kills
	if active_relics.has("vampiric_chalice"):
		if player and is_instance_valid(player):
			player.heal(1.5)
			
	if is_blood_sacrifice and player:
		player.heal(6.0)


func add_score(amount: int) -> void:
	if game_over:
		return
	score += amount
	score_changed.emit(score)


func on_player_died() -> void:
	if game_over:
		return
	game_over = true
	weapons_disabled = false
	is_blood_sacrifice = false
	is_abyssal_fog = false
	reset_combo()
	stop_all_audio()
	if get_tree():
		get_tree().paused = true
	play_sfx(sfx_death)
	save_game()
	player_died.emit()


var elixir_armor_bonus: float = 0.0
var elixir_cdr_bonus: float = 0.0
var elixir_speed_bonus: float = 0.0
var elixir_crit_bonus: float = 0.0
var scythe_kill_stacks: int = 0

func relic_value(stat: String) -> float:
	var val: float = 0.0
	for r in active_relics:
		match r:
			"heart_of_the_abyss":
				if stat == "flat_hp": val += 150.0
				elif stat == "cooldown": val -= 0.25
			"blood_pact_blade":
				if stat == "damage": val += 1.00
				elif stat == "hp_mult": val -= 0.30
			"chronos_hourglass":
				if stat == "cooldown": val += 0.45
			"vampiric_chalice":
				if stat == "hp_mult": val -= 0.25
				elif stat == "pickup": val -= 0.30
			"greed_ring":
				if stat == "xp_mult": val += 1.50
			"titan_aegis":
				if stat == "armor": val += 0.60
				elif stat == "movespeed": val -= 0.30
			"death_scythe_shard":
				if stat == "crit": val += 0.50
				elif stat == "hp_mult": val -= 0.40
				elif stat == "damage": val += min(3.0, scythe_kill_stacks * 0.005)
			"shadow_boots":
				if stat == "movespeed": val += 0.50
			"ancient_censer":
				if stat == "pickup": val -= 0.50
			"void_prism":
				pass
	return val


func passive_value(stat: String) -> float:
	var total := 0.0
	var total_levels := 0
	for id in passive_levels.keys():
		var data := _find_passive(id)
		if data and data.stat == stat:
			total += data.value_per_level * passive_levels[id]
		total_levels += passive_levels[id]
			
	total += relic_value(stat)
	
	if stat == "cooldown":
		total += elixir_cdr_bonus
		if current_class == "assassin":
			total += 0.20
		if total_levels >= 5:
			total += 0.03
		if has_rune_resonance("lightning"):
			total += 0.20
		return min(0.75, total)
			
	if stat == "movespeed":
		total += elixir_speed_bonus
		if has_rune_resonance("lightning"):
			total += 0.20
			
	if stat == "armor":
		total += elixir_armor_bonus
		
	if stat == "crit":
		total += elixir_crit_bonus
		
	if stat == "damage":
		if current_class == "berserker" and player:
			total += player.berserker_dmg_buff
		total += stolen_dark_dmg
		if is_blood_sacrifice:
			total += 2.0
			
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

var _is_nuking: bool = false

func trigger_void_nuke() -> void:
	if _is_nuking: return
	_is_nuking = true
	
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
		if e.get("active_auras") != null and type_string(typeof(e.active_auras)) == "Array" and e.active_auras.has("void"):
			if e.get("enemy_type") == "boss":
				if e.has_method("take_damage"):
					e.take_damage(e.max_hp * 0.25)
			else:
				if e.has_method("_die"):
					e._die()
					count += 1
	print("VOID NUKE TRIGGERED! Collapsed ", count, " void entities.")
	hit_stop(0.1) # 0.1s hit stop for huge impact
	_is_nuking = false

func _trigger_level_up() -> void:
	if pending_level_ups <= 0:
		return
	pending_level_ups -= 1
	paused_for_levelup = true
	get_tree().paused = true
	leveled_up_choices.emit(_build_level_up_choices())


func _build_level_up_choices() -> Array:
	var pool: Array = []

	for s in active_skills:
		if banished_ids.has(s.data.id): continue
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
			if not banished_ids.has(data.id) and not _has_active(data.id):
				pool.append({
					"weight": 2, "type": "new_active", "skill_id": data.id,
					"tag": "New Skill", "title": data.display_name,
					"desc": "Learn a new active skill.",
				})
		
		# Ensure new weapons are also added to available_active_skills pool dynamically if they are not there
		var extra_skills = ["res://resources/skills/chain_lightning.tres", "res://resources/skills/throwing_knife.tres", "res://resources/skills/throwing_axe.tres", "res://resources/skills/elemental_orbs.tres", "res://resources/skills/whip.tres"]
		for path in extra_skills:
			var data = load(path)
			if data and not banished_ids.has(data.id) and not _has_active(data.id) and not available_active_skills.has(data):
				pool.append({
					"weight": 2, "type": "new_active", "skill_id": data.id,
					"tag": "New Skill", "title": data.display_name,
					"desc": "Learn a new active skill.",
				})

	for id in passive_levels.keys():
		if banished_ids.has(id): continue
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
			if not banished_ids.has(data.id) and not passive_levels.has(data.id):
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
				if not banished_ids.has(v) and not collected_vong.has(v):
					pool.append({
						"weight": 2, "type": "new_vong", "vong_id": v,
						"tag": "Seal", "title": v,
						"desc": "Collect Seals to weave spells.",
					})
		
		# If missing Net
		if collected_net.size() <= crafted_spells.size():
			for n in available_net:
				if not banished_ids.has(n) and not collected_net.has(n):
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

func reroll_choices() -> void:
	if rerolls_left <= 0:
		return
	rerolls_left -= 1
	leveled_up_choices.emit(_build_level_up_choices())

func banish_choice(choice: Dictionary) -> void:
	if banishes_left <= 0:
		return
	banishes_left -= 1
	var target_id = ""
	if choice.has("skill_id"):
		target_id = choice.skill_id
	elif choice.has("passive_id"):
		target_id = choice.passive_id
	elif choice.has("vong_id"):
		target_id = choice.vong_id
	elif choice.has("net_id"):
		target_id = choice.net_id
		
	if target_id != "" and not banished_ids.has(target_id):
		banished_ids.append(target_id)
		
	leveled_up_choices.emit(_build_level_up_choices())

func skip_level_up() -> void:
	if player:
		player.heal(25.0)
	if pending_level_ups > 0:
		_trigger_level_up()
	else:
		paused_for_levelup = false
		get_tree().paused = false

func trigger_void_magnet() -> void:
	var orbs = get_tree().get_nodes_in_group("xp_orbs")
	for o in orbs:
		if is_instance_valid(o) and not o.is_queued_for_deletion():
			o.is_attracted = true

func trigger_cataclysm_nuke() -> void:
	hit_stop(0.08)
	if player:
		player._shake_intensity = 25.0
	for e in active_enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		if e.get("enemy_type") == "boss":
			if e.has_method("take_damage"):
				e.take_damage(350.0)
		else:
			if e.has_method("_die"):
				e._die()

func trigger_time_stasis(duration: float = 4.5) -> void:
	for e in active_enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion(): continue
		if e.has_method("apply_element"):
			e.is_frozen = true
			e.ice_slow_time = max(e.ice_slow_time, duration)
			e.queue_redraw()

func grant_random_upgrades(count: int) -> Array:
	var granted: Array = []
	for i in range(count):
		var pool = []
		
		# 1. Existing Active Skills
		for s in active_skills:
			if s.level < s.data.max_level:
				pool.append({"type": "upgrade_active", "skill": s, "name": s.data.display_name, "weight": 4})
				
		# 2. Existing Passives
		for id in passive_levels.keys():
			var data = _find_passive(id)
			if data and passive_levels[id] < data.max_level:
				pool.append({"type": "upgrade_passive", "id": id, "name": data.display_name, "weight": 4})
				
		# 3. Unowned Cursed Relics
		var all_relics = ["death_scythe_shard", "blood_pact_blade", "chronos_hourglass", "vampiric_chalice", "greed_ring", "titan_aegis", "void_prism", "ancient_censer", "shadow_boots", "heart_of_the_abyss"]
		for r in all_relics:
			if not active_relics.has(r):
				pool.append({"type": "grant_relic", "relic_id": r, "weight": 3})
				
		# 4. Stat Elixirs (Always available so pool is never exhausted)
		pool.append({"type": "elixir_might", "name": "Elixir of War (+15% Might)", "weight": 2})
		pool.append({"type": "elixir_armor", "name": "Elixir of Iron (+10% Armor)", "weight": 2})
		pool.append({"type": "elixir_cdr", "name": "Elixir of Chronos (-8% Cooldown)", "weight": 2})
		pool.append({"type": "elixir_speed", "name": "Elixir of the Wind (+12% Speed)", "weight": 2})
		pool.append({"type": "elixir_crit", "name": "Elixir of Fortune (+15% Crit)", "weight": 2})
		pool.append({"type": "elixir_hp", "name": "Elixir of the Titan (+50 Max HP)", "weight": 2})
		pool.append({"type": "elixir_xp", "name": "Essence of the Void (+150 Bonus XP)", "weight": 2})
		
		# Weighted pick
		var total_w = 0
		for item in pool: total_w += item.weight
		var roll = randi_range(1, total_w)
		var picked = pool[0]
		var cur_w = 0
		for item in pool:
			cur_w += item.weight
			if roll <= cur_w:
				picked = item
				break
				
		match picked.type:
			"upgrade_active":
				picked.skill.level += 1
				granted.append(picked.name + " Lv" + str(picked.skill.level))
			"upgrade_passive":
				passive_levels[picked.id] += 1
				granted.append(picked.name + " Lv" + str(passive_levels[picked.id]))
			"grant_relic":
				active_relics.append(picked.relic_id)
				var relic_names = {
					"death_scythe_shard": "Soul Reaper Scythe",
					"blood_pact_blade": "Blood Pact Dagger",
					"chronos_hourglass": "Chronos Doomglass",
					"vampiric_chalice": "Vampiric Chalice",
					"greed_ring": "Ring of Midas",
					"titan_aegis": "Titan Sarcophagus",
					"void_prism": "Void Singularity Prism",
					"ancient_censer": "Censer of the Plague",
					"shadow_boots": "Phantom Shadow Boots",
					"heart_of_the_abyss": "Abyssal Heart"
				}
				granted.append("CURSED RELIC: " + relic_names.get(picked.relic_id, "Relic").to_upper())
			"elixir_might":
				stolen_dark_dmg += 0.15
				granted.append("ELIXIR OF WAR (+15% MIGHT)")
			"elixir_armor":
				elixir_armor_bonus += 0.10
				granted.append("ELIXIR OF IRON (+10% ARMOR)")
			"elixir_cdr":
				elixir_cdr_bonus += 0.08
				granted.append("ELIXIR OF CHRONOS (-8% CDR)")
			"elixir_speed":
				elixir_speed_bonus += 0.12
				granted.append("ELIXIR OF SPEED (+12% SPEED)")
			"elixir_crit":
				elixir_crit_bonus += 0.15
				granted.append("ELIXIR OF FORTUNE (+15% CRIT)")
			"elixir_hp":
				stolen_dark_hp += 50.0
				if player: player._update_max_hp(); player.heal(50.0)
				granted.append("ELIXIR OF TITAN (+50 MAX HP)")
			"elixir_xp":
				grant_xp(150)
				granted.append("ESSENCE OF VOID (+150 BONUS XP)")
				
	if player:
		player._update_max_hp()
	return granted


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
		get_tree().paused = false

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
	var extra_skills = ["res://resources/skills/chain_lightning.tres", "res://resources/skills/throwing_knife.tres", "res://resources/skills/throwing_axe.tres", "res://resources/skills/elemental_orbs.tres", "res://resources/skills/whip.tres"]
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
		setting_damage_numbers = config.get_value("Gameplay", "damage_numbers", true)
		setting_show_fps = config.get_value("Gameplay", "show_fps", false)
	
	_apply_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("Video", "fullscreen", setting_fullscreen)
	config.set_value("Video", "vsync", setting_vsync)
	config.set_value("Audio", "master_vol", setting_master_vol)
	config.set_value("Audio", "music_vol", setting_music_vol)
	config.set_value("Audio", "sfx_vol", setting_sfx_vol)
	config.set_value("Gameplay", "screen_shake", setting_screen_shake)
	config.set_value("Gameplay", "damage_numbers", setting_damage_numbers)
	config.set_value("Gameplay", "show_fps", setting_show_fps)
	config.save(SETTINGS_FILE)
	
	_apply_settings()

# SFX assets
var sfx_electric_shock: AudioStream = preload("res://music/sfx/electric_shock.mp3")
var sfx_level_up: AudioStream = preload("res://music/sfx/level_up.mp3")
var sfx_death: AudioStream = preload("res://music/sfx/death.mp3")
var sfx_achievement: AudioStream = preload("res://music/sfx/achivement.mp3")

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	if not stream: return
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "SFX"
	p.pitch_scale = pitch_scale
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.add_to_group("sfx_players")
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func _apply_settings() -> void:
	if setting_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	if setting_vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
	# Ensure Music bus
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx == -1:
		AudioServer.add_bus()
		music_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_idx, "Music")
		AudioServer.set_bus_send(music_idx, "Master")

	# Ensure SFX bus
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx == -1:
		AudioServer.add_bus()
		sfx_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")

	# Apply Master volume
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		if setting_master_vol <= 0.01:
			AudioServer.set_bus_mute(master_idx, true)
		else:
			AudioServer.set_bus_mute(master_idx, false)
			AudioServer.set_bus_volume_db(master_idx, linear_to_db(setting_master_vol))
			
	# Apply Music volume
	if music_idx >= 0:
		if setting_music_vol <= 0.01:
			AudioServer.set_bus_mute(music_idx, true)
		else:
			AudioServer.set_bus_mute(music_idx, false)
			AudioServer.set_bus_volume_db(music_idx, linear_to_db(setting_music_vol))
			
	# Apply SFX volume
	if sfx_idx >= 0:
		if setting_sfx_vol <= 0.01:
			AudioServer.set_bus_mute(sfx_idx, true)
		else:
			AudioServer.set_bus_mute(sfx_idx, false)
			AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(setting_sfx_vol))

	# Also apply directly to bgm players if needed
	var music_db = -80.0 if setting_music_vol <= 0.01 else linear_to_db(setting_music_vol)
	if is_instance_valid(bgm_player_1): bgm_player_1.volume_db = music_db
	if is_instance_valid(bgm_player_2): bgm_player_2.volume_db = music_db

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
	
	bgm_playlist = [
		preload("res://music/bgm/map2/The_Stone_Chamber.mp3"),
		preload("res://music/bgm/map2/Blade_in_the_Hall.mp3"),
		preload("res://music/bgm/map2/The_Forgotten_Altar.mp3")
	]
	
	bgm_player_1 = AudioStreamPlayer.new()
	bgm_player_1.bus = "Music"
	bgm_player_1.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_player_1)
	
	bgm_player_2 = AudioStreamPlayer.new()
	bgm_player_2.bus = "Music"
	bgm_player_2.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_player_2)
	
	active_bgm_player = bgm_player_1
	
	var script = load("res://scripts/QuestPopup.gd")
	if script:
		var popup = script.new()
		get_tree().root.call_deferred("add_child", popup)
