extends Node3D

@onready var playerPrefab = preload("res://Assets/Prefabs/Player.tscn")
@export var playerSpawnPos :Node3D
@onready var mainCam : Camera3D = $Camera3D
@export var audioToPlayAfter :AudioStreamPlayer3D
@export var deadDad: Node3D
@onready var set1 :Node3D = $Set1
@onready var set2 :Node3D = $Set2
var tempSpawn
var sceneFinished :bool = false
@onready var timer : Timer = $CutsceneTimer
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("land") && !sceneFinished:
		timer.timeout.emit()

func CloseSceneAfterTimer():
	sceneFinished = true
	tempSpawn = playerPrefab.instantiate()
	tempSpawn.position = playerSpawnPos.global_position
	get_parent().add_child(tempSpawn)
	tempSpawn.SetCamMain()
	mainCam.current = false
	mainCam.visible = false
	audioToPlayAfter.play()
	deadDad.visible = true
	set1.visible = false
	set2.visible = false
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_cutscene_timer_timeout() -> void:
	CloseSceneAfterTimer()
