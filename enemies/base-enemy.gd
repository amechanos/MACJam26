extends CharacterBody2D
class_name BaseEnemy

@onready var hurtbox: Area2D = get_node_or_null("Area2D") as Area2D

@export_group("Stats")
@export var max_health: float = 100.0
@export var forward_speed: float = 120.0 # Speed moving left (pixels per second)

@export_group("Shooting")
@export var shoot_interval: float = 2.5 # Time in seconds between shots
@export var auto_shoot: bool = true

@export_group("Wave Movement")
@export var wave_amplitude: float = 40.0 # Height of vertical sway (set to 0 for straight line)
@export var wave_frequency: float = 2.0 # Speed of vertical sway

@export_group("Rotation Parameters")
@export var angular_velocity: float = 0.5 # Base rotation speed magnitude in rad/sec
@export_range(0.0, 1.0) var direction_change_chance: float = 0.3 # Probability per second to flip direction
@export var rotation_smoothness: float = 8.0
@export_range(0.0, 360.0) var min_angle_degrees: float = 170.0
@export_range(0.0, 360.0) var max_angle_degrees: float = 190.0

var health: float
var screen_size: Vector2 = Vector2.ZERO

var min_angle_rad: float
var max_angle_rad: float
var current_angular_velocity: float = 0.0
var target_angular_velocity: float = 0.0
var direction_timer: float = 0.0

# Timers and motion state
var shoot_timer: float = 0.0
var spawn_y: float = 0.0
var time_alive: float = 0.0

# Gun management
var gun_list: Array[WeaponBase] = []
var gun_orientation: Array[float] = [] # Relative rotation offset (in radians) for each gun

func _ready() -> void:
	health = max_health
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
	
	# Default spawn off the right edge if position isn't pre-set
	if global_position == Vector2.ZERO:
		global_position = Vector2(screen_size.x + 80.0, randf_range(60.0, screen_size.y - 60.0))
		
	spawn_y = global_position.y

func _process(delta: float) -> void:
	time_alive += delta
	
	# 1. Progressive leftward movement + vertical wave
	move_enemy(delta)
	
	# 2. Dynamic rotation wiggling
	update_rotation(delta)

	# 3. Update gun positions/orientations
	orient_gun()
	
	# 4. Controlled Fire Rate Timer
	if auto_shoot:
		shoot_timer += delta
		if shoot_timer >= shoot_interval:
			shoot_timer = 0.0
			fire_gun()

	# 5. Despawn check when completely off the left side of the screen
	if global_position.x < -100.0:
		queue_free()

func move_enemy(delta: float) -> void:
	# Continuous movement leftward
	global_position.x -= forward_speed * delta
	
	# Subtle sine-wave pattern along Y axis
	global_position.y = spawn_y + sin(time_alive * wave_frequency) * wave_amplitude

func update_rotation(delta: float) -> void:
	direction_timer += delta
	if direction_timer >= 1.0:
		direction_timer -= 1.0
		if randf() < direction_change_chance:
			target_angular_velocity = -target_angular_velocity

	if rotation >= max_angle_rad:
		rotation = max_angle_rad
		target_angular_velocity = -abs(angular_velocity)
	elif rotation <= min_angle_rad:
		rotation = min_angle_rad
		target_angular_velocity = abs(angular_velocity)

	current_angular_velocity = lerp(current_angular_velocity, target_angular_velocity, 1.0 - exp(-rotation_smoothness * delta))
	rotation += current_angular_velocity * delta

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
	if not area.from_player:
		return
	
	take_dmg(area.damage)
	area.pierce -= 1

func take_dmg(dmg: float) -> void:
	health -= dmg
	if health <= 0:
		kill()

func kill() -> void:
	queue_free()
