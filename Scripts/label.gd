extends Label

@export var life_time: float = 1.4
@export var gravity: float = 1000.0
@export var bounce_damping: float = 0.5

var velocity: Vector2
var start_position: Vector2
var timer: float = 0.0

var bounced := false

func _ready():
	start_position = global_position
	modulate.a = 1.0
	
	# Random throw direction
	var horizontal = randf_range(-180, 180)
	var upward = randf_range(-280, -140)
	
	velocity = Vector2(horizontal, upward)
	
	scale = Vector2(1.2, 1.2)

func _process(delta):
	timer += delta
	if timer > life_time:
		queue_free()
		return

	# Gravity
	velocity.y += gravity * delta

	# Move
	global_position += velocity * delta
	
	scale = lerp(scale, Vector2.ONE, 5 * delta)

	# Bounce once when hitting "ground"
	if global_position.y > (start_position.y + 20):
		global_position.y = start_position.y + 20
		velocity.y *= -0.4
		velocity.x *= 0.8

	# Fade out over time (smooth)
	var t = timer / life_time
	modulate.a = 1.2 - t
