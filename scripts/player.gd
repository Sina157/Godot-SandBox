extends CharacterBody3D
# head view rotate
@export var move_speed = 11
@export var jump_force = 11  
@export var mass = 20 
@export var jumps_count = 2
@export var health = 100
@export var anim = "Idle"
@export var color = "blue":
	set(value):
		if color != value:  # Only update if the value changes
			color = value
			_on_property_changed(value) 
var rotation_speed = 10.0 
var velocity_y = 0  
var touching = false
var jump_action = false
var jumped_count = 0
var can_control = true
var auto_anim = true
var can_attack = true
@onready var chat_ui_input = GlobalScript.GetNode("chat_ui/LineEdit")

func _enter_tree() -> void:
	color = GlobalScript.color

func _ready() -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id(): 
		$SpringArmOffset/SpringArm3D/Camera3D.queue_free()
		return
	var selectedName = GlobalScript.GetNode("start_menu/name_input").text
	$Nickname.text = "anonymous" if selectedName == "" else selectedName
	get_viewport().connect("size_changed", Callable(self, "responsive_2d"))
	respawn()
	responsive_2d()
	regen_health()

func regen_health():
	await get_tree().create_timer(1).timeout
	if health in range(1,100): health += 1
	regen_health()

func respawn(delay = 0):
	await get_tree().create_timer(delay).timeout
	health = 100
	position = GlobalScript.GetNode("spawn_pos").position 
	can_control = true

func _on_property_changed(property):
	set_color.rpc(name)

@rpc("call_local","any_peer")
func set_color(player_hash):
	var texture
	var player = GlobalScript.GetNode(player_hash)
	if player == null: return
	if player.color == "red":
		texture = load("res://models/GodotRobotPaletteSwap/GodotRedPalette.png")
	elif player.color == "blue":
		texture = load("res://models/3DGodotRobot_GodotPalette.png")
	elif player.color == "yellow":
		texture = load("res://models/GodotRobotPaletteSwap/GodotYellowPalette.png")
	elif player.color == "green":
		texture = load("res://models/GodotRobotPaletteSwap/GodotGreenPalette.png")
	elif player.color == "black":
		texture = load("res://models/GodotRobotPaletteSwap/GodotBlackPalette.png")
	
	for bodyPart in player.get_node("RobotArmature/Skeleton3D").get_children():
		var new_material := StandardMaterial3D.new()
		new_material.albedo_texture = texture
		bodyPart.set_surface_override_material(0, new_material)


func responsive_2d():
	var screen_size = get_viewport().size
	screen_size = Vector2(screen_size.y / 1.25 , screen_size.x)
	$SpringArmOffset/SpringArm3D/Camera3D/JumpBtn.scale = screen_size.normalized() / 1.5
	$SpringArmOffset/SpringArm3D/Camera3D/attackBtn.scale = screen_size.normalized() / 1.5
	$SpringArmOffset/SpringArm3D/Camera3D/Joystick.scale = screen_size.normalized() / 0.75

# It was made so that the animation speed is the same for everyone. Maybe I'll find a better way later.
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


