extends Camera3D

func _ready():
	for node in get_tree().get_nodes_in_group("player"):
		node.visible = false
