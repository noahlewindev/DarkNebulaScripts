extends CharacterBody3D
class_name Drivable
@export var inSpace :bool = false
@export var inLandableSpace :bool = false
@export var isLandSpeeder :bool = false
@export var starFighterMesh :Node3D
@export var optionalActiveSprite :AnimatedSprite3D
@onready var SPEED = 4.0
@export var gravity :float = 0
## rate at which the ship will realign to straigthen out, 0.01 is default
@export_range(0.0001, 1.00001) var glideRealignRate : float = 0.01
@onready var mouseInputLerpedV = Vector2.ZERO
@onready var playerSpawnPos :Node3D = $"Player Spawn pos"
const moveSpeedDefault :float = 4.0
@export var defaultBaseSpeed :float = 7.0
var mouse_sens :float = 0.4
@export var cameraRotateLerpSpeed = 0.5
var direction = Vector3.ZERO
var dead :bool = false
var isMoving :bool = false
var canMove :bool = true

# Is our engines on?
@export var isGliding :bool = false
var isInTransitionAnim :bool = false
@onready var camera :Camera3D= $SpringArm3D/Camera3D

var bullet = preload("res://Assets/Prefabs/bullets/drivable_bullet_a.tscn")
var speederBullet = preload("res://Assets/Prefabs/bullets/drivable_bullet_b.tscn")
var playerPrefab = preload("res://Assets/Prefabs/Player.tscn")

var isPossessed :bool = false
@onready var engine :AudioStreamPlayer3D = $shipEngine
func _ready():
	Engine.max_fps = SaveSystem.get_var("MaxFPS", 90)
	camera.fov = SaveSystem.get_var("FOV", 85)
	mouse_sens = SaveSystem.get_var("MouseSens", 0.4)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func Possess():
	isLanding = false
	camera.current = true
	canMove = true
	gear = 0
	position.y += 1
	if optionalActiveSprite != null:
		optionalActiveSprite.visible = true
	await get_tree().create_timer(0.125).timeout
	isPossessed = true
	isGliding = true
	GameManager.playerDrivableShip = self

signal landedSignal
var isLanding = true
var tempSpawn
func Land():
	isInTransitionAnim = true
	isLanding = true
	canMove = false
	velocity.y = -2
	await landedSignal
	isLanding = false
	if optionalActiveSprite != null:
		optionalActiveSprite.visible = false
	camera.current = false
	if hasAltCam != null:
		hasAltCam.current = false
	tempSpawn = playerPrefab.instantiate()
	tempSpawn.position = playerSpawnPos.global_position
	get_parent().add_child(tempSpawn)
	camera.current = false
	if hasAltCam != null:
		hasAltCam.current = false
	isInTransitionAnim = false
	canMove = false
	isPossessed = false
func _physics_process(delta: float) -> void:
	if isPossessed:
		if isLanding:
			isGliding = false
			velocity.y = -4
			velocity.x = 0
			velocity.z = 0
			if is_on_floor():
				landedSignal.emit()
				rotation_degrees.x = 0
				rotation_degrees.z = 0
		if Input.is_action_just_pressed("interact"):
			ToggleExtraCam()
		if Input.is_action_pressed("escape"):
			get_tree().change_scene_to_file("uid://cydkp5jqc5btm")
	
		if isGliding:
			GlideInput(delta)
			# Call for shooting laser
			if Input.is_action_pressed("attack") && !isFiring:
				FireLaser()
		if isFocusing:
			LerpToTarget(delta)
		CameraAnimatonLogic()
		SetSpeed(delta)
		move_and_slide()
var laserCounter:int = 0
@onready var laserBlastLeft :AudioStreamPlayer3D = $FirePorts/LeftPort
@onready var laserBlastRight :AudioStreamPlayer3D = $FirePorts/RightPort
var tempBullet
var isFiring :bool = false
var gear :int = 0
@export var maxGEAR :int = 5
func Gravity(delta:float):
	velocity.y -= gravity * delta
func ChangeGear(value :int) -> void:
	gear += value
	if gear > maxGEAR:
		gear = maxGEAR
	if gear < 0:
		gear = 0
func FireLaser() -> void:
	if isLandSpeeder:
		tempBullet = speederBullet.instantiate()
	else:
		tempBullet = bullet.instantiate()
	isFiring = true
	match laserCounter:
		0: 
			tempBullet.position = laserBlastLeft.global_position
			laserBlastLeft.play()
		1:
			tempBullet.position = laserBlastRight.global_position
			laserBlastRight.play()
	tempBullet.transform.basis = global_transform.basis
	get_parent().add_child(tempBullet)
	laserCounter += 1
	if laserCounter > 1:
		laserCounter = 0
	await get_tree().create_timer(0.123).timeout
	isFiring = false
