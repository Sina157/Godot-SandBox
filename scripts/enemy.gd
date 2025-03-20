extends CharacterBody3D

var speed = 10
var velocity_y = 0  
var mass = 20 
var anim = "Idle"
var died = false
var can_attack = true
var auto_anim = true
var walk_sound = preload("res://sounds/walk.mp3")
@export var health = 100
@onready var path = $"../..".name+"/owned_enemies/"+name

func  play_sound(sound,volume):
	var sound_player = $AudioStreamPlayer3D
	if sound_player.playing: return
	sound_player.stream = sound
	sound_player.volume_db = volume
	sound_player.play()


@rpc("call_local","any_peer")
func take_damage(hash_id,damage = 10,dir = Vector3.ZERO , power = 20):
	if name != hash_id: return
	if get_multiplayer_authority() != multiplayer.get_unique_id():  return
	health -= damage
	GlobalScript.play_sound.rpc(path,["hit1","hit2"].pick_random())
	for i in range(10):
		velocity += dir * power
		move_and_slide()
		await get_tree().create_timer(0.001).timeout

func die():
	if died: return
	died = true
	$AnimationPlayer.play("Hurt")
	$AnimationPlayer.seek(0.875, true)
	GlobalScript.play_sound.rpc(path,"die")
	await get_tree().create_timer(3).timeout
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	
func find_closest_node(nodes):
	var closest_node = null
	var closest_distance = INF  # مقدار بی‌نهایت برای شروع
	for node in nodes:
		var node_position = node.global_transform.origin
		var distance = position.distance_to(node_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_node = node
	return closest_node

func attack(target):
	if not can_attack: return
	auto_anim = false
	can_attack = false
	var dir = (target.position - position).normalized()
	dir.y += 0.7
	$AnimationPlayer.play(["Attack1","Kick"].pick_random())
	await get_tree().create_timer(0.2).timeout
	if (target.position - $RobotArmature/attack_area.global_position).length() < 2.5:
		target.take_damage.rpc(target.name,10,dir)
	await get_tree().create_timer(1).timeout
	can_attack = true
	auto_anim = true

func _physics_process(delta: float) -> void:
	$health_bar/SubViewport/ProgressBar.value = health
	$health_bar.visible = health != 100
	if anim == "Run":
		play_sound(walk_sound , -5)
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	if health <= 0:
		die()
		return
	var players = get_tree().get_nodes_in_group("player")
	if len(players) == 0: return
	var target = null
	for player in players:
		target = player
	target = find_closest_node(players)
	var move_force = -(position - target.position + Vector3.LEFT).normalized()
	velocity = move_force * speed
	
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0  # نادیده گرفتن تغییرات ارتفاع (محور Y)
	if direction != Vector3.ZERO:
		rotation.y = atan2(direction.x, direction.z)
	velocity.y = velocity_y  
	if is_on_floor():
		if randi() % 300 == 50:
			jump()
	else:
		velocity_y -= mass * delta
	move_and_slide()
	if (target.position - $RobotArmature/attack_area.global_position).length() < 5:
		attack(target)
	if auto_anim:
		handle_anim()
	if position.y < -10 : die()


func jump():
	velocity_y = 11 
	GlobalScript.play_sound(path,"jump")


func handle_anim():
	if velocity.x + velocity.z != 0:
		anim = "Run"
	else:
		anim = "Idle"
	if velocity.y > 0:
		anim = "Jump"
	elif velocity.y < 0:
		anim = "Fall"
	$AnimationPlayer.play(anim)


func _on_animation_player_current_animation_changed(name: String) -> void:
	var step = 0.04
	if name == "Hurt":
		for i in range(100):
			await get_tree().create_timer(0.001).timeout
			$AnimationPlayer.seek(0.875, true)
	elif name == "Attack1":
		for i in range(1 , 41):
			$AnimationPlayer.seek(step * i  ,true)
			await get_tree().create_timer(.01).timeout
	elif name == "Kick":
		for i in range(1 , 25):
			$AnimationPlayer.seek(step * i  ,true)
			await get_tree().create_timer(.01).timeout
	auto_anim = true
