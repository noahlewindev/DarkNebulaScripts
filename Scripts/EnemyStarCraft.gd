extends CharacterBody3D

@export var health :int = 500
@export var player: Drivable
@onready var firePortLeft: AudioStreamPlayer3D = $FirePorts/LeftPort
@onready var firePortRight: AudioStreamPlayer3D = $FirePorts/RightPort
@onready var enemyStarcraftbullet = preload("res://Assets/Prefabs/bullets/enemy_starcraft_bullet.tscn")
var smooth_dir :Vector3
var desiredPos
var isHurt :bool = false
var isDead :bool = false
func _physics_process(delta: float) -> void:
	look_at_position(player.global_position, delta, 0.7)
	if global_position.distance_to(player.global_position) < 120:
		velocity += transform.basis.z * delta * 5
		if !isFiring && CanSeePlayer() && !isInAnimation:
			FireBullet()
	elif global_position.distance_to(player.global_position) <= 10:
		velocity += transform.basis.z * delta * -5
	else:
		velocity = velocity.lerp(Vector3.ZERO, 0.125)
	move_and_slide()
func TakeDamage(value :int):
	isHurt = true
	health -= value 
	if health <= 0:
		isInAnimation = true
		$hit.play()
		$ImpactSprite.play("fire")
		await get_tree().create_timer(0.05).timeout
		$Destroy.play()
		isDead = true
		await get_tree().create_timer(0.3505).timeout
		queue_free()
	else:
		$hit.play()
		$ImpactSprite.play("fire")
		await get_tree().create_timer(0.05).timeout
		isHurt = false
var tempBullet
var isFiring :bool = false
var isInAnimation :bool = false
func FireBullet() -> void:
	isFiring = true
	firePortLeft.play()
	tempBullet = enemyStarcraftbullet.instantiate()
	tempBullet.position = firePortLeft.position
	tempBullet.transform.basis = global_transform.basis
	get_parent().add_child(tempBullet)
	await get_tree().create_timer(0.09).timeout
	firePortRight.play()
	tempBullet = enemyStarcraftbullet.instantiate()
	tempBullet.position = firePortRight.position
	tempBullet.transform.basis = global_transform.basis
	get_parent().add_child(tempBullet)
	await get_tree().create_timer(0.29).timeout
	isFiring = false
@export var rays :Array[RayCast3D]
func CanSeePlayer() -> bool:
	var collider
	for r in rays:
		if r.is_colliding():
			return true
	return false
func look_at_position(target_position: Vector3, delta: float, turn_speed: float) -> void:
	var target_vec := target_position - global_position

	if not target_vec.length():
		return

	var target_rotation := lerp_angle(
		global_rotation.y,
		atan2(target_vec.x, target_vec.z),
		turn_speed * delta
	)
	global_rotation.y = target_rotation
