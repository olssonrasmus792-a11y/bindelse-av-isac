extends Resource
class_name ItemData

@export var name: String
@export var description: String
@export var stats: Array[String] = []
@export var stat_colors: Array[Color] = []
@export var price: int
@export var icon: Texture2D

@export var tracked_stats: Array[String] = []
@export var tracked_stat_values: Array[int] = []
@export var tracked_stat_colors: Array[Color] = []
