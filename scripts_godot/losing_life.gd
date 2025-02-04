extends Area3D

func _ready():
	# Connexion des signaux `body_entered` et `body_exited`
	connect("body_entered", self._on_body_entered)
	connect("body_exited", self._on_body_exited)
	
func _on_body_entered(body: Node3D) -> void:
	# Vérifie si l'objet détecté est le joueur
	if body.name == "Player":
		body.lose_life()  # Appelle la méthode lose_life() du joueur
		body.enter_lava()  # Active le saut continu

func _on_body_exited(body: Node3D) -> void:
	# Vérifie si l'objet détecté est le joueur
	if body.name == "Player":
		body.exit_lava()  # Désactive le saut continu
