extends Sprite2D

@onready var player := get_tree().get_first_node_in_group("player")

@onready var bubble: Label = $ChatBubble
@onready var timer: Timer = $ChatTimer
@onready var hide_timer: Timer = $ChatHideTimer

@export var talk_chance := 0.6  # 40% chance to talk each timer tick

@export var player_is_in_room = false

var lines = [
	"Buy something broski",
	"Mi bombo",
	"This the best shop in town twin",
	"I'm waiting for you to buy something",
	"Better prepare for the boss...",
	"I got the good stuff here twin"
]

var no_money_lines = [
	"You poor as hell",
	"No money?",
	"You ain't got no money gng",
	"Come back when you have enough coins",
	"Go get some money first",
	"Bro that's cheap",
	"No coins, no items"
]

var purchase_lines = [
	"Let's go gng",
	"Thank you bro",
	"Appreciate you twin",
	"That's a banger",
	"That item is goated bro",
	"Good choice.",
	"Please buy more stuff",
	"I knew you'd buy that one"
]

func _ready() -> void:
	timer.timeout.connect(_on_chat_timer)
	hide_timer.timeout.connect(_on_hide_timeout)
	timer.start(randf_range(6.0, 12.0))

func _process(_delta: float) -> void:
	if player.global_position.x > global_position.x:
		flip_h = true
	else:
		flip_h = false
	
	if !player_is_in_room:
		timer.stop()

func show_dialogue(text: String):
	hide_timer.stop() # cancel previous hide
	timer.stop()
	
	bubble.text = text
	bubble.visible = true
	
	timer.start(randf_range(6.0, 12.0))
	hide_timer.start(5.0)

func _on_chat_timer() -> void:
	timer.start(randf_range(6.0, 12.0))

	if randf() > talk_chance:
		return

	show_dialogue(lines.pick_random())

func _on_hide_timeout():
	bubble.visible = false

func not_enough_money():
	timer.paused = true
	
	show_dialogue(no_money_lines.pick_random())
	
	await hide_timer.timeout
	timer.paused = false

func item_bought():
	timer.paused = true
	
	show_dialogue(purchase_lines.pick_random())
	
	await hide_timer.timeout
	timer.paused = false
