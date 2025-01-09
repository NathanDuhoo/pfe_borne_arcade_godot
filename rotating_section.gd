extends Node3D

@export var rotation_speed = 150.0  # Vitesse des rotations en degrés par seconde
@export var translation_speed = 30.0  # Vitesse des translations

# Rotations cibles
@export var target_rotation_x = 0.0  # Rotation finale sur l'axe X (vision horizontale)
@export var target_rotation_z = 0.0  # Rotation finale sur l'axe Z (vision inversée)
var current_rotation_x = 0.0  # Rotation actuelle sur l'axe X
var current_rotation_z = 0.0  # Rotation actuelle sur l'axe Z

# Translations cibles
@export var target_translation_y = 0.0  # Fin de la translation sur l'axe Y (pour positionner la caméra)
@export var current_translation_y = 0.0  # Position initiale sur l'axe Y
@export var target_translation_z = 0.0  # Fin de la translation sur l'axe Z (éloignement)
@export var current_translation_z = 0.0  # Position initiale sur l'axe Z

# Flag pour vérifier si les animations sont en cours
var is_transforming = false

# Référence à la caméra (modifie le chemin en fonction de ta hiérarchie de scène)
@onready var camera := $"../CameraPivot"

# Fonction appelée chaque frame
func _process(delta):
	if not is_transforming:
		return

	var animation_complete = true

	# Translation sur l'axe Y
	if current_translation_y < target_translation_y:
		var step_y_translation = translation_speed * delta
		current_translation_y += step_y_translation
		current_translation_y = min(current_translation_y, target_translation_y)
		var new_position = camera.transform.origin
		new_position.y = current_translation_y
		camera.transform.origin = new_position
		animation_complete = false

	# Translation sur l'axe Z
	if current_translation_z > target_translation_z:
		var step_z_translation = translation_speed * delta
		current_translation_z -= step_z_translation
		current_translation_z = max(current_translation_z, target_translation_z)
		var new_position = camera.transform.origin
		new_position.z = current_translation_z
		camera.transform.origin = new_position
		animation_complete = false

	# Rotation sur l'axe Z (inversion de la vision)
	if current_rotation_z < target_rotation_z:
		var step_z_rotation = rotation_speed * delta
		current_rotation_z += step_z_rotation
		current_rotation_z = min(current_rotation_z, target_rotation_z)  # Ne dépasse pas la cible
		camera.rotate_z(deg_to_rad(step_z_rotation))
		animation_complete = false

	# Rotation sur l'axe X (si besoin d'un ajustement vertical)
	if current_rotation_x > target_rotation_x:
		var step_x_rotation = rotation_speed * delta
		current_rotation_x -= step_x_rotation
		current_rotation_x = max(current_rotation_x, target_rotation_x)  # Ne dépasse pas la cible
		camera.rotate_x(deg_to_rad(-step_x_rotation))
		animation_complete = false

	# Vérifie si toutes les animations sont terminées
	if animation_complete:
		log_final_camera_state()
		is_transforming = false  # Arrête les animations

# Initialise les transformations
func start_transformations():
	# Réinitialise les positions et rotations de la caméra
	current_rotation_x = 0.0
	current_rotation_z = 0.0
	current_translation_y = 0.0
	current_translation_z = 0.0
	is_transforming = true  # Active les animations

# Log la position et la rotation finale pour le débogage
func log_final_camera_state():
	var position = camera.transform.origin
	var rotation = camera.rotation_degrees
	print("Final Camera Position: ", position)
	print("Final Camera Rotation: ", rotation)

# Déclenche les transformations lorsque le joueur entre dans une zone spécifique
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):  # Vérifie si l'objet appartient au groupe "player"
		start_transformations()  # Lance les transformations
