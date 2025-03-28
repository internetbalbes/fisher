extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_menubutton_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _on_menubutton_oprions_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/optionsmenu.tscn")  # Przejdź do menu opcji


func _on_menubutton_quit_pressed() -> void:
	get_tree().quit()
