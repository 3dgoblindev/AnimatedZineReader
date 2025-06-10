extends Node2D

@export var page_textures: Array[Texture2D] = []
var current_page_index = 0

var special_sounds = {
	200: "res://sounds/page_dramatic.wav"
}

var special_page
var turning_right = false

func _ready():
	special_page = $Minigame
	_load_current_pages()

func _load_current_pages():
	if current_page_index < page_textures.size():
		$LPage.texture = page_textures[current_page_index]
	else:
		$LPage.texture = null

	if current_page_index + 1 < page_textures.size():
		$RPage.texture = page_textures[current_page_index + 1]
	else:
		$RPage.texture = null

	if current_page_index + 2 < page_textures.size():
		$LPage2.texture = page_textures[current_page_index + 2]
	else:
		$LPage2.texture = null

	if current_page_index + 3 < page_textures.size():
		$RPage0.texture = page_textures[current_page_index + 3]
	else:
		$RPage0.texture = null

	if current_page_index - 2 >= 0:
		$LPage0.texture = page_textures[current_page_index - 2]
	else:
		$LPage0.texture = null

	if current_page_index - 1 >= 0:
		$RPage2.texture = page_textures[current_page_index - 1]
	else:
		$RPage2.texture = null


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if special_page.visible:
			return

		if is_at_last_page():
			_show_minigame()
			return
		
		var x = event.position.x
		var screen_width = get_viewport().size.x

		if x < screen_width / 2:
			TurnLeft()
		else:
			TurnRight()


func TurnLeft():
	if current_page_index - 2 >= 0:
		turning_right = false
		$TurnPage.play()
		$AnimationPlayer.play("TurnPage_L")

func TurnRight():
	if current_page_index + 2 < page_textures.size():
		turning_right = true
		$TurnPage.play()
		$AnimationPlayer.play("TurnPage_R")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "TurnPage_R" or anim_name == "TurnPage_L":
		if turning_right:
			current_page_index += 2
		else:
			current_page_index -= 2

		_load_current_pages()

		$LPage2.visible = false
		$RPage2.visible = false
		$LPage.visible = true
		$RPage.visible = true
		$RPage.scale.x = 1
		$LPage.scale.x = 1
		
		if special_sounds.has(current_page_index):
			var path = special_sounds[current_page_index]
			var custom_sound = load(path)
			if custom_sound:
				$SpecialSoundPlayer.stream = custom_sound
				$SpecialSoundPlayer.play()
	
func is_at_last_page() -> bool:
	return current_page_index + 1 >= page_textures.size()

func _show_minigame():
	special_page.visible = true
	$Minigame/Container.start_game()
	$LPage.visible = false
	$RPage.visible = false
