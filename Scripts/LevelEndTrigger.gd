extends Area3D

@export var enemiesToKill :Array[Node3D]
@export var playerToRemove :Node3D
@export var cutsceneToPlay :AnimationPlayer
@export var cutsceneOBJ :Node3D
@onready var hasEnabledEnd:bool = false
@export var levelEndMarker :Sprite3D
@export var timer :Timer
@export var levelToLoad :String
func _process(_delta: float) -> void:
	if !hasEnabledEnd:
		if !AreEnemiesAlive():
			monitoring = true
			levelEndMarker.visible = true
			hasEnabledEnd = true

func AreEnemiesAlive() -> bool:
	for e in enemiesToKill:
		if e != null:
			return true
	return false

func _on_body_entered(_body: Node3D) -> void:
	playerToRemove.queue_free()
	cutsceneOBJ.visible = true
	cutsceneToPlay.play("LevelEndScene")
	timer.start()

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file(levelToLoad)
