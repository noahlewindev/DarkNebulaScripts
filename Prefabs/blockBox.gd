extends Area3D

@export var playerAudio :PlayerAudio

func PlaySFX():
	playerAudio.PlayBlasterDeflect()
	playerAudio.player.Deflect()
