extends Area2D

## A fixed beam that appears at the muzzle position/direction at the moment
## it is fired, then stays put (does NOT track the ship) dealing damage
## every tick for `duration` seconds before disappearing.

@export var damage_per_second: float = 40.0
@export var beam_length: float = 900.0
@export var beam_width: float = 16.0
@export var duration: float = 3.0

var direction: Vector2 = Vector2.UP

const TICK_INTERVAL: float = 0.1
var _time_left: float
var _tick_timer: float = 0.0

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: Polygon2D = $Polygon2D

func _ready() -> void:
	_time_left = duration
	rotation = direction.angle() + PI / 2.0

	var shape := _collision_shape.shape as RectangleShape2D
	shape.size = Vector2(beam_width, beam_length)
	_collision_shape.position = Vector2(0, -beam_length / 2.0)

	var half_w := beam_width / 2.0
	_visual.polygon = PackedVector2Array([
		Vector2(-half_w, 0),
		Vector2(half_w, 0),
		Vector2(half_w, -beam_length),
		Vector2(-half_w, -beam_length),
	])
	_visual.color = Color(0.3, 0.9, 1.0, 0.8)

func _physics_process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
		return

	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = TICK_INTERVAL
		for body in get_overlapping_bodies():
			if body.has_method("take_damage"):
				body.take_damage(damage_per_second * TICK_INTERVAL)
