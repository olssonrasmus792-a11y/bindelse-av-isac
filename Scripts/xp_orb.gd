extends Area2D

@export var xp_value: float = 0.0
@export var speed: float = 0
@export var magnet_range: float = 200
var magnet_enabled := false

@onready var pop: AudioStreamPlayer = $Pop

var player: Node2D = null
var velocity: Vector2 = Vector2.ZERO

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	# Strong directional burst (true "shoot out")
	var angle = randf_range(0, TAU)
	var power = randf_range(80, 140)
	
	velocity = Vector2.RIGHT.rotated(angle) * power
	
	# Slight size variation
	var size = randf_range(0.8, 1.2)
	scale = Vector2(size, size)
	
	# Delay magnet activation
	await get_tree().create_timer(randf_range(0.35, 0.6)).timeout
	magnet_enabled = true

func _physics_process(delta):
	if player == null:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# Slow down initial burst
	velocity = velocity.move_toward(Vector2.ZERO, 150 * delta)
	global_position += velocity * delta
	
	# Magnet effect
	if magnet_enabled and distance < magnet_range:
		var direction = (player.global_position - global_position).normalized()
		speed = lerp(speed, 650.0, 0.1)
		global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.add_xp(xp_value)
		queue_free()
