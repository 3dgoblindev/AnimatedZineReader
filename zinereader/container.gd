extends Container
var start = false
@export var flower_texture: Texture2D
@export var rock_texture: Texture2D
@export var goal_texture: Texture2D
@export var start_texture: Texture2D
@export var empty_texture: Texture2D
@export var tile_size: int = 64
@export var car_texture: Texture2D

@export var win_sound: AudioStream
@export var click_sound: AudioStream
@export var car_move_sound: AudioStream
@export var flower_sound: AudioStream
@export var path_step_sound: AudioStream


var win_audio: AudioStreamPlayer
var click_audio: AudioStreamPlayer
var car_audio: AudioStreamPlayer
var flower_audio: AudioStreamPlayer
var path_audio: AudioStreamPlayer



var car_sprite: Sprite2D
var car_position 
var restart_b
var imagen1
var imagen2

var max_turns = 6
var used_turns = []
var car_direction := Vector2i(0, -1) # Empieza hacia la derecha
var car_path := []
var flowers_adjacent_count := 0
var turn_directions: Dictionary = {}


var level := [
	["-", "-", "-", "-", "-", "-", "F", "-", "-", "G"],
	["-", "-", "-", "F", "-", "-", "P", "-", "-", "-"],
	["F", "-", "-", "-", "-", "-", "-", "F", "-", "-"],
	["-", "-", "-", "P", "-", "-", "-", "-", "-", "-"],
	["-", "-", "-", "-", "-", "-", "-", "-", "-", "-"],
	["-", "F", "-", "-", "-", "-", "F", "-", "-", "-"],
	["-", "-", "-", "-", "-", "-", "-", "-", "P", "-"],
	["-", "-", "-", "-", "-", "-", "-", "-", "-", "-"],
	["-", "-", "-", "P", "-", "-", "F", "-", "-", "-"],
	["S", "P", "-", "F", "-", "-", "-", "-", "-", "-"]
]
var tile_nodes = {}


func _ready() -> void:
	print("ready")



