extends GPUParticles2D
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var gpu_particles_2d: GPUParticles2D = $"."
var timer = 0.0
var has_emitted

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	has_emitted = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if gpu_particles_2d.emitting:
		timer = gpu_particles_2d.lifetime
		has_emitted = true
	
	if timer > 0.0:
		timer -= delta
	
	point_light_2d.energy = timer
	
	if has_emitted and point_light_2d.energy <= 0:
		queue_free()
