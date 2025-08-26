extends CharacterBody3D
class_name PlayerScript
@onready var nodeCamLeft: Node3D = $RefPos/CamLeft
@onready var nodeCamRight: Node3D = $RefPos/CamRight

@onready var mainCam: Camera3D = $SpringArm3D/Camera3D
@onready var springArm : SpringArm3D = $SpringArm3D
@onready var healthBar : TextureProgressBar = $UI/HealthBar
@onready var fuelBar : TextureProgressBar = $UI/JetBoost
@onready var alive :bool = true
@onready var shoulderRight :bool = true
@onready var direction :Vector3
@export var mouse_sens :float = 0.4
@export var cameraRotateLerpSpeed :float = 0.125

# Default gravity, normally is 12
@export var gravity :float = 12
@onready var playerSprite :AnimatedSprite3D = $PlayerSprite
## Ref to our Player Audio Manager
@onready var playerAudio :PlayerAudio = $PlayerAudioManager
## Raycast for
@onready var drivableCheck :RayCast3D = $Rays/DrivableCheck

# "isInAnimation" : General marker for if the player is busy in a generic action
# used for functions that require animation changes.
# Main priority is translating to the Animate func if player should display idles.
var isInAnimation :bool = false
# Allow player movement?
var canMove :bool = true
## Are our rocket boots active or not
var isJetPack :bool = false
enum Direction {forward,backward,right,left}
var lastDirection :Direction = Direction.forward

# VFX for Flame Boots
@onready var flameBoot :AnimatedSprite3D = $FX/FlameBoots
# VFX for Flame Hover
@onready var rightBootHover :AnimatedSprite3D = $FX/RightBootHover
@onready var leftBootHover :AnimatedSprite3D = $FX/LeftBootHover
# Player bullet prefab
@onready var playerBullet = preload("res://Assets/Prefabs/bullets/player_bullet_b.tscn")
func _ready():
	Engine.max_fps = SaveSystem.get_var("MaxFPS", 90)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_sens = SaveSystem.get_var("MouseSens", 0.4)
	mainCam.fov = SaveSystem.get_var("FOV", 85)
	mainCam.current = true
	GameManager.player = self
	DisplayLevelTile(GetLevelTitle())
@onready var planetLabel = $UI/PlanetInfoIcon/PlanetLabel
@onready var planetIcon = $UI/PlanetInfoIcon

# Returns name for level we're on.
func GetLevelTitle() -> String:
	if get_tree().current_scene.name == "Level_0":
		return "Station #3"
	if get_tree().current_scene.name == "Level1":
		return "Shran Ka Prime"
	if get_tree().current_scene.name == "level_2":
		return "Nexus Trilla IX"
	if get_tree().current_scene.name == "Level_3":
		return "Defeat the general!"
	if get_tree().current_scene.name == "Test_level_2":
		return "Bogton"
	return ""
# Slowly types out the level name with the planetIcon UI
func DisplayLevelTile(title:String):
	planetLabel.text = ""
	for char in title:
		planetLabel.text += char
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(3).timeout
	planetIcon.visible = false
func _input(event):
	if !alive :
		return
	# Check for Mouse Input
	if event is InputEventMouseMotion:
		rotation_degrees.y = lerp(rotation_degrees.y, rotation_degrees.y - event.relative.x * mouse_sens, cameraRotateLerpSpeed)
		mainCam.rotate_x(-event.relative.y * (mouse_sens / 800))
		if isJetPack:
			RotateRelativeX(event)
		_clamp_camera_x()
	# Check for Jump input
	if event.is_action_pressed("jump") && (is_on_floor() || wallRunCounter > 0.5) && !IsBusyDoingAction() && !isAiming:
		if Input.is_action_pressed("rocket"):
			Flip()
		else:
			Jump()
	# Check for Dodge input
	if canDodge && event.is_action_released("dodge") && (is_on_floor() || isJetPack):
		Dodge()
	# Check for toggle rocket input
	if event.is_action_pressed("rocket") && fuelBar.value > 0 && !is_on_floor():
		ToggleRocket()
# Allows for omnidirectional mouse rotation when called
func RotateRelativeX(eventRelative : InputEventMouseMotion) -> void:
	rotate(transform.basis.x, 1 * 0.005 * -eventRelative.relative.y)
func Heal(value :int):
	healthBar.value += value
	playerAudio.healSound.play()
	if healthBar.value > healthBar.max_value:
		healthBar.value = healthBar.max_value

