extends Resource
class_name ItemData

enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var name: String
@export var icon: Texture2D
@export var price: int
@export var rarity: Rarity
@export var description: String
@export var stats: Array[String] = []
@export var stat_colors: Array[Color] = []

@export var tracked_stats: Array[String] = []
@export var tracked_stat_values: Array[int] = []
@export var tracked_stat_value_percentage: Array[bool] = []
@export var tracked_stat_colors: Array[Color] = []

@export var unique: bool
