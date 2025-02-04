extends Area3D

var laser_active = false  # Pour savoir si le laser est actif

func _ready():
	laser_active = true
	connect("body_entered", Callable(self, "_on_body_entered"))  # 📌 Détecte automatiquement les objets entrants
	print("🚀 Laser activé, détecte les collisions !")

func _on_body_entered(body):
	if body.is_in_group("player"):  
		print("🎯 Le joueur est touché ! Vies avant : ", body.lives)
		
		body.lose_life()  

		# Attendre un court instant avant de supprimer le laser
		await get_tree().create_timer(0.5).timeout
		_remove_laser()  


func _remove_laser():
	laser_active = false
	await get_tree().create_timer(0.1).timeout
	queue_free()