func find_start() -> Vector2i:
	for y in range(level.size()):
		for x in range(level[y].size()):
			if level[y][x] == "S":
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _on_tile_pressed(x: int, y: int) -> void:
	var tile = tile_nodes.get(Vector2i(x, y))
	click_audio.play()
	if tile:
		var tween = create_tween()
		tween.tween_property(tile, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(tile, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)

		await tween.finished  # Espera a que termine la animación para ejecutar la lógica

		_handle_tile_logic(x, y)
	
func _handle_tile_logic(x: int, y: int) -> void:
	if start:
		var pos = Vector2i(x, y)

		if not pos in car_path:
			return  # Solo permite clics en el camino

		# Primero: detectar si pos está **antes** del último giro en used_turns
		if used_turns.size() > 0:
			var last_turn_index = used_turns.size() - 1
			var last_turn_pos = used_turns[last_turn_index]
			var clicked_index = car_path.find(pos)

			var last_turn_path_index = car_path.find(last_turn_pos)

			# Si el click está antes del último giro en la ruta (menor índice)
			if clicked_index < last_turn_path_index:
				# Eliminar giros que están **después** del click
				# Buscar el índice de ese giro en used_turns
				var to_remove = []
				for i in range(used_turns.size()):
					var turn_pos = used_turns[i]
					var turn_path_index = car_path.find(turn_pos)
					if turn_path_index > clicked_index:
						to_remove.append(turn_pos)
				
				for turn_pos in to_remove:
					used_turns.erase(turn_pos)
					turn_directions.erase(turn_pos)
				
				print("Giross borrados después de", pos, ":", to_remove)

		# Ahora la lógica normal para añadir o cambiar giros
		if not used_turns.has(pos):
			if used_turns.size() < max_turns:
				used_turns.append(pos)
				if used_turns.size() % 2 != 0:
					turn_directions[pos] = Vector2i(1, 0)
				else:
					turn_directions[pos] = Vector2i(0, 1)
			else:
				print("¡Has usado todos los giros!")
				return
		else:
			if pos in turn_directions:
				var dir = turn_directions[pos]
				var new_dir = Vector2i(-dir.x, -dir.y)
				turn_directions[pos] = new_dir
				print("🔁 Giro adicional en", pos, "→", new_dir)

	calculate_path()

	if check_victory():
		animate_car_movement()

func update_car_position():
	var tile = tile_nodes.get(car_position)
	if tile:
		var global_pos = tile.get_global_position()
		car_sprite.global_position = global_pos + Vector2(tile_size * 0.5, tile_size * 0.5)


func get_texture_for_char(char: String) -> Texture2D:
	match char:
		"F": return flower_texture
		"P": return rock_texture
		"S": return start_texture
		"G": return goal_texture
		"-": return empty_texture
		_: return empty_texture  # fallback

func calculate_path():
	print("\n== CALCULANDO CAMINO ==")
	car_path.clear()
	flowers_adjacent_count = 0
	var counted_flowers := {}

	var pos = find_start()
	print("Inicio en:", pos)
	var dir = car_direction
	var turns = 0

	while true:
		pos += dir
		print("Avanzando a:", pos)
		
		if not is_inside_level(pos):
			print("Fuera del nivel. Fin del camino.")
			break

		var cell = level[pos.y][pos.x]
		print("Celda:", cell)

		if cell == "P":
			print("¡Piedra encontrada! Fin del camino.")
			break
		elif cell == "F":
			print("¡Flor encontrada! Fin del camino.")
			break

		car_path.append(pos)
		
		# Ver si está adyacente a una flor no contada
		for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var npos = pos + offset
			if is_inside_level(npos) and level[npos.y][npos.x] == "F" and not counted_flowers.has(npos):
				counted_flowers[npos] = true
				flowers_adjacent_count += 1
				print("🌸 Flor adyacente nueva encontrada en", npos, "- Total:", flowers_adjacent_count)
				break
		
		# Comprobar si hay giro manual
		if pos in turn_directions:
			print("🔁 Giro manual en", pos)
			dir = turn_directions[pos]
			
			turns += 1
			print("Número de giros:", turns)
			if turns > max_turns:
				print("⚠️ Exceso de giros. Fin del camino.")
				break
		
		if cell == "G":
			print("🏁 Meta alcanzada en", pos)
			break

	print("Camino final calculado:", car_path)
	print("Flores adyacentes únicas:", flowers_adjacent_count)
	animate_car_path()


func animate_car_path():
	for tile_pos in tile_nodes:
		var tile = tile_nodes[tile_pos]
		tile.modulate = Color.WHITE
	var delay_step := 0.01
	var pitch = 1
	for i in range(car_path.size()):
		var pos = car_path[i]
		var tile = tile_nodes.get(pos)
		if tile:
			tile.scale = Vector2(1.0, 1.0)
			tile.modulate = Color.WHITE  # Resetea color antes de animar (opcional)
			
			await get_tree().create_timer(delay_step * i).timeout

			var tween = create_tween()
			tween.tween_property(tile, "scale", Vector2(1.2, 1.2), 0.05).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(tile, "scale", Vector2(1.0, 1.0), 0.05).set_trans(Tween.TRANS_BACK)
			tween.tween_callback(func():
				path_audio.pitch_scale = pitch
				pitch += 0.1
				if pos in used_turns:
					tile.modulate = Color.GREEN_YELLOW
					path_audio.play()
				else: 
					tile.modulate = Color.AQUAMARINE  # Cambia a cualquier color que quieras
					path_audio.play()
				
			)

		# Animar flores adyacentes
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var adj_pos = pos + offset
			if is_inside_level(adj_pos) and level[adj_pos.y][adj_pos.x] == "F":
				var flower_tile = tile_nodes.get(adj_pos)
				if flower_tile:
					flower_tile.scale = Vector2(1.0, 1.0)
					flower_tile.modulate = Color.WHITE
					
					var flower_tween = create_tween()
					flower_tween.tween_property(flower_tile, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_ELASTIC)
					flower_tween.tween_property(flower_tile, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
					flower_tween.tween_callback(func():
						if flowers_adjacent_count <= 3:
							flower_tile.modulate = Color.PINK  # O cualquier otro para flores
							flower_audio.play()
						else:
							flower_tile.modulate = Color.FIREBRICK  # O cualquier otro para flores

					)

		delay_step = max(0.001, delay_step - 0.001)




func is_inside_level(pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < level.size() and pos.x >= 0 and pos.x < level[0].size()


func check_victory():
	if car_path.size() == 0:
		return false
	var last = car_path[car_path.size() - 1]
	if level[last.y][last.x] != "G":
		return false
	if used_turns.size() != max_turns:
		return false
	if flowers_adjacent_count != 3:
		return false
	return true


func start_game():
	
	win_audio = AudioStreamPlayer.new()
	win_audio.stream = win_sound
	add_child(win_audio)

	click_audio = AudioStreamPlayer.new()
	click_audio.stream = click_sound
	add_child(click_audio)

	car_audio = AudioStreamPlayer.new()
	car_audio.stream = car_move_sound
	add_child(car_audio)
	
	flower_audio = AudioStreamPlayer.new()
	flower_audio.stream = flower_sound
	add_child(flower_audio)
	
	path_audio = AudioStreamPlayer.new()
	path_audio.stream = path_step_sound
	add_child(path_audio)

	restart_b = $"../TextureButton"
	imagen1 = $"../Win"
	imagen2 = $"../Ole"
	restart_b.connect("pressed", Callable(self, "reset_game"))

	start=true
	print("game started")
		# Luego puedes calcular el camino inicial y mostrarlo
	car_sprite = Sprite2D.new()
	car_sprite.texture = car_texture
	car_sprite.visible = false
	add_child(car_sprite)
	
	var grid = $CenterContainer/GridContainer
	grid.columns = level[0].size()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pitch = 1
	for y in range(level.size()):
		for x in range(level[y].size()):
			var cell = level[y][x]
			var tile = TextureButton.new()
			tile.texture_normal = get_texture_for_char(cell)
			tile.custom_minimum_size = Vector2(tile_size, tile_size)
			tile.connect("pressed", Callable(self, "_on_tile_pressed").bind(x, y))
			grid.add_child(tile)

			var pos = Vector2i(x, y)
			tile_nodes[pos] = tile
			
			tile.scale = Vector2.ZERO  # Empieza invisiblemente pequeño
						

			await get_tree().process_frame  # Espera un frame

			var tween = create_tween()  # Ahora sí funciona
			# Efecto de pop animado con delay
			var delay = 0.02 * (y * level[0].size() + x)  # Efecto de ola
			tween.tween_property(tile, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(tile, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)
			
			await get_tree().process_frame  # Espera un frame
			click_audio.play()
			click_audio.pitch_scale = pitch
			pitch += 0.1
			
			# 🚗 Coloca el coche si es la casilla S
			if cell == "S":
				car_position = pos
				await get_tree().process_frame
				update_car_position()
			
	car_sprite.visible = true
	calculate_path()

func reset_game():
	print("🔄 Reiniciando juego...")
	
	used_turns.clear()
	turn_directions.clear()
	car_path.clear()
	flowers_adjacent_count = 0
	
	car_position = find_start()
	car_direction = Vector2i(0, -1)  # Dirección inicial: hacia la derecha
	
	update_car_position()
	calculate_path()

func paint_path_gray():
	for pos in car_path:
		if tile_nodes.has(pos):
			tile_nodes[pos].modulate = Color.GRAY

func animate_car_movement() -> void:
	# Resetea colores tiles
	for tile_pos in tile_nodes:
		var tile = tile_nodes[tile_pos]
		tile.modulate = Color.WHITE

	var delay_step := 0.3  # Tiempo de duración del tween para cada paso
	var prev_pos = find_start()
	var current_dir = car_direction

	for pos in car_path:
		var tile = tile_nodes.get(pos)
		if tile:
			# Animar el tile del camino
			tile.modulate = Color.AQUAMARINE
			if pos in used_turns:
				tile.modulate = Color.GREEN_YELLOW

		# Calcula la dirección desde la posición anterior a la actual
		var new_dir = pos - prev_pos

		# Actualiza la rotación del coche si cambia de dirección
		if new_dir != current_dir:
			current_dir = new_dir
			update_car_rotation(current_dir)

		# Mueve el coche suavemente con Tween
		var tile_node = tile_nodes.get(pos)
		if tile_node:
			var target_pos = tile_node.get_global_position() + Vector2(tile_size * 0.5, tile_size * 0.5)
			var tween = get_tree().create_tween()
			tween.tween_property(car_sprite, "global_position", target_pos, delay_step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			# Espera a que termine la animación antes de continuar
			await tween.finished
			car_audio.play()

		prev_pos = pos
	animate_win()
	
func animate_win() -> void:
	imagen1.visible = true
	imagen2.visible = true

	var tween = get_tree().create_tween()
	tween.tween_property(imagen1, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(imagen2, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# Vuelve a su escala original si quieres que rebote y vuelva
	tween.tween_property(imagen1, "scale", Vector2(1, 1), 0.2)
	tween.parallel().tween_property(imagen2, "scale", Vector2(1, 1), 0.2)
	
	win_audio.play()


func update_car_rotation(direction: Vector2i) -> void:
	# Asumiendo que la dirección inicial Vector2i(0, -1) significa "arriba"
	if direction == Vector2i(0, -1):
		car_sprite.rotation_degrees = 0
	elif direction == Vector2i(1, 0):
		car_sprite.rotation_degrees = 90
	elif direction == Vector2i(0, 1):
		car_sprite.rotation_degrees = 180
	elif direction == Vector2i(-1, 0):
		car_sprite.rotation_degrees = 270
