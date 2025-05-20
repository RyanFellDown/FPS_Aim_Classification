extends Control

@onready var main = $"../../"

func _on_button_pressed() -> void:
	main.pauseMenu()

func _on_button_2_pressed() -> void:
	get_tree().quit()

func _on_h_slider_value_changed(value: float) -> void:
	# Update sensitivity in a global singleton or player controller
	pass
