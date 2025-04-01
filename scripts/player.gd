extends CharacterBody3D

# player's speed slow
const SPEED_SLOW = 2.5
# player's speed normal
const SPEED_NORMAL = 5.0
# player's speed fast
const SPEED_FAST = 10.0
const JUMP_VELOCITY = 4.5
# camer's sensitivity
const SENSITIVITY = 0.1
const FISHCATCHED_MAX = 10
# angle catching rod
const ROD_THROW_ANGLE: float = 45.0
# power catching rod 
var ROD_THROW_FORCE: float = 100.0 

@export var label_tip: Label
@export var label_fishcatched: Label
@export var ray_camera : RayCast3D
@export var timer_fishcatched: Timer
@export var image_fishcatched: TextureRect
@export var dialog_gameend: ConfirmationDialog
@export var image_pointcatch: TextureRect
@export var rod_shaft: MeshInstance3D
@export var rod_float: StaticBody3D
@export var rod_cord: Path3D
@export var rod_float_mesh: MeshInstance3D
@export var rod_end: Node3D
@export var map: Node3D

# player's state
enum playerstate {
	IDLE,	# state idle
	WALKING,	# state mowing
	JUMPING,	# state jamping
	FINDLAKE,	# state finding lake
	CASTFISHRODON,# state cast a fishing rod on
	CASTFISHRODOFF,# state cast a fishing rod off
	CASTFISHRODON_PROCESS,# state process cast a fishing rod on
	CASTFISHRODOFF_PROCESS,# state process cast a fishing rod off
}
# player's initial state
var state = playerstate.IDLE
# helping for user
var tipson: bool = false
# vector direction catching rod
var rod_direction : Vector3 = Vector3.ZERO
# point cross float and water
var rod_water_point_cross: Vector3 = Vector3.ZERO
# player is near lake
var near_lake: bool = false
# object water_plane
var water_plane: StaticBody3D

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		label_tip.visible = config.get_value("common", "tip", 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	image_pointcatch.visible = false
	rod_shaft.visible = false	
	rod_float.visible = false
	rod_cord.visible = false
	water_plane = map.get_node("water_plane").get_child(0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if  state == playerstate.IDLE &&  event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if rod_cord.visible:
				timer_fishcatched.stop()
				state = playerstate.CASTFISHRODOFF_PROCESS
			elif near_lake:
				image_pointcatch.visible = true
				ray_camera.enabled = true
				state = playerstate.FINDLAKE
	else: if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
	else: if Input.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	

func _process(delta):
	if state == playerstate.FINDLAKE:
		if ray_camera.is_colliding() && ray_camera.get_collider() == water_plane:
			gametips(0)		
			timer_fishcatched.one_shot = true
			rod_water_point_cross = ray_camera.get_collision_point()
			image_pointcatch.visible = false
			rod_float_mesh.mesh.material.albedo_color = Color(0, 1, 0)			
			var path_curve = Curve3D.new() 	
			path_curve.add_point(rod_end.global_transform.origin)
			path_curve.add_point(rod_water_point_cross)
			rod_cord.curve = path_curve
			state = playerstate.CASTFISHRODON_PROCESS
		else:
			state = playerstate.IDLE
		ray_camera.enabled = false		
	elif state == playerstate.CASTFISHRODON_PROCESS:
		rod_float.global_transform.origin = rod_water_point_cross
		rod_cord.visible = true
		rod_float.visible = true
		state = playerstate.CASTFISHRODON
	elif state == playerstate.CASTFISHRODON:
		timer_fishcatched.wait_time = randf_range(5, 10)
		timer_fishcatched.start()
		state = playerstate.IDLE
	elif state == playerstate.CASTFISHRODOFF_PROCESS:
		state = playerstate.CASTFISHRODOFF
	elif state == playerstate.CASTFISHRODOFF:	
		#Player is still near water
		if rod_float_mesh.mesh.material.albedo_color == Color(1, 0, 0):
			# fish is catched
			label_fishcatched.text = str(label_fishcatched.text.to_int() + 1)
		if near_lake:
			gametips(1)
			image_pointcatch.visible = true
		else:
			rod_shaft.visible = false
		rod_float.visible = false
		rod_cord.visible = false
		rod_float_mesh.mesh.material.albedo_color = Color(0, 1, 0)	
		state = playerstate.IDLE
		var count = label_fishcatched.text.to_int()
		if  abs(count - FISHCATCHED_MAX) < 0.001:
			if !dialog_gameend.is_visible():
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				dialog_gameend.popup_centered()  # Wyświetla dialog na ekranie
	else:
		if !is_on_floor():
			# Ruch w powietrzu (np. grawitacja, opadanie)
			velocity += get_gravity() * delta
			state = playerstate.JUMPING
		else:
			if Input.is_action_pressed("jump"):
				velocity.y = JUMP_VELOCITY
			var speed = SPEED_NORMAL	
			if Input.is_action_pressed("sneek"):
				speed = SPEED_SLOW
			elif Input.is_action_pressed("run"):
				speed = SPEED_FAST	
			var input_dir := Input.get_vector("left", "right", "forward", "back")
			var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if direction:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
				state = playerstate.WALKING
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
				state = playerstate.IDLE
		move_and_slide()
	#message(state)

func message(data):
	# Jeśli gramy w trybie debug, komunikaty będą wyświetlane
	if OS.has_feature("editor"):  # To sprawdza, czy jesteśmy w edytorze Godot
		print(data)

func gametips(number: int):
	if label_tip.visible:
		match number:
			1: 
				label_tip.text = "Left mouse button to cast a fishing rod"
			_:	
				label_tip.text = ""

func _on_timer_fishcatched_timeout() -> void:
	rod_float_mesh.mesh.material.albedo_color = Color(1, 0, 0)  # Czerwony kolor (RGB)

func _on_confirmation_dialog_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")  # Przejdź do menu opcji	


func _on_confirmation_dialog_canceled() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	

func _on_area_tip_body_entered(body: Node3D) -> void:
	if body == water_plane:
		near_lake = true
		gametips(1)
		image_pointcatch.visible = true
		rod_shaft.visible = true

func _on_area_tip_body_exited(body: Node3D) -> void:
	if body == water_plane:
		near_lake = false
		gametips(0)
		if !rod_cord.visible:
			image_pointcatch.visible = false
			rod_shaft.visible = false
			rod_float.visible = false
		else:
			timer_fishcatched.stop()
			state = playerstate.CASTFISHRODOFF_PROCESS
