extends Area3D

@export var spaceBattleMusic :AudioStreamPlayer3D
@export var sadMusic :AudioStreamPlayer3D
@export var anim : AnimationPlayer
func _on_body_entered(_body: Node3D) -> void:
	spaceBattleMusic.play()
	sadMusic.stop()
	anim.play("destroyer_intro")
