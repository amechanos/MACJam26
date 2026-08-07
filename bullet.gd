extends Node2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 0.0

func setup(dir: Vector2, spd: float) -> void:
	direction = dir
	speed = spd
	# Rotate the bullet sprite to face the direction it's moving
	rotation = direction.angle()

func _process(delta: float) -> void:
	position += direction * speed * delta
