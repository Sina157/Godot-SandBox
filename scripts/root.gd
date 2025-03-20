extends Node3D

const PlayerComponent :=  preload("res://objects/3d_godot_robot.tscn")
var is_game_owner = false
var matcha_room 


func Join_Room():
	# for telegram users
	matcha_room  = MatchaRoom.create_mesh_room({ "identifier": "Public" })
	multiplayer.multiplayer_peer = matcha_room
	matcha_room.peer_joined.connect(func(_id, peer):
		print("Peer connected: ", peer.peer_id)
		_add_player(peer.peer_id,_id)
	)
	matcha_room.peer_left.connect(func(_id, peer):
		print("Peer disconnected: ", peer.peer_id)
		GlobalScript.erase(peer.peer_id)
		get_node(peer.peer_id).queue_free()
	)

func _ready():
	Join_Room()
	var screen_size = get_viewport().size
	screen_size = Vector2(screen_size.y / 1.25 , screen_size.x).normalized() 
	var telegram_name = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('name')")
	if telegram_name != null:
		$start_menu/name_input.text = telegram_name
	if screen_size.x < screen_size.y:
		$start_menu.scale = screen_size 
		$start_menu.position.x = screen_size.x * 500
		$start_menu/extra_size.visible = true

func _add_player(peer_id: String, authority_id: int) -> void:
	if peer_id in GlobalScript.players: return # That peer is already known
	var node := PlayerComponent.instantiate()
	node.position = Vector3(0,10000,0)
	node.name = peer_id # The node must have the same name for every person. Otherwise syncing it will fail because path mismatch
	GlobalScript.players[peer_id] = authority_id
	node.set_multiplayer_authority(authority_id)
	add_child(node)

func _on_button_pressed() -> void:
	_add_player(matcha_room.peer_id, multiplayer.get_unique_id()) # add self
	$start_menu.visible = false




func _on_color_pressed(extra_arg_0: String) -> void:
	GlobalScript.color = extra_arg_0
