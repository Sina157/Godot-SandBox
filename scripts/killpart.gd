extends Area3D




func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		body.health = 0
