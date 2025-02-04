extends Area3D

@export var laser_scene: PackedScene
@export var texture_rect_path: NodePath  # Chemin vers le TextureRect dans la hiérarchie
var client_node: ClientNode
var total_session_timer: Timer
var laser_spawn_timer: Timer
var active_lasers = []
var can_spawn_laser = true
var texture_rect: TextureRect  # Référence à l'effet d'alerte
var upcoming_laser_position = "center"  # Stocke la future position du laser
var platform_timer: Timer  # Timer pour faire clignoter la plateforme
var max_simultaneous_lasers = 1  # Commence avec un seul laser au début
var session_elapsed_time = 0.0  # Temps écoulé dans la session


func _ready():
	_initialize_texture_rect()

	client_node = get_tree().get_root().get_node("Main/ClientNode")
	if client_node == null:
		print("Erreur : Impossible de trouver le nœud ClientNode.")
	connect("body_entered", self._on_body_entered)

func _process(delta):
	if total_session_timer and total_session_timer.is_stopped() == false:
		session_elapsed_time += delta

		# Augmenter progressivement le nombre de lasers actifs
		if session_elapsed_time >= 20.0 and session_elapsed_time < 40.0:
			max_simultaneous_lasers = 2
		elif session_elapsed_time >= 40.0:
			max_simultaneous_lasers = 3

func _initialize_texture_rect():
	if texture_rect_path:
		texture_rect = get_node(texture_rect_path)
		if texture_rect and texture_rect is TextureRect:
			texture_rect.visible = false
		else:
			print("Erreur : Le noeud spécifié n'est pas un TextureRect.")
	else:
		print("Erreur : Aucun chemin de TextureRect spécifié.")

func _on_body_entered(body):
	if body.name == "Player":
		start_laser_sequence()

func start_laser_sequence():
	# Timer total de la session
	total_session_timer = Timer.new()
	total_session_timer.wait_time = 50.0
	total_session_timer.one_shot = true
	total_session_timer.connect("timeout", Callable(self, "_end_laser_session"))
	add_child(total_session_timer)
	total_session_timer.start()

	# **Détermination de la position du premier laser et affichage de l'alerte**
	_determine_laser_position()
	
	_display_laser_effect()

	# Timer de délai avant de commencer le spawn des lasers
	var initial_delay_timer = Timer.new()
	initial_delay_timer.wait_time = 5.0  # Temps avant que le laser apparaisse
	initial_delay_timer.one_shot = true
	initial_delay_timer.connect("timeout", Callable(self, "_start_laser_spawning"))
	add_child(initial_delay_timer)
	initial_delay_timer.start()

func _display_laser_effect():


	if texture_rect:
		# Mise à jour de la position du TextureRect selon le laser
		update_texture_position()
		texture_rect.visible = true
		var animation_player = texture_rect.get_node("MoveTexture")
		if animation_player:
			animation_player.play("new_animation")

	# Création d'un Timer pour cacher l'effet après 1 seconde
	var hide_effect_timer = Timer.new()
	hide_effect_timer.wait_time = 1.0
	hide_effect_timer.one_shot = true
	hide_effect_timer.connect("timeout", Callable(self, "_hide_texture_rect"))
	add_child(hide_effect_timer)
	hide_effect_timer.start()


func _toggle_platform_visibility():
	if texture_rect:
		texture_rect.visible = not texture_rect.visible

func _hide_texture_rect():
	if texture_rect:
		texture_rect.visible = false

func _start_laser_spawning():
	# Initialisation du timer de spawn des lasers (qui se déclenchera toutes les 2 secondes)
	laser_spawn_timer = Timer.new()
	laser_spawn_timer.wait_time = 2.0  # Les lasers apparaissent toutes les 2 secondes après le délai initial
	laser_spawn_timer.connect("timeout", Callable(self, "_spawn_laser"))
	add_child(laser_spawn_timer)
	laser_spawn_timer.start()

