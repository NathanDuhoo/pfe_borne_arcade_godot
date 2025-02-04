extends Control
	
var client := StreamPeerTCP.new()
var server_ip := "127.0.0.1"
var server_port := 12345
var _status: int = 0

func _ready():
	print("[GODOT] Initialisation du client TCP")
	connect_to_server()
	await get_tree().process_frame  # Attendre le chargement complet de la scène
	force_first_button_focus()

func connect_to_server():
	print("[GODOT] Connexion au serveur %s:%d..." % [server_ip, server_port])
	_status = client.STATUS_NONE
	var err = client.connect_to_host(server_ip, server_port)
	if err != OK:
		print("[GODOT] Erreur de connexion au serveur : %s" % err)
		emit_signal("error")
	else:
		print("[GODOT] Tentative de connexion en cours...")

func _process(_delta):
	client.poll()
	var new_status: int = client.get_status()
	if new_status != _status:
		_status = new_status
		match _status:
			client.STATUS_NONE:
				print("[GODOT] Déconnecté du serveur.")
				emit_signal("disconnected")
			client.STATUS_CONNECTING:
				print("[GODOT] Tentative de connexion au serveur...")
			client.STATUS_CONNECTED:
				print("[GODOT] Connexion au serveur réussie.")
				emit_signal("connected")
			client.STATUS_ERROR:
				print("[GODOT] Erreur de connexion au serveur.")
				emit_signal("error")
	
	if _status == client.STATUS_CONNECTED and client.get_available_bytes() > 0:
		var buffer = client.get_string(client.get_available_bytes()).strip_edges()
		print("[GODOT] Données reçues :", buffer)
		emit_signal("data_received", buffer)
		handle_menu_navigation(buffer)

func handle_menu_navigation(direction):
	print("[GODOT] Tentative de navigation avec :", direction)
	var current_scene = get_tree().current_scene.name.to_lower()
	var valid_menus = ["game_over", "menu", "you_win"]
	
	if current_scene in valid_menus:
		print("[GODOT] Navigation dans le menu détectée :", direction)
		var buttons = find_all_buttons()
		if buttons.is_empty():
			print("[GODOT] Aucun bouton trouvé dans le menu.")
			return

		var focused = get_viewport().gui_get_focus_owner()
		print("[GODOT] Élément focus actuel :", focused)
		
		if not focused or not focused is Button:
			print("[GODOT] Aucun bouton focus, assignation du premier bouton.")
			buttons[0].grab_focus()
			return

		# Trouver l'index du bouton actuel
		var index = buttons.find(focused)
		if index == -1:
			print("[GODOT] Bouton non trouvé dans la liste, assignation du premier bouton.")
			buttons[0].grab_focus()
			return

		# Déplacement vers le haut ou vers le bas
		if direction == "up" and index > 0:
			buttons[index - 1].grab_focus()
		elif direction == "down" and index < buttons.size() - 1:
			buttons[index + 1].grab_focus()
		elif direction == "jump":
			print("[GODOT] Activation du bouton sélectionné :", focused)
			focused.emit_signal("pressed")

func force_first_button_focus():
	var first_button = find_first_button()
	if first_button:
		print("[GODOT] Premier bouton détecté :", first_button)
		first_button.grab_focus()
	else:
		print("[GODOT] Aucun bouton détecté dans la scène.")

func find_first_button():
	var scene_root = get_tree().current_scene
	if scene_root:
		return find_button_recursive(scene_root)
	return null

func find_button_recursive(node):
	if node is Button:
		return node
	for child in node.get_children():
		var result = find_button_recursive(child)
		if result:
			return result
	return null

func find_all_buttons():
	var scene_root = get_tree().current_scene
	if not scene_root:
		return []

	var buttons = []
	find_buttons_recursive(scene_root, buttons)
	return buttons

func find_buttons_recursive(node, buttons):
	if node is Button:
		buttons.append(node)
	for child in node.get_children():
		find_buttons_recursive(child, buttons)

func _on_quit_pressed() -> void:
	print("[GODOT] Fermeture du jeu")
	get_tree().quit()

func _on_play_pressed() -> void:
	print("[GODOT] Lancement du jeu")
	get_tree().change_scene_to_file("res://tscn_godot/Main.tscn")

func _on_menu_pressed() -> void:
	print("[GODOT] Retour au menu principal")
	get_tree().change_scene_to_file("res://tscn_godot/menu.tscn")
