extends Line2D

@export var lifetime := 0.2          # lightning line life
@export var light_lifetime := 0.5   # 👈 longer light
@export var jaggedness := 10.0
@export var segments := 6

@onready var light := $ImpactLight
@onready var sparks := $Sparks

func setup(start: Vector2, end: Vector2):
	clear_points()

	# --- Lightning shape ---
	for i in range(segments + 1):
		var t = float(i) / segments
		var point = start.lerp(end, t)

		if i != 0 and i != segments:
			point += Vector2(
				randf_range(-jaggedness, jaggedness),
				randf_range(-jaggedness, jaggedness)
			)

		add_point(point)

	# --- Impact position ---
	light.global_position = end
	sparks.global_position = end

	# --- Randomize light ---
	light.energy = randf_range(2.0, 3.5)
	light.texture_scale = randf_range(0.8, 1.3)

	# --- Trigger sparks ---
	sparks.restart()
	sparks.emitting = true

	# --- Fade light slower than lightning ---
	var tween = create_tween()
	tween.tween_property(light, "energy", 0.0, light_lifetime)

	# --- Remove lightning line quickly ---
	await get_tree().create_timer(lifetime).timeout
	visible = false  # hide line but keep light/sparks alive

	# --- Wait for light + particles to finish ---
	await get_tree().create_timer(light_lifetime).timeout
	queue_free()
