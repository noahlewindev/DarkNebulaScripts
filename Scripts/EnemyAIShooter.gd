extends CharacterBody3D
class_name EnemyAIRanged

@export var health : int = 100
@export var tooCloseRange : int = 3

@export var tooFarRange : int = 7

@export var rays :Array[RayCast3D]

@onready var lastPlayerPosition :Vector3
@onready var sprite :AnimatedSprite3D = $Sprite
@export var isInAnimation :bool = false
@export var isHurt :bool = false
@export var isAlert :bool = false
@export var isWalking :bool = false
@onready var alertCounter :float = 0.0
@onready var runningAway : bool = false
@onready var isDead :bool = false
@onready var enemyBullet = preload("res://Assets/Prefabs/bullets/enemyBullet.tscn")
@export var deflectionProbe :Area3D
@export var deflectionProbeCollider :CollisionShape3D
@export var shield :Node3D

func ChanceForTaunt() ->void :
	var chance = rng.randi_range(0,100)
	if !isOmniPresent:
		if chance < 40:
			if chance < 20:
				$Audio/Taunt1.play()
			else:
				$Audio/Taunt2.play()
	else:
		if chance < 40:
			if chance > 35:
				$Audio/Taunt3.play()
			elif chance <= 35 && chance > 18:
				$Audio/Taunt1.play()
			else:
				$Audio/Taunt2.play()
var dirNormal
func _process(delta: float) -> void:
	if isDead:
		return
	if !isInAnimation && !isHurt && !isWalkingBack && !isWalkingForward && DistanceFromCameraMain() < 60:
		Animate()
		if (GameManager.player != null && position.distance_to(GameManager.player.position) < 9) || CanSeePlayer():
			if !isAlert:
				ChanceForTaunt()
				isAlert = true
			alertCounter += delta
			if !isInAnimation && !isWalkingBack && !isWalkingForward:
				if !isOmniPresent && canShoot && DistanceFromLastPlayerPos(lastPlayerPosition) < tooFarRange && DistanceFromLastPlayerPos(lastPlayerPosition) > tooCloseRange:
					Shoot()
				elif isOmniPresent && canShoot && DistanceFromLastPlayerPos(GameManager.player.global_position) > tooCloseRange:
					ShootOmni()
				elif DistanceFromLastPlayerPos(lastPlayerPosition) <= tooCloseRange:
					MoveBack()
				elif DistanceFromLastPlayerPos(lastPlayerPosition) >= tooFarRange:
					MoveForward()
		else:
			if isAlert:
				alertCounter -= delta / 2
				if alertCounter <= 0:
					isAlert = false
					alertCounter = 0
func DistanceFromCameraMain() -> float:
	return position.distance_to(get_viewport().get_camera_3d().global_position)
func Push(basis):
	velocity = basis * -10
func _physics_process(delta: float) -> void:
	Gravity(delta)
	if isDead:
		return
	if isWalkingBack:
		velocity += DirectionToPlayer() * -5 * delta
	if isWalkingForward:
		velocity += DirectionToPlayer() * 5 * delta
	move_and_slide()
func Animate() -> void:
	if !isInAnimation:
		if !isWalking:
			if isAlert:
				sprite.play("idle_agro")
			else :
				sprite.play("idle_unalert")
		else :
			if runningAway:
				sprite.play("walk_backward")
			else:
				sprite.play("walk_forward")
@export var isOmniPresent :bool = false
func CanSeePlayer() -> bool:
	if !isOmniPresent:
		var collider
		for r in rays:
			if r.is_colliding():
				collider = r.get_collider()
				if collider.get_collision_layer_value(2):
					lastPlayerPosition = r.get_collision_point()
					return true
		return false
	else:
		if position.distance_to(GameManager.player.global_position) < 20:
			return true
		return false
func DirectionToPlayer():
	return global_position.direction_to(lastPlayerPosition)
func DistanceFromLastPlayerPos(playerPos :Vector3) -> float:
	return global_position.distance_to(playerPos)
var tempBullet
@export var canShoot :bool = true
var rng = RandomNumberGenerator.new()
func Shoot() -> void:
	isInAnimation = true
	sprite.play("shoot")
	$Audio/BlasterFire.play()
	canShoot = false
	lastPlayerPosition = GameManager.player.global_position
	await get_tree().create_timer(0.05).timeout
	tempBullet = enemyBullet.instantiate()
	tempBullet.position = $FirePos.global_position
	tempBullet.look_at_from_position($FirePos.global_position, lastPlayerPosition, Vector3.UP, false)
	get_parent().add_child(tempBullet)
	await get_tree().create_timer(0.221).timeout
	isInAnimation = false
	await get_tree().create_timer(randf_range(0.2, 1.1)).timeout
	canShoot = true
func ShootOmni() -> void:
	isInAnimation = true
	sprite.play("shoot")
	$Audio/BlasterFire.play()
	canShoot = false
	lastPlayerPosition = GameManager.player.global_position
	await get_tree().create_timer(0.05).timeout
	tempBullet = enemyBullet.instantiate()
	tempBullet.position = $FirePos.global_position
	tempBullet.look_at_from_position($FirePos.global_position, lastPlayerPosition, Vector3.UP, false)
	get_parent().add_child(tempBullet)
	await get_tree().create_timer(0.05).timeout
	tempBullet = enemyBullet.instantiate()
	tempBullet.position = $FirePos.global_position
	tempBullet.look_at_from_position($FirePos.global_position, lastPlayerPosition, Vector3.UP, false)
	get_parent().add_child(tempBullet)
	await get_tree().create_timer(0.05).timeout
	tempBullet = enemyBullet.instantiate()
	tempBullet.position = $FirePos.global_position
	tempBullet.look_at_from_position($FirePos.global_position, lastPlayerPosition, Vector3.UP, false)
	get_parent().add_child(tempBullet)
	await get_tree().create_timer(0.221).timeout
	isInAnimation = false
	await get_tree().create_timer(randf_range(0.4, 1.2)).timeout
	canShoot = true
func TakeDamage(value :int):
	isHurt = true
	health -= value 
	if health <= 0:
		isInAnimation = true
		sprite.play("dead")
		$Audio/Hurt2.play()
		$impactSprite.play("destroy")
		await get_tree().create_timer(0.05).timeout
		$Audio/Destroy.play()
		isDead = true
		await get_tree().create_timer(1.105).timeout
		queue_free()
	else:
		$Audio/Hurt1.pitch_scale = rng.randf_range(0.89, 1.01)
		$Audio/Hurt1.play()
		$impactSprite.play("hit")
		await get_tree().create_timer(0.05).timeout
		isHurt = false
@export var isWalkingBack :bool = false
func MoveBack() -> void:
	isInAnimation = true
	isWalkingBack = true
	sprite.play("walk_backward")
	await get_tree().create_timer(rng.randf_range(1.0, 1.5)).timeout
	velocity.x = 0
	velocity.z = 0
	isWalkingBack = false
	isInAnimation = false
@export var isWalkingForward :bool = false
func MoveForward() -> void:
	isInAnimation = true
	isWalkingForward = true
	sprite.play("walk_forward")
	await get_tree().create_timer(rng.randf_range(1.0, 1.7)).timeout
	velocity.x = 0
	velocity.z = 0
	isInAnimation = false
	isWalkingForward = false
func Gravity(_delta :float):
	if !is_on_floor():
		if isInAnimation:
			velocity.y -= 12 / 2 * _delta
		else :
			velocity.y -= 12 * _delta
	if position.y <= -3000:
		queue_free()
