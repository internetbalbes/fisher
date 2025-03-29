extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
# camer's sensitivity
const SENSITIVITY = 0.1
const FISHCATCHED_MAX = 10

@export var label_tip: Label
@export var label_fishcatched: Label
@export var ray_camera : RayCast3D
@export var timer_fishcatched: Timer
@export var image_fishcatched: TextureRect
@export var dialog_gameend: ConfirmationDialog
@export var rodfloat: StaticBody3D
@export var rodfloat_mesh: MeshInstance3D

# player's state
enum playerstate {
	IDLE,	# state idle
	WALKING,	# state mowing
	JUMPING,	# state jamping
	FINDLAKE,	# state finding lake
	CASTFISHRODON,# state cast a fishing rod on
	CASTFISHRODOFF,# state cast a fishing rod off
}
# player's initial state
var state = playerstate.IDLE
# helping for user
var tipson: bool = false

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		label_tip.visible = config.get_value("common", "tip", 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	rodfloat.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if  state == playerstate.IDLE &&  event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if rodfloat.visible:
				state = playerstate.CASTFISHRODOFF
			else:
				ray_camera.enabled = true
				state = playerstate.FINDLAKE			
	else: if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
	else: if Input.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	

func _process(delta):
	if state == playerstate.FINDLAKE:
		if ray_camera.is_colliding():
			gametips(0)		
			timer_fishcatched.one_shot = true
			rodfloat.global_transform.origin = ray_camera.get_collision_point()
			state = playerstate.CASTFISHRODON
		else:
			state = playerstate.IDLE
		ray_camera.enabled = false
	if state == playerstate.CASTFISHRODON:
		timer_fishcatched.wait_time = randf_range(5, 10)
		timer_fishcatched.start()
		rodfloat_mesh.mesh.material.albedo_color = Color(0, 1, 0)  # Ustawienie koloru na zielony        
		rodfloat.visible = true
		state = playerstate.IDLE
	elif state == playerstate.CASTFISHRODOFF:
		timer_fishcatched.stop()
		if rodfloat_mesh.mesh.material.albedo_color == Color(1, 0, 0):
			# fish is catched
			label_fishcatched.text = str(label_fishcatched.text.to_int() + 1)
		rodfloat.visible = false
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
			var input_dir := Input.get_vector("left", "right", "forward", "back")
			var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if direction:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
				state = playerstate.WALKING
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				velocity.z = move_toward(velocity.z, 0, SPEED)
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
				label_tip.text = "The player is near the water, point the camera at the water and press the right mouse button to cast the fishing rod."
			_:	
				label_tip.text = ""
		
func _on_timer_fishcatched_timeout() -> void:
	rodfloat_mesh.mesh.material.albedo_color = Color(1, 0, 0)  # Czerwony kolor (RGB)

func _on_confirmation_dialog_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")  # Przejdź do menu opcji	


func _on_confirmation_dialog_canceled() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	

func _on_area_tip_body_entered(body: Node3D) -> void:
	if body.name =="lake":
		gametips(1)

func _on_area_tip_body_exited(body: Node3D) -> void:
	if body.name =="lake":
		gametips(0)
		if rodfloat.visible:
			state = playerstate.CASTFISHRODOFF
			rodfloat_mesh.mesh.material.albedo_color = Color(0, 1, 0)  # Ustawienie koloru na zielony 
		label_fishcatched.text = "0"
