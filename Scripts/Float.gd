extends CharacterBody3D

@export var pos1 : Vector3
@export var pos2 : Vector3
@export var timeToPosition : float

@export var movingToPos1 :bool = true

func _physics_process(_delta: float) -> void:
	if movingToPos1:
		position.y = lerpf(position.y, pos1.y, .5 * _delta)
	else:
		position.y = lerpf(position.y, pos2.y, .5 * _delta)

func _ready() -> void:
	MoveToPos1()
func MoveToPos1():
	movingToPos1 = true
	await get_tree().create_timer(timeToPosition).timeout
	MoveToPos2()
func MoveToPos2():
	movingToPos1 = false
	await get_tree().create_timer(timeToPosition).timeout
	MoveToPos1()
