class_name ClientNode
extends Node

var client := StreamPeerTCP.new()  # Créer un client TCP
var server_ip := "127.0.0.1"       # Adresse IP du serveur
var server_port := 12345           # Port du serveur

var player: CharacterBody3D        # Référence au personnage à contrôler
var _status: int = 0               # Statut de la connexion
var mult: float = 1.5

func _ready():
	_status = client.get_status()
	# Recherche du nœud `player` dans la scène (assurez-vous du chemin correct)
	player = get_tree().get_root().get_node("Main/Player")
	if player == null:
		print("Erreur : Le nœud 'player' n'a pas été trouvé.")
	else:
		print("Nœud 'player' trouvé.")
	connect_to_server()

func _process(_delta):
	# Appeler poll() pour mettre à jour l'état de la connexion
	client.poll()

	# Lire les données si connecté
	if _status == client.STATUS_CONNECTED:
		if client.get_available_bytes() > 0:
			var data = client.get_utf8_string(client.get_available_bytes())
			print("Données reçues du serveur : %s" % data)
			emit_signal("data_received", data)
			_handle_data(data)

func connect_to_server():
	print("Connexion au serveur %s:%d..." % [server_ip, server_port])
	_status = client.STATUS_NONE
	var err = client.connect_to_host(server_ip, server_port)
	if err != OK:
		print("Erreur de connexion au serveur : %s" % err)
		emit_signal("error")
	else:
		print("Tentative de connexion en cours...")

func send_data(data: String):
	# Envoyer des données au serveur
	if client.get_status() == client.STATUS_CONNECTED:
		client.put_utf8_string(data + "\n")
		print("Données envoyées au serveur : %s" % data)
	else:
		print("Erreur : Impossible d'envoyer les données, client non connecté.")

func _handle_data(data: String):
	# Gestion des données reçues
	var commands = data.split("\n")
	for command in commands:
		if command.find("X:") != -1:
			var x_str = command.split(":")[1]
			var x = float(x_str)
			print("Coordonnée extraite : X = %f" % x)
			_move_player(x)
			

		elif command.strip_edges() == "jump":
			if player and player.has_method("jump"):
				player.jump()
				print("Commande 'jump' exécutée : le joueur saute.")
			else:
				print("Erreur : La méthode 'jump' n'existe pas ou 'player' est invalide.")

func _move_player(x: float):
	# Déplacement du personnage uniquement sur l'axe X
	var new_position = Vector3(x, player.global_position.y, player.global_position.z)
	player.global_position = new_position
	print("Personnage déplacé à : X = %f" % x)

func _exit_tree():
	if client.get_status() == client.STATUS_CONNECTED:
		client.disconnect_from_host()
		print("Déconnecté du serveur | Exit.")
