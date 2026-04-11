extends Control

@onready var combo_text = $ComboText
@onready var timer_bar = $TimerBarBackground/TimerBar
@onready var bonus_text: Label = $BonusText

var combo_count := 0
var combo_time := 4.0
var time_left := 0.0

func _ready():
	hide()

func add_kill():
	combo_count += 1
	time_left = combo_time
	
	combo_text.text = "Combo x" + str(combo_count)
	bonus_text.text = "x" + str(1 + combo_count * 0.1) + " Drop Chance!"
	
	if combo_count > 1:
		show()
	
	animate_combo()

func animate_combo():
	# Kill previous tweens so it doesn't stack weirdly
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 🔥 Scale intensity based on combo
	var strength = clamp(combo_count * 0.1, 0.2, 1.5)
	
	# 💥 Bounce scale
	combo_text.scale = Vector2(1.0 + strength, 1.0 - strength * 0.3)
	tween.tween_property(combo_text, "scale", Vector2(1, 1), 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# 🎯 Slight random rotation (feels juicy)
	var rot = randf_range(-0.1, 0.1) * strength
	combo_text.rotation = rot
	tween.tween_property(combo_text, "rotation", 0, 0.2)
	
	# 🎨 Color intensity
	var color = Color.WHITE
	if combo_count >= 10:
		color = Color(1, 0.2, 0.2) # red
	elif combo_count >= 5:
		color = Color(1, 0.6, 0.1) # orange
	elif combo_count >= 3:
		color = Color(1, 1, 0.3) # yellow
	
	combo_text.modulate = color
	
	# ✨ Flash effect
	combo_text.modulate = Color(2, 2, 2)
	tween.tween_property(combo_text, "modulate", color, 0.2)

func _process(delta):
	if GameState.combo != combo_count:
		add_kill()
	
	if combo_count > 0:
		time_left -= delta
		
		GameState.coin_drop_chance = 0.1 * (1 + 0.1 * combo_count)
		
		# Timer bar shrink
		var ratio = time_left / combo_time
		timer_bar.scale.x = max(ratio, 0)
		
		# 🔥 Make bar color change over time
		timer_bar.modulate = Color(1, ratio, ratio)
		
		if time_left <= 0:
			reset_combo()

func reset_combo():
	combo_count = 0
	
	GameState.combo = 0
	GameState.coin_drop_chance = 0.1
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.3)
	tween.tween_callback(hide)
	tween.tween_property(self, "modulate:a", 1, 0)
