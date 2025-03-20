extends Panel

var player_name 
@onready var chat_color = generate_random_color()

func generate_random_color() -> Color:
	var r = randf()  # Random value for red component
	var g = randf()  # Random value for green component
	var b = randf()  # Random value for blue component
	if r + g + b < 1: # no dark color
		return Color(r, g, b) * 2.5 
	else : 
		return Color(r, g, b) 

func _ready() -> void:
	make_responsive()

func make_responsive():
	var screen_size = get_viewport().size
	screen_size = Vector2(screen_size.y / 1.25 , screen_size.x).normalized()
	scale = screen_size * 10
	$"../chat_btn".scale = screen_size / 3.5
	await get_tree().create_timer(1).timeout
	make_responsive()




func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text.strip_edges() == "": return
	send_new_message.rpc(new_text,player_name,chat_color)
	$LineEdit.release_focus()
	$LineEdit.text = ""

@rpc("any_peer","call_local")
func send_new_message(_message , _name , _color):
	var message_node = $ScrollContainer/message_row.duplicate()
	message_node.visible = true
	message_node.get_node("player_name").modulate = _color
	message_node.get_node("player_name").text = _name+": "
	message_node.get_node("message").text = _message + "\n"
	$ScrollContainer/messages.add_child(message_node)
	if not visible: $"../chat_btn/new_msg".visible = true

func _on_visibility_changed() -> void:
	player_name = GlobalScript.GetNode("start_menu/name_input").text
	player_name = "anonymous" if player_name == "" else player_name


func _on_button_toggled(toggled_on: bool) -> void:
	visible = toggled_on
	if toggled_on: $"../chat_btn/new_msg".visible = false
	$"../chat_btn".release_focus()
