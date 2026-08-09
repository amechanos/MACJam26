extends Node

const SHAPES = {
	"CORE":    [[1]],
	"LASER":  [[1, 1],
				[1, 0]],
	"DRONE":   [[1],
				[1],
				[1]],
	"BLASTER": [[1, 1]],
	"BOMB-BASE-2":  [[0, 1],
				[1, 1],
				[0, 1]]
}

var assembly_placements: Dictionary = {}
var assembly_config: Dictionary = {
	"grid_cols": 5,
	"grid_rows": 5,
	"cell_size": 50
}

func has_assembly() -> bool:
	return not assembly_placements.is_empty()

func store_assembly(placements: Dictionary, config: Dictionary) -> void:
	assembly_placements = placements.duplicate(true)
	assembly_config = config.duplicate(true)

func clear_assembly() -> void:
	assembly_placements.clear()

func get_rotated_shape(shape_name: String, rot: int) -> Array:
	var base: Array = SHAPES[shape_name].duplicate(true)
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
