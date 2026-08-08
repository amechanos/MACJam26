extends Node2D

# ============================================================================
# CONFIGURATION
# ============================================================================
@export var grid_cols: int = 5
@export var grid_rows: int = 5
@export var cell_size: float = 64.0

@export var grid_color: Color = Color(1.0, 1.0, 1.0, 0.3)
@export var grid_line_width: float = 1.0
@export var ghost_valid_color: Color = Color(0.2, 1.0, 0.2, 0.35)
@export var ghost_invalid_color: Color = Color(1.0, 0.2, 0.2, 0.35)

@export var palette_margin: float = 30.0
@export var palette_spacing: float = 16.0

# ============================================================================
# SHAPE DEFINITIONS
# ============================================================================
const SHAPES = {
	"dot": [[1]],
	"I": [[1, 1, 1, 1]],
	"O": [[1, 1],
		  [1, 1]],
	"T": [[1, 1, 1],
		  [0, 1, 0]],
	"L": [[1, 0],
		  [1, 0],
		  [1, 1]],
	"J": [[0, 1],
		  [0, 1],
		  [1, 1]],
	"S": [[0, 1, 1],
		  [1, 1, 0]],
	"Z": [[1, 1, 0],
		  [0, 1, 1]],
}

# ============================================================================
# STATE
# ============================================================================
var grid_origin: Vector2 = Vector2.ZERO
var grid_matrix: Array = []

var _dragging: Control = null
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_start_grid: Vector2i = Vector2i(-1, -1)
var _drag_was_in_palette: bool = false

var _ghost_col: int = -1
var _ghost_row: int = -1

var _palette_positions: Dictionary = {}

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready() -> void:
	_init_grid()
	_center_grid()
	get_tree().root.size_changed.connect(_on_window_resized)
	_setup_all_components()
	
	var center_col := grid_cols / 2  # 2 for a 5×5 grid
	var center_row := grid_rows / 2  # 2 for a 5×5 grid
	_place_component($comp_layer/Core, center_col, center_row, 0)

func _init_grid() -> void:
	grid_matrix.clear()
	for r in grid_rows:
		var row: Array = []
		row.resize(grid_cols)
		row.fill(null)
		grid_matrix.append(row)

func _center_grid() -> void:
	var vp := get_viewport_rect().size
	var grid_px := Vector2(grid_cols * cell_size, grid_rows * cell_size)
	grid_origin = (vp - grid_px) / 2.0

func _on_window_resized() -> void:
	_center_grid()
	_layout_palette()
	_reposition_placed_components()
	queue_redraw()

# ============================================================================
# COMPONENT SETUP
# ============================================================================
func _setup_all_components() -> void:
	var candidates: Array = []
	if has_node("comp_layer"):
		for c in $comp_layer.get_children():
			if c is Control:
				candidates.append(c)
	for c in get_children():
		if c is Control and c not in candidates and c.name != "comp_layer":
			candidates.append(c)
	
	for i in range(candidates.size()):
		var c: Control = candidates[i]
		if not c.has_meta("palette_index"):
			c.set_meta("palette_index", i)
		_setup_component(c)
	
	_layout_palette()

func _setup_component(c: Control) -> void:
	if not c.has_meta("shape_name"):
		c.set_meta("shape_name", "dot")
	if not c.has_meta("grid_rot"):
		c.set_meta("grid_rot", 0)
	if not c.has_meta("grid_col"):
		c.set_meta("grid_col", -1)
	if not c.has_meta("grid_row"):
		c.set_meta("grid_row", -1)
	if not c.has_meta("in_palette"):
		c.set_meta("in_palette", true)
	
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	if not c.gui_input.is_connected(_on_component_gui_input):
		c.gui_input.connect(_on_component_gui_input.bind(c))
	
	if not c.draw.is_connected(_on_component_draw.bind(c)):
		c.draw.connect(_on_component_draw.bind(c))
	
	_apply_component_size(c)
	
func _on_component_draw(c: Control) -> void:
	var shape := get_shape(c)
	var h: int = shape.size()
	var w: int = shape[0].size()
	
	# Set this to whatever color you want your shapes to be
	var block_color := Color(0.2, 0.6, 1.0, 0.9) 
		
	for r in range(h):
		for cl in range(w):
			if shape[r][cl] == 1:
				var rect := Rect2(Vector2(cl, r) * cell_size, Vector2(cell_size, cell_size))
				# Draw the inner block
				c.draw_rect(rect, block_color)
				# Optional: Draw an outline for each block
				c.draw_rect(rect, Color(1, 1, 1, 0.5), false, 1.0)

