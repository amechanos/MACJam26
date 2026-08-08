extends Node2D
class_name WeaponBase

@export var bullet_scene: PackedScene
@onready var body = get_node_or_null("body")

# Must specify these
@export var bullet_speed: float = 0.0
@export var fire_rate: float = 0.0
@export var from_player: bool = true

var time_since_last_shot: float = 0.0

func _process(delta: float) -> void:
	time_since_last_shot += delta
	fire()

func rotate_cw() -> void:
	global_rotation += deg_to_rad(90.0)

func fire() -> void:
	pass
