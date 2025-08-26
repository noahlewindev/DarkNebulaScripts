extends Node3D

class_name PlayerAudio

@export var player : PlayerScript

@onready var saberHum :AudioStreamPlayer3D = $SaberHum
@onready var jetBootsHum :AudioStreamPlayer3D = $JetBootsHum
@onready var blasterFire :AudioStreamPlayer3D = $Blaster
@onready var saberSwing :AudioStreamPlayer3D = $SaberSwing
@onready var jetBootsEnableSFX :AudioStreamPlayer3D = $JetBootsActivate
@onready var swingBigSFX :AudioStreamPlayer3D = $SaberSwingBig
@onready var dodgeSFX :AudioStreamPlayer3D = $Dodge
@onready var deflectSourceSFX :AudioStreamPlayer3D = $Deflect
@onready var deathSFX :AudioStreamPlayer3D = $Death
@onready var hurtSFXPlayer :AudioStreamPlayer3D = $Hurt
@onready var jump :AudioStreamPlayer3D = $Jump
@export var swingSFX :Array[AudioStream]
@export var deflectSFX :Array[AudioStream]
@export var hurtSFX :Array[AudioStream]
@onready var slamStart : AudioStreamPlayer3D = $SlamStart
@onready var slamLand : AudioStreamPlayer3D = $SlamLand

@onready var healSound : AudioStreamPlayer3D = $Heal
func _process(_delta: float) -> void:
	if player.isJetPack:
		jetBootsHum.stream_paused = false
		if Input.is_action_pressed("jump"):
			jetBootsHum.pitch_scale = lerpf(jetBootsHum.pitch_scale, 1.23, 0.5)
		else :
			jetBootsHum.pitch_scale = lerpf(jetBootsHum.pitch_scale, 1.0, 0.5)
	else:
		jetBootsHum.stream_paused = true
		jetBootsHum.pitch_scale = lerpf(jetBootsHum.pitch_scale, 1.0, 0.5)
func PlayJump():
	jump.play()
func PlayJetBoots():
	jetBootsEnableSFX.play()
func PlayDodge():
	dodgeSFX.play()
func PlaySwingBig():
	swingBigSFX.play()
func PlayBlasterFire():
	blasterFire.play()
func PlayBlasterDeflect():
	deflectSourceSFX.stream = GetRandomDeflectSound()
	deflectSourceSFX.play()
func PlayHurt():
	hurtSFXPlayer.stream = GetRandomHurtSFX()
	hurtSFXPlayer.play()
func PlaySwing():
	saberSwing.stream = GetRandomSwingSound()
	saberSwing.play()
var rng = RandomNumberGenerator.new()
func GetRandomSwingSound() -> AudioStream:
	var rando = rng.randi_range(0,swingSFX.size() -1)
	return swingSFX[rando]
func GetRandomDeflectSound() -> AudioStream:
	var rando = rng.randi_range(0,deflectSFX.size() -1)
	return deflectSFX[rando]
func GetRandomHurtSFX() -> AudioStream:
	var rando = rng.randi_range(0,hurtSFX.size() -1)
	return hurtSFX[rando]
