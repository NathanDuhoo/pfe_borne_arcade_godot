extends AnimatedSprite3D

@onready var player := $"../Player"
@onready var camera2 := $"../SubViewport/Camera3DBarnaby"
@onready var animated_sprite := $"../Barnaby"

@export var max_camera_speed = 22.5
@export var camera_distance = 50.0
@export var min_distance_from_player = 50.0
@export var max_distance_z_from_player = 50
@export var barnaby_speed = 10.0  # Vitesse de déplacement de Barnaby

func _ready():
	if sprite_frames.has_animation("barnaby"):
		animation = "barnaby"
		play()
	else:
		print("L'animation 'barnaby' n'existe pas dans SpriteFrames !")

func _process(delta):
	if not player:
		print("Le joueur n'est pas trouvé !")
		return

	# Vérifier la distance et ajuster en douceur
	adjust_distance_from_player(delta)

	# Synchroniser la vitesse en Z uniquement si le joueur bouge
	# Synchroniser la vitesse en Z uniquement si le joueur bouge
	var player_velocity_z = player.velocity.z if player is CharacterBody3D else 0
	if abs(player_velocity_z) > 0.1:  # Se déplace uniquement si le joueur avance
		global_transform.origin.z = move_toward(global_transform.origin.z, global_transform.origin.z + player_velocity_z * delta, barnaby_speed * delta)

	# Ajuster la caméra en douceur
	adjust_camera2_speed(delta)

func adjust_distance_from_player(delta):
	var player_position = player.global_transform.origin
	var barnaby_position = global_transform.origin

	# Vérification de la distance uniquement sur Z
	var distance_z = abs(barnaby_position.z - player_position.z)

	# Si Barnaby est trop proche, il doit s'arrêter et ne pas "s'envoler"
	if distance_z < min_distance_from_player:
		global_transform.origin.z = move_toward(barnaby_position.z, player_position.z - min_distance_from_player, barnaby_speed * delta)

	# Si Barnaby dépasse la distance max en Z, il doit être ramené progressivement
	if distance_z > abs(max_distance_z_from_player):
		global_transform.origin.z = move_toward(barnaby_position.z, player_position.z + max_distance_z_from_player, barnaby_speed * delta)

func adjust_camera2_speed(delta):
	var target_camera_z = global_transform.origin.z + camera_distance
	var camera_position_z = camera2.global_transform.origin.z

	# Ajustement progressif de la caméra
	camera2.global_transform.origin.z = move_toward(camera_position_z, target_camera_z, max_camera_speed * delta)
