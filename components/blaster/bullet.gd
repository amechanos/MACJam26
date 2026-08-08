extends Node2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 0.0

@export var from_player = true
@export var damage: float = 25.0
@export var pierce: int = 1

func setup(dir: Vector2, spd: float) -> void:
	direction = dir
	speed = spd
	rotation = direction.angle()

func _process(delta: float) -> void:
	if pierce <= 0:
		queue_free()
	position += direction * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