func _apply_component_size(c: Control) -> void:
	var shape := get_shape(c)
	var h: int = shape.size()
	var w: int = shape[0].size()
	c.size = Vector2(w * cell_size, h * cell_size)
	
	if c.has_node("Visual"):
		c.get_node("Visual").rotation_degrees = 0
		c.get_node("Visual").hide() # Hide the bounding-box background
		
	# NEW: Force the component to redraw its specific shape blocks
	c.queue_redraw()

func _layout_palette() -> void:
	var all := _get_all_components()
	all.sort_custom(func(a, b): return a.get_meta("palette_index") < b.get_meta("palette_index"))
	
	var x: float = palette_margin
	var y: float = palette_margin
	
	for c in all:
		_palette_positions[c] = Vector2(x, y)
		if c.get_meta("in_palette"):
			c.global_position = Vector2(x, y)
		y += max(c.size.y, cell_size * 1.5) + palette_spacing

func _reposition_placed_components() -> void:
	for c in _get_all_components():
		var col: int = c.get_meta("grid_col")
		var row: int = c.get_meta("grid_row")
		if col >= 0 and row >= 0:
			c.global_position = grid_origin + Vector2(col, row) * cell_size

func _get_all_components() -> Array:
	var result: Array = []
	if has_node("comp_layer"):
		for c in $comp_layer.get_children():
			if c is Control:
				result.append(c)
	for c in get_children():
		if c is Control and c not in result and c.name != "comp_layer":
			result.append(c)
	return result

# ============================================================================
# SHAPE HELPERS
# ============================================================================
func get_shape(c: Control) -> Array:
	var name: String = c.get_meta("shape_name")
	var base: Array = SHAPES[name].duplicate(true)
	var rot: int = c.get_meta("grid_rot")
	
	for i in range(rot % 4):
		var rows = base.size()
		var cols = base[0].size()
		var rotated: Array = []
		for c_idx in range(cols):
			var new_row: Array = []
			for r_idx in range(rows - 1, -1, -1):
				new_row.append(base[r_idx][c_idx])
			rotated.append(new_row)
		base = rotated
	return base

# ============================================================================
# DRAWING
# ============================================================================
func _draw() -> void:
	var grid_px := Vector2(grid_cols * cell_size, grid_rows * cell_size)
	
	# Grid background
	draw_rect(Rect2(grid_origin, grid_px), Color(0.05, 0.05, 0.1, 0.9))
	
	# Grid lines
	for i in range(grid_rows + 1):
		var y := grid_origin.y + i * cell_size
		draw_line(Vector2(grid_origin.x, y), Vector2(grid_origin.x + grid_px.x, y), grid_color, grid_line_width)
	for i in range(grid_cols + 1):
		var x := grid_origin.x + i * cell_size
		draw_line(Vector2(x, grid_origin.y), Vector2(x, grid_origin.y + grid_px.y), grid_color, grid_line_width)
	
	# Ghost preview
	if _dragging and _ghost_col >= 0 and _ghost_row >= 0:
		var shape := get_shape(_dragging)
		var valid := _can_place(_ghost_col, _ghost_row, shape, _dragging)
		var color := ghost_valid_color if valid else ghost_invalid_color
		
		var h: int = shape.size()
		var w: int = shape[0].size()
		for r in range(h):
			for cl in range(w):
				if shape[r][cl] == 1:
					var pos := grid_origin + Vector2(_ghost_col + cl, _ghost_row + r) * cell_size
					draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), color)

# ============================================================================
# INPUT HANDLING
# ============================================================================
func _on_component_gui_input(event: InputEvent, component: Control) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(component)
			else:
				_end_drag(component)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if _dragging == component:
				_rotate(component)
	elif event is InputEventMouseMotion and _dragging == component:
		_update_drag(component)

func _start_drag(c: Control) -> void:
	_dragging = c
	_drag_offset = c.global_position - get_global_mouse_position()
	_drag_start_pos = c.global_position
	_drag_start_grid = Vector2i(c.get_meta("grid_col"), c.get_meta("grid_row"))
	_drag_was_in_palette = c.get_meta("in_palette")
	
	if _drag_start_grid.x >= 0:
		_remove_from_grid(c)
		c.set_meta("grid_col", -1)
		c.set_meta("grid_row", -1)
	
	c.set_meta("in_palette", false)
	
	if c.get_parent():
		c.get_parent().move_child(c, -1)
	
	queue_redraw()

func _update_drag(c: Control) -> void:
	c.global_position = get_global_mouse_position() + _drag_offset
	
	var local := get_global_mouse_position() - grid_origin
	_ghost_col = int(local.x / cell_size)
	_ghost_row = int(local.y / cell_size)
	queue_redraw()

