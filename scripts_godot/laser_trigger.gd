extends Area3D

class_name Player

@export var laser_scene: PackedScene
@export var texture_rect_path: NodePath  # Chemin vers le TextureRect dans la hiérarchie
var laser_instance
var player_detected = false
var client_node: ClientNode
var texture_rect: TextureRect
var debug_polygon: Polygon2D  # Zone visuelle pour le débogage
var is_zone_dangerous = false
var dangerous_zone_min_x = 0
var dangerous_zone_max_x = 0
var taille = 90

func _ready():
	_initialize_texture_rect()

	# Vérifier si le signal est déjà connecté avant d'ajouter une nouvelle connexion
	if is_connected("body_entered", Callable(self, "_on_body_entered")):
		disconnect("body_entered", Callable(self, "_on_body_entered"))
	
	connect("body_entered", Callable(self, "_on_body_entered"))

func _initialize_texture_rect():
	# Connexion au ClientNode
	client_node = get_tree().get_root().get_node("Main/ClientNode")
	if client_node == null:
		print("Erreur : Impossible de trouver le nœud ClientNode.")
	
	# Récupération du TextureRect pour l'image 2D
	if texture_rect_path:
		texture_rect = get_node(texture_rect_path)
		if texture_rect and texture_rect is TextureRect:
			texture_rect.visible = false
		else:
			print("Erreur : Le noeud spécifié n'est pas un TextureRect.")
	else:
		print("Erreur : Aucun chemin de TextureRect spécifié.")

func _on_body_entered(body):
	if body.name == "Player" and not player_detected:
		player_detected = true
		_display_laser_effect()
		send_platform_data()
		_mark_zone_as_dangerous()

		# Créer un timer pour retarder l'apparition du laser
		var delay_timer = Timer.new()
		delay_timer.wait_time = 1.0  # Délai avant l'affichage du laser (1 seconde)
		delay_timer.one_shot = true
		delay_timer.connect("timeout", Callable(self, "_spawn_laser_scene"))
		add_child(delay_timer)
		delay_timer.start()

func _spawn_laser_scene():
	if laser_scene:
		# Instancier le laser
		laser_instance = laser_scene.instantiate()

		# Déplacer le laser sous 'Main' pour ne pas suivre la plateforme
		get_tree().get_root().get_node("Main").add_child(laser_instance)
		
		# Corrige l'orientation du laser
		laser_instance.global_transform.basis = global_transform.basis

		# Position du laser (fixe)
		laser_instance.global_transform.origin = Vector3(
			dangerous_zone_min_x + (dangerous_zone_max_x - dangerous_zone_min_x) / 2.0,
			-5,  # Hauteur fixée
			global_transform.origin.z  # Alignement avec la plateforme
		)

		# Ajuste la largeur du laser
		var laser_scale = laser_instance.get_node("CollisionShape3D")
		if laser_scale:
			laser_scale.scale.x = (dangerous_zone_max_x - dangerous_zone_min_x) + taille  

		# Création d'un timer pour désactiver le laser après 1 seconde
		var laser_timer = Timer.new()
		laser_timer.wait_time = 1.0
		laser_timer.one_shot = true
		laser_timer.connect("timeout", Callable(self, "_remove_laser").bind(laser_instance))
		add_child(laser_timer)
		laser_timer.start()
	else:
		print("Erreur : `laser_scene` n'est pas défini.")


func _display_laser_effect():
	if texture_rect:
		update_texture_position()
		texture_rect.visible = true
		var animation_player = texture_rect.get_node("MoveTexture")
		if animation_player:
			animation_player.play("new_animation")

# 🚀 Fonction pour envoyer les données de position au serveur
func send_platform_data():
	if client_node and client_node.is_connected:
		var platform_data = determine_platform_position()
		
		# Envoi immédiat de la position
		client_node.send_data(platform_data + "\n")
		print("Données envoyées au serveur : %s" % platform_data)
		
		# Mise en place d'un Timer pour envoyer "0" après 0.5 secondes
		var timer = Timer.new()
		timer.wait_time = 0.7
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "_hide_texture_rect"))
		add_child(timer)
		timer.start()

func _hide_texture_rect():
	if texture_rect:
		texture_rect.visible = false
		
func _mark_zone_as_dangerous():
	is_zone_dangerous = true
	_set_dangerous_zone_limits()  # Définir la bonne zone pour ce trigger
	# Afficher le point d’exclamation à la bonne position
	if texture_rect:
		texture_rect.visible = true
	
# ⏱️ Fonction appelée après le délai
func _send_zero_to_server():
	print("cense envoyer 0")
	if client_node and client_node.is_connected:
		client_node.send_data("0\n")
		print("Données '0' envoyées au serveur.")
	else:
		print("Erreur : Pas de client TCP connecté.")

func _set_dangerous_zone_limits():
	var area3d_x = global_transform.origin.x
	if area3d_x < -7:
		dangerous_zone_min_x = -25
		dangerous_zone_max_x = -7
	elif area3d_x <= 10:
		dangerous_zone_min_x = -7
		dangerous_zone_max_x = 10
	else:
		dangerous_zone_min_x = 10
		dangerous_zone_max_x = 25

func _send_zero_after_delay():
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_send_zero_to_server"))
	add_child(timer)
	timer.start()

# 🔍 Détermine la position de la plateforme pour envoyer au serveur
func determine_platform_position() -> String:
	var area3d_x = global_transform.origin.x
	if area3d_x < -7:
		return "1"  # Gauche
	elif area3d_x <= 10:
		return "2"  # Centre
	else:
		return "3"  # Droite

func update_texture_position():
	if texture_rect:
		var area3d_x = global_transform.origin.x
		if area3d_x < -7:
			texture_rect.position.x = 250
		elif area3d_x <= 10:
			texture_rect.position.x = 650
		else:
			texture_rect.position.x = 1050
			
func _remove_laser(_laser_instance):
	if laser_instance:
		laser_instance.queue_free()  # Supprime le laser après 1 seconde.")
		
