extends Line2D

@export var lifetime := 0.1
@export var jaggedness := 10.0
@export var segments := 6

func setup(start: Vector2, end: Vector2):
	clear_points()

	for i in range(segments + 1):
		var t = float(i) / segments
		var point = start.lerp(end, t)

		# add randomness for lightning effect
		if i != 0 and i != segments:
			point += Vector2(
				randf_range(-jaggedness, jaggedness),
				randf_range(-jaggedness, jaggedness)
			)

		add_point(point)

	await get_tree().create_timer(lifetime).timeout
	queue_free()
