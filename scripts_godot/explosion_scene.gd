extends Node3D

@export var explosion_duration: float = 1.5  # Durée avant suppression

func _ready():
	$CPUParticles3D.emitting = true
	await get_tree().create_timer(explosion_duration).timeout
	queue_free()
