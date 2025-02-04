extends CharacterBody3D

@export var speed = 15
@export var fall_acceleration = 75
@export var jump_force = 30
@export var max_camera_speed = 22.5
@export var camera_distance = 20
@export var camera_offset_z = -10  # Distance constante entre le personnage et la caméra

@export var offset_camera_1 = 10
@onready var client_node := $"../ClientNode"

var target_velocity = Vector3.ZERO
var move_direction = Vector3.ZERO
@onready var camera := $"../CameraPivot/Camera3D"
@onready var camera2 := $"../SubViewport/Camera3DBarnaby"
@onready var lives_label := $"../FPSLabel"

const GameOverScreen = preload("res://tscn_godot/game_over.tscn")
var has_double_jumped = false

var jump_count = 0  # Nombre de sauts effectués
var max_jump_count = 2  # Limitation normale des sauts
var in_lava = false  # Détermine si le joueur est dans la lave

# Flags pour les commandes UDP
var move_left_flag = false
var move_right_flag = false
var move_forward_flag = false
var move_back_flag = false  # Déplacement manuel sur Z

# Nouvelle variable de contrôle
var auto_move_z = true  # Définit si le Z est auto ou manuel

# Système de vie
var lives = 8  # Le joueur commence avec 7 vies

# Gestion de l'invincibilité
var is_invincible = false  # Indique si le joueur est invincible
@export var invincibility_duration = 2.0  # Durée d'invincibilité en secondes
@onready var invincibility_timer := Timer.new()

func _ready():
	add_to_group("player")
	# Initialisation du Timer d'invincibilité
	invincibility_timer.one_shot = true
	invincibility_timer.wait_time = invincibility_duration
	add_child(invincibility_timer)
	invincibility_timer.connect("timeout", self._on_invincibility_timeout)
	
	client_node = get_tree().get_root().get_node("Main/ClientNode")
	if client_node == null:
		print("Erreur : Impossible de trouver le nœud ClientNode.")
	
	# Met à jour l'affichage initial des vies et des FPS
	update_lives_label()
	
func _physics_process(delta):
	# Vérifie si l'objet est bien dans l'arbre de scène avant d'exécuter la physique
	if not is_inside_tree():
		return

	# Réinitialise la direction
	move_direction = Vector3.ZERO
	
	if is_on_floor():
		jump_count = 0  # Réinitialise le compteur de saut

	# Ajout des directions via les flags UDP
	if move_left_flag:
		move_direction.x -= 1
	if move_right_flag:
		move_direction.x += 1
	if move_forward_flag:
		move_direction.z -= 1
	if move_back_flag:
		move_direction.z += 1

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

	# Ajout du mouvement automatique sur Z si activé
	if auto_move_z:
		move_direction.z += 1

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

	# Vérifie si `global_transform` est bien accessible
	if is_inside_tree() and has_method("get_global_transform"):
		if global_transform.origin.y <= -200:
			lives = 0
			game_over()

	# Déplacement final en s'assurant que l'objet est bien dans l'arbre
	if is_inside_tree():
		velocity = target_velocity
		move_and_slide()

	# Ajuste la vitesse des caméras
	adjust_camera_speed(delta)
	update_lives_label()


# Désactive le déplacement automatique sur Z et ajuste la logique de la caméra
func stop_auto_move_z():
	auto_move_z = false


# Active le déplacement automatique sur Z
func start_auto_move_z():
	auto_move_z = true

func jump():
	if in_lava:
		# Saut continu activé
		target_velocity.y = jump_force
		return
	else:
		# Saut normal (double saut)
		if is_on_floor() or jump_count < max_jump_count:
			target_velocity.y = jump_force
			jump_count += 1

# Ajustement de la caméra pour suivre le personnage
func adjust_camera_speed(delta):
	if not is_inside_tree():
		return
	# Calcul de la position cible de la caméra
	var camera_position = camera.global_transform.origin

	# Calcul de la position cible uniquement sur l'axe Z
	var target_camera_z = global_transform.origin.z - camera_offset_z

	# Calcul de la vitesse de déplacement sur l'axe Z uniquement
	var camera_speed = (target_camera_z - camera_position.z) * max_camera_speed * delta

	# Appliquer le mouvement uniquement sur l'axe Z
	camera_position.z += camera_speed

	# Mettre à jour la position de la caméra
	camera.global_transform.origin = Vector3(
		camera.global_transform.origin.x,  # X reste inchangé
		camera.global_transform.origin.y,  # Y reste inchangé
		camera_position.z                 # Z mis à jour
	)

	if auto_move_z:
		target_camera_z += offset_camera_1  # Ajoute un offset seulement si auto_move_z est activé
	
func lose_life():
	if is_invincible:
		return

	lives -= 1
	print("🔴 Le joueur a perdu une vie. Vies restantes :", lives)

	update_lives_label()

	if lives <= 0:
		print("[GAME OVER] Le joueur n'a plus de vie !")
		
		# Vérifie si l'objet est encore dans l'arbre avant d’appeler game_over
		if not is_inside_tree():
			print("⚠️ Le joueur n'est plus dans l'arbre, annulation de game_over()")
			return
		
		# Utilise call_deferred pour s'assurer que game_over est appelé après ce cycle de frame
		call_deferred("game_over")
	else:
		activate_invincibility()

func game_over():
	if get_tree() == null:
		print("❌ Erreur : get_tree() est null, impossible de changer de scène.")
		return
	
	print("🚀 Changement de scène vers Game Over...")
	get_tree().change_scene_to_file("res://tscn_godot/game_over.tscn")  # Mets ici le bon chemin


func activate_invincibility():
	is_invincible = true
	invincibility_timer.start()

func _on_invincibility_timeout():
	is_invincible = false

func update_lives_label():
	if lives_label:
		# Calcule les FPS
		var fps = Engine.get_frames_per_second()
		# Met à jour le texte avec les vies et les FPS
		lives_label.text = "Vies : " + str(lives) + " | FPS : " + str(fps)
		
func jump_high():
	jump()

# Ajuste l'état lorsque le joueur entre ou sort de la lave
func enter_lava():
	in_lava = true
	jump_high()

func exit_lava():
	in_lava = false

# Réactive le déplacement automatique sur l'axe Z
func resume_auto_move_z():
	auto_move_z = true
