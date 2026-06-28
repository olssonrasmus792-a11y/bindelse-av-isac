extends Node

var explosions: Array[Node] = []

var max_explosions := 75

func add_explosion(explosion):
	explosions.append(explosion)

	if explosions.size() > max_explosions:
		var oldest = explosions.pop_front()

		if is_instance_valid(oldest):
			oldest.queue_free()

func remove_explosion(explosion):
	explosions.erase(explosion)
