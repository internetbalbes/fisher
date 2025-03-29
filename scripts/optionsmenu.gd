extends Control

@export var slider_volume: Slider
@export var checkbutton_tip: CheckButton

var config = ConfigFile.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if config.load("res://settings.cfg") == OK:
		slider_volume.value = config.get_value("audio", "volume", 50)
		checkbutton_tip.button_pressed = config.get_value("common", "tip", 0)

func _on_menubutton_back_pressed() -> void:
	# Zapisanie ustawień
	config.set_value("audio", "volume", slider_volume.value)
	# Ustawienie głośności na głównym busie audio
	var volume_db = slider_volume.value / 100.0 * -80.0  # Konwersja do skali decybeli (-80 dB to cisza)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)
	config.set_value("common", "tip", checkbutton_tip.button_pressed)
	config.save("res://settings.cfg")
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
