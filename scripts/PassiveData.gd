class_name PassiveData
extends Resource

@export var id: String = "damage"
@export var display_name: String = "Damage"
@export var max_level: int = 5

@export_enum("damage", "cooldown", "movespeed", "maxhp", "pickup") var stat: String = "damage"

@export var value_per_level: float = 0.08