var isFocusing :bool = false
var target
func Focus(collidedOBJ :Node3D) -> void:
	if collidedOBJ != null:
		isFocusing = true
		target = transform.looking_at(collidedOBJ.global_position, Vector3.UP)
		position = position.move_toward(collidedOBJ.global_position, 0.4)
		await get_tree().create_timer(0.123).timeout
		isFocusing = false
func LerpToTarget(delta) -> void:
	global_transform.basis.y=lerp(global_transform.basis.y, target.basis.y, delta * 6)
	global_transform.basis.x=lerp(global_transform.basis.x, target.basis.x, delta * 6)
	global_transform.basis.z=lerp(global_transform.basis.z, target.basis.z, delta * 6)
	scale = Vector3(1,1,1)
func SetSpeed(_delta:float) -> void:
	if isGliding:
		match gear:
			0:
				SPEED = lerpf(SPEED, defaultBaseSpeed / 2, 0.0125)
				engine.pitch_scale = lerpf(engine.pitch_scale, .8, 0.125)
			1:
				SPEED = lerpf(SPEED, defaultBaseSpeed, 0.0125)
				engine.pitch_scale = lerpf(engine.pitch_scale, 1.0, 0.125)
			3:
				SPEED = lerpf(SPEED, defaultBaseSpeed * 1.5, 0.0125)
				engine.pitch_scale = lerpf(engine.pitch_scale, 1.2, 0.125)
			4:
				SPEED = lerpf(SPEED, defaultBaseSpeed * 2, 0.0125)
				engine.pitch_scale = lerpf(engine.pitch_scale, 1.4, 0.125)
			5:
				SPEED = lerpf(SPEED, defaultBaseSpeed * 2.5, 0.0125)
				engine.pitch_scale = lerpf(engine.pitch_scale, 1.6, 0.125)
	else :
		SPEED = lerpf(SPEED, defaultBaseSpeed, 0.0125)
		engine.pitch_scale = lerpf(engine.pitch_scale, 0.01, 0.125)
var rayNormal
var airCounter :float = 0.0
func GlideInput(delta) -> void:
	cameraInput()
	if Input.is_action_pressed("move_right"):
		RotateRight()
	if Input.is_action_pressed("move_left"):
		RotateLeft()
	if Input.is_action_just_pressed("move_forward"):
		ChangeGear(1)
	if Input.is_action_just_pressed("move_backward"):
		ChangeGear(-1)
	if !isLandSpeeder:
		GlideRealign(Vector3.UP)
	else:
		Gravity(delta)
		if $GroundNormalCheck.is_colliding():
			rayNormal = $GroundNormalCheck.get_collision_normal()
			xform = AlignWithY(global_transform, rayNormal)
			global_transform = global_transform.interpolate_with(xform, 0.01)
			airCounter = 0
		else:
			airCounter += delta
			GlideRealign(Vector3.UP)
			RotateRelativeMouseX(mouse_sens * 6 * airCounter)
	velocity = transform.basis.z * -200 * SPEED * delta
#Check our mouse movements
func _input(event : InputEvent) -> void:
	# If not drivable code won't continue
	if dead || !isPossessed:
		return
	# Mouse Input Check
	if event is InputEventMouseMotion:
		rotation_degrees.y = lerp(rotation_degrees.y, rotation_degrees.y - event.relative.x * mouse_sens / 2, cameraRotateLerpSpeed)
		if !isLanding:
			RotateRelative(event)
		RotateRelativeX(event)
		camera.rotate_x(-event.relative.y * (mouse_sens / 100))
		_clamp_camera_x()
	if event.is_action_pressed("land") && !isInTransitionAnim && landPoint.is_colliding():
		if !inSpace:
			Land()
		else :
			if inLandableSpace:
				Land()
@export var cameraMinXDEGREES : int = -4
@export var cameraMaxXDEGREES : int = 4

# How much is the camera allowed to look up and down
func _clamp_camera_x() -> void:
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(cameraMinXDEGREES), deg_to_rad(cameraMaxXDEGREES))

# floor normal for our transform basis to be referenced during re-alignment
var xform
# Realign our ship to keep it flat.
func GlideRealign(floor_normal : Vector3) -> void:
	xform = global_transform
	xform.basis.y = floor_normal
	xform.basis.x = -xform.basis.z.cross(floor_normal)
	xform.basis = xform.basis.orthonormalized()
	global_transform = global_transform.interpolate_with(xform, glideRealignRate)
func AlignWithY(xForm : Transform3D, new_y):
	xForm.basis.y = new_y
	xForm.basis.x = -xForm.basis.z.cross(new_y)
	xForm.basis = xForm.basis.orthonormalized()
	return xForm
