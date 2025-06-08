extends Container
var start = false
@export var flower_texture: Texture2D
@export var rock_texture: Texture2D
@export var goal_texture: Texture2D
@export var start_texture: Texture2D
@export var empty_texture: Texture2D
@export var tile_size: int = 64
@export var car_texture: Texture2D
var car_sprite: Sprite2D
var car_position 

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
'''	
func _on_tile_pressed(x: int, y: int) -> void:
	print("Tile clicked at: ", x, ", ", y, " -> ", level[y][x])
	car_position = Vector2i(x, y)
	update_car_position()
'''
func _on_tile_pressed(x: int, y: int) -> void:
	if start:
		var pos = Vector2i(x, y)

		if not pos in car_path:
			return  # Solo permite clics en el camino

		# Solo añade a used_turns si es la primera vez
		if not used_turns.has(pos):
			if used_turns.size() < max_turns:
				used_turns.append(pos)
				turn_directions[pos] = Vector2i(0, -1)  # Primera rotación: derecha
			else:
				print("¡Has usado todos los giros!")
				return
		else:
			# Ya giraste antes: rota la dirección
			if pos in turn_directions:
				var dir = turn_directions[pos]
				var new_dir = Vector2i(-dir.y, dir.x)  # Rota 90° a la derecha
				turn_directions[pos] = new_dir
				print("🔁 Giro adicional en", pos, "→", new_dir)
	
	calculate_path()
	update_car_path_visuals()
	if check_victory():
		print("¡Victoria!")



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
		
		# Ver si está adyacente a una flor
		for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var npos = pos + offset
			if is_inside_level(npos) and level[npos.y][npos.x] == "F":
				flowers_adjacent_count += 1
				print("🌸 Flor adyacente encontrada en", npos, "- Total:", flowers_adjacent_count)
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
	print("Flores adyacentes:", flowers_adjacent_count)


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

func update_car_path_visuals():
	# Primero limpiamos todas las casillas
	for tile_pos in tile_nodes:
		var tile = tile_nodes[tile_pos]
		tile.modulate = Color.WHITE

	# Coloreamos el camino
	for i in range(car_path.size()):
		var pos = car_path[i]
		if tile_nodes.has(pos):
			tile_nodes[pos].modulate = Color.CYAN

	# Coloreamos los giros
	for pos in used_turns:
		if tile_nodes.has(pos):
			tile_nodes[pos].modulate = Color.ORANGE

	# Coloreamos el punto final si es victoria
	if check_victory():
		var goal = car_path[car_path.size() - 1]
		if tile_nodes.has(goal):
			tile_nodes[goal].modulate = Color.GREEN

func start_game():
	start=true
	print("game started")
		# Luego puedes calcular el camino inicial y mostrarlo
	car_sprite = Sprite2D.new()
	car_sprite.texture = car_texture
	add_child(car_sprite)
	
	var grid = $CenterContainer/GridContainer
	grid.columns = level[0].size()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
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
			
			# 🚗 Coloca el coche si es la casilla S
			if cell == "S":
				car_position = pos
				await get_tree().process_frame  # Asegura que la posición global esté lista
				update_car_position()
	calculate_path()
	update_car_path_visuals()
