extends Node2D

@onready var hbox = $HBoxContainer

# --- MOVEMENT VARIABLES ---
@export var move_speed: float = 400.0
@export var use_mouse_movement: bool = false # Toggle in the inspector!

var time_since_last_shot: float = 0.0
var screen_size: Vector2

func _ready() -> void:
	screen_size = get_viewport_rect().size
			
func _process(delta: float) -> void:
	move(delta)
	
func move(delta: float) -> void:
	if use_mouse_movement:
		var target_pos = get_global_mouse_position()
		position = position.lerp(target_pos, 20 * delta)
		
	position.x = clamp(position.x, 0, screen_size.x-350)
	position.y = clamp(position.y, 0, screen_size.y-90)
