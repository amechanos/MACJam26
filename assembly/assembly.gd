extends Node2D

const CELL_SIZE: float = 50
const GRID_COLS: int = 5
const GRID_ROWS: int = 5
const PALETTE_COUNT: int = 3

# grid[col][row] = block_name or ""
var grid: Array = []

# Blocks currently snapped to the grid
var placed_blocks: Dictionary = {}  # name -> DraggableBlock

# Blocks currently in the bottom palette
var palette_blocks: Array[DraggableBlock] = []

var grid_origin: Vector2 = Vector2.ZERO

@onready var blocks_container: Node2D = $BlocksContainer
@onready var palette_hbox: HBoxContainer = $CanvasLayer/PalettePanel/MarginContainer/HBoxContainer
@onready var confirm_btn: Button = $CanvasLayer/ConfirmButton

func _ready() -> void:
	var vp: Vector2 = get_viewport_rect().size
	grid_origin = Vector2(
		(vp.x - GRID_COLS * CELL_SIZE) / 2.0,
		80.0
	)
	
	# Keep Global in sync
	Global.assembly_config = {
		"grid_cols": GRID_COLS,
		"grid_rows": GRID_ROWS,
		"cell_size": CELL_SIZE
	}
	
	_init_grid()
	
	# --- FIRST ITERATION LOGIC ---
	if Global.has_assembly():
		_restore_assembly()
	else:
		_place_core_at_center()
	
	_spawn_palette_blocks()
	_setup_ui()


func _init_grid() -> void:
	grid.clear()
	for x in range(GRID_COLS):
		grid.append([])
		for y in range(GRID_ROWS):
			grid[x].append("")


# ---------------------------------------------------------------------------
# CORE & RESTORE
# ---------------------------------------------------------------------------

func _place_core_at_center() -> void:
	var cc: int = GRID_COLS / 2  # 2 in a 5x5
	var cr: int = GRID_ROWS / 2
	var block: DraggableBlock = _create_block("CORE")
	block.name = "CORE_0"
	_commit_block_to_grid(block, cc, cr)
	blocks_container.add_child(block)
	placed_blocks[block.name] = block


func _restore_assembly() -> void:
	for block_name in Global.assembly_placements.keys():
		var data = Global.assembly_placements[block_name]
		var block: DraggableBlock = _create_block(data.shape_name)
		block.name = block_name
		block.rotation_state = data.rotation
		_commit_block_to_grid(block, data.col, data.row)
		blocks_container.add_child(block)
		placed_blocks[block_name] = block


func _create_block(shape_name: String) -> DraggableBlock:
	var block: DraggableBlock = preload("res://assembly/block.tscn").instantiate()
	block.shape_name = shape_name
	block.cell_size = CELL_SIZE
	block.grid_origin = grid_origin
	block.grid_cols = GRID_COLS
	block.grid_rows = GRID_ROWS
	block.palette_y_threshold = grid_origin.y + GRID_ROWS * CELL_SIZE + 40.0
	
	block.drag_started.connect(_on_block_drag_started)
	block.dropped.connect(_on_block_dropped)
	return block


func _commit_block_to_grid(block: DraggableBlock, col: int, row: int) -> void:
	var matrix: Array = Global.get_rotated_shape(block.shape_name, block.rotation_state)
	
	# Wipe this block's previous occupation
	_clear_block_from_grid(block.name)
	
	# Write to matrix
	for r in range(matrix.size()):
		for c in range(matrix[r].size()):
			if matrix[r][c] == 1:
				grid[col + c][row + r] = block.name
	
	# Snap visually
	block.global_position = grid_origin + Vector2(col, row) * CELL_SIZE
	block.is_placed = true
	block.placed_col = col
	block.placed_row = row


func _clear_block_from_grid(block_name: String) -> void:
	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			if grid[x][y] == block_name:
				grid[x][y] = ""


# ---------------------------------------------------------------------------
# PALETTE (Pick 1 of 3)
# ---------------------------------------------------------------------------

func _spawn_palette_blocks() -> void:
	# Wipe old palette
	for b in palette_blocks:
		if is_instance_valid(b):
			b.queue_free()
	palette_blocks.clear()
	
	# Wait one frame so HBoxContainer has finished layout
	await get_tree().process_frame
	
	var pool: Array = Global.SHAPES.keys()
	# Don't offer CORE if one already exists on the grid
	if _has_core_placed():
		pool.erase("CORE")
	
	pool.shuffle()
	
	var slots: Array[Node] = palette_hbox.get_children()
	for i in range(min(PALETTE_COUNT, slots.size())):
		var shape: String = pool[i % pool.size()]
		var block: DraggableBlock = _create_block(shape)
		block.name = "%s_palette_%d" % [shape, i]
		block.slot_index = i
		
		# Center block inside its HBox slot
		var slot: Control = slots[i]
		var slot_center: Vector2 = slot.global_position + slot.size / 2.0
		var matrix: Array = Global.get_rotated_shape(shape, 0)
		var off: Vector2 = Vector2(matrix[0].size(), matrix.size()) * CELL_SIZE / 2.0
		
		block.global_position = slot_center - off
		block.resting_position = block.global_position
		
		blocks_container.add_child(block)
		palette_blocks.append(block)


