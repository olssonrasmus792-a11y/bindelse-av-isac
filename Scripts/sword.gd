extends Node2D
@onready var player: CharacterBody2D = $".."
@export var distance_from_player := 15
@export var scale_factor = 1.0
@export var offset_amount := 10.0

@onready var trail: Polygon2D = $SwordPivot/SwordSprite/Trail
@onready var sword_sprite: AnimatedSprite2D = $SwordPivot/SwordSprite
@onready var attack_area: Area2D = $SwordPivot/SwordSprite/AttackArea
@onready var flying: AudioStreamPlayer = $"../Flying"

@export var throw_speed := 900.0
@export var return_speed := 1000.0
@export var max_distance := 500.0
@export var spin_speed := 60.0
@export var follow_mouse := true
@export var thrown := false
@export var returning := false

var sprite_start_local_transform := Transform2D.IDENTITY
var throw_direction := Vector2.ZERO
var start_position := Vector2.ZERO
var sword_pivot: Node2D

func _ready() -> void:
	follow_mouse = true
	trail.visible = false
	sprite_start_local_transform = sword_sprite.transform
	sword_pivot = $SwordPivot

func _process(delta):
	if thrown:
		handle_throw(delta)
	
	if !follow_mouse:
		return
	
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - get_parent().global_position
	
	if dir.length() > 5:
		dir = dir.normalized()
		
		var flip = 1.0
		if mouse_pos.x < get_parent().global_position.x:
			flip = -1.0
		
		var perp = dir.rotated(PI / 2) * flip
		
		global_position = (
			get_parent().global_position
			+ dir * distance_from_player
			+ perp * offset_amount
		)
		
		rotation = dir.angle()
		
		scale.y = flip * scale_factor
		scale.x = 1 * scale_factor

func throw_sword() -> void:
	if thrown:
		return
	thrown = true
	follow_mouse = false
	returning = false
	attack_area.monitoring = true
	flying.play(0.15)
	start_position = player.global_position
	throw_direction = (get_global_mouse_position() - player.global_position).normalized()

	# Save world-space transform, reparent to scene root, restore it
	var world_transform = sword_sprite.global_transform
	sword_pivot.remove_child(sword_sprite)
	get_tree().current_scene.add_child(sword_sprite)
	sword_sprite.global_transform = world_transform

func handle_throw(delta):
	if GameState.weapon != "clover":
		trail.visible = true
	sword_sprite.rotation += spin_speed * delta
	if !returning:
		sword_sprite.global_position += throw_direction * throw_speed * delta
		if sword_sprite.global_position.distance_to(start_position) >= max_distance:
			returning = true
			player.enemies_hit.clear()
	else:
		var dir_to_player = (player.global_position - sword_sprite.global_position).normalized()
		sword_sprite.global_position += dir_to_player * return_speed * delta
		if sword_sprite.global_position.distance_to(player.global_position) < 60:
			thrown = false
			returning = false
			follow_mouse = true
			trail.visible = false
			attack_area.monitoring = false
			flying.stop()

			# Reparent back to sword pivot and restore local position
			var current_scene = get_tree().current_scene
			current_scene.remove_child(sword_sprite)
			sword_pivot.add_child(sword_sprite)
			sword_sprite.transform = sprite_start_local_transform
