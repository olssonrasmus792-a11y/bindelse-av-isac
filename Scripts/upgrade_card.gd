extends Control

signal selected(card)

@export var card_data: CardData

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var card_holder: Control = $CardHolder
@onready var front: Panel = $CardHolder/Front
@onready var back: Panel = $CardHolder/Back
@onready var back_panel: Panel = $CardHolder/Back/BackPanel
@onready var back_panel_2: Panel = $CardHolder/Back/BackPanel2
@onready var back_line: Line2D = $CardHolder/Back/BackLine
@onready var back_line_2: Line2D = $CardHolder/Back/BackLine2
@onready var front_line: Line2D = $CardHolder/Front/FrontLine
@onready var front_line_2: Line2D = $CardHolder/Front/FrontLine2

@onready var rarity_label: Label = $CardHolder/Front/RarityLabel
@onready var name_label: Label = $CardHolder/Front/NameLabel
@onready var desc_label: Label = $CardHolder/Front/DescLabel
@onready var gain_label: Label = $CardHolder/Front/GainLabel
@onready var level_panel: Panel = $CardHolder/Front/LevelPanel
@onready var level: Label = $CardHolder/Front/LevelPanel/Level
@onready var icon: TextureRect = $CardHolder/Front/Icon

var revealed := false
var flipped := false

var rarity_color: Color = Color.WHITE
var shimmer_time := 0.0
var rarity_intensity := 0.0

var hover_strength := 4.0
var max_rotation := 6.0
var smooth_speed := 4.0

var float_time := randf() * 10.0
var float_amount := 6.0
var float_speed := 2.0

var base_position := Vector2.ZERO


func _ready():
	base_position = card_holder.position

	if front.material:
		front.material = front.material.duplicate()

	if card_data:
		setup_card()


func setup_card():
	animation_player.play("RESET")
	
	flipped = false
	revealed = false
	
	# Match rarity colors from your other script
	match card_data.rarity:
		"Uncommon":
			rarity_color = Color.MEDIUM_SEA_GREEN
			rarity_intensity = 0.1
		
		"Rare":
			rarity_color = Color.ROYAL_BLUE
			rarity_intensity = 0.3
		
		"Epic":
			rarity_color = Color.REBECCA_PURPLE
			rarity_intensity = 0.6
		
		"Legendary":
			rarity_color = Color.GOLD
			rarity_intensity = 1.8
		
		"Unique":
			rarity_color = Color.HOT_PINK
			rarity_intensity = 0.5
		
		_:
			rarity_color = Color.WHITE
			rarity_intensity = 0.05
	
	front.self_modulate = rarity_color
	level_panel.self_modulate = rarity_color
	back.self_modulate = rarity_color
	back_panel.self_modulate = rarity_color
	back_panel_2.self_modulate = rarity_color
	front_line.self_modulate = rarity_color
	front_line_2.self_modulate = rarity_color
	back_line.self_modulate = rarity_color
	back_line_2.self_modulate = rarity_color
	
	# Use CardData variables
	rarity_label.text = card_data.rarity
	rarity_label.modulate = rarity_color
	
	name_label.text = card_data.card_name
	desc_label.text = card_data.description
	
	gain_label.text = card_data.increase
	icon.texture = card_data.icon
	
	if card_data.current_level + 1 >= card_data.max_level:
		level.text = "Level: " + str(card_data.current_level) + " -> " +"Max"
	else:
		level.text = "Level: " + str(card_data.current_level) + " -> " + str(card_data.current_level + 1)


func _process(delta):
	shimmer_time += delta * 0.6
	
	update_shine()
	update_tilt(delta)


func update_shine():
	var mat := front.material as ShaderMaterial
	
	if mat:
		mat.set_shader_parameter("shine_color", rarity_color)
		mat.set_shader_parameter("intensity", rarity_intensity)
		mat.set_shader_parameter("sweep_pos", fmod(shimmer_time, 3.0) - 0.5)


func update_tilt(delta):
	var mouse = get_global_mouse_position()
	var rect = card_holder.get_global_rect()
	
	if rect.has_point(mouse):
		var center = rect.position + rect.size * 0.5
		
		var offset = (mouse - center) / (rect.size * 0.5)
		offset = offset.clamp(Vector2(-1, -1), Vector2(1, 1))
		
		var target_rot = offset.x * max_rotation
		var target_pos = offset * hover_strength
		
		card_holder.rotation_degrees = lerp(
			card_holder.rotation_degrees,
			target_rot,
			delta * smooth_speed
		)
		
		card_holder.position = card_holder.position.lerp(
			target_pos,
			delta * smooth_speed
		)
	
	else:
		card_holder.rotation_degrees = lerp(
			card_holder.rotation_degrees,
			0.0,
			delta * smooth_speed
		)
		
		card_holder.position = card_holder.position.lerp(
			Vector2.ZERO,
			delta * smooth_speed
		)

func reveal():
	revealed = true

func _on_button_pressed():
	if revealed and flipped:
		selected.emit(self)
		
	elif revealed:
		animation_player.play("flip")
		shimmer_time = 0.0
		flipped = true

func _on_timer_timeout() -> void:
	reveal()