func _has_core_placed() -> bool:
	for n in placed_blocks.keys():
		if placed_blocks[n].shape_name == "CORE":
			return true
	return false


# ---------------------------------------------------------------------------
# DRAG EVENTS
# ---------------------------------------------------------------------------

func _on_block_drag_started(block: DraggableBlock) -> void:
	# If it was on the grid, free those cells so we can move it
	if block.placed_col >= 0:
		_clear_block_from_grid(block.name)
	block.z_index = 100


func _on_block_dropped(block: DraggableBlock) -> void:
	block.z_index = 0
	
	# Dropped below the build zone?
	if block.global_position.y > block.palette_y_threshold:
		if block.placed_col >= 0:
			# It was a placed block dragged off-grid → revert to old spot
			_revert_block(block)
		else:
			# Palette block dragged back down → return to slot
			block.global_position = block.resting_position
		return
	
	# Try to snap to grid
	var matrix: Array = Global.get_rotated_shape(block.shape_name, block.rotation_state)
	var rel: Vector2 = block.global_position - grid_origin
	var col: int = int(round(rel.x / CELL_SIZE))
	var row: int = int(round(rel.y / CELL_SIZE))
	
	# Validate bounds & collisions
	for r in range(matrix.size()):
		for c in range(matrix[r].size()):
			if matrix[r][c] == 1:
				var gc: int = col + c
				var gr: int = row + r
				if gc < 0 or gc >= GRID_COLS or gr < 0 or gr >= GRID_ROWS:
					_revert_or_return(block)
					return
				if grid[gc][gr] != "" and grid[gc][gr] != block.name:
					_revert_or_return(block)
					return
	
	# --- VALID PLACEMENT ---
	_commit_block_to_grid(block, col, row)
	
	# If this was a fresh palette pick, discard the other two (Pick 1 of 3)
	if block.slot_index >= 0:
		_dismiss_other_palette_blocks(block)
		block.slot_index = -1
	
	placed_blocks[block.name] = block


func _revert_or_return(block: DraggableBlock) -> void:
	if block.placed_col >= 0:
		_revert_block(block)
	else:
		block.global_position = block.resting_position


func _revert_block(block: DraggableBlock) -> void:
	_commit_block_to_grid(block, block.placed_col, block.placed_row)


func _dismiss_other_palette_blocks(kept: DraggableBlock) -> void:
	for b in palette_blocks:
		if b != kept and is_instance_valid(b):
			b.queue_free()
	palette_blocks.clear()

# ---------------------------------------------------------------------------
# EXPORT
# ---------------------------------------------------------------------------

func _setup_ui() -> void:
	confirm_btn.text = "Confirm Build"
	confirm_btn.pressed.connect(_on_confirm_pressed)


func _on_confirm_pressed() -> void:
	if placed_blocks.is_empty():
		print("BuildManager: Nothing to save.")
		return
	
	var placements: Dictionary = {}
	for block_name in placed_blocks.keys():
		var b: DraggableBlock = placed_blocks[block_name]
		placements[block_name] = {
			"col": b.placed_col,
			"row": b.placed_row,
			"shape_name": b.shape_name,
			"rotation": b.rotation_state
		}
	
	Global.store_assembly(placements, Global.assembly_config)
	print("BuildManager: Saved %d components." % placements.size())
	_print_matrix()
	
	get_tree().change_scene_to_file("res://main.tscn")


func _print_matrix() -> void:
	print("--- Build Matrix ---")
	for y in range(GRID_ROWS):
		var line: String = ""
		for x in range(GRID_COLS):
			line += "[X]" if grid[x][y] != "" else "[ ]"
		print(line)
	print("--------------------")


# ---------------------------------------------------------------------------
# VISUALS
# ---------------------------------------------------------------------------

func _draw() -> void:
	var rect: Rect2 = Rect2(grid_origin, Vector2(GRID_COLS, GRID_ROWS) * CELL_SIZE)
	draw_rect(rect, Color(0.08, 0.08, 0.12, 1.0))
	
	for x in range(GRID_COLS + 1):
		var a: Vector2 = grid_origin + Vector2(x * CELL_SIZE, 0)
		var b: Vector2 = grid_origin + Vector2(x * CELL_SIZE, GRID_ROWS * CELL_SIZE)
		draw_line(a, b, Color(0.25, 0.25, 0.35), 1.5)
	
	for y in range(GRID_ROWS + 1):
		var a: Vector2 = grid_origin + Vector2(0, y * CELL_SIZE)
		var b: Vector2 = grid_origin + Vector2(GRID_COLS * CELL_SIZE, y * CELL_SIZE)
		draw_line(a, b, Color(0.25, 0.25, 0.35), 1.5)
