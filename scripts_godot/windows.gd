extends Node

func _ready():
	# Mettre la fenêtre principale en plein écran
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Configurer une deuxième fenêtre en plein écran
	var window = $Window
	window.name = "Barnaby"
	window.size = Vector2(1366, 768)  # Taille de la deuxième fenêtre
	window.mode = Window.MODE_FULLSCREEN  # Activer le plein écran pour la deuxième fenêtre
	window.set_current_screen(0)
	window.show()
