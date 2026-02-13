extends CanvasLayer
@onready var label: Label = $Label
@onready var keys: Label = $KeyPanel/HBoxContainer/Keys
@onready var gold: Label = $GoldPanel/HBoxContainer/Gold
@onready var timer: Label = $Timer
var time_left
var start_time = 300.0

@onready var vignette: TextureRect = $DamageVignette
@export var flash_duration: float = 0.25

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_left = start_time
	vignette.modulate.a = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	keys.text = "Keys: " + str(GameState.keys)
	gold.text = "Gold: " + str(GameState.gold)
	label.text = "Kills: " + str(GameState.kills)
	
	time_left -= delta
	timer.text = format_time(time_left)

func format_time(seconds: float) -> String:
	var m = int(seconds) / 60
	var s = int(seconds) % 60
	return "%02d:%02d" % [m, s]


func flash_vignette():
	# Immediately show vignette
	vignette.modulate.a = 1
	
	# Tween alpha back to 0
	var tween = create_tween()
	tween.tween_property(vignette, "modulate:a", 0.0, flash_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
