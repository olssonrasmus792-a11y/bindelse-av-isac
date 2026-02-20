extends Sprite2D

@onready var player := get_tree().get_first_node_in_group("player")

@onready var bubble: Label = $ChatBubble
@onready var timer: Timer = $ChatTimer

@export var talk_chance := 0.4  # 40% chance to talk each timer tick

var lines = [
	"Buy something broski",
	"Mi bombo"
]

func _ready() -> void:
	timer.timeout.connect(_on_chat_timer)
	timer.start(randf_range(2.0, 5.0))

func _process(_delta: float) -> void:
	if player.global_position.x > global_position.x:
		flip_h = true
	else:
		flip_h = false

func _on_chat_timer() -> void:
	timer.start(randf_range(2.0, 6.0))

	if randf() > talk_chance:
		bubble.visible = false
		return

	bubble.text = lines.pick_random()
	bubble.visible = true

	# Hide after a bit
	await get_tree().create_timer(5.0).timeout
	bubble.visible = false
