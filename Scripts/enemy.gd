extends CharacterBody3D


const SPEED = 4
const JUMP_VELOCITY = 4.5

var moveLeftChance
var moveRightChance
var moveForwardChance
var moveBackwardChance
var direction
var input_dir = Vector2(0, 0)


func _physics_process(delta: float) -> void:
	moveLeftChance = randf()
	moveRightChance = randf()
	moveForwardChance = randf()
	moveBackwardChance = randf()
	
	#Find out way to move enemy right or left, depending on chance from random variables.
	if moveLeftChance > .99:
		print("randomly moved left")
		input_dir = Vector2(0, -1)
	elif moveRightChance > .99:
		print("randomly moved right")
		input_dir = Vector2(0, 1)
	elif moveForwardChance > .99:
		print("randomly moved forward")
		input_dir = Vector2(-1, 0)
	elif moveBackwardChance > .99:
		print("randomly moved backward")
		input_dir = Vector2(1, 0)
	
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
