extends Node3D

# Chemins vers les plateformes
@export var cage1: NodePath
@export var cage2: NodePath
@export var cage3: NodePath
@export var cage4: NodePath

# Vitesse initiale de chute
@export var initial_fall_speed: float = 15.0  # Vitesse initiale sur l'axe Y
@export var max_fall_speed: float = 110.0  # Vitesse maximale de chute
@export var session_duration: float = 60.0  # Durée de la session en secondes

# Variables locales
var local_triggered: bool = false
var elapsed_time: float = 0.0  # Temps écoulé depuis le début de la session
var fall_speed: float = initial_fall_speed  # Vitesse de chute actuelle
var is_falling: bool = false  # Empêche plusieurs chutes en parallèle
var current_cage: NodePath = NodePath()  # La plateforme actuellement en chute (initialisée vide)

# Sauvegarde des positions initiales
var initial_positions: Dictionary = {}

# Liste des plateformes
var cages: Array = []

# Timer de session
var session_active: bool = false

func _ready():
	# Sauvegarde les positions initiales des cages
	cages = [cage1, cage2, cage3, cage4]
	for cage_path in cages:
		var cage = get_node(cage_path)
		if cage:
			initial_positions[cage_path] = cage.global_transform.origin

func _process(delta):
	if Global.triggered and not local_triggered:
		local_triggered = true
		var delay_timer = Timer.new()
		delay_timer.wait_time = 5.0
		delay_timer.one_shot = true
		delay_timer.connect("timeout", Callable(self, "_start_platform_fall_sequence"))
		add_child(delay_timer)
		delay_timer.start()
	
	if session_active:
		_process_falling_platform(delta)

func _start_platform_fall_sequence():
	session_active = true
	elapsed_time = 0.0
	fall_speed = initial_fall_speed
	is_falling = false

	_start_platform_warning()

func _process_falling_platform(delta):
	elapsed_time += delta
	fall_speed = lerp(initial_fall_speed, max_fall_speed, elapsed_time / session_duration)

	if is_falling and current_cage != NodePath():
		var cage = get_node(current_cage)
		if cage:
			var new_position = cage.global_transform.origin
			new_position.y -= fall_speed * delta
			cage.global_transform.origin = new_position

			if new_position.y < -100:
				reset_platform(current_cage)
				is_falling = false
				_start_platform_warning()

	if elapsed_time >= session_duration:
		reset_all_platforms()
		Global.triggered = false
		local_triggered = false
		session_active = false
		elapsed_time = 0.0
		fall_speed = initial_fall_speed
		
		# Réactivation du déplacement du joueur
		var player = get_tree().get_root().get_node("Main/Player")
		if player:
			player.resume_auto_move_z()  # Vérifie que cette fonction existe dans le script du joueur
		else:
			print("Erreur : Joueur introuvable !")

func _start_platform_warning():
	if is_falling:
		return

	current_cage = cages[randi() % cages.size()]
	var platform = get_node(current_cage)

	if not platform:
		print("Erreur : Impossible de récupérer la plateforme.")
		return
	

	# Calcul du temps de clignotement en fonction de la vitesse de chute
	var blink_duration = _calculate_blink_duration()
	
	_toggle_platform_clignotement(platform, blink_duration)

func _toggle_platform_clignotement(platform, blink_duration):
	if not platform:
		print("Erreur : Impossible de clignoter, plateforme non définie.")
		return

	var blink_times = 5
	for i in range(blink_times):
		await get_tree().create_timer(blink_duration / blink_times).timeout
		platform.visible = not platform.visible
	
	platform.visible = true
	
	start_fall()

func start_fall():
	is_falling = true

func _calculate_blink_duration():
	# Ajuste la durée entre 2 et 4 secondes en fonction de la vitesse de chute
	var min_time = 1.0
	var max_time = 2.3
	return max_time - ((fall_speed - initial_fall_speed) / (max_fall_speed - initial_fall_speed)) * (max_time - min_time)

func reset_platform(cage_path: NodePath):
	var cage = get_node(cage_path)
	if cage and cage_path in initial_positions:
		cage.global_transform.origin = initial_positions[cage_path]

func reset_all_platforms():
	for cage_path in initial_positions.keys():
		reset_platform(cage_path)