# Hurt the player with passed damage value
func TakeDamage(value : int):
	if !isSwinging && !isAiming:
		healthBar.value -= value
		if healthBar.value <= 0:
			counterTemp = 0
			flameBoot.play("off")
			rightBootHover.play("off")
			leftBootHover.play("off")
			isJetPack = false
			healthBar.value = 0
			playerAudio.deathSFX.play()
			isInAnimation = true
			playerSprite.play("death")
			alive = false
			await get_tree().create_timer(1).timeout
			get_tree().reload_current_scene()
		else:
			playerAudio.PlayHurt()
# Instal kills player
func Kill():
	counterTemp = 0
	flameBoot.play("off")
	rightBootHover.play("off")
	leftBootHover.play("off")
	isJetPack = false
	alive = false
	healthBar.value = 0
	playerAudio.deathSFX.play()
	isInAnimation = true
	playerSprite.play("death")
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene()
# Clamping the camera up and down rotation
func _clamp_camera_x():
	if isJetPack:
		mainCam.rotation.x = clamp(mainCam.rotation.x, deg_to_rad(-18), deg_to_rad(0))
	else :
		mainCam.rotation.x = clamp(mainCam.rotation.x, deg_to_rad(-30), deg_to_rad(20))
func Deflect():
	if !isInAnimation:
		DeflectAnim()
var deflectCount :int = 0
var isDeflecting :bool = false
# Display Deflect anim if aiming and not busy
func DeflectAnim():
	isInAnimation = true
	isDeflecting = true
	DamageSwordTargets(6)
	match deflectCount:
		0: playerSprite.play("deflect_1")
		1: playerSprite.play("deflect_2")
	deflectCount += 1
	if deflectCount > 1:
		deflectCount = 0
	await get_tree().create_timer(.25).timeout
	isInAnimation = false
	isDeflecting = false
# Updates player speed.
# Allows multiple states to mod speed values.
func SetSpeed(delta:float):
	if isShooting:
		SPEED = lerpf(SPEED, shootMoveSpeed, 0.0123)
	elif isJumping:
		SPEED += 10 * delta
		if Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right"):
			SPEED += 10 * delta
	elif isSwinging:
		SPEED = lerpf(SPEED, swingMoveSpeed, 0.023)
	elif isWallRunningLeft || isWallRunningRight:
		SPEED = lerpf(SPEED, swingMoveSpeed + 2, 0.08)
	elif isJetPack:
		SPEED = lerpf(SPEED, swingMoveSpeed, 0.0123)
	elif isAiming:
		SPEED = lerpf(SPEED, aimMoveSpeed, 0.023)
	else:
		SPEED = lerpf(SPEED, defaultMoveSpeed, 0.023)
# Enter vehicle in front of you
func EnterDrivable():
	drivableCheck.get_collider().Possess()
	await get_tree().create_timer(0.023).timeout
	queue_free()
@onready var deflection :Area3D = $HitBoxBlock
@onready var rayNormal
@onready var counterTemp :float = 0.0
@onready var wallRunLeft :RayCast3D = $Rays/WallrunLeft
@onready var wallRunRight :RayCast3D = $Rays/WallrunRight
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("escape"):
			get_tree().change_scene_to_file("uid://cydkp5jqc5btm")
	move_and_slide()
	WallRunning(delta)
	Gravity(delta)
	if !alive:
		return
	timeFromLastSwing += delta
	if timeFromLastSwing >= 0.52:
		swingCounter = 0
	if Input.is_action_pressed("interact") && drivableCheck.is_colliding():
		EnterDrivable()
	if isAiming || isSwinging || isDeflecting || isFlipping:
		deflection.monitorable = true
		deflection.monitoring = true
	else :
		deflection.monitorable = false
		deflection.monitoring = false
	if isSlaming:
		if is_on_floor() || !Input.is_action_pressed("attack"):
			leaveSlam.emit()
			airCounter = 0
	counterTemp += delta
	if isJetPack:
		airCounter = 0
		if counterTemp > .125:
			fuelBar.value -= 1
			counterTemp = 0
		if fuelBar.value <= 0:
			counterTemp = 0
			flameBoot.play("off")
			rightBootHover.play("off")
			leftBootHover.play("off")
			isJetPack = false
	else:
		if counterTemp > .25 && fuelBar.value < 200:
			fuelBar.value += 5  
			counterTemp = 0
	if is_on_floor():
		if airCounter > 2.0:
			TakeDamage(50)
		airCounter = 0
		if isJetPack:
			flameBoot.play("off")
			rightBootHover.play("off")
			leftBootHover.play("off")
			isJetPack = false
		rayNormal = $Rays/GroundNormalCheck.get_collision_normal()
		xform = AlignWithY(global_transform, rayNormal)
		global_transform = global_transform.interpolate_with(xform, 0.05)
	else:
		airCounter += delta
		AlignWithDefaultY(Vector3.UP)
		if isJetPack && isAiming:
			global_transform = global_transform.interpolate_with(xform, 0.005)
		if isSwinging:
			global_transform = global_transform.interpolate_with(xform, 0.25)
		else:
			global_transform = global_transform.interpolate_with(xform, 0.015)
	SetSpeed(delta)
	CameraInput(delta)
	MoveInput()
	ActionsInput(delta)
	Animate()
