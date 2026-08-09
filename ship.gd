extends CharacterBody2D
class_name Ship

@onready var hurtbox: Area2D = get_node_or_null("Area2D") as Area2D

var health: float = 1000.0
var max_health: float = 1000.0
@export var xp: float = 0.0
var level: int = 0

# --- MOVEMENT VARIABLES ---
@export var move_speed: float = 400.0

# --- GUN VARIABLES ---
var gun_list: Array[WeaponBase] = []
var gun_orientation: Array[float] = []  # Relative rotation offset (in radians) for each gun

var time_since_last_shot: float = 0.0
var screen_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	
	if container == null:
		container = self
	if build_on_ready:
		build()
	
	screen_size = get_viewport_rect().size
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	else:
		push_warning("Ship: 'Area2D' child node not found on " + name)

func _process(delta: float) -> void:
	move(delta)
	orient_gun()
	fire_gun()

func move(delta: float) -> void:
	var target_pos = get_global_mouse_position()
	position = position.lerp(target_pos, 20 * delta)
		
	position.x = clamp(position.x, 0, screen_size.x - 100)
	position.y = clamp(position.y, 0, screen_size.y)

func heal(hp: float) -> void:
	health = min(health + hp, max_health)

func orient_gun() -> void:
	for i in range(gun_list.size()):
		if i < gun_orientation.size() and is_instance_valid(gun_list[i]):
			gun_list[i].global_rotation = global_rotation + gun_orientation[i]

func fire_gun() -> void:
	for gun in gun_list:
		if is_instance_valid(gun):
			gun.fire()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area is not BaseProjectile:
		return
	if area.from_player:
		return
	
	take_dmg(area.damage)
	area.pierce = 0

func take_dmg(dmg: float) -> void:
	health -= dmg
	print("Player took %d damage! %d health remaining." % [dmg, health])
	if health <= 0:
		kill()

func kill() -> void:
	# Death sounds here!
	print("Game Over!")
	queue_free()
	
#-------------------------------------------------------------------------------
#BUILDING SHIP VIA MATRIX

@export var container: Node2D
@export var center_grid: bool = true
@export var build_on_ready: bool = true

var _built: Array = []

func clear():
	for c in _built:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			c.queue_free()
	_built.clear()

func build():
	clear()
	
	if not Global.has_assembly():
		push_warning("ShipBuilder: No assembly data.")
		return
	
	var cfg = Global.assembly_config
	var grid_px = Vector2(cfg.grid_cols * cfg.cell_size, cfg.grid_rows * cfg.cell_size)
	var origin = -grid_px / 2.0 if center_grid else Vector2.ZERO
	
	for comp_key in Global.assembly_placements.keys():
		var data = Global.assembly_placements[comp_key]
		var shape_name: String = data.get("shape_name", comp_key.split("_")[0])
		var rotation_idx: int = data.get("rotation", 0)
		
		var components_folder: String = "res://components/%s/" % shape_name.to_lower()
		var path = components_folder.path_join(shape_name.to_lower() + ".tscn")
		
		if not ResourceLoader.exists(path):
			push_warning("ShipBuilder: Scene not found: %s" % path)
			continue
		
		var scene: PackedScene = load(path)
		var inst = scene.instantiate()
		container.add_child(inst)
		
		# 1. Get rotated matrix dimensions (how many cols/rows it occupies on the grid)
		var rot_matrix = Global.get_rotated_shape(shape_name, rotation_idx)
		var rot_cols: int = rot_matrix[0].size()
		var rot_rows: int = rot_matrix.size()
		
		# 2. Calculate center pixel offset of the shape's occupied grid footprint
		var footprint_center = Vector2(
			data.col,
			data.row
		) * cfg.cell_size
		
		# 3. Position instance at the footprint center and apply rotation
		inst.position = origin + footprint_center
		inst.rotation_degrees = rotation_idx * 90
		inst.name = comp_key
		
		# Store shape metadata on instance for export
		inst.set_meta("shape_name", shape_name)
		inst.set_meta("rotation", rotation_idx)
		
		print("Found ", inst.name, " with data: ", data)
		print("Set component ", inst.name, " to position: ", inst.position)
		
		_built.append(inst)
	
	print("Ship built: %d components" % _built.size())
