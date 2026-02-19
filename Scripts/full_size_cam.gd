extends Camera2D

var zoom_speed := 0.1
var min_zoom := 0.05
var max_zoom := 2.0
var drag_speed = 0.8

var dragging := false

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	zoom.x = 0.5
	zoom.y = zoom.x

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom *= (1 - zoom_speed)
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= (1 + zoom_speed)
		
		zoom.x = clamp(zoom.x, min_zoom, max_zoom)
		zoom.y = zoom.x

	if event is InputEventMouseMotion and dragging:
		position -= event.relative / zoom.x * drag_speed
