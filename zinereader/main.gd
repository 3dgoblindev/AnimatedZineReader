extends Node2D

var page_paths = []
var current_page_index = 0

var special_sounds = {
	200: "res://sounds/page_dramatic.wav"
}

var turning_right = false
# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = DirAccess.open("res://pages")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png") and not dir.current_is_dir():
				page_paths.append("res://pages/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		page_paths.sort() # Asegura orden como page_0, page_1, etc.
		_load_current_pages()

func _load_current_pages():
	# Página izquierda actual
	if current_page_index < page_paths.size():
		$LPage.texture = load(page_paths[current_page_index])
	else:
		$LPage.texture = null

	# Página derecha actual
	if current_page_index + 1 < page_paths.size():
		$RPage.texture = load(page_paths[current_page_index + 1])
	else:
		$RPage.texture = null

	# Página izquierda siguiente (para animación)
	if current_page_index + 2 < page_paths.size():
		$LPage2.texture = load(page_paths[current_page_index + 2])
	else:
		$LPage2.texture = null

	# Página derecha siguiente (para animación)
	if current_page_index + 3 < page_paths.size():
		$RPage0.texture = load(page_paths[current_page_index + 3])
	else:
		$RPage0.texture = null
		
	# Página izquierda siguiente (para animación)
	if current_page_index - 2 > 0:
		$LPage0.texture = load(page_paths[current_page_index - 2])
	else:
		$LPage0.texture = null

	# Página derecha siguiente (para animación)
	if current_page_index - 1 > 0:
		$RPage2.texture = load(page_paths[current_page_index -1 ])
	else:
		$RPage2.texture = null

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event):
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
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

		#añadir animacion de girar para la izq. Creo que necsito añadir paginas temporales pal otro lado
		

func TurnRight():
	if current_page_index + 2 < page_paths.size():
		turning_right = true
		$TurnPage.play()
		$AnimationPlayer.play("TurnPage_R")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "TurnPage_R" or anim_name == "TurnPage_L":
		# Actualiza el índice de página
		if turning_right:
			current_page_index += 2
		else:
			current_page_index -= 2

		# Cargar nuevas texturas
		_load_current_pages()

		# Resetear visibilidades/posiciones si es necesario
		# Por ejemplo:
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
	
