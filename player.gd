extends CharacterBody3D

@export var speed = 14
@export var fall_acceleration = 75
@export var jump_force = 15
@export var max_camera_speed = 25

# Variables pour le mouvement
var target_velocity = Vector3.ZERO
var move_direction = Vector3.ZERO  # Direction actuelle du déplacement
@onready var camera := $"../CameraPivot/Camera3D"

var has_double_jumped = false

# Flags pour les commandes UDP
var move_left_flag = false
var move_right_flag = false
var move_forward_flag = false
var move_back_flag = true  # Toujours vrai pour un mouvement constant vers l'arrière

# Variables pour l'éloignement progressif de la caméra
var current_target_camera_distance = 50  # Distance initiale cible
@export var max_target_camera_distance = 70  # Distance maximale cible
@export var camera_recede_speed = 5  # Vitesse d'éloignement progressif

func _physics_process(delta):
	# Réinitialise la direction
	move_direction = Vector3.ZERO

	# Mouvement constant vers l'arrière
	move_direction.z += 1

	# Ajout des directions via les flags UDP
	if move_left_flag:
		move_direction.x -= 1
		move_direction.z += 2
	if move_right_flag:
		move_direction.x += 1
		move_direction.z += 2
	if move_forward_flag:
		move_direction.z -= 1

	# Ajout des directions via le clavier
	if Input.is_action_pressed("move_right"):
		move_direction.x += 1
	if Input.is_action_pressed("move_left"):
		move_direction.x -= 1
	if Input.is_action_pressed("move_back"):
		move_direction.z += 1
	if Input.is_action_pressed("move_forward"):
		move_direction.z -= 1
	if Input.is_action_just_pressed("jump"):
		jump()

	# Normalisation de la direction et mise à jour de l'orientation
	if move_direction != Vector3.ZERO:
		move_direction = move_direction.normalized()
		$Pivot.basis = Basis.looking_at(move_direction)

	# Mise à jour des vitesses en fonction de la direction
	target_velocity.x = move_direction.x * speed
	target_velocity.z = move_direction.z * speed

	# Gravité si le personnage est en l'air
	if not is_on_floor():
		target_velocity.y -= fall_acceleration * delta

	# Déplacement final
	velocity = target_velocity
	move_and_slide()

	# Ajuste la vitesse de la caméra
	adjust_camera_speed(delta)

# Commandes UDP
func move_left():
	move_left_flag = true

func move_right():
	move_right_flag = true

func move_forward():
	move_forward_flag = true

func move_back():
	move_back_flag = true

func stop_move_left():
	move_left_flag = false

func stop_move_right():
	move_right_flag = false

func stop_move_forward():
	move_forward_flag = false

func stop_move_back():
	move_back_flag = false

# Saut
func jump():
	if is_on_floor():
		target_velocity.y = jump_force
		has_double_jumped = false
	elif not has_double_jumped:
		target_velocity.y = jump_force
		has_double_jumped = true

# Ajustement de la vitesse de la caméra pour reculer progressivement
func adjust_camera_speed(delta):
	# Augmente progressivement la distance cible jusqu'à la distance maximale
	if current_target_camera_distance < max_target_camera_distance:
		current_target_camera_distance += camera_recede_speed * delta
		current_target_camera_distance = min(current_target_camera_distance, max_target_camera_distance)

	# Calcule la position cible de la caméra
	var target_camera_z = global_transform.origin.z + current_target_camera_distance
	var camera_position = camera.global_transform.origin.z

	# Calcule la vitesse de la caméra pour se rapprocher de la cible
	var camera_speed = (target_camera_z - camera_position) * delta * max_camera_speed
	camera_speed = clamp(camera_speed, -max_camera_speed, max_camera_speed)

	# Applique le déplacement sur l'axe Z
	camera.global_transform.origin.z += camera_speed * delta
