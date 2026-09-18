extends Node
class_name AIAgentMapGenerator

signal map_generation_completed(map_data: Dictionary)

const GROQ_KEYS = [
	"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",
	"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",
	"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",
	"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"
]

const OPENROUTER_KEYS = [
	"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",
	"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",
	"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"
]

var _http_request: HTTPRequest
var _current_key_idx: int = 0
var _using_openrouter: bool = false

# Preset Ancient Ruined Realm Archetypes for instant seamless fallback
const REALM_ARCHETYPES = [
	{
		"realm_name": "SANCTUM OF THE FALLEN SUN",
		"lore": "An ancient obsidian necropolis where temporal anomalies pulse through decayed stone arches.",
		"pillar_density": "high",
		"theme": "obsidian_ruin",
		"tint": Color(0.9, 0.85, 0.75),
		"hazard_mod": "meteor_rain"
	},
	{
		"realm_name": "OBSIDIAN CATACOMBS OF AZGARTH",
		"lore": "Deep subterranean ruins carved with eldritch runes. Dark energy resonates through the cracked pillars.",
		"pillar_density": "medium",
		"theme": "dark_catacombs",
		"tint": Color(0.7, 0.65, 0.85),
		"hazard_mod": "abyssal_fog"
	},
	{
		"realm_name": "DESOLATE HALLS OF THE FROST QUEEN",
		"lore": "Frozen glacial halls frozen in time. Glacial stalagmites pierce through ancient ruined cobblestone.",
		"pillar_density": "high",
		"theme": "frost_ruin",
		"tint": Color(0.65, 0.85, 1.0),
		"hazard_mod": "void_vortex"
	},
	{
		"realm_name": "TEMPLE OF PRIMORDIAL LIGHTNING",
		"lore": "Weathered battlements overlooking the cosmic abyss, supercharged with roaring celestial sparks.",
		"pillar_density": "medium",
		"theme": "storm_sanctuary",
		"tint": Color(1.0, 0.95, 0.7),
		"hazard_mod": "magic_silence"
	}
]

func _init() -> void:
	pass

func generate_map_blueprint(theme_hint: String = "") -> void:
	if not _http_request:
		_http_request = HTTPRequest.new()
		_http_request.timeout = 5.0
		add_child(_http_request)
		_http_request.request_completed.connect(_on_http_response)
		
	_fetch_ai_map_async(theme_hint)

func _fetch_ai_map_async(theme_hint: String) -> void:
	var prompt = """You are a procedural map generator for a 2D dark fantasy top-down roguelike game.
Generate a unique ruined dungeon map blueprint in JSON.
Output ONLY valid JSON with this exact schema:
{
  "realm_name": "NAME IN UPPERCASE",
  "lore": "A compelling 1-2 sentence atmospheric description",
  "pillar_count": 28,
  "urn_count": 40,
  "room_sectors": [
    {"type": "central_plaza", "radius": 450, "pillar_ring": true},
    {"type": "north_sanctum", "x": 0, "y": -900, "w": 600, "h": 500},
    {"type": "south_catacomb", "x": 0, "y": 900, "w": 600, "h": 500},
    {"type": "east_armory", "x": 900, "y": 0, "w": 500, "h": 600},
    {"type": "west_shrine", "x": -900, "y": 0, "w": 500, "h": 600}
  ],
  "hazard_event": "meteor_rain"
}"""
	
	var headers = ["Content-Type: application/json"]
	var url = ""
	var body_json = {}
	
	if not _using_openrouter:
		# Use Groq API (High-speed Llama-3.3-70b)
		url = "https://api.groq.com/openai/v1/chat/completions"
		var key = GROQ_KEYS[_current_key_idx % GROQ_KEYS.size()]
		headers.append("Authorization: Bearer " + key)
		body_json = {
			"model": "llama-3.3-70b-versatile",
			"messages": [
				{"role": "system", "content": prompt},
				{"role": "user", "content": "Generate an ancient ruined map layout. " + theme_hint}
			],
			"response_format": {"type": "json_object"},
			"temperature": 0.7
		}
	else:
		# Use OpenRouter Fallback
		url = "https://openrouter.ai/api/v1/chat/completions"
		var key = OPENROUTER_KEYS[_current_key_idx % OPENROUTER_KEYS.size()]
		headers.append("Authorization: Bearer " + key)
		headers.append("HTTP-Referer: https://localhost")
		body_json = {
			"model": "meta-llama/llama-3.3-70b-instruct:free",
			"messages": [
				{"role": "system", "content": prompt},
				{"role": "user", "content": "Generate an ancient ruined map layout. " + theme_hint}
			]
		}
		
	var err = _http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body_json))
	if err != OK:
		# Fallback to local procedural AI archetype immediately
		_use_fallback_archetype()

func _on_http_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json_res = JSON.parse_string(body.get_string_from_utf8())
		if json_res and json_res.has("choices") and json_res["choices"].size() > 0:
			var raw_content = json_res["choices"][0]["message"]["content"]
			var parsed_map = JSON.parse_string(raw_content)
			if parsed_map and parsed_map.has("realm_name"):
				map_generation_completed.emit(parsed_map)
				return
				
	# If failed, switch provider/key or use procedural archetype
	if not _using_openrouter:
		_using_openrouter = true
		_fetch_ai_map_async("")
	else:
		_use_fallback_archetype()

func _use_fallback_archetype() -> void:
	var arch = REALM_ARCHETYPES[randi() % REALM_ARCHETYPES.size()]
	var blueprint = {
		"realm_name": arch.realm_name,
		"lore": arch.lore,
		"pillar_count": randi_range(28, 42),
		"urn_count": randi_range(35, 55),
		"theme": arch.theme,
		"room_sectors": [
			{"type": "central_plaza", "radius": 450, "pillar_ring": true},
			{"type": "north_sanctum", "x": 0, "y": -950, "w": 650, "h": 550},
			{"type": "south_catacomb", "x": 0, "y": 950, "w": 650, "h": 550},
			{"type": "east_armory", "x": 950, "y": 0, "w": 550, "h": 650},
			{"type": "west_shrine", "x": -950, "y": 0, "w": 550, "h": 650}
		],
		"hazard_event": arch.hazard_mod
	}
	map_generation_completed.emit(blueprint)