func _physics_process(delta):
	$health_bar/SubViewport/ProgressBar.value = health
	$health_bar.visible = health != 100
	if anim == "Run":
		play_sound(walk_sound , -5)
	else: $AudioStreamPlayer3D.stop()
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		return
	if position.y < -10: respawn()
	if health <= 0: 
		if can_control:
			GlobalScript.play_sound.rpc(name,"die")
			anim = "Hurt"
			$AnimationPlayer.play(anim)
			respawn(3)
		can_control = false
	elif auto_anim:
		$AnimationPlayer.play(anim)
	var move_force = Vector3.ZERO
	if can_control:
		if Input.is_action_pressed("move_back"):
			move_force.z -= 1
		if Input.is_action_pressed("move_forward"):
			move_force.z += 1
		if Input.is_action_pressed("move_right"):
			move_force.x -= 1
		if Input.is_action_pressed("move_left"):
			move_force.x += 1
		if Input.is_action_just_pressed("jump"):
			jump_action = true
		var jp = $SpringArmOffset/SpringArm3D/Camera3D/Joystick.posVector
		if jp.length() > 0.45:
			move_force = -Vector3(jp.x,0,jp.y)
		var spring_arm = $SpringArmOffset/SpringArm3D
		move_force = move_force.rotated(Vector3.UP, spring_arm.rotation.y) # move to camera view
	if chat_ui_input.has_focus(): move_force = Vector3.ZERO
	if move_force.length() > 0:
		var target_direction = move_force
		var current_forward = -$RobotArmature.global_transform.basis.z 
		var target_rotation = current_forward.slerp(-target_direction, rotation_speed * delta) 
		$RobotArmature.look_at($RobotArmature.global_transform.origin + target_rotation, Vector3.UP)
	
	velocity = move_force.normalized() * move_speed
	if is_on_floor():
		jumped_count = 0
		if move_force.length() == 0:
			anim = "Idle"
		else:
			anim = "Run"
		if jump_action and not chat_ui_input.has_focus():
			GlobalScript.play_sound.rpc(name,"jump")
			velocity_y = jump_force  
			jumped_count += 1
	else:
		if jumped_count == 0: jumped_count += 1 
		if jump_action and jumped_count != jumps_count:
			velocity_y = jump_force  
			jumped_count += 1
			GlobalScript.play_sound.rpc(name,"jump")
		if velocity_y > 0:
			if jumped_count == 1:
				anim = "Jump"
			else :
				anim = "Fall2"
		else:
			anim = "Fall"
		velocity_y -= mass * delta  
	
	velocity.y = velocity_y  
	move_and_slide()
	jump_action = false
	if is_on_floor():
		velocity_y = 0


func _on_touch_screen_button_pressed() -> void:
	touching = true
	if get_viewport().get_mouse_position().x > 300: return # bug
	if get_viewport().get_mouse_position().y < 300: return # bug
	$SpringArmOffset/SpringArm3D/Camera3D/Joystick.position = get_viewport().get_mouse_position()
	$SpringArmOffset/SpringArm3D/Camera3D/Joystick/Knob.pressing = true
	$SpringArmOffset/SpringArm3D/Camera3D/Joystick/Ring.visible = true
	$SpringArmOffset/SpringArm3D/Camera3D/Joystick/Knob.visible = true


func _on_touch_screen_button_released() -> void:
	touching = false
	$SpringArmOffset/SpringArm3D/Camera3D/Joystick/Knob.pressing = false
	$SpringArmOffset/SpringArm3D/Camera3D/Joystick/Ring.visible = false
	$SpringArmOffset/SpringArm3D/Camera3D/Joystick/Knob.visible = false


func _unhandled_input(_event) -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	var spring_arm = $SpringArmOffset/SpringArm3D
	var MOUSE_SENSIBILITY = 0.012
	var MIN_X_ROTATION = -90
	var MAX_X_ROTATION = 60
	var max_rotate_speed = 100
	
	if _event is InputEventScreenDrag:
		chat_ui_input.release_focus()
		if _event.index == 1: max_rotate_speed = 30
		if _event.relative.length() > max_rotate_speed: return
		var rotation_x = spring_arm.rotation.x - _event.relative.y * MOUSE_SENSIBILITY
		var rotation_y = spring_arm.rotation.y - _event.relative.x * MOUSE_SENSIBILITY
	
		rotation_x = clamp(rotation_x, deg_to_rad(MIN_X_ROTATION), deg_to_rad(MAX_X_ROTATION))
	
		spring_arm.rotation.x = rotation_x
		spring_arm.rotation.y = rotation_y


func _on_jump_btn_pressed() -> void:
	if not can_control: return
	chat_ui_input.release_focus()
	jump_action = true

var walk_sound = preload("res://sounds/walk.mp3")
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
	GlobalScript.play_sound.rpc(name,["hit1","hit2"].pick_random())
	for i in range(10):
		velocity += dir * power
		move_and_slide()
		await get_tree().create_timer(0.001).timeout


func _on_attack_btn_pressed() -> void:
	if health <= 0 or not can_attack: return
	if get_multiplayer_authority() != multiplayer.get_unique_id():  return
	var players = get_tree().get_nodes_in_group("character")
	auto_anim = false
	$AnimationPlayer.play(["Attack1","Kick"].pick_random())
	can_attack = false
	for player in players:
		if player == self: continue
		var max_attack_range = 2.5
		if (player.position - $RobotArmature/attack_area.global_position).length() > max_attack_range: continue
		var dir = (player.position - position).normalized()
		dir.y += 0.7
		await get_tree().create_timer(0.2).timeout
		player.take_damage.rpc(player.name,10,dir)
	await get_tree().create_timer(1).timeout
	can_attack = true
