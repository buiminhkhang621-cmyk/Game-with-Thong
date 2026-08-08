class_name SkillData
extends Resource

@export var id: String = "orbit"

@export var display_name: String = "Orbit Blade"

@export_enum("orbit", "projectile", "nova", "aoe") var skill_type: String = "orbit"

@export var max_level: int = 5

@export_group("Damage")
@export var base_damage: float = 6.0
@export var damage_per_level: float = 2.0

@export_group("Pacing (for skill_type = projectile)")
@export var base_cooldown: float = 1.0
@export var projectile_speed: float = 380.0

@export_group("Radius (for skill_type = orbit)")
@export var base_radius: float = 55.0
@export var radius_per_level: float = 5.0

@export_group("Visuals")
@export var color: Color = Color(0.94, 0.79, 0.37, 1.0)
