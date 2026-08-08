extends CharacterBody2D
class_name Ship

@onready var hurtbox: Area2D = get_node_or_null("Area2D") as Area2D

var health: float = 100.0
@export var xp: float = 0.0
var level: int = 0

# --- MOVEMENT VARIABLES ---
@export var move_speed: float = 400.0
@export var use_mouse_movement: bool = false  # Toggle in the inspector!

# --- GUN VARIABLES ---
<<<<<<< Updated upstream
var gun_list: Array[Gun] = []
var gun_orientation: Array[float] = [] # Relative rotation offset (in radians) for each gun

var time_since_last_shot: float = 0.0
=======
>>>>>>> Stashed changes
var screen_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	screen_size = get_viewport_rect().size
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	else:
		push_warning("Ship: 'Area2D' child node not found on " + name)

func _process(delta: float) -> void:
	move(delta)

func _on_hurtbox_area_entered(area: Area2D) -> void:
<<<<<<< Updated upstream
	if area is not Projectile:
		return
=======
	#if area is not BaseProjectile:
		#return
>>>>>>> Stashed changes
	if area.from_player:
		return
	
	take_dmg(area.damage)
	area.pierce -= 1

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
