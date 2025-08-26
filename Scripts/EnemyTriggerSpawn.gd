extends Area3D

@export var spawnsGroundUnit :bool = true
@export var possibleSpawns :Array[Node3D]
@onready var droidPrefab = preload("res://Assets/Prefabs/DroidA.tscn")
@onready var droidShipPrefab = preload("res://Assets/Prefabs/enemy_star_craft.tscn")

@export var optionalAudioToPlay :AudioStreamPlayer3D

var hasTriggered

func _on_body_entered(body: Node3D) -> void:
	if spawnsGroundUnit:
		SpawnGroundUnit()
	else:
		SpawnAirUnit()
	set_deferred("monitoring", false)

var rng = RandomNumberGenerator.new()
var tempSpawnEnemy
func SpawnGroundUnit():
	for spawn in possibleSpawns:
		tempSpawnEnemy = droidPrefab.instantiate()
		tempSpawnEnemy.position = spawn.position
		get_parent().add_child(tempSpawnEnemy)
	if optionalAudioToPlay != null:
		optionalAudioToPlay.play()
func SpawnAirUnit():
	pass