var input_dir
@onready var isMoving :bool = false
@export var SPEED :float = 5.5
@export var defaultMoveSpeed :float = 8.5
@export var aimMoveSpeed :float = 3.0
@export var shootMoveSpeed :float = 6.0
@export var swingMoveSpeed :float = 16.0
func MoveInput():
	input_dir = Input.get_vector("move_left","move_right","move_forward","move_backward")
	direction = (transform.basis * Vector3(input_dir.x,0,input_dir.y)).normalized()
	
	if Input.is_action_pressed("move_forward"):
		lastDirection = Direction.forward
	if Input.is_action_pressed("move_backward"):
		lastDirection = Direction.backward
	if Input.is_action_pressed("move_right"):
		lastDirection = Direction.right
	if Input.is_action_pressed("move_left"):
		lastDirection = Direction.left
	
	if canMove && (direction.x != 0 || direction.z != 0):
		isMoving = true
		velocity.x = lerp(velocity.x, direction.x * SPEED, 0.5)
		velocity.z = lerp(velocity.z, direction.z * SPEED, 0.5)
	else :
		velocity.x = move_toward(velocity.x,0,SPEED)
		velocity.z = move_toward(velocity.z,0,SPEED)
		isMoving = false
# Aligns the player direction with ground the player is standing on
func AlignWithY(xForm : Transform3D, new_y):
	xForm.basis.y = new_y
	xForm.basis.x = -xForm.basis.z.cross(new_y)
	xForm.basis = xForm.basis.orthonormalized()
	return xForm
var xform
# Aligns the player direction with the normalized direction given
func AlignWithDefaultY(floor_normal : Vector3) -> void:
	xform = global_transform
	xform.basis.y = floor_normal
	xform.basis.x = -xform.basis.z.cross(floor_normal)
	xform.basis = xform.basis.orthonormalized()
# Apply gravity to player
func Gravity(_delta :float):
	if !is_on_floor():
		if isInAnimation && isJumping:
			velocity.y -= gravity / 2 * _delta
		elif isWallRunningLeft || isWallRunningRight:
			velocity.y = lerpf(velocity.y, -1, 0.0015)
		elif isJetPack:
			velocity.y = lerpf(velocity.y, -1, 0.025)
		else :
			velocity.y -= gravity * _delta
var airCounter :float = 0.0
@onready var mouseInputLerpedV = Vector2.ZERO
# Input handling for non-mouse based camera controls
func CameraInput(_delta :float):
	if Input.is_action_just_pressed("shoulder"):
		shoulderRight = !shoulderRight
	
	if shoulderRight:
		springArm.position = springArm.position.lerp(nodeCamRight.position, 0.125)
	else:
		springArm.position = springArm.position.lerp(nodeCamLeft.position, 0.125)
	if Input.is_action_pressed("look_left"):
		mouseInputLerpedV = mouseInputLerpedV.lerp(Vector2(0, 3 * mouse_sens), cameraRotateLerpSpeed)
		rotation_degrees.y += mouseInputLerpedV.y
	if Input.is_action_pressed("look_right"):
		mouseInputLerpedV = mouseInputLerpedV.lerp(Vector2(0, 3 * mouse_sens), cameraRotateLerpSpeed)
		rotation_degrees.y -= mouseInputLerpedV.y
	if Input.is_action_pressed("look_down"):
		if isJetPack:
			RotateForward()
		mainCam.rotate_x(-(mouse_sens / 50))
		_clamp_camera_x()
	if Input.is_action_pressed("look_up"):
		if isJetPack:
			RotateBackward()
		mainCam.rotate_x((mouse_sens / 50))
		_clamp_camera_x()
