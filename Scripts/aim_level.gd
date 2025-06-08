extends Node3D

@onready var timer: Timer = $Timer
@onready var camera_3d: Camera3D = $ProtoController/Head/Camera3D
@onready var proto_controller: CharacterBody3D = $ProtoController
@onready var start_ui = $UI/StartUI
@onready var start_button = $UI/StartUI/Button
@onready var end_ui = $UI/EndUI
@onready var results_container = $UI/EndUI/Panel/VBoxContainer
@onready var resume_button: Button = $UI/PauseUI/Button
@onready var quit_button: Button = $UI/PauseUI/Button2
@onready var pause_ui: Control = $UI/PauseUI
@onready var replay_button: Button = $UI/EndUI/Button


var training_started = false
var training_ended = false
var spawnObject = preload("res://Nodes/ball_train.tscn")
var randomY
var randomZ
var currentTime
var initialTime
var displayed = false
var totalGenerated = 0
var isPresent = true
var paused = false
var stats


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer = $Timer
	start_button.pressed.connect(_on_start_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	timer.timeout.connect(_on_training_ended)
	if not timer.timeout.is_connected(_on_training_ended):
		timer.timeout.connect(_on_training_ended)
		
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	end_ui.visible = false
	pause_ui.hide()


func _on_start_pressed():
	print("Start button pressed!")
	Engine.time_scale = 1
	# Hide the ball spawner logic or pause it here too.
	start_ui.visible = false
	timer.start()
	initialTime = timer.time_left
	
	#Set training started to true now, as it would call timeout too early before.
	training_started = true
	print(initialTime)


func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pauseMenu()
	#Check the current time each frame and if there is a ball present.
	currentTime = timer.time_left
	isPresent = camera_3d.isBallPresent()
	
	#If no ball and still time, generate a new one.
	if not isPresent and currentTime > 0:
		spawn()
		print("Current is ", currentTime)
		camera_3d.setBallPresent(true)
		camera_3d.isFirstShot = true
	
	#If the time is up, disable the player movements, return the stats, and display them.
	if currentTime == 0.0 and displayed == false and training_started:
		proto_controller.disablePlayer(true)
		displayed = true


func pauseMenu():
	if paused:
		pause_ui.hide()
		#get the mouse back AND stop raycast shooting
		proto_controller.disablePlayer(false)
		proto_controller.capture_mouse()
		Engine.time_scale = 1
	else:
		pause_ui.show()
		proto_controller.disablePlayer(true)
		Engine.time_scale = 0
	
	paused = !paused


#Spawn a ball in a random range in front of the players
func spawn():
	randomY = randf_range(.5, 7)
	randomZ = randf_range(-5, 5)
	print("Spawning..")
	totalGenerated += 1
	var obj = spawnObject.instantiate()
	obj.global_position = Vector3(5, randomY, randomZ)
	add_child(obj)


func _on_training_ended():
	training_ended = true
	#Return the results from the camera, create some new variables from them, and allow the end_ui to be visible.
	var results = camera_3d.returnStats()
	var reactionTime = float(initialTime)/float(results["Total Hits"])
	var missRate = results["Total Shots"] - results["Total Hits"]
	var totalMissed = float(results["Overshoot"] + results["Undershoot"])
	var overshot = float(results["Overshoot"])/totalMissed
	var undershot = float(results["Undershoot"])/totalMissed
	end_ui.show()

	
	#Returns a dictionary of all the stats; lowk more effecient to do this in the camera, but I can't be bothered.
	stats = {
		"Accuracy": str(results["Accuracy"]*100) + "%",
		"Avg Precision": str(results["Precision"]*100) + "%",
		"Avg Reaction Time": str(reactionTime*1000) + "ms",
		#"Avg First Shot Accuracy": str(results["First Shot Accuracy"]*100)+"%",
		"Missed Shots": missRate,
		"Avg Max Mouse Speed": results["Average Top Mouse Speed"],
		"Overshoot": str(overshot*100)+"%",
		"Undershoot": str(undershot*100)+"%"
	}
	
	#Set all the labels in the end_ui screen and clear the old ones too.
	for child in results_container.get_children():
		if child is Label:
			child.queue_free()
	
	#Add the labels from stats dictionary to the labels of the UI, so they display at end, and then export to CSV.
	for key in stats.keys():
		var label = Label.new()
		label.text = key + ": " + str(stats[key])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		results_container.add_child(label)
	export_results_to_csv()
	
	
func export_results_to_csv():
	#Set as a local folder/file path to record the training takes into a CSV file.
	var folder_path = "user://test_results"
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(folder_path):
		dir.make_dir_recursive(folder_path)

	# Timestamp for unique filename
	var timestamp = Time.get_datetime_string_from_system(true).replace(":", "-").replace(" ", "_")
	var file_path = folder_path + "/results_" + timestamp + ".csv"

	#If the file has successfully been made, update it with the data saved from the training session.
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var headers = stats.keys()
		var values = []
		for key in headers:
			values.append(str(stats[key]))
		
		# Write header row
		file.store_line(",".join(headers))
		# Write values row
		file.store_line(",".join(values))
		file.close()
		print("Exported to: ", file_path)
	else:
		print("Failed to create file at ", file_path)
