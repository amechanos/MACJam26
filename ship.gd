extends CharacterBody2D
class_name Ship

@onready var hurtbox: Area2D = get_node_or_null("Area2D") as Area2D

var health: float = 1000.0
var max_health: float = 1000.0
var health_regen: float = 10.0
var health_regen_interval: float = 1.0  # Seconds
var time_since_last_regen: float = 0.0

@export var xp: float = 0.0
@export var level: int = 0

# --- MOVEMENT VARIABLES ---
@export var move_speed: float = 400.0
@export var use_mouse_movement: bool = false  # Toggle in the inspector!

# --- GUN VARIABLES ---
var gun_list: Array[WeaponBase] = []
var gun_orientation: Array[float] = []  # Relative rotation offset (in radians) for each gun

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
	time_since_last_regen += delta
	if time_since_last_regen >= health_regen_interval:
		heal(health_regen)
		time_since_last_regen = 0.0
	
	move(delta)
	orient_gun()
	fire_gun()

func heal(hp: float) -> void:
	var old_health = health
	health = min(health + hp, max_health)
	var healed_amount = health - old_health
	if healed_amount != 0:
		dmg_number(health - old_health, Color.LIME_GREEN)

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

# Exact same as in base-enemy.gd
func dmg_number(dmg: float, color) -> void:
	# Spawn Floating Damage Label
	var label := Label.new()
	label.text = str(round(dmg))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.global_position = global_position
	label.modulate = color
	
	# Add to main scene tree so it remains visible even if enemy dies
	var scene_root = get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root
	scene_root.add_child(label)
	
	# Center pivot offset so scaling expands from label center
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2(0.5, 0.5)
	
	# Sequentially animate over 1 second total
	var tween := label.create_tween()
	# Phase 1 (0.0s - 0.5s): Slowly enlarge
	tween.tween_property(label, "scale", Vector2(1.5, 1.5), 0.5)
	# Phase 2 (0.5s - 1.0s): Fade to transparent
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	# Cleanup label node upon completion
	tween.tween_callback(label.queue_free)

func take_dmg(dmg: float) -> void:
	health -= dmg
	print("Player took %d damage! %d health remaining." % [dmg, health])
	dmg_number(dmg, Color.FIREBRICK)
	
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
		
		print("Found ", inst.name, " with data: ", data)
		print("Set component ", inst.name, " to position: ", inst.position)
		
		_built.append(inst)
	
	print("Ship built: %d components" % _built.size())

func defeated_enemy(enemy: CharacterBody2D):
	xp += enemy.xp
	print("Gained %d xp" % enemy.xp)
