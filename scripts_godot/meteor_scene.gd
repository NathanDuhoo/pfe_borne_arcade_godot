extends RigidBody3D

func _ready():
	# Vérifie si le signal est déjà connecté avant de le reconnecter
	if not body_entered.is_connected(self._on_body_entered):
		connect("body_entered", self._on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):  # Vérifie si l'objet appartient au groupe "player"
		print("🔥 Le joueur est touché par la météorite :", body.name)
		if body.has_method("lose_life"):  # Vérifie si le joueur a une méthode "lose_life"
			body.lose_life()  # Appelle lose_life() sur le joueur
		else:
			print("⚠️ Le joueur n'a pas de méthode lose_life()")
	else:
		print("⚠️ Collision ignorée avec :", body.name)