func cameraInput() -> void:
	if Input.is_action_pressed("look_left"):
		if isLandSpeeder && $GroundNormalCheck.is_colliding():
			mouseInputLerpedV = mouseInputLerpedV.lerp(Vector2(0, 6 * mouse_sens), cameraRotateLerpSpeed)
		else:
			mouseInputLerpedV = mouseInputLerpedV.lerp(Vector2(0, 3 * mouse_sens), cameraRotateLerpSpeed)
		rotation_degrees.y += mouseInputLerpedV.y
	if Input.is_action_pressed("look_right"):
		if isLandSpeeder && $GroundNormalCheck.is_colliding():
			mouseInputLerpedV = mouseInputLerpedV.lerp(Vector2(0, 6 * mouse_sens), cameraRotateLerpSpeed)
		else:
			mouseInputLerpedV = mouseInputLerpedV.lerp(Vector2(0, 3 * mouse_sens), cameraRotateLerpSpeed)
		rotation_degrees.y -= mouseInputLerpedV.y
	if Input.is_action_pressed("look_down"):
		camera.rotate_x(-(mouse_sens / 100))
		RotateRelativeMouseX(mouse_sens * 3)
		_clamp_camera_x()
	if Input.is_action_pressed("look_up"):
		camera.rotate_x((mouse_sens / 100))
		if isLandSpeeder :
			RotateRelativeMouseX(-mouse_sens * 9)
		else:
			RotateRelativeMouseX(-mouse_sens * 3)
		_clamp_camera_x()
@onready var camIdle_mid :Node3D = $CamPos/idlePos
@onready var camIdle_right :Node3D = $CamPos/IdleRight
@onready var camIdle_left :Node3D = $CamPos/IdleLeft
@onready var cameraARM :SpringArm3D = $SpringArm3D
@export var cameraLerpToSpeed : float = 0.1
@export var cameraLerpBackSpeed : float  = 0.0125
func CameraAnimatonLogic() -> void:
	if Input.is_action_pressed("move_right"):
		cameraARM.position = cameraARM.position.lerp(camIdle_right.position, cameraLerpToSpeed)
	elif Input.is_action_pressed("move_left"):
		cameraARM.position = cameraARM.position.lerp(camIdle_left.position, cameraLerpToSpeed)
	else:
		cameraARM.position = cameraARM.position.lerp(camIdle_mid.position, cameraLerpBackSpeed)

func Kill() -> void:
	engine.stream_paused = true
	starFighterMesh.visible = false
	$Destroy.play()
	$ImpactSprite.play("fire")
	if optionalActiveSprite != null:
		optionalActiveSprite.visible = false
	velocity = Vector3.ZERO
	move_and_slide()
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()

var input_dir
@onready var landPoint :RayCast3D = $LandPoint
func moveInput() -> void:
	input_dir = Input.get_vector("move_left","move_right","move_forward","move_backward")
	direction = (transform.basis * Vector3(input_dir.x,0,-abs(input_dir.y))).normalized()
func RotateForward() -> void:
	rotate(transform.basis.x, -2 * 0.01)
func RotateForwardSlightly() -> void:
	rotate(transform.basis.x, -1 * 0.01)
func RotateForwardAlot() -> void:
	rotate(transform.basis.x, -4 * 0.01)
func RotateBackwardAlot() -> void:
	rotate(transform.basis.x, 3 * 0.00123)
func RotateDodge(delta) -> void:
	rotate(transform.basis.x, 90 * 0.075 * delta)
func RotateBackward() -> void:
	rotate(transform.basis.x, 2 * 0.01)
func RotateBackwardSlightly() -> void:
	rotate(transform.basis.x, 2 * 0.02)
func RotateRelative(eventRelative : InputEventMouseMotion) -> void:
	rotate(transform.basis.z, 1 * 0.00065 * -eventRelative.relative.x)
func RotateRelativeX(eventRelative : InputEventMouseMotion) -> void:
	rotate(transform.basis.x, 1 * 0.01 * -eventRelative.relative.y)
func RotateRelativeMouseX(amount : float) -> void:
	rotate(transform.basis.x, 1 * 0.01 * -amount)
@export var rotateAmount :float = 0.01
@export var rotateDefaultBasis :int = 3
func RotateLeft() -> void:
	rotate(transform.basis.z, 3 * rotateAmount)
	if isLandSpeeder && $LandPoint.is_colliding():
		rotation_degrees.y += 2 * 0.04
func RotateRight() -> void:
	rotate(transform.basis.z, -3 * rotateAmount)
	if isLandSpeeder && $LandPoint.is_colliding():
		rotation_degrees.y -= 2 * 0.04
func _on_collision_area_entered(area: Area3D) -> void:
	if isPossessed:
		Kill()
func _on_collision_body_entered(body: Node3D) -> void:
	if isPossessed:
		Kill()
@export var hasAltCam :Camera3D
@onready var usingAltCam :bool = false
@onready var defaultCam :Camera3D = $SpringArm3D/Camera3D
func ToggleExtraCam():
	if hasAltCam != null:
		usingAltCam = !usingAltCam
		if usingAltCam:
			hasAltCam.current = true
			defaultCam.current = false
		else:
			hasAltCam.current = false
			defaultCam.current = true
