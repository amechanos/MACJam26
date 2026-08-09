extends CharacterBody2D
class_name Ship

@onready var hurtbox: Area2D = get_node_or_null("Area2D") as Area2D

var health: float = 1000.0
var max_health: float = 1000.0
@export var xp: float = 0.0
@export var level: int = 0

# --- MOVEMENT VARIABLES ---
@export var move_speed: float = 400.0
@export var use_mouse_movement: bool = false  # Toggle in the inspector!

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
	
func move(delta: float) -> void:
	if use_mouse_movement:
		var target_pos = get_global_mouse_position()
		position = position.lerp(target_pos, 20 * delta)
		
	position.x = clamp(position.x, 0, screen_size.x * 0.5)
	position.y = clamp(position.y, 0, screen_size.y)
	
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
	
	for comp_name in Global.assembly_placements.keys():
		var data = Global.assembly_placements[comp_name]
		var components_folder: String = "res://components/%s/" % data.shape_name.to_lower()
		var path = components_folder.path_join(data.shape_name.to_lower() + ".tscn")
		
		if not ResourceLoader.exists(path):
			push_warning("ShipBuilder: Scene not found: %s" % path)
			continue
		
		var scene: PackedScene = load(path)
		var inst = scene.instantiate()
		container.add_child(inst)
		
		inst.position = origin + Vector2(data.col, data.row) * cfg.cell_size
		inst.rotation_degrees = data.rotation * 90
		inst.name = comp_name
		
		_built.append(inst)
	
	print("Ship built: %d components" % _built.size())

func export_back_to_global():
	var placements := {}
	var cfg = Global.assembly_config
	for c in _built:
		var local = c.position
		var origin = -Vector2(cfg.grid_cols * cfg.cell_size, cfg.grid_rows * cfg.cell_size) / 2.0 if center_grid else Vector2.ZERO
		var grid_pos = (local - origin) / cfg.cell_size
		placements[c.name] = {
			"col": int(round(grid_pos.x)),
			"row": int(round(grid_pos.y)),
			"shape_name": c.name,  # or however you map it
			"rotation": int(round(c.rotation_degrees / 90.0)) % 4
		}
	Global.store_assembly(placements, cfg)

func defeated_enemy(enemy: CharacterBody2D):
	xp += enemy.xp
	print("Gained %d xp" % enemy.xp)
