extends Area3D

class_name ComputerNode

@onready var box :CSGBox3D = $CSGBox3D
@onready var objIcon :Sprite3D = $Sprite3D
@onready var sfx :AudioStreamPlayer3D = $sfx
@export var boxONTexture : Material
@export var boxOffTexture : Material
@export var isOFF : bool = false
func _on_body_entered(_body: Node3D) -> void:
	box.material = boxOffTexture
	objIcon.visible = false
	sfx.play()
	isOFF = true
	set_deferred("monitoring", false)
func TurnBackOn():
	box.material = boxONTexture
	objIcon.visible = true
	set_deferred("monitoring", true)
	isOFF = false
