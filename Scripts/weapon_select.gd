extends Control
@onready var player := get_tree().get_first_node_in_group("player")
@onready var camera_2d: Camera2D = $Camera2D
@onready var color_rect: ColorRect = $ColorRect
@onready var weapon_container: HBoxContainer = $ScrollContainer/WeaponContainer
@onready var sort_button: Button = $SortButton

var sort_modes = ["New", "Level", "Name"]

func _ready() -> void:
	camera_2d.make_current()
	
	if GameSettings.dark_mode:
		color_rect.color = Color.BLACK
	else:
		color_rect.color = Color(0.376, 0.306, 0.459)
	
	sort_button.text = "Sort: " + sort_modes[GameState.current_weapon_sort]
	sort_weapon_cards()

func _on_quit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func sort_weapon_cards():
	var cards = []

	for child in weapon_container.get_children():
		if child.has_method("update_card") and child.data != null:
			cards.append(child)

	cards.sort_custom(sort_cards)

	# move only cards, keep spacers
	for i in range(cards.size()):
		weapon_container.move_child(cards[i], i + 1)


func sort_cards(a, b):
	match sort_modes[GameState.current_weapon_sort]:

		"Level":
			var a_level = GameState.weapon_progress[a.data.id]["level"]
			var b_level = GameState.weapon_progress[b.data.id]["level"]

			var a_xp = GameState.weapon_progress[a.data.id]["xp"]
			var b_xp = GameState.weapon_progress[b.data.id]["xp"]

			# Higher level first
			if a_level != b_level:
				return a_level > b_level

			# Same level -> higher XP first
			if a_xp != b_xp:
				return a_xp > b_xp

			var a_new = (
				GameState.unlocked_weapons.get(a.data.id, false)
				and GameState.weapon_progress[a.data.id]["runs_played"] <= 0
			)

			var b_new = (
				GameState.unlocked_weapons.get(b.data.id, false)
				and GameState.weapon_progress[b.data.id]["runs_played"] <= 0
			)

			# Same level/xp -> new first
			if a_new != b_new:
				return a_new

			# Same everything -> alphabetical
			return a.data.name < b.data.name


		"Name":
			return a.data.name < b.data.name


		"New":
			var a_new = (
				GameState.unlocked_weapons.get(a.data.id, false)
				and GameState.weapon_progress[a.data.id]["runs_played"] <= 0
			)

			var b_new = (
				GameState.unlocked_weapons.get(b.data.id, false)
				and GameState.weapon_progress[b.data.id]["runs_played"] <= 0
			)

			if a_new != b_new:
				return a_new

			var a_unlocked = GameState.unlocked_weapons.get(a.data.id, false)
			var b_unlocked = GameState.unlocked_weapons.get(b.data.id, false)

			if a_unlocked != b_unlocked:
				return a_unlocked


	return a.data.name < b.data.name

func _on_sort_button_pressed() -> void:
	GameState.current_weapon_sort += 1
	
	if GameState.current_weapon_sort >= sort_modes.size():
		GameState.current_weapon_sort = 0
	
	sort_button.text = "Sort: " + sort_modes[GameState.current_weapon_sort]
	sort_weapon_cards()
