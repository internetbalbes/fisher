extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
# camer's sensitivity
const SENSITIVITY = 0.1
const FISHCATCHED_MAX = 10

@export var label_tip: Label
@export var label_tutorial: Label
@export var label_fishcatched: Label
@export var ray_camera : RayCast3D
@export var timer_fishcatched: Timer
@export var image_fishcatched: TextureRect
@export var dialog_gameend: ConfirmationDialog

# player's state
enum playerstate {
	IDLE,	# state idle
	WALKING,	# state walking
	JUMPING,	# state jamping
	FINDLAKE,	# state finding lake
	CASTFISHROD,# state cast a fishing rod
	FISHING,	# state fishing
	FISHCATCHED	# state fish is catched
}
# player's initial state
var state = playerstate.IDLE
# helping for user
var tutorial_step = 0
var tutorialson: bool = false
var tipson: bool = false

func _ready() -> void:
	#tutorial_label.text = "Welcome to the game! Press space to jump."
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		label_tutorial.visible = config.get_value("common", "tutorial", 0)
		label_tip.visible = config.get_value("common", "tip", 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT && event.pressed:
			ray_camera.enabled = true
			state = playerstate.FINDLAKE
	else: if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
	else: if Input.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	

func _process(delta):
	match state:
		playerstate.IDLE:
			handle_idle()
		playerstate.WALKING:
			handle_walking()
		playerstate.JUMPING:
			handle_jumping(delta)
		playerstate.FINDLAKE:
			handle_findlake()
		playerstate.CASTFISHROD:
			handle_castfishrod(delta)
		playerstate.FISHING:
			handle_fishing(delta)
		playerstate.FISHCATCHED:
			handle_fishcatched(delta)			
	#message(state)

func handle_idle():
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	if input_dir.length()>0:
		state = playerstate.WALKING
	elif Input.is_action_just_pressed("jump"):
		state = playerstate.JUMPING

func handle_walking():
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	if input_dir.y < 0:
		tutorial(2)
	elif input_dir.y > 0:
		tutorial(3)
	elif input_dir.x < 0:
		tutorial(4)		
	elif input_dir.x > 0:
		tutorial(5)		
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		state = playerstate.IDLE
	move_and_slide()

func handle_jumping(delta):
	# Jump's Logic
	if is_on_floor():
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY
		else:
			state = playerstate.IDLE  # Po skoku wracamy do stanu IDLE
			tutorial(1)
	else:
		# Ruch w powietrzu (np. grawitacja, opadanie)
		velocity += get_gravity() * delta
	move_and_slide()

func handle_findlake():
	if ray_camera.is_colliding():
		gametips(0)		
		label_fishcatched.text = "0"
		timer_fishcatched.wait_time = randf_range(5, 10)
		timer_fishcatched.one_shot = true		
		state = playerstate.CASTFISHROD
	else:
		state = playerstate.IDLE
	ray_camera.enabled = false

func handle_castfishrod(delta):	
	state = playerstate.FISHING
	timer_fishcatched.wait_time = randf_range(5, 10)
	timer_fishcatched.start()
	
func handle_fishing(delta):
	pass
	
func handle_fishcatched(delta):
	var count = label_fishcatched.text.to_int()
	if  abs(count - FISHCATCHED_MAX) < 0.001:
		if !dialog_gameend.is_visible():
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			dialog_gameend.popup_centered()  # Wyświetla dialog na ekranie
	else:
		state = playerstate.CASTFISHROD

func message(data):
	# Jeśli gramy w trybie debug, komunikaty będą wyświetlane
	if OS.has_feature("editor"):  # To sprawdza, czy jesteśmy w edytorze Godot
		print(data)
		
func tutorial(number: int):
	if label_tutorial.visible && number-tutorial_step == 1:
		tutorial_step = number
		match tutorial_step:
			1:
				label_tutorial.text = "Great! Now try moving to Forward - W."
			2:
				label_tutorial.text = "Great! Now try moving to Back - S."
			3:
				label_tutorial.text = "Excellent job! Great! Now try moving to left - A."
			4:
				label_tutorial.text = "Excellent job! Great! Now try moving to left - D."
			5:
				label_tutorial.text = "Bravo! Tutorial completed!"

func gametips(number: int):
	if label_tip.visible:
		match number:
			1: 
				label_tip.text = "The player is near the water, point the camera at the water and press the right mouse button to cast the fishing rod."
			_:	
				label_tip.text = ""

func _on_timer_fishcatched_timeout() -> void:
	state = playerstate.FISHCATCHED
	label_fishcatched.text = str(label_fishcatched.text.to_int() + 1)

func _on_confirmation_dialog_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")  # Przejdź do menu opcji	


func _on_confirmation_dialog_canceled() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	

func _on_area_tutorial_body_entered(body: Node3D) -> void:
	if body.name =="lake":
		gametips(1)
