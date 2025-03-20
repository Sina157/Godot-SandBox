extends MeshInstance3D

var can_press = true


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not can_press or body.get_multiplayer_authority() != multiplayer.get_unique_id() or not body.is_in_group("player"): return
	$AnimationPlayer.play("pressed")
	can_press = false
	GlobalScript.play_sound(name,"button")
	for enemy in body.get_node("owned_enemies").get_children():
		if enemy.visible: continue
		enemy.visible = true
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.died = false
		enemy.health = 100
		enemy.position = $spawn_pos.global_position
		break
	await get_tree().create_timer(3).timeout
	$AnimationPlayer.stop()
	can_press = true