func _spawn_laser():

	if active_lasers.size() >= max_simultaneous_lasers:
		return

	_determine_laser_position()
	_display_laser_effect()

	# Timer pour faire apparaître le laser après l'effet
	var spawn_laser_timer = Timer.new()
	spawn_laser_timer.wait_time = 1.0
	spawn_laser_timer.one_shot = true
	spawn_laser_timer.connect("timeout", Callable(self, "_create_laser"))
	add_child(spawn_laser_timer)
	spawn_laser_timer.start()


func _determine_laser_position():
	# Choisir la position du laser AVANT son apparition
	var positions = ["far_left", "left", "center", "right", "far_right"]
	upcoming_laser_position = positions[randi() % positions.size()]  # Stocker la position sélectionnée

func _create_laser():
	send_platform_data(upcoming_laser_position)

	if laser_scene:
		var laser_instance = laser_scene.instantiate()
		get_parent().add_child(laser_instance)

		# Définir la position du laser en fonction de `upcoming_laser_position`
		match upcoming_laser_position:
			"far_left":
				laser_instance.scale = Vector3(100, 1, 15)
				laser_instance.global_transform.origin = global_transform.origin + Vector3(-40, -45, -25)
			"left":
				laser_instance.scale = Vector3(100, 1, 15)
				laser_instance.global_transform.origin = global_transform.origin + Vector3(-20, -45, -25)
			"far_right":
				laser_instance.scale = Vector3(100, 1, 15)
				laser_instance.global_transform.origin = global_transform.origin + Vector3(40, -45, -25)
			"right":
				laser_instance.scale = Vector3(100, 1, 15)
				laser_instance.global_transform.origin = global_transform.origin + Vector3(20, -45, -25)
			"center":
				laser_instance.scale = Vector3(100, 1, 15)
				laser_instance.global_transform.origin = global_transform.origin + Vector3(0, -45, -25)

		# Connecter les signaux de détection pour ce laser
		laser_instance.connect("body_entered", self._on_laser_body_entered)

		# Ajouter le laser à la liste des lasers actifs
		active_lasers.append(laser_instance)

		# Timer pour désactiver ce laser spécifique après 2 secondes
		var laser_timer = Timer.new()
		laser_timer.wait_time = 2.0
		laser_timer.one_shot = true
		laser_timer.connect("timeout", Callable(self, "_remove_laser").bind(laser_instance))
		add_child(laser_timer)
		laser_timer.start()

		# Timer pour réactiver le spawn de lasers
		var spawn_delay_timer = Timer.new()
		spawn_delay_timer.wait_time = 1.0
		spawn_delay_timer.one_shot = true
		spawn_delay_timer.connect("timeout", Callable(self, "_enable_laser_spawn"))
		add_child(spawn_delay_timer)
		spawn_delay_timer.start()

func update_texture_position():
	if texture_rect:
		match upcoming_laser_position:
			"far_left":
				texture_rect.position.x = 300  # À ajuster selon tes besoins
			"left":
				texture_rect.position.x = 500
			"center":
				texture_rect.position.x = 600
			"right":
				texture_rect.position.x = 800
			"far_right":
				texture_rect.position.x = 900

func _remove_laser(laser):
	if laser in active_lasers:
		active_lasers.erase(laser)
		laser.queue_free()
	else:
		print("Erreur : Tentative de suppression d'un laser non trouvé.")

func _enable_laser_spawn():
	can_spawn_laser = true

func _end_laser_session():
	# Arrêter les timers
	if laser_spawn_timer:
		laser_spawn_timer.stop()
		laser_spawn_timer.queue_free()
	
	# Supprimer tous les lasers restants
	for laser in get_parent().get_children():
		if laser.name.begins_with("Laser"):
			laser.queue_free()

func send_platform_data(position_platform):
	if client_node and client_node.is_connected:
		var platform_code = {"far_left": "1", "left": "2", "far_right": "3","right": "4", "center": "5"}
		client_node.send_data(platform_code[position_platform] + "\n")

func _on_laser_body_entered(body):
	if body.name == "Player":
		body.lose_life()  # Appelle la méthode lose_life() du joueur
