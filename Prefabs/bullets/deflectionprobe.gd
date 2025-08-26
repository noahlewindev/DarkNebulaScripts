extends Area3D

@onready var bullet = $".."
@onready var ray :RayCast3D = $"../RayCast3D"

@export var monitorsEnemyDeflection :bool = false

func FlipEnemyBullet():
	ray.set_collision_mask_value(2,false)
	ray.set_collision_mask_value(4,true)
	ray.set_collision_mask_value(8,true)
	#ray.set_collision_mask_value(9,true)
	set_collision_layer_value(9, true)
	bullet.global_rotation_degrees.y += 180
	bullet.damage += bullet.damage / 2
	monitorsEnemyDeflection = true
func FlipPlayerBullet():
	ray.set_collision_mask_value(2,true)
	ray.set_collision_mask_value(4,false)
	ray.set_collision_mask_value(8,false)
	bullet.global_rotation_degrees.y += 180
	bullet.damage += bullet.damage / 2
	monitorsEnemyDeflection = false
func Flip():
	if !monitorsEnemyDeflection:
		FlipEnemyBullet()
	else:
		FlipPlayerBullet()
	

func _on_area_entered(_area: Area3D) -> void:
	if !monitorsEnemyDeflection && _area.has_method("PlaySFX"):
		_area.PlaySFX()
	Flip()

func _on_body_entered(_body: Node3D) -> void:
	Flip()
