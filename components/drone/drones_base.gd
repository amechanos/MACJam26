extends Node2D

@export var radius: float = 225.0
@export var orbit_speed: float = 2

var angle: float = 0.0

func _process(delta: float) -> void:

	angle += orbit_speed * delta

	$proj.global_position = (self.global_position + Vector2($ColorRect.size.x / 2, $ColorRect.size.y / 2)) + Vector2(
			cos(angle),
			sin(angle)
	) * radius
