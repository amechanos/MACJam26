extends Node2D

class_name Gun

@onready var body = $body

@export var bullet_scene: PackedScene
@export var bullet_speed: float = 600.0
@export var fire_rate: float = 0.25
@export var component_size: Vector2 = Vector2(1, 2)

var time_since_last_shot: float = 0.0

func _process(delta: float) -> void:
	time_since_last_shot += delta
	if time_since_last_shot >= fire_rate:
		fire()
		time_since_last_shot = 0.0

func rotate_cw() -> void:
	global_rotation += 90
	if global_rotation == 360: 
		global_rotation = 0

func fire() -> void:
	if bullet_scene == null:
		return
		
	var new_bullet = bullet_scene.instantiate()
	get_tree().root.add_child(new_bullet) 
	
	new_bullet.global_position = global_position + Vector2(body.size.x * 0.67, body.size.y / 2)
	
	# Changed to Vector2.RIGHT for horizontal gameplay
	var direction = Vector2.RIGHT.rotated(global_rotation)
	
	if new_bullet.has_method("setup"):
		new_bullet.setup(direction, bullet_speed)
