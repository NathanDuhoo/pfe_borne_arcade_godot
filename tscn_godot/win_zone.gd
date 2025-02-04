extends Area3D

# Chemin vers la scène de victoire
const WIN_SCENE = "res://tscn_godot/win.tscn"

func _ready():
	# Connecte le signal "body_entered" à la fonction _on_body_entered
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	# Vérifie si le joueur est bien celui qui entre
	if body.is_in_group("player"):
		get_tree().change_scene_to_file(WIN_SCENE)
