extends Node3D

var timeAlive = 0
const MAX_RADIUS = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("ball")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timeAlive += delta

func getTotalTime():
	return timeAlive

func calculate_precision(center: Vector3, camera: Camera3D, mouse_position: Vector2) -> float:
	#Get the origin and direction of camera raycast at hit time.
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_dir = camera.project_ray_normal(mouse_position)
	
	# Project center of ball onto ray.
	var to_center = center - ray_origin
	var distance_along_ray = to_center.dot(ray_dir)
	var closest_point_on_ray = ray_origin + ray_dir * distance_along_ray

	#Get the distance to the center from mouse position, and thus get precision of that shot.
	var distance_to_center = center.distance_to(closest_point_on_ray)
	var precision = 1.0 - clamp(distance_to_center / MAX_RADIUS, 0.0, 1.0)

	return precision



func calculate_offshoot(center: Vector3, camera: Camera3D, mouse_position: Vector2) -> float:
	#Get the origin and direction of camera raycast at hit time.
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_dir = camera.project_ray_normal(mouse_position)
	
	# Project center of ball onto ray.
	var to_center = center - ray_origin
	var distance_along_ray = to_center.dot(ray_dir)
	var closest_point_on_ray = ray_origin + ray_dir * distance_along_ray

	#Get the distance to the center from mouse position, and thus get precision of that shot.
	var distance_to_center = center.distance_to(closest_point_on_ray)

	return distance_to_center