func Animate():
	if !isInAnimation:
		if is_on_floor():
			if isMoving:
				if isAiming:
					if Input.is_action_pressed("move_backward"):
						playerSprite.play("block_backwardwalk")
					else:
						playerSprite.play("block_walk")
				else:
					if Input.is_action_pressed("move_backward"):
						playerSprite.play("backward_walk")
					else:
						playerSprite.play("forward_walk")
			else:
				if isAiming:
					playerSprite.play("aim")
				else:
					playerSprite.play("idle")
		else:
			if !isJetPack:
				if isWallRunningLeft:
					shoulderRight = true
					playerSprite.play("wallrun_left")
				elif isWallRunningRight:
					shoulderRight = false
					playerSprite.play("wallrun_right")
				else:
					playerSprite.play("fall")
			else :
				if isRising:
					flameBoot.play("on")
					leftBootHover.play("off")
					rightBootHover.play("off")
					playerSprite.play("rocket_rise")
				elif isAiming:
					flameBoot.play("off")
					leftBootHover.play("on")
					rightBootHover.play("on")
					playerSprite.play("rocket_aim")
				else:
					flameBoot.play("off")
					leftBootHover.play("on")
					rightBootHover.play("on")
					playerSprite.play("rocket_idle")
# Signals if player should stop slamming
signal leaveSlam
# Is the player busy doing something already?
func IsBusyDoingAction() -> bool:
	if !isInAnimation && !isShooting && !isJumping && !isSwinging && !isSlaming:
		return false
	return true
# Player actions like attacks, aiming, and jetboots
func ActionsInput(_delta:float) -> void:
	if !IsBusyDoingAction():
		if Input.is_action_pressed("aim"):
			isAiming = true
			if Input.is_action_pressed("attack"):
				Fire()
		else:
			isAiming = false
			if Input.is_action_just_pressed("attack"):
				if Input.is_action_pressed("dodge") && !is_on_floor():
					Slam()
				elif Input.is_action_pressed("rocket") && !isJetPack:
					Boost()
				else:
					Swing()
		if isJetPack:
			if Input.is_action_pressed("jump"):
				fuelBar.value -= 1
			if Input.is_action_pressed("jump"):
				velocity.y = lerpf(velocity.y, 12 + (SPEED / 2), 0.025)
				isRising = true
			else:
				isRising = false
	else :
		isAiming = false
var isJumping :bool = false
var isRising :bool = false
var isAiming :bool = false
var isSwinging :bool = false
var isShooting :bool = false
var canDodge :bool = true
# Dodge function
func Dodge() -> void:
	isInAnimation = true
	canMove = false
	playerAudio.PlayDodge()
	canDodge = false
	if isJetPack:
		fuelBar.value -= 10
	PushSwordTargets()
	if lastDirection == Direction.forward:
		playerSprite.play("dodge_forward")
		velocity = transform.basis.z * -60
	else:
		if lastDirection == Direction.backward:
			velocity = transform.basis.z * 60
		elif lastDirection == Direction.right:
			velocity += transform.basis.x * 60 * (SPEED / 10)
		elif lastDirection == Direction.left:
			velocity += transform.basis.x * -60 * (SPEED / 10)
		playerSprite.play("dodge_else")
	DamageSwordTargets(15)
	await get_tree().create_timer(0.11).timeout
	PushSwordTargets()
	canMove = true
	SPEED += 1
	DamageSwordTargets(15)
	await get_tree().create_timer(0.21).timeout
	PushSwordTargets()
	SPEED += 1
	isInAnimation = false
	DamageSwordTargets(15)
	await get_tree().create_timer(0.5).timeout
	canDodge = true
var isFlipping :bool = false
# Example of Special or alternate movement function
func Flip() -> void:
	isInAnimation = true
	playerAudio.PlayDodge()
	playerAudio.jetBootsEnableSFX.play()
	canDodge = false
	isFlipping = true
	velocity.y = 8
	SPEED += 5
	if Input.is_action_pressed("move_right"):
		velocity += transform.basis.x * 80
		playerSprite.play("flip_right")
	else :
		velocity += transform.basis.x * -80
		playerSprite.play("flip_left")
	DamageSwordTargets(50)
	await get_tree().create_timer(0.225).timeout
	velocity.y += 3
	SPEED += 3
	DamageSwordTargets(40)
	await get_tree().create_timer(0.225).timeout
	velocity.y = -6
	DamageSwordTargets(25)
	isFlipping = false
	SPEED += 3
	isInAnimation = false
	if !isJetPack:
		ToggleRocket()
	await get_tree().create_timer(2.0).timeout
	canDodge = true
