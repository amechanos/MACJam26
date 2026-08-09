extends Node2D
class_name DraggableBlock

signal drag_started(block: DraggableBlock)
signal dropped(block: DraggableBlock)

@export var shape_name: String = "CORE"
@export var rotation_state: int = 0  # 0-3 (90° steps)
@export var cell_size: float = 64.0

var is_dragging: bool = false
var is_placed: bool = false
var resting_position: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO

var grid_origin: Vector2 = Vector2.ZERO
var grid_cols: int = 5
var grid_rows: int = 5
var palette_y_threshold: float = 0.0

var placed_col: int = -1
var placed_row: int = -1
var slot_index: int = -1  # >=0 means it lives in the palette HBox


func _ready() -> void:
	_update_visual()


func _update_visual() -> void:
	for c in get_children():
		c.queue_free()

	var matrix: Array = Global.get_rotated_shape(shape_name, rotation_state)
	var color: Color = _get_shape_color()

	for row in range(matrix.size()):
		for col in range(matrix[row].size()):
			if matrix[row][col] == 1:
				var rect: ColorRect = ColorRect.new()
				rect.size = Vector2(cell_size - 4.0, cell_size - 4.0)
				rect.position = Vector2(col * cell_size + 2.0, row * cell_size + 2.0)
				rect.color = color
				add_child(rect)

				var border: ReferenceRect = ReferenceRect.new()
				border.size = rect.size
				border.position = rect.position
				border.border_color = Color.WHITE
				border.border_width = 2
				border.editor_only = false
				add_child(border)


func _get_shape_color() -> Color:
	match shape_name:
		"CORE": return Color.DIM_GRAY
		"CANNON": return Color.CRIMSON
		"LASER": return Color.CYAN
		"BLASTER": return Color.ORANGE
		"ENGINE": return Color.FOREST_GREEN
		"SHIELD": return Color.GOLD
		_: return Color.WHITE


# ---------------------------------------------------------------------------
# INPUT
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_mouse_over() and not is_dragging:
			_start_drag()
		elif not event.pressed and is_dragging:
			_end_drag()

	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and is_dragging:
			rotation_state = (rotation_state + 1) % 4
			_update_visual()


func _start_drag() -> void:
	is_dragging = true
	drag_offset = get_global_mouse_position() - global_position
	z_index = 100
	drag_started.emit(self)


func _end_drag() -> void:
	is_dragging = false
	z_index = 0
	dropped.emit(self)


func _is_mouse_over() -> bool:
	var matrix: Array = Global.get_rotated_shape(shape_name, rotation_state)
	var max_c: int = 0
	var max_r: int = 0

	for row in range(matrix.size()):
		for col in range(matrix[row].size()):
			if matrix[row][col] == 1:
				max_c = maxi(max_c, col + 1)
				max_r = maxi(max_r, row + 1)

	var rect: Rect2 = Rect2(global_position, Vector2(max_c * cell_size, max_r * cell_size))
	return rect.has_point(get_global_mouse_position())
