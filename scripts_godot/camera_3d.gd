extends Camera3D

func _ready():
	# Afficher tous les objets du groupe "visible_for_camera1"
	for node in get_tree().get_nodes_in_group("player"):
		node.visible = true
