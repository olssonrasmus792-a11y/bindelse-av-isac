extends Control

@onready var label: Label = $Label

func draw_map():
	queue_redraw()

func _draw():
	label.visible = false
	
	if GameState.dungeon_map.is_empty() or GameState.get_item_count("Treasure Map") <= 0:
		label.visible = true
		return


	# Area where the map is allowed to draw
	var map_area = Rect2(
		Vector2(0,0),
		Vector2(200,200)
	)



	# Find bounds
	var min_pos = Vector2.INF
	var max_pos = -Vector2.INF


	for pos in GameState.dungeon_map.keys():

		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)

		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)



	var dungeon_size = max_pos - min_pos



	# Calculate scale so it fits inside map_area
	var scale_x = map_area.size.x / max(dungeon_size.x, 1)
	var scale_y = map_area.size.y / max(dungeon_size.y, 1)

	@warning_ignore("shadowed_variable_base_class")
	var scale = min(scale_x, scale_y)



	# Center dungeon inside the area
	var dungeon_center = (min_pos + max_pos) / 2.0

	var offset = map_area.position + map_area.size / 2.0 - dungeon_center * scale



	# DRAW LINES FIRST
	for pos in GameState.dungeon_map:

		var room = GameState.dungeon_map[pos]

		var p = offset + pos * scale


		for connection in room.connections:

			var c = offset + connection * scale


			draw_line(
				p,
				c,
				Color("#6b4b2a"),
				max(scale / 5, 2)
			)



# DRAW ROOMS LAST
	for pos in GameState.dungeon_map:

		var p = offset + pos * scale


		var color = Color("c26727ff")
		var icon = preload("res://Textures/Battle.png")


		if pos == GameState.treasure_room_pos:

			color = Color.RED
			icon = preload("res://Textures/Skull.png")


		elif pos == GameState.start_room_pos:

			color = Color.WHITE
			icon = preload("res://Textures/House.png")


		elif pos in GameState.shop_positions:

			color = Color.YELLOW
			icon = preload("res://Textures/Shop.png")


		elif pos in GameState.workshop_positions:

			color = Color.HOT_PINK
			icon = preload("res://Textures/Workshop.png")



		var room_size = clamp(scale * 0.5, 5, 20)


		var rect = Rect2(
			p - Vector2(room_size, room_size) / 2,
			Vector2(room_size, room_size)
		)


		# rectangle background
		draw_rect(
			rect,
			color
		)


		# icon on top of rectangle
		if icon:

			draw_texture_rect(
				icon,
				rect,
				false
			)