func _end_drag(c: Control) -> void:
	var mouse_pos := get_global_mouse_position()
	var local := mouse_pos - grid_origin
	var col := int(local.x / cell_size)
	var row := int(local.y / cell_size)
	var shape := get_shape(c)
	
	var grid_rect := Rect2(grid_origin, Vector2(grid_cols * cell_size, grid_rows * cell_size))
	var dropped_in_grid := grid_rect.has_point(mouse_pos)
	
	if dropped_in_grid and _can_place(col, row, shape, c):
		_place_component(c, col, row, c.get_meta("grid_rot"))
	else:
		# Dragged off grid -> return to palette
		if _drag_start_grid.x >= 0 and not dropped_in_grid:
			_return_to_palette(c)
		# Invalid placement on grid -> return to old grid spot
		elif _drag_start_grid.x >= 0:
			_place_component(c, _drag_start_grid.x, _drag_start_grid.y, c.get_meta("grid_rot"))
		# Came from palette and failed -> return to palette
		else:
			_return_to_palette(c)
	
	_dragging = null
	_ghost_col = -1
	_ghost_row = -1
	queue_redraw()

func _rotate(c: Control) -> void:
	var new_rot: int = (c.get_meta("grid_rot") + 1) % 4
	c.set_meta("grid_rot", new_rot)
	_apply_component_size(c)
	queue_redraw()

func _return_to_palette(c: Control) -> void:
	c.set_meta("in_palette", true)
	c.set_meta("grid_col", -1)
	c.set_meta("grid_row", -1)
	if _palette_positions.has(c):
		c.global_position = _palette_positions[c]
	else:
		_layout_palette()
		c.global_position = _palette_positions[c]

# ============================================================================
# GRID LOGIC
# ============================================================================
func _can_place(col: int, row: int, shape: Array, exclude: Control) -> bool:
	var h: int = shape.size()
	var w: int = shape[0].size()
	
	if col < 0 or row < 0 or col + w > grid_cols or row + h > grid_rows:
		return false
	
	for r in range(h):
		for cl in range(w):
			if shape[r][cl] == 1:
				if grid_matrix[row + r][col + cl] != null and grid_matrix[row + r][col + cl] != exclude:
					return false
	return true

func _place_component(c: Control, col: int, row: int, rot: int) -> void:
	c.set_meta("grid_col", col)
	c.set_meta("grid_row", row)
	c.set_meta("grid_rot", rot)
	c.set_meta("in_palette", false)
	
	var shape := get_shape(c)
	var h: int = shape.size()
	var w: int = shape[0].size()
	
	for r in range(h):
		for cl in range(w):
			if shape[r][cl] == 1:
				grid_matrix[row + r][col + cl] = c
	
	c.global_position = grid_origin + Vector2(col, row) * cell_size
	_apply_component_size(c)

func _remove_from_grid(c: Control) -> void:
	var col: int = c.get_meta("grid_col")
	var row: int = c.get_meta("grid_row")
	if col < 0 or row < 0:
		return
	
	var shape := get_shape(c)
	var h: int = shape.size()
	var w: int = shape[0].size()
	
	for r in range(h):
		for cl in range(w):
			if shape[r][cl] == 1:
				var gr := row + r
				var gc := col + cl
				if gr >= 0 and gr < grid_rows and gc >= 0 and gc < grid_cols:
					if grid_matrix[gr][gc] == c:
						grid_matrix[gr][gc] = null

# ============================================================================
# CENTER PLACEMENT HELPER
# ============================================================================
func place_centered(c: Control, rot: int = 0) -> void:
	var old_rot: int = c.get_meta("grid_rot")
	c.set_meta("grid_rot", rot)
	var shape := get_shape(c)
	c.set_meta("grid_rot", old_rot)  # restore so _place_component sets it properly
	
	var h: int = shape.size()
	var w: int = shape[0].size()
	var col := (grid_cols - w) / 2
	var row := (grid_rows - h) / 2
	
	_remove_from_grid(c)
	_place_component(c, col, row, rot)

# ============================================================================
# PUBLIC API
# ============================================================================
func get_grid_matrix() -> Array:
	return grid_matrix.duplicate(true)

func get_placements() -> Dictionary:
	var result := {}
	for c in _get_all_components():
		var col: int = c.get_meta("grid_col")
		if col >= 0:
			result[c.name] = {
				"col": col,
				"row": c.get_meta("grid_row"),
				"shape_name": c.get_meta("shape_name"),
				"rotation": c.get_meta("grid_rot")
			}
	return result

func print_grid() -> void:
	print("--- Grid State ---")
	for r in grid_rows:
		var line := ""
		for c in grid_cols:
			if grid_matrix[r][c] == null:
				line += ".  "
			else:
				line += grid_matrix[r][c].name.substr(0, 2) + " "
		print(line)
	print("------------------")
