extends Area3D




func _on_body_entered(body: Node3D) -> void:
	if body.velocity_y > -10: body.velocity_y = -10 # min
	body.velocity_y *= -1.2
	GlobalScript.play_sound(name,"spring")
