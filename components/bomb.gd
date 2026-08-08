extends Area2D

## AOE bomb fired by Cannon. Travels forward briefly, then expands into
## a damage radius and lingers for a moment before disappearing.
## Spawned into the main scene, independent of the ship.

@export var damage: float = 30.0
@export var radius: float = 80.0
@export var travel_speed: float = 300.0
@export var travel_time: float = 0.4       ## time flying forward before it detonates
@export var explosion_duration: float = 0.3

var direction: Vector2 = Vector2.RIGHT
var _traveling: bool = true
var _timer: float = 0.0
var _hit_bodies: Array = []

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: Polygon2D = $Polygon2D

func _ready() -> void:
	(_collision_shape.shape as CircleShape2D).radius = 5.0
	_visual.polygon = _make_circle(5.0)
	_visual.color = Color(1.0, 0.4, 0.2, 0.9)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _traveling:
		global_position += direction * travel_speed * delta
		_timer += delta
		if _timer >= travel_time:
			_explode()
	else:
		_timer -= delta
		if _timer <= 0.0:
			queue_free()

func _explode() -> void:
	_traveling = false
	_timer = explosion_duration
	(_collision_shape.shape as CircleShape2D).radius = radius
	_visual.polygon = _make_circle(radius)
	_visual.color = Color(1.0, 0.4, 0.1, 0.5)
	# Hit everything already overlapping the moment it detonates.
	for body in get_overlapping_bodies():
		_damage_body(body)

func _on_body_entered(body: Node2D) -> void:
	if not _traveling:
		_damage_body(body)

func _damage_body(body: Node2D) -> void:
	if body in _hit_bodies:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	_hit_bodies.append(body)

func _make_circle(r: float, points: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in points:
		var angle := TAU * i / points
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	return pts
