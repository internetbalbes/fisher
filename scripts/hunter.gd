extends CharacterBody3D

const SPEED = 2.5

@export var player: CharacterBody3D
@export var dialog_gameend: ConfirmationDialog
@export var map: Node3D
@export var ray_cast_ground: RayCast3D


var direction_hunter = "up"
var is_see_player : bool = false
var ground_plane: StaticBody3D
var last_coord : Vector3 = Vector3.ZERO

func _ready() -> void:
	ground_plane = map.get_node("ground_plane").get_child(0)	

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()
	else:		
		if is_see_player:
			if player.global_transform.origin.distance_to(global_transform.origin) < 1.1:
				if !dialog_gameend.is_visible():
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					dialog_gameend.popup_centered()  # Wyświetla dialog na ekranie
			else:			
				var direction = (player.global_transform.origin - global_transform.origin).normalized()
				velocity = direction * SPEED
				# Poruszamy bota w kierunku gracza
				move_and_slide()
			 	# Obracanie bota w kierunku gracza
				if direction.length() > 0:
					var target_rotation = direction.angle_to(Vector3.FORWARD)
					rotation.y = lerp_angle(rotation.y, target_rotation, SPEED * delta)
		else:			
			if !ray_cast_ground.is_colliding() || ray_cast_ground.get_collider() != ground_plane:
				rotate_y(-deg_to_rad(randf_range(5, 10)))
			else:
				# Get the input direction and handle the movement/deceleration.
				# As good practice, you should replace UI actions with custom gameplay actions.
				last_coord = global_transform.origin
				var input_dir = Vector2.ZERO
				if direction_hunter == "left":
					input_dir = Vector2(-1, 0)
				elif direction_hunter == "right":
					input_dir = Vector2(1, 0)	
				elif direction_hunter == "up":
					input_dir = Vector2(0, -1)
				elif direction_hunter == "down":
					input_dir = Vector2(0, 1)
				var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
				if direction != Vector3.ZERO:
					velocity.x = direction.x * SPEED
					velocity.z = direction.z * SPEED
				else:
					velocity.x = move_toward(velocity.x, 0, SPEED)
					velocity.z = move_toward(velocity.z, 0, SPEED)
				move_and_slide()
				if global_transform.origin.distance_to(last_coord) < 0.001:
					rotate_y(-deg_to_rad(randf_range(5, 10)))

func _on_area_hunter_body_entered(body: Node3D) -> void:
	if body == player:
		is_see_player = true


func _on_area_hunter_body_exited(body: Node3D) -> void:
	if body == player:
		is_see_player = false
