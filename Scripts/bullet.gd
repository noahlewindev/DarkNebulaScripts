extends Node3D

@export var SPEED : float = 4.0

@onready var mesh :MeshInstance3D = $MeshInstance3D
@onready var ray :RayCast3D = $RayCast3D
@onready var particle :GPUParticles3D = $GPUParticles3D
@onready var hasHit :bool = false

@export var damage :int = 10

var collider
func _physics_process(delta: float) -> void:
	position += transform.basis * Vector3(0,0,-SPEED) * delta
	if ray.is_colliding() && !hasHit:
		collider = ray.get_collider()
		if collider!= null && (collider.get_collision_layer_value(2) || collider.get_collision_layer_value(4)):
			collider.TakeDamage(damage)
		DestroyParticle()
func DestroyParticle() -> void:
	hasHit = true
	mesh.visible = false
	particle.emitting = true
	await get_tree().create_timer(1).timeout
	queue_free()

func _on_timer_timeout() -> void:
	queue_free()
