extends Node3D
class_name MainMenuScript

@onready var buttonsUI = $UI/Buttons
@onready var newGameButton :Button = $UI/Buttons/NewGame
@onready var optionsButton :Button = $UI/Buttons/Options
@onready var controlButon :Button = $UI/Buttons/Controls
@onready var creditsButton :Button = $UI/Buttons/Credits
@onready var exitGameButton :Button = $"UI/Buttons/Exit Game"
@onready var levelSelectButton :Button = $UI/Buttons/LevelSelect
@onready var levelSelectGoBackButton :Button = $UI/AltMenus/LevelSelectScreen/GoBackFromLevelSelect
@onready var mouseSensSlider :HSlider = $UI/AltMenus/Options/BoxContainer/MouseSensSlider
@onready var mouseSensLabel :RichTextLabel = $UI/AltMenus/Options/BoxContainer/MouseSensLabel
@onready var controlsScreen = $UI/AltMenus/Controls
@onready var controlGoBackButton :Button = $UI/AltMenus/Controls/Goback

@onready var creditScreen = $UI/AltMenus/Credits
@onready var creditGoBackButton :Button = $UI/AltMenus/Credits/GoBackFromCredits
@onready var levelSelectScreen  = $UI/AltMenus/LevelSelectScreen

@onready var optionsScreen = $UI/AltMenus/Options
@onready var optionsGoBackButton :Button = $UI/AltMenus/Options/GoBackFromOptions
@onready var musicLabel :RichTextLabel = $UI/AltMenus/Options/BoxContainer/MusicLabel2
@onready var sfxLabel :RichTextLabel = $UI/AltMenus/Options/BoxContainer/SFXLabel
@onready var maxFPSLabel :RichTextLabel = $UI/AltMenus/Options/BoxContainer/MAXFPSLabel
@onready var fovLabel :RichTextLabel = $UI/AltMenus/Options/BoxContainer/FOVLabel
@onready var VOLabel :RichTextLabel = $UI/AltMenus/Options/BoxContainer/VOLabel
@onready var VOSlider :HSlider = $UI/AltMenus/Options/BoxContainer/VOSlider
@onready var windowedToggle :CheckButton = $UI/AltMenus/Options/BoxContainer/Windowed
@onready var VSYNCToggle :CheckButton = $UI/AltMenus/Options/BoxContainer/VSYNC
@onready var musicSlider :HSlider = $UI/AltMenus/Options/BoxContainer/MusicSlider2
@onready var sfxSlider :HSlider = $UI/AltMenus/Options/BoxContainer/SFXSlider
@onready var fpsSlider :HSlider = $UI/AltMenus/Options/BoxContainer/FPSSlider
@onready var fovSlider :HSlider = $UI/AltMenus/Options/BoxContainer/FOVSlider

@onready var sfxBusIndex :int
@onready var voBusIndex :int
@onready var musicBusIndex
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	sfxBusIndex = AudioServer.get_bus_index("SFX")
	musicBusIndex = AudioServer.get_bus_index("Music")
	voBusIndex = AudioServer.get_bus_index("VO")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	SetSFXLabelText(str(SaveSystem.get_var("SFXVolume", 1.0)))
	sfxSlider.value = SaveSystem.get_var("SFXVolume", 1.0)
	SetMusicLabelText(str(SaveSystem.get_var("MusicVolume", 1.0)))
	musicSlider.value = SaveSystem.get_var("MusicVolume", 1.0)
	SetFOVSliderText(str(roundi(SaveSystem.get_var("FOV", 85))))
	VOSlider.value = SaveSystem.get_var("VOVolume", 1.0)
	SetVOLabelText(str(SaveSystem.get_var("VOVolume", 1.0)))
	fovSlider.value = SaveSystem.get_var("FOV", 85)
	SetFPSSliderText(str(roundi(SaveSystem.get_var("MaxFPS", 90))))
	fpsSlider.value = SaveSystem.get_var("MaxFPS", 90)
	mouseSensSlider.value = SaveSystem.get_var("MouseSens", 0.4)
	SetMouseSensLabelText(str(mouseSensSlider.value))
	if SaveSystem.get_var("UseVsync", true):
		VSYNCToggle.button_pressed = true
	else :
		VSYNCToggle.button_pressed = false
	await get_tree().create_timer(.125).timeout
	newGameButton.grab_focus()

