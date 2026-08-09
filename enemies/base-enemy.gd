extends CharacterBody2D
class_name BaseEnemy

signal dead

@onready var hurtbox: Area2D = get_node_or_null("Area2D") as Area2D

var health: float = 100.0
var speed: float = 3.0
var scroll_speed: float = 60.0
var target_pos: Vector2 = Vector2.ZERO
var screen_size: Vector2 = Vector2.ZERO
@export var xp: float = 1.0

# Rotation parameters
@export var angular_velocity: float = 0.5 # Base rotation speed magnitude in rad/sec
@export_range(0.0, 1.0) var direction_change_chance: float = 0.3 # Probability (0.0 to 1.0) per second to flip direction
@export var rotation_smoothness: float = 8.0 # Interpolation speed for smooth direction transitions
@export_range(0.0, 360.0) var min_angle_degrees: float = 170.0
@export_range(0.0, 360.0) var max_angle_degrees: float = 190.0

var min_angle_rad: float
var max_angle_rad: float
var current_angular_velocity: float = 0.0
var target_angular_velocity: float = 0.0
var direction_timer: float = 0.0

# Gun management
var gun_list: Array[WeaponBase] = []
var gun_orientation: Array[float] = [] # Relative rotation offset (in radians) for each gun

# Interval range for picking new locations (seconds)
var min_interval: float = 1.0
var max_interval: float = 3.0

# Offset range from current position while moving to a new position
var min_offset: Vector2 = Vector2(-150.0, -150.0)
var max_offset: Vector2 = Vector2(150.0, 150.0)

# Bounding box dictionary: "x" and "y" each hold Vector2(min, max)
var boundary: Dictionary = {}
var move_timer: float = 0.0
var current_interval: float = 0.0

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	else:
		push_warning("BaseEnemy: 'Area2D' child node not found on " + name)
	
	# Set initial facing direction to Left (PI radians / 180 degrees)
	rotation = PI
	
	# Convert Inspector degree values to radians
	min_angle_rad = deg_to_rad(min_angle_degrees)
	max_angle_rad = deg_to_rad(max_angle_degrees)
	
	# Initialize target rotation velocities
	target_angular_velocity = angular_velocity
	current_angular_velocity = angular_velocity
	
	if boundary.is_empty():
		boundary = {
			"x": Vector2(50.0, screen_size.x - 50.0),
			"y": Vector2(50.0, screen_size.y - 50.0)
		}
		
	global_position = Vector2(screen_size.x + 50, randf_range(50.0, screen_size.y - 50.0))
	_reset_move_timer()
	_pick_new_target()

func teleport_x(dest: float) -> void:
	global_position.x = dest
	target_pos.x = dest

func teleport_y(dest: float) -> void:
	global_position.y = dest
	target_pos.y = dest

func _process(delta: float) -> void:
	# Bound the enemy to the screen
	if global_position.x < 0:
		teleport_x(screen_size.x)
	if global_position.y < 0:
		teleport_y(screen_size.y)
	elif global_position.y > screen_size.y:
		teleport_y(screen_size.y)
	
	move(target_pos, delta)
	
	# 1. Timer check: Randomly attempt to flip direction once per second
	direction_timer += delta
	if direction_timer >= 1.0:
		direction_timer -= 1.0
		if randf() < direction_change_chance:
			target_angular_velocity = -target_angular_velocity

	# 2. Limit check: Reverse rotation target direction if exceeding angular boundaries
	if rotation >= max_angle_rad:
		rotation = max_angle_rad
		target_angular_velocity = -abs(angular_velocity)
	elif rotation <= min_angle_rad:
		rotation = min_angle_rad
		target_angular_velocity = abs(angular_velocity)

	# 3. Smooth transition: Interpolate current angular velocity towards target angular velocity
	current_angular_velocity = lerp(current_angular_velocity, target_angular_velocity, 1.0 - exp(-rotation_smoothness * delta))
	rotation += current_angular_velocity * delta

	orient_gun()
	
	move_timer += delta
	if move_timer >= current_interval:
		move_timer = 0.0
		_reset_move_timer()
		_pick_new_target()
	target_pos -= Vector2(scroll_speed * delta, 0)

func orient_gun() -> void:
	for i in range(gun_list.size()):
		if i < gun_orientation.size() and is_instance_valid(gun_list[i]):
			gun_list[i].global_rotation = global_rotation + gun_orientation[i]

func fire_gun() -> void:
	for gun in gun_list:
		if is_instance_valid(gun):
			gun.fire()

func _pick_new_target() -> void:
	var offset_x: float = randf_range(min_offset.x, max_offset.x)
	var offset_y: float = randf_range(min_offset.y, max_offset.y)
	var candidate_pos: Vector2 = global_position + Vector2(offset_x, offset_y)
	
	candidate_pos.x = clampf(candidate_pos.x, boundary["x"].x, boundary["x"].y)
	candidate_pos.y = clampf(candidate_pos.y, boundary["y"].x, boundary["y"].y)
	
	target_pos = candidate_pos

func _reset_move_timer() -> void:
	current_interval = randf_range(min_interval, max_interval)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area is not BaseProjectile:
		return
	if not area.from_player:
		return
	
	take_dmg(area.damage)
	area.pierce -= 1
	
func move(destination: Vector2, delta: float) -> void:
	global_position = global_position.lerp(destination, 1.0 - exp(-speed * delta))

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
	print("Enemy took damage!")
	dmg_number(dmg, Color.STEEL_BLUE)

	if health <= 0:
		kill()

func kill() -> void:
	dead.emit()
	queue_free()
	print("Enemy died!")
