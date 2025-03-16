extends CharacterBody3D

# Zmienna prędkości ruchu
const SPEED = 10.0

const SENSITIVITY : float = 0.15
const MAX_VERTICAL_ANGLE = 90
const MIN_VERTICAL_ANGLE = -90

@export var camera : Camera3D

var vertical_angle = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
		vertical_angle = clamp(vertical_angle - event.relative.y * SENSITIVITY, MIN_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE)
		camera.rotation_degrees.x = vertical_angle
	
func _physics_process(delta: float) -> void:
	var input_direction = Input.get_vector("a", "d", "w", "s")
	var direction = Vector3(input_direction.x, 0, input_direction.y).normalized()
	var local_direction = transform.basis.x * direction.x + transform.basis.z * direction.z
	velocity.x = local_direction.x * SPEED
	velocity.z = local_direction.z * SPEED
	move_and_slide()
