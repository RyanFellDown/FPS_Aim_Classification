extends Camera3D
@onready var proto_controller: CharacterBody3D = $"../.."
@onready var gun_noise: AudioStreamPlayer = $"../../Sounds/GunNoise"
@onready var ball_noise: AudioStreamPlayer = $"../../Sounds/BallNoise"
@onready var hit_marker: TextureRect = $HitMarker
@onready var miss_marker: TextureRect = $MissMarker
@onready var miss_timer: Timer = $MissTimer
@onready var hit_timer: Timer = $HitTimer


#VARIABLES:
	#(DONE)
	#Reaction Time: tells how fast player reacted to the ball
	#Accuracy: generally how accurate the player was
	#Precision: shows how precise the player was, so just because a player was accurate doesn't mean they are hitting vital spots
	#First shot accuracy: how often they hit the target on the first shot
	#Speed of Mouse: shows whether the user is more of a flicking or tracking aim style; both could get similar scores BUT have
	#have differing styles of aim
	#Overshoot percentage: detect how far someone goes past the ball when they shoot IF they don't hit it
	#Undershoot percentage: detect how far someone goes before the ball when they shoot IF they don't hit it


#Variables to do with the shots of the player.
var shotsHit = 0
var shotsTaken = 0
var accuracy = 0
var totalTime = 0
var precision = 0
var isPresent = false
var isFirstShot = true
var firstShotsTaken = 0
var totalFirstShots = 0

#Variables to do with the raycast.
var rayRange = 50
var Center = 0
var RayEnd = 0
var RayOrigin = 0
var intersection = 0
var newIntersection = 0

#Variables to do with the actual mouse position of the player.
var mousePosition = 0
var initialPosition = Vector3(0, 0, 0)
var farthestPosition = 0
var ballPosition = 0
var center = 0
var offShoot = 0
var highestSpeeds = 0
var maxMouseVelocities = []
var ball
var overshootPercent = 0
var undershootPercent = 0

func _ready() -> void:
	hit_marker.visible = false
	miss_marker.visible = false


func _process(delta: float) -> void:
	if proto_controller.hasStarted() and not proto_controller.hasEnded():
		proto_controller.storeMouseVelocities()


func _input(event):
	var gameStart = proto_controller.hasStarted()
	var gameEnd = proto_controller.hasEnded()
	var gamePaused = proto_controller.hasPaused()
	if event.is_action_pressed("shoot") and gameStart and not gameEnd and not gamePaused:
		hit_marker.visible = false
		miss_marker.visible = false
		shotsTaken += 1
		gun_noise.play()
		GetCameraCollision()


func GetCameraCollision():
	var Center = get_viewport().get_size()/2
	var RayOrigin = project_ray_origin(Center)
	var RayDir = project_ray_normal(Center).normalized()
	var RayEnd = RayOrigin + project_ray_normal(Center)*rayRange
	var newIntersection = PhysicsRayQueryParameters3D.create(RayOrigin, RayEnd)
	var intersection = get_world_3d().direct_space_state.intersect_ray(newIntersection)
	
	#This works, so check for this and then don't get the overshoot if this happens
	#So do this, or we try and create a giant invisible wall that they can hit, and otherwise it returns nothing.
	if intersection.is_empty():
		miss_marker.visible = true
		print("Empty")
	var ballShot = intersection.collider
	center = ballShot.global_transform.origin

	
	#If it's not empty and it's a ball, note that it's been hit, add one to toal hit AND number of shots, update time and queue_free ball.
	if (not intersection.is_empty()) and (intersection.collider.name == "BallTrainBody"):
		#Update the total time, what was shot, and number of shots hit.
		print("Hit a target")
		hit_marker.visible = true
		hit_timer.start()
		print("still going through script tho")
		ball_noise.play()
		shotsHit += 1
		totalTime += ballShot.getTotalTime()
		
		#Update where the center of the ball was versus where the player hit for precision.
		precision += ballShot.calculate_precision(center, self, get_viewport().get_mouse_position())
		
		#Delete the ball, say no ball present, and 
		ballShot.queue_free()
		isPresent = false
		if isFirstShot:
			firstShotsTaken = firstShotsTaken + 1
			totalFirstShots = totalFirstShots + 1
			isFirstShot = false
		
		#Store the max mouse velocity amongst the others.
		maxMouseVelocities.append(proto_controller.getMouseVelocity())
		
		#Storing the initial position of the raycast to find direction for over and under shooting.
		initialPosition = intersection["position"]
	
	elif(not intersection.is_empty()) and (intersection.collider.name == "Over_Undershoot Plane"):
		#Not actually shot the ball, but instead the plane on the same axis, so I wanna see it's position in comparison to ball position.
		miss_marker.visible = true
		miss_timer.start()
		var planeShot = intersection["position"]
		for node in get_tree().get_nodes_in_group("ball"):
			ball = node
		if ball != null:
			print(evaluate_overshoot_or_undershoot(ball, planeShot))
	
	
	#This is where you log a first shot being missed AND what the overshoot OR undershoot of the player's shot was.
	else:
		print("No ball hit")
		miss_marker.visible = true
		if isFirstShot:
			totalFirstShots = totalFirstShots + 1
			isFirstShot = false
	
	accuracy = float(shotsHit)/float(shotsTaken)

func _on_hit_timer_timeout() -> void:
	hit_marker.visible = false

func _on_miss_timer_timeout() -> void:
	miss_marker.visible = false


#I think I need to get an initial position for where the raycast SHOULD hit the plane and thus get the direction from it;
#then, I can calculate if it's overshoot or undershoot.
func evaluate_overshoot_or_undershoot(ball: Object, PlaneIntersection: Vector3):
	var direction = ball.global_transform.origin.z - PlaneIntersection.z
	
	# If ball is to the right (positive x) of the player
	if ball.global_transform.origin.z >= 0:
		if direction < 0:
			overshootPercent += 1
			return "Overshoot"
		else:
			undershootPercent += 1
			return "Undershoot"
	
	# If ball is to the left (negative x)
	elif ball.global_transform.origin.z < 0:
		if direction > 0:
			overshootPercent += 1
			return "Overshoot"
		else:
			undershootPercent += 1
			return "Undershoot"
	
	# If directly in front
	return "Neither – Direct Hit or Centered"



#Return if the ball is present or not, if we shot it this returns false, and therefore we can create a new ball.
func isBallPresent():
	return isPresent


#Once created a new ball, set isPresent to true from the main level script.
func setBallPresent(setTo):
	isPresent = setTo


#Return all the stats we've added up in this dictionary in the main level to display.
func returnStats() -> Dictionary:
	var total = 0
	if maxMouseVelocities.size() != 0:
		for speed in maxMouseVelocities:
			total += speed
	return {
		"Accuracy": accuracy,
		"Total Hits": shotsHit,
		"Total Lifetimes": totalTime,
		"Total Shots": shotsTaken,
		"First Shot Accuracy": float(firstShotsTaken)/float(totalFirstShots),
		"Precision": float(precision)/float(shotsHit),
		"Average Top Mouse Speed": float(total)/float(shotsHit),
		"Overshoot": overshootPercent,
		"Undershoot": undershootPercent
	}
