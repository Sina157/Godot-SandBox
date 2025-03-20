extends Sprite2D

@onready var parent = $".."

var pressing = false

@export var maxLength = 65
var deadzone = 15

func _ready():
	deadzone = parent.deadzone
	maxLength *= parent.scale.x

func _process(delta):
	if pressing:
		var screen_size = get_viewport().size
		screen_size = Vector2(screen_size.y / 1.25 , screen_size.x).normalized()
		if get_global_mouse_position().distance_to(parent.global_position ) <= maxLength / 1.5:
			global_position = get_global_mouse_position()
		else:
			var angle = parent.global_position.angle_to_point(get_global_mouse_position())
			global_position.x = parent.global_position.x + cos(angle)*maxLength * screen_size.x 
			global_position.y = parent.global_position.y + sin(angle)*maxLength * screen_size.y 
		calculateVector()
	else:
		global_position = lerp(global_position, parent.global_position, delta*50)
		parent.posVector = Vector2(0,0)
		visible = false # bug
		
func calculateVector():
	if abs((global_position.x - parent.global_position.x)) >= deadzone:
		parent.posVector.x = (global_position.x - parent.global_position.x)/maxLength
	if abs((global_position.y - parent.global_position.y)) >= deadzone:
		parent.posVector.y = (global_position.y - parent.global_position.y)/maxLength
		
func _on_button_button_down():
	if Input.is_action_pressed("jump"): return # bug
	visible = true



func _on_button_button_up():
	pressing = false
