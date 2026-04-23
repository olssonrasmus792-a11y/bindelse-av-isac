extends Node2D
class_name ShopItem

@export var data: ItemData
@onready var player := get_tree().get_first_node_in_group("player")
@onready var guy := get_tree().get_nodes_in_group("guy")
@onready var inventory := get_tree().get_first_node_in_group("inventory")

var base_y
var time := 0.0
@export var float_speed := 2.0
@export var float_amount := 5.0

var velocity := Vector2.ZERO
var gravity := 900.0
var bounce := 0.4
var floor_y := 0.0
var flying := false
var has_bounced := false

@onready var sprite := $Sprite2D
@onready var area_2d: Area2D = $Area2D
@onready var pop_up: Control = $PopUp
@onready var shadow: ColorRect = $Shadow
@onready var label: Label = $PopUp/Panel/Label
@onready var price: Label = $PopUp/Panel/Label2
@onready var description: RichTextLabel = $PopUp/Panel/RichTextLabel
@onready var purchase: AudioStreamPlayer = $Purchase
@onready var deny: AudioStreamPlayer = $Deny
@onready var pop: AudioStreamPlayer = $Pop

func _ready():
	if data:
		sprite.texture = data.icon
		label.text = data.name
		description.text = data.description
		price.text = "Purchase (E) : " + str(data.price) + " Coins"
		base_y = sprite.position.y
		pop_up.visible = false
		if data.description == "":
			description.text = get_stats_text(data.stats, data.stat_colors)

func _physics_process(delta):
	if flying:
		if !has_bounced:
			shadow.visible = false
			area_2d.monitoring = false

		velocity.y += gravity * delta
		position += velocity * delta
		sprite.rotation += velocity.x * 0.002

		# Hit ground
		if global_position.y >= floor_y:
			global_position.y = floor_y
			has_bounced = true

			# Bounce
			if abs(velocity.y) > 50:
				velocity.y *= -bounce
				velocity.x *= randf_range(0.4, 0.8) # lose some sideways speed
				area_2d.monitoring = true
				shadow.visible = true
			else:
				velocity = Vector2.ZERO
				flying = false
				area_2d.monitoring = true
				shadow.visible = true
	else:
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, 5 * delta)

func _process(delta: float) -> void:
	time += delta
	sprite.position.y = base_y + sin(time * float_speed) * float_amount
	
	if GameState.coins >= data.price:
		price.modulate = Color.LIME_GREEN
	else:
		price.modulate = Color.RED
	
	if data.price == 0:
		price.text = "Take Item (E) : Free"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and pop_up.visible == true:
		if GameState.coins >= data.price:
			buy_item()
		else:
			deny.play()
			shake_label()
			for guys in guy:
				guys.not_enough_money()

func buy_item():
	GameState.coins -= data.price
	GameState.taken_items.append(data)
	apply_item(data.name)
	
	for guys in guy:
		guys.item_bought()
	
	inventory.display_inventory()
	
	var sound = purchase
	if data.price == 0:
		sound = pop
	sound.get_parent().remove_child(sound)
	get_tree().current_scene.add_child(sound)
	sound.play()
	
	queue_free()

func apply_item(item_name):
	match item_name:
		"Key":
			GameState.keys += 1
		"Heart":
			player.max_health += 1
			player.health = player.max_health
			player.update_health()
		"Barrel":
			for barrels in get_tree().get_nodes_in_group("barrel"):
				barrels.explosion_size *= 1.25
				barrels.explosion_size = clamp(barrels.explosion_size, 1, 16)
				barrels.explosion_particles *= 1.05
				barrels.explosion_particles = clamp(barrels.explosion_particles, 20, 60)
		"Caged Muddy":
			GameState.muddy_spawn_rate *= 1.2
		"Clover":
			GameState.luck += 0.1
			GameState.calculate_stats()

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

func get_stats_text(stats: Array[String], stat_colors: Array[Color]) -> String:
	var text := ""
	
	for i in range(stats.size()):
		var stat = stats[i]
		
		# fallback color if missing
		var color = Color.WHITE
		if i < stat_colors.size():
			color = stat_colors[i]
		
		text += "[color=#%s]• %s[/color]\n" % [color.to_html(), stat]
	
	return text.strip_edges()

func shake_label():
	var original_pos = price.position

	var strength = 10.0
	var duration = 0.15
	var elapsed = 0.0

	# instant punch (important for feel)
	price.scale = Vector2(1.15, 1.15)

	while elapsed < duration:
		var offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)

		price.position = original_pos + offset
		price.rotation = randf_range(-0.02, 0.02)

		await get_tree().process_frame

		elapsed += get_process_delta_time()

		# fast decay = “impact → settle”
		strength = lerp(strength, 0.0, 0.35)

		# smooth return scale
		price.scale = lerp(price.scale, Vector2.ONE, 0.25)

	# reset cleanly
	price.position = original_pos
	price.rotation = 0
	price.scale = Vector2.ONE
