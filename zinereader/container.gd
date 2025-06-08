extends Container

@export var tile_texture: Texture2D
@export var tile_size: int = 64

func _ready() -> void:
	var grid = GridContainer.new()
	grid.columns = 10
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(grid)

	for i in range(100):
		var tile = TextureRect.new()
		tile.texture = tile_texture
		tile.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tile.custom_minimum_size = Vector2(tile_size, tile_size)
		grid.add_child(tile)
		print("added")
