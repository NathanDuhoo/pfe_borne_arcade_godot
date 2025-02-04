extends Node3D

@export var rotation_speed = 150.0  # Vitesse des rotations en degrés par seconde
@export var translation_speed = 30.0  # Vitesse des translations

# Flags pour vérifier si des animations sont en cours (inutile ici mais conservé pour structure)
var is_transforming = false

# Fonction appelée chaque frame (désactivée car aucun effet de caméra)
func _process(_delta):
	# Rien à effectuer ici car aucun effet de caméra
	pass

# Initialise les transformations (désactivée pour éviter les effets de caméra)
func start_transformations():
	# Ne fait rien
	is_transforming = false

# Log la position et la rotation finale pour le débogage (inutile sans transformations)
func log_final_camera_state():
	# Supprimé car aucune caméra n'est modifiée
	pass

# Déclenchement des transformations (désactivé)
func _on_area_3d_body_entered(body: Node3D) -> void:
	# Vérifie si l'objet appartient au groupe "player" mais ne fait rien
	if body.is_in_group("player"):
		pass