func _on_exit_game_pressed() -> void:
	get_tree().quit()

func _on_credits_pressed() -> void:
	creditGoBackButton.grab_focus()
	creditScreen.visible = true
	buttonsUI.visible = false
func _on_controls_pressed() -> void:
	controlGoBackButton.grab_focus()
	controlsScreen.visible = true
	buttonsUI.visible = false
func _on_options_pressed() -> void:
	optionsGoBackButton.grab_focus()
	optionsScreen.visible = true
	buttonsUI.visible = false
func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("uid://bhkr10jqhne3c")

func _on_go_back_from_credits_pressed() -> void:
	creditScreen.visible = false
	buttonsUI.visible = true
	creditsButton.grab_focus()
func _on_go_back_from_options_pressed() -> void:
	optionsScreen.visible = false
	buttonsUI.visible = true
	optionsButton.grab_focus()

func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(musicBusIndex,linear_to_db(value))
	SetMusicLabelText(str(value))
	SaveSystem.set_var("MusicVolume", value)
	SaveSystem.save()
func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfxBusIndex,linear_to_db(value))
	SetSFXLabelText(str(value))
	SaveSystem.set_var("SFXVolume", value)
	SaveSystem.save()
func _on_fps_slider_value_changed(value: float) -> void:
	SaveSystem.set_var("MaxFPS", value)
	SetFPSSliderText(str(roundi(value)))
	SaveSystem.save()
func _on_fov_slider_value_changed(value: float) -> void:
	SaveSystem.set_var("FOV", value)
	SetFOVSliderText(str(roundi(value)))
	SaveSystem.save()

func _on_windowed_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else :
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _on_vsync_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		SaveSystem.set_var("UseVsync", true)
	else :
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		SaveSystem.set_var("UseVsync", false)
func SetFOVSliderText(fovValue : String):
	fovLabel.text = "FOV : " + fovValue
func SetFPSSliderText(fpsValue : String):
	maxFPSLabel.text = "Max FPS : " + fpsValue
func SetSFXLabelText(sfxValue : String):
	sfxLabel.text = "SFX Volume : " + sfxValue
func SetMusicLabelText(musicValue : String):
	musicLabel.text = "Music Volume : " + musicValue
func SetMouseSensLabelText(value : String):
	mouseSensLabel.text = "Mouse Sensitivity : " + value
func SetVOLabelText(value : String):
	VOLabel.text = "Voice Over Volume : " + value
func _on_level_select_pressed() -> void:
	optionsScreen.visible = false
	levelSelectScreen.visible = true
	buttonsUI.visible = false
	levelSelectScreen.visible = true
	levelSelectGoBackButton.grab_focus()
	levelSelectScreen.visible = true

func _on_go_back_from_level_select_pressed() -> void:
	optionsScreen.visible = false
	levelSelectScreen.visible = false
	buttonsUI.visible = true
	levelSelectButton.grab_focus()

func _on_lv_1_pressed() -> void:
	get_tree().change_scene_to_file("uid://bhkr10jqhne3c")
func _on_lv_2_pressed() -> void:
	get_tree().change_scene_to_file("uid://day12gh83ejbi")
func _on_lv_3_pressed() -> void:
	get_tree().change_scene_to_file("uid://fi7s4245neui")
func _on_lv_4_pressed() -> void:
	get_tree().change_scene_to_file("uid://qbioubxi6ma2")
func _on_lv_5_pressed() -> void:
	get_tree().change_scene_to_file("uid://cqotqdsxmlfmx")


func _on_goback_pressed() -> void:
	controlsScreen.visible = false
	buttonsUI.visible = true
	controlButon.grab_focus()


func _on_mouse_sens_slider_value_changed(value: float) -> void:
	SetMouseSensLabelText(str(value))
	SaveSystem.set_var("MouseSens", value)
	SaveSystem.save()


func _on_vo_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(voBusIndex,linear_to_db(value))
	SetVOLabelText(str(value))
	SaveSystem.set_var("VOVolume", value)
	SaveSystem.save()
