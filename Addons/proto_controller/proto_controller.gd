# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D


## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.0006
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"
## Name of Input Action to shoot.
@export var shoot : String = "shoot"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var disablePlayerMovements = false
var dontMovePlayer = true
var capturingMouse = false
var mouseVelocity = 0

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var shootRayCast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var aim_trainer: Node3D = $".."


func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	shootRayCast.enabled = false


func disablePlayer(boolDisable):
	disablePlayerMovements = boolDisable



#Just checking if the game's started yet; if so, then allow raycasts for the camera (aka score updates).
func hasStarted():
	return aim_trainer.training_started

#Just checking if the game's ended yet; if so, then don't allow raycasts for the camera (aka no score updates).
func hasEnded():
	return aim_trainer.training_ended

func hasPaused():
	return aim_trainer.paused


func getMouseVelocity():
	var finalTopVelocity = mouseVelocity
	mouseVelocity = 0
	return finalTopVelocity

func storeMouseVelocities():
	var speed = Input.get_last_mouse_velocity().length()
	if speed > mouseVelocity:
		mouseVelocity = speed

func _unhandled_input(event: InputEvent) -> void:
	#Once we're done, disable the player mouse.
	if not disablePlayerMovements:
		# Mouse capturing
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and aim_trainer.training_started:
			capture_mouse()
		if Input.is_key_pressed(KEY_ESCAPE):
			release_mouse()
		
		# Look around
		if mouse_captured and event is InputEventMouseMotion:
			rotate_look(event.relative)
		
		# Toggle freefly mode
		if can_freefly and Input.is_action_just_pressed(input_freefly):
			if not freeflying:
				enable_freefly()
			else:
				disable_freefly()

func _physics_process(delta: float) -> void:
	#Just disabling player movement in general, could do the same as mouse if we still want player movements though.
	if not dontMovePlayer:
		# If freeflying, handle freefly and nothing else
		if can_freefly and freeflying:
			var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
			var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			motion *= freefly_speed * delta
			move_and_collide(motion)
			return
		
		# Apply gravity to velocity
		if has_gravity:
			if not is_on_floor():
				velocity += get_gravity() * delta

		# Apply jumping
		if can_jump:
			if Input.is_action_just_pressed(input_jump) and is_on_floor():
				velocity.y = jump_velocity

		# Modify speed based on sprinting
		if can_sprint and Input.is_action_pressed(input_sprint):
				move_speed = sprint_speed
		else:
			move_speed = base_speed

		# Apply desired movement to velocity
		if can_move:
			var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
			var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if move_dir:
				velocity.x = move_dir.x * move_speed
				velocity.z = move_dir.z * move_speed
			else:
				velocity.x = move_toward(velocity.x, 0, move_speed)
				velocity.z = move_toward(velocity.z, 0, move_speed)
		else:
			velocity.x = 0
			velocity.y = 0
		
		# Use velocity to actually move
		move_and_slide()
		
		
	if aim_trainer.training_started and not aim_trainer.training_ended and not capturingMouse:
		capture_mouse()
		capturingMouse = true
	elif aim_trainer.training_started and aim_trainer.training_ended and capturingMouse:
		release_mouse()
		capturingMouse = false


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)
	
	#Need to get the speed of the player camera from here to calculate flick or tracking
	#If the average peak is really fast, it could be flick, jitter, etc
	#If the average peak is not super fast, it could be tracker, smooth, etc.
	
	#Overshoot amount would be the OTHER issue to try and calculate, like how much farther
	#there mouse moves over and to the other side of the target per kill, could be ruined if
	#I have more than one ball, though.


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