# Example of Special or alternate movement function
func Boost() -> void:
	isInAnimation = true
	playerAudio.PlayDodge()
	playerAudio.jetBootsEnableSFX.play()
	canDodge = false
	velocity.y = 9
	SPEED += 3
	playerSprite.play("boost")
	DamageSwordTargets(20)
	await get_tree().create_timer(0.11).timeout
	SPEED += 3
	DamageSwordTargets(20)
	await get_tree().create_timer(0.21).timeout
	DamageSwordTargets(15)
	SPEED += 3
	isInAnimation = false
	if !isJetPack:
		ToggleRocket()
	await get_tree().create_timer(1.5).timeout
	canDodge = true
# Sets the main camera to the player camera, just in case a cutscene or vehicle demanded camera priority
func SetCamMain()-> void:
	mainCam.current = true
func Jump() -> void:
	isInAnimation = true
	velocity.y = 6
	playerSprite.play("jump")
	isJumping = true
	playerAudio.PlayJump()
	SPEED += 3
	wallRunCounter = 0
	await get_tree().create_timer(0.212).timeout
	isJumping = false
	isInAnimation = false
# Toggle your rocket boots on & off
func ToggleRocket() -> void:
	isInAnimation = true
	velocity.y = 0
	playerAudio.PlayJetBoots()
	SPEED += 1
	await get_tree().create_timer(0.0125).timeout
	isJetPack = !isJetPack
	if isJetPack == false:
		flameBoot.play("off")
		rightBootHover.play("off")
		leftBootHover.play("off")
	isInAnimation = false

# Consecutive swing counter
var swingCounter :int = 0
# time elapsed since last swing
var timeFromLastSwing :float = 0.0
# Swinging our gun sword attack function
func Swing() -> void:
	isInAnimation = true
	isSwinging = true
	isJetPack = false
	flameBoot.play("off")
	rightBootHover.play("off")
	leftBootHover.play("off")
	DisplaySwing()
	airCounter = 0
	# 0.5 in this if is the max time elapsed between swings to consider a consecutive swing
	if timeFromLastSwing <= 0.5:
		swingCounter += 1
	# 4 in this if is our max swings before resetting the animations
	if swingCounter > 4:
		swingCounter = 0
	timeFromLastSwing = 0
	await get_tree().create_timer(0.1).timeout
	# common short swing
	# 4 in this if is our max swings before performing a big swing, check DisplaySwing() for animation details
	if swingCounter < 4:
		playerAudio.PlaySwing()
		velocity = transform.basis.z * -40
		await get_tree().create_timer(0.1).timeout
		DamageSwordTargets(60)
		await get_tree().create_timer(0.211).timeout
		timeFromLastSwing = 0
	# After 3 consecutive swings the 4th will be this big swing with altered effects
	else:
		playerAudio.PlaySwingBig()
		velocity.y = 3
		velocity = transform.basis.z * -55
		await get_tree().create_timer(0.1).timeout
		DamageSwordTargets(62)
		await get_tree().create_timer(0.111).timeout
		DamageSwordTargets(62)
		velocity = transform.basis.z * -40
		await get_tree().create_timer(0.211).timeout
		timeFromLastSwing = 0
	timeFromLastSwing = 0
	isInAnimation = false
	isSwinging = false
var isSlaming :bool = false
var isWallRunningRight :bool = false
var isWallRunningLeft :bool = false
# How long is our current wall run?
var wallRunCounter :float = 0.0
## Max time a player can wallrun before it deactivates
@export var maxWallRunTime :float = 4.0
# Wall Running Functionality
func WallRunning(_delta:float) -> void:
	if !isJetPack && !isInAnimation && Input.is_action_pressed("move_forward") && wallRunLeft.is_colliding() && wallRunCounter < maxWallRunTime:
		isWallRunningLeft = true
		airCounter = 0
		wallRunCounter += _delta
	else:
		isWallRunningLeft = false
	if !isJetPack && !isInAnimation && Input.is_action_pressed("move_forward") && wallRunRight.is_colliding() && wallRunCounter < maxWallRunTime:
		isWallRunningRight = true
		airCounter = 0
		wallRunCounter += _delta
	else:
		isWallRunningRight = false

	if !isWallRunningLeft && !isWallRunningRight:
		wallRunCounter = 0
