extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("res://settings.cfg") == OK:
		var volume = config.get_value("audio", "volume", 50)
		var volume_db = volume * 80 / 100.0 - 80.0  # Konwersja do skali decybeli (-80 dB to cisza)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
