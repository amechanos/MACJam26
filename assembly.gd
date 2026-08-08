extends Node2D

@export var wave: int = 0
@onready var components_layer = $comp_layer
@onready var core = $comp_layer/core
@export var n: int = 3               
@export var cell_size: float = 50.0 
@export var grid_color: Color = Color(1.0, 1.0, 1.0, 0.8) 
@export var line_width: float = 2.0   

func _ready() -> void:
	get_tree().root.size_changed.connect(queue_redraw)
	
	var screen_size = get_viewport_rect().size
	var body = core.get_child(0)
	
	core.global_position = Vector2(screen_size.x/2 - body.size.x/2, screen_size.y/2 - body.size.y/2)

func _draw():
	# 1. Calculate dimensions
	var viewport_size = get_viewport_rect().size
	var total_grid_size = float(n) * cell_size
	
	# 2. Find the top-left starting corner to center the grid
	var start_pos = (viewport_size - Vector2(total_grid_size, total_grid_size)) / 2.0
	
	# 3. Draw Horizontal lines
	# We iterate n + 1 times to draw both the starting and closing boundary lines
	for i in range(n + 1):
		var y = start_pos.y + (i * cell_size)
		var start_point = Vector2(start_pos.x, y)
		var end_point = Vector2(start_pos.x + total_grid_size, y)
		draw_line(start_point, end_point, grid_color, line_width)
		
	# 4. Draw Vertical lines
	for i in range(n + 1):
		var x = start_pos.x + (i * cell_size)
		var start_point = Vector2(x, start_pos.y)
		var end_point = Vector2(x, start_pos.y + total_grid_size)
		draw_line(start_point, end_point, grid_color, line_width)
