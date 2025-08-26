extends Node

@export var audioDialogue :AudioStream
@export var audioDialogueToPlay :AudioStreamPlayer3D
@export var sceneToPlay : AnimationPlayer
@export var sceneTitle :String

func PlayAudio() -> void:
	audioDialogueToPlay.stream = audioDialogue
	audioDialogueToPlay.play()
	if sceneTitle != "":
		sceneToPlay.play(sceneTitle)


func _on_timeout() -> void:
	PlayAudio()