@onready var slamImpact :AnimatedSprite3D = $SlamImpact
# Slam attack!
func Slam() -> void:
	isInAnimation = true
	isSlaming = true
	isSwinging = true
	isJetPack = false
	canMove = false
	flameBoot.play("off")
	rightBootHover.play("off")
	leftBootHover.play("off")
	playerSprite.play("slam")
	airCounter = 0
	velocity.y = 5
	playerAudio.PlaySwing()
	playerAudio.slamStart.play()
	await get_tree().create_timer(0.1).timeout
	velocity.y = -6
	await get_tree().create_timer(0.05).timeout
	velocity.y = -9
	canMove = true
	DamageSwordTargets(80)
	airCounter = 0
	slamImpact.play("empty")
	await leaveSlam
	if is_on_floor():
		playerAudio.PlaySwing()
		slamImpact.play("impact")
		playerAudio.slamLand.play()
		airCounter = 0
		DamageSwordTargets(80)
		PushSwordTargets()
		canMove = false
		await get_tree().create_timer(0.125).timeout
	DamageSwordTargets(50)
	canMove = true
	airCounter = 0
	timeFromLastSwing = 0
	isInAnimation = false
	isSwinging = false
	isSlaming = false

# Match the counter in Fire func to apply multiple animations
var fireCounter :int = 0
var tempBullet
@onready var bulletSpawnPos = $BulletSpawnPos
# Shoots the gun sword
func Fire() -> void:
	isInAnimation = true
	playerAudio.PlayBlasterFire()
	velocity += transform.basis.z * 2
	isShooting = true
	match fireCounter:
		0: playerSprite.play("shoot_1")
		1: playerSprite.play("shoot_2")
	fireCounter += 1
	# the 1 in this IF statement is the max # of your Fire animations for your player sprite
	if fireCounter > 1:
		fireCounter = 0
	velocity = transform.basis.z * 1
	await get_tree().create_timer(0.05).timeout
	tempBullet = playerBullet.instantiate()
	tempBullet.transform.basis = mainCam.global_transform.basis
	tempBullet.position = bulletSpawnPos.global_position
	get_parent().add_child(tempBullet)
	playerAudio.PlayBlasterFire()
	await get_tree().create_timer(0.05).timeout
	tempBullet = playerBullet.instantiate()
	tempBullet.transform.basis = mainCam.global_transform.basis
	tempBullet.position = bulletSpawnPos.global_position
	get_parent().add_child(tempBullet)
	if !isJetPack:
		await get_tree().create_timer(0.2).timeout
	else:
		await get_tree().create_timer(0.1).timeout
	isInAnimation = false
	isShooting = false
# Just animates our current sword swing given our swing counter
func DisplaySwing() -> void:
	playerSprite.play("jump")
	# if you wish to add more swing anims, increase the match statement here and add your aniamtions to the player sprite
	match swingCounter:
		0: playerSprite.play("swing_1")
		1: playerSprite.play("swing_2")
		2: playerSprite.play("swing_3")
		3: playerSprite.play("swing_4")
		_:playerSprite.play("swing_air")
# Hurts any Enemies within range of gun sword using passed damage value
func DamageSwordTargets(damage :int) -> void:
	for s in swordTargets:
		if s != null:
			s.TakeDamage(damage)
		if s == null:
			swordTargets.erase(s)
# Pushes any Enemies within range of gun sword away from player's pos
func PushSwordTargets() -> void:
	for s in swordTargets:
		if s != null:
			s.Push(transform.basis.z)
		if s == null:
			swordTargets.erase(s)
func RotateForward() -> void:
	rotate(transform.basis.x, -2 * 0.01)
func RotateBackward() -> void:
	rotate(transform.basis.x, 2 * 0.01)
# Any target that enters within your damage area of effect will
# be listed in this array. Removed when killed or out of range.
@onready var swordTargets :Array[Node3D]
# Adds enemies that enter area of effect to our swordTargets array
func _on_hitbox_sword_body_entered(body: Node3D) -> void:
	swordTargets.append(body)
# Removes enemies that exit area of effect from our swordTargets array
func _on_hitbox_sword_body_exited(body: Node3D) -> void:
	swordTargets.erase(body)
