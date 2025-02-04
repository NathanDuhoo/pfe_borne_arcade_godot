extends MeshInstance3D

@export var fall_delay = 0.5  # ⏳ Temps avant la chute après contact
@export var fall_speed = 10.0  # ⬇️ Vitesse de descente
@export var reset_after = 3.0  # 🔄 Temps avant de réinitialiser la plateforme (0 = pas de reset)

var is_falling = false
var initial_position = Vector3.ZERO  # Sauvegarde de la position initiale

func _ready():
	initial_position = global_transform.origin  # Enregistre la position initiale

	# Vérifie si la plateforme possède un `Area3D` pour détecter le joueur
	var area = $Area3D if has_node("Area3D") else null
	if area:
		area.connect("body_entered", Callable(self, "_on_body_entered"))
	else:
		print("⚠️ Attention : Aucun `Area3D` trouvé sous", name)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_falling:  # Vérifie que c'est bien le joueur
		is_falling = true
		print("🎭 Le joueur a activé la chute !")
		await get_tree().create_timer(fall_delay).timeout
		start_falling()

func start_falling():
	print("⬇️ La plateforme commence à tomber !")
	
	while global_transform.origin.y > -100:
		global_transform.origin.y -= fall_speed * get_process_delta_time()
		if not get_tree():
			print("Erreur: get_tree() est null, annulation de l'attente de frame")
			return
		else:
			await get_tree().process_frame


	print("💥 La plateforme est tombée !")

	if reset_after > 0:
		print("🔄 Réinitialisation après", reset_after, "secondes...")
		await get_tree().create_timer(reset_after).timeout
		reset_platform()
	else:
		queue_free()  # Supprime définitivement la plateforme si pas de reset

func reset_platform():
	global_transform.origin = initial_position
	is_falling = false
	print("✅ Plateforme réinitialisée !")
