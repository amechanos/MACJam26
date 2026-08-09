extends Node2D

@onready var body = $ColorRect

@export var laser_scene: PackedScene
@export var fire_rate: float = 10.00

var current_laser = null
var time_since_last_shot: float = 0.0

func _process(delta: float) -> void:
	time_since_last_shot += delta
	if time_since_last_shot >= fire_rate:
		create_laser()
		time_since_last_shot = 0.0

func _ready() -> void:
	create_laser()

func create_laser() -> void:
	if laser_scene == null:
		return

	current_laser = laser_scene.instantiate()

	add_child(current_laser)

	current_laser.position = Vector2(
			body.size.x,
			body.size.y / 2 - 9
	)
	$Timer.start(5)

func _on_timer_timeout() -> void:
	current_laser.queue_free()
