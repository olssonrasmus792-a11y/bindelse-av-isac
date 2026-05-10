extends Panel

@onready var leaderboard_container = $VBoxContainer
@onready var stats: Label = $Stats
@onready var loading: Label = $Loading
@onready var button: Button = $Button

var is_loading := false

func _ready() -> void:
	load_scores()

func _on_visibility_changed() -> void:
	if visible:
		load_scores()

func load_scores():
	if is_loading:
		return

	is_loading = true

	loading.text = "Loading..."
	loading.visible = true

	for child in leaderboard_container.get_children():
		child.queue_free()

	var sw_result: Dictionary = await SilentWolf.Scores.get_scores().sw_get_scores_complete
	
	if sw_result.success:
		var scores = sw_result.scores
		
		if scores.size() == 0:
			loading.text = "Nobody here broski :("
			is_loading = false
			return

		# --- STEP 1: Keep only BEST score per player ---
		var best_scores = {}

		for score_data in scores:
			@warning_ignore("shadowed_variable_base_class")
			var name = score_data.player_name
			var score = int(score_data.score)

			if !best_scores.has(name) or score > best_scores[name]:
				best_scores[name] = score

		# --- STEP 2: Convert dictionary to sortable array ---
		var sorted_scores = []

		@warning_ignore("shadowed_variable_base_class")
		for name in best_scores.keys():
			sorted_scores.append({
				"name": name,
				"score": best_scores[name]
			})

		sorted_scores.sort_custom(func(a, b):
			return a.score > b.score
		)

		loading.visible = false

		# --- STEP 3: Display TOP 5 unique players ---
		for i in range(min(5, sorted_scores.size())):
			var entry = sorted_scores[i]

			var label = Label.new()
			label.text = "#" + str(i + 1) + " " + entry.name + " - " + str(entry.score) + " Kills"

			var font = load("res://Fonts/Bungee-Regular.ttf")
			label.add_theme_font_override("font", font)
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_constant_override("outline_size", 4)

			if i == 0:
				label.modulate = Color(1.0, 1.0, 0.0, 1.0)
			elif i == 1:
				label.modulate = Color(0.75, 0.75, 0.75)
			elif i == 2:
				label.modulate = Color(0.8, 0.5, 0.2)

			leaderboard_container.add_child(label)

	else:
		stats.text = "Failed to load scores"

	is_loading = false

func _on_button_pressed() -> void:
	load_scores()
