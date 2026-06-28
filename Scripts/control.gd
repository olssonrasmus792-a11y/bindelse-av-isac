extends Control

@onready var bar: ProgressBar = $ProgressBar
var scene_path := "res://Scenes/main.tscn"
var changing_scene := false

func _ready():
	GameState.reset_game()
	ResourceLoader.load_threaded_request(scene_path)

func _process(_delta):
	if changing_scene:
		return
	var progress := []
	var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	if progress.size() > 0:
		bar.value = progress[0] * 100
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		changing_scene = true
		set_process(false)
		var packed_scene = ResourceLoader.load_threaded_get(scene_path)
		# Grab tree reference BEFORE the scene change frees this node
		var tree = get_tree()
		tree.change_scene_to_packed(packed_scene)
		await tree.process_frame
		var dungeon = tree.current_scene.find_child("RoomGenerator", true, false)
		await dungeon.dungeon_loaded
		bar.value = 100
