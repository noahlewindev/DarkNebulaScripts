extends Area3D

@export var value :int = 20

func _on_body_entered(body: Node3D) -> void:
	body.Heal(value)
	queue_free()
