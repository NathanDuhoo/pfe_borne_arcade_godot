extends Node3D

@export var spawn_area: Vector2 = Vector2(10, 10) # Zone de spawn
@export var fall_height: float = 20.0  # Hauteur initiale de spawn des météorites
var shadow_texture
@export var shadow_size_factor: float = 1.0  # Facteur d'échelle de l'ombre

var meteors = []
var player: CharacterBody3D  # Référence au joueur
var is_spawning = false  # Flag pour gérer l'état du spawner

func _ready():
	player = get_tree().get_root().get_node("Main/Player")
	if player != null:
		print("Player détecté :", player.name)

func start_spawning():
	if is_spawning:
		return
	
	is_spawning = true
	var timer = Timer.new()
	timer.wait_time = 2.0  # Fréquence d'apparition
	timer.autostart = true
	
	# Vérifier si le signal est déjà connecté avant de le faire
	if not timer.timeout.is_connected(spawn_meteors):
		timer.timeout.connect(spawn_meteors)
		
	add_child(timer)

func stop_spawning():
	if not is_spawning:
		return

	is_spawning = false
	for child in get_children():
		if child is Timer:
			child.queue_free()  # Supprime tous les timers en cours

func spawn_meteors():
	if player == null or not is_spawning:
		return

	shadow_texture = load("res://assets - blender/textures/ombre.png")
	var meteor_scene = load("res://tscn_godot/meteor_scene.tscn")
	if meteor_scene == null:
		return

	var num_meteors = randi_range(3, 7)  # Générer entre 3 et 7 météorites
	for i in range(num_meteors):
		spawn_single_meteor(meteor_scene)

func spawn_single_meteor(meteor_scene):
	var meteor = meteor_scene.instantiate() as RigidBody3D
	if meteor == null:
		return

	await get_tree().create_timer(1.0).timeout  # Délai avant la chute

	add_child(meteor)  # Ajoute l'objet avant d'accéder à ses propriétés
	await get_tree().process_frame  # Attend une frame pour éviter l'erreur

	var player_position = player.global_position
	var spawn_x = player_position.x + randf_range(-20, 20)
	var spawn_z = player_position.z + randf_range(-spawn_area.y, spawn_area.y) + 15
	meteor.global_position = Vector3(spawn_x, fall_height, spawn_z)

	var shadow = create_shadow()
	add_child(shadow)  # Ajoute l'ombre avant de modifier sa position
	await get_tree().process_frame

	shadow.global_position = Vector3(spawn_x, 0.1, spawn_z)

	meteors.append({ "meteor": meteor, "shadow": shadow })
	meteor.gravity_scale = 4.0  # Augmente la gravité

func create_shadow() -> MeshInstance3D:
	var shadow = MeshInstance3D.new()
	shadow.mesh = PlaneMesh.new()
	shadow.mesh.size = Vector2(8, 8)

	var material = StandardMaterial3D.new()
	material.albedo_texture = shadow_texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR  # Utiliser la bonne constante
	material.alpha_scissor_threshold = 0.1
	shadow.material_override = material

	return shadow


func _process(_delta):
	for entry in meteors:
		var meteor = entry["meteor"]
		var shadow = entry["shadow"]

		if meteor == null or shadow == null:
			continue

		var meteor_position = meteor.global_position
		shadow.global_position.x = meteor_position.x
		shadow.global_position.z = meteor_position.z

		var shadow_scale = shadow_size_factor * max(0.5, 1.0 - (meteor_position.y / fall_height))
		shadow.scale = Vector3(shadow_scale, 1, shadow_scale)

		if meteor_position.y <= 0:
			print("Suppression de l'ombre")
			shadow.queue_free()
			meteors.erase(entry)

func _on_Area3D_body_entered(body):
	if body == player:
		print("Player est entré dans l'Area3D. Spawning activé.")
		start_spawning()

func _on_Area3D_body_exited(body):
	if body == player:
		print("Player a quitté l'Area3D. Spawning désactivé.")
		stop_spawning()
