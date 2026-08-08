extends CharacterBody2D
class_name Ship

@onready var hurtbox: Area2D = get_node_or_null("Area2D") as Area2D

var health: float = 1000.0
@export var xp: float = 0.0
var level: int = 0

# --- MOVEMENT VARIABLES ---
@export var move_speed: float = 400.0
@export var use_mouse_movement: bool = false  # Toggle in the inspector!

# --- GUN VARIABLES ---
var gun_list: Array[Weapon] = []
var gun_orientation: Array[float] = [] # Relative rotation offset (in radians) for each gun

var time_since_last_shot: float = 0.0
var screen_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	screen_size = get_viewport_rect().size
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	else:
		push_warning("Ship: 'Area2D' child node not found on " + name)

func _process(delta: float) -> void:
	move(delta)
	orient_gun()
	fire_gun()

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
