extends Node2D
class_name ShopItem

@export var data: ItemData
@onready var player := get_tree().get_first_node_in_group("player")

var base_y
var time := 0.0
@export var float_speed := 2.0
@export var float_amount := 5.0

@onready var sprite := $Sprite2D
@onready var pop_up: Control = $PopUp
@onready var label: Label = $PopUp/Panel/Label
@onready var price: Label = $PopUp/Panel/Label2
@onready var description: RichTextLabel = $PopUp/Panel/RichTextLabel

func _ready():
	if data:
		sprite.texture = data.icon
		label.text = data.name
		description.text = data.description
		price.text = "Purchase(E) : " + str(data.price) + " Coins"
		base_y = sprite.position.y
		pop_up.visible = false

func _process(delta: float) -> void:
	time += delta
	sprite.position.y = base_y + sin(time * float_speed) * float_amount
	
	if GameState.coins >= data.price:
		price.modulate = Color.LIME_GREEN
	else:
		price.modulate = Color.RED
	
	if player.global_position.x > global_position.x:
		pop_up.position.x = -384
	else:
		pop_up.position.x = 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and pop_up.visible == true:
		if GameState.coins >= data.price:
			buy_item()
		else:
			pass

func buy_item():
	GameState.coins -= data.price
	GameState.taken_items[data.name] = true
	
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		show_item_popup()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		hide_item_popup()

func show_item_popup():
	pop_up.visible = true

func hide_item_popup():
	pop_up.visible = false
