extends Node

var color = "blue"
var players = {}

func GetNode(path):
	var node = get_tree().root.get_node("./Root/" + path)
	return node

@rpc("call_local","any_peer")
func own_node(node_path_or_node , peer_id):
	if not peer_id in players:
		print("player not found")
		return
	var id = players[peer_id]
	var node = GetNode(node_path_or_node) if node_path_or_node is String else node_path_or_node
	node.set_multiplayer_authority(id) 

@rpc("any_peer","call_local")
func play_sound(path: String, sound_name: String , volume= 0):
	var node = GetNode(path)
	var sound_player = AudioStreamPlayer3D.new()
	node.add_child(sound_player)
	sound_player.stream = load("res://sounds/"+sound_name+".mp3")
	sound_player.volume_db = volume
	sound_player.play()
	while sound_player.playing:
		await get_tree().create_timer(0.1).timeout
		if node == null: return
	sound_player.queue_free()
