extends Area3D

# Récupère le nœud AnimationPlayer
@onready var animation_player: AnimationPlayer = $DoorAnimationPlayer
var camera

func _ready():
	# Connexion du signal `body_entered`
	connect("body_entered", self._on_door_trigger_body_entered)
	
	# Vérifie si l'AnimationPlayer est bien trouvé
	if animation_player == null:
		print("Erreur : AnimationPlayer introuvable.")
	else:
		print("Succès : AnimationPlayer trouvé.")
		
	camera = get_tree().get_root().get_node("Main/CameraPivot")
	if camera == null:
		print("camera introuvable")
	else:
		print("camera trouvée")

func _on_door_trigger_body_entered(body: Node3D) -> void:
	# Vérifie si l'objet détecté est le joueur
	if body.name == "Player":
		print("Le joueur est entré dans la zone !")
		open_door()

# Fonction pour jouer l'animation d'ouverture de la porte
func open_door():
	print("Avant lancement de l'animation")
	if animation_player && !(Global.triggered):
		print("Lancement de l'animation 'new_animation'")
		animation_player.play("new_animation")
		Global.triggered = true
	else:
		print("Erreur : AnimationPlayer non défini !")

	# Désactiver le mouvement automatique sur Z du joueur
	var player = get_tree().get_root().get_node("Main/Player")  # Ajuste le chemin si nécessaire
	if player:
		player.stop_auto_move_z()
		print("Déplacement automatique désactivé pour le joueur.")
	else:
		print("Erreur : Joueur introuvable !")
