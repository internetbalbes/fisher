extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
# camer's sensitivity
const SENSITIVITY = 0.1
const FISHCATCHED_MAX = 10
 # siła grawitacji
const gravity = Vector3(0, -9.8, 0) 
# poziom wody
const water_level = -5.0
# Długość linki
const ROD_COORD_LENGTH: float = 20.0
# angle catching rod
const ROD_THROW_ANGLE: float = 45.0
# power catching rod 
var ROD_THROW_FORCE: float = 100.0
# old coordinate rod
var rod_position : Vector3 = Vector3.ZERO

@export var label_tip: Label
@export var label_fishcatched: Label
@export var ray_camera : RayCast3D
@export var timer_fishcatched: Timer
@export var image_fishcatched: TextureRect
@export var dialog_gameend: ConfirmationDialog
@export var image_pointcatch: TextureRect
@export var rod: Node3D
@export var rod_shaft: MeshInstance3D
@export var rod_float: StaticBody3D
@export var rod_float_mesh: MeshInstance3D

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

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		label_tip.visible = config.get_value("common", "tip", 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	image_pointcatch.visible = false
	rod.visible = false	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if  state == playerstate.IDLE &&  event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if rod_float.position == Vector3(0, 1, 0):			
				image_pointcatch.visible = true
				ray_camera.enabled = true
				state = playerstate.FINDLAKE
			else:
				include_object(rod, self)
				rod.position = rod_position
				timer_fishcatched.stop()
				state = playerstate.CASTFISHRODOFF_PROCESS	
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
			rod_water_point_cross = ray_camera.get_collision_point()
			image_pointcatch.visible = false
			rod_float.position = Vector3(0, 1, 0)
			rod_float_mesh.mesh.material.albedo_color = Color(0, 1, 0)
			rod.rotation = Vector3(-deg_to_rad(0), 0, 0)			
			state = playerstate.CASTFISHRODON_PROCESS
		else:
			state = playerstate.IDLE
		ray_camera.enabled = false		
	elif state == playerstate.CASTFISHRODON_PROCESS:
		if rad_to_deg(-rod.rotation.x) < ROD_THROW_ANGLE:
			rod.rotation += Vector3(-deg_to_rad(ROD_THROW_FORCE * delta), 0, 0)
		else:
			rod_float.global_transform.origin = rod_water_point_cross
			state = playerstate.CASTFISHRODON
	elif state == playerstate.CASTFISHRODON:
		rod_position = rod.position
		include_object(rod, get_tree().root)
		timer_fishcatched.wait_time = randf_range(5, 10)
		timer_fishcatched.start()
		state = playerstate.IDLE
	elif state == playerstate.CASTFISHRODOFF_PROCESS:
		rod_float.position = Vector3(0, 1, 0)
		if rad_to_deg(-rod.rotation.x) > 0:
			rod.rotation -= Vector3(-deg_to_rad(ROD_THROW_FORCE * delta), 0, 0)
		else:
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
			rod.visible = false	
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
				label_tip.text = "Left mouse button to cast a fishing rod"
			_:	
				label_tip.text = ""

func include_object(obj, obj_to):
# Zapisujemy globalną transformację obiektu (jego pozycję w przestrzeni świata)
	var obj_global_transform = obj.global_transform
	# Usuwamy obiekt z jego rodzica
	obj.get_parent().remove_child(obj)
	# Dodajemy obiekt z powrotem do głównego drzewa lub innego węzła
	obj_to.add_child(obj)  # Przykład: dodanie do głównej sceny (root)
	# Przywracamy obiektowi tę samą globalną transformację, aby pozostał w tym samym miejscu
	obj.global_transform = obj_global_transform

func _on_timer_fishcatched_timeout() -> void:
	rod_float_mesh.mesh.material.albedo_color = Color(1, 0, 0)  # Czerwony kolor (RGB)

func _on_confirmation_dialog_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")  # Przejdź do menu opcji	


func _on_confirmation_dialog_canceled() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")  # Przejdź do menu opcji	

func _on_area_tip_body_entered(body: Node3D) -> void:
	if body.name =="lake":
		near_lake = true
		gametips(1)
		image_pointcatch.visible = true
		rod.visible = true

func _on_area_tip_body_exited(body: Node3D) -> void:
	if body.name =="lake":
		near_lake = false
		gametips(0)
		if rod_float.position == Vector3(0, 1, 0):
			image_pointcatch.visible = false
			rod.visible = false
		else:
			include_object(rod, self)
			rod.position = rod_position
			timer_fishcatched.stop()
			state = playerstate.CASTFISHRODOFF_PROCESS
