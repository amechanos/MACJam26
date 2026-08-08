extends Node2D
class_name Cannon

## Attach this to an empty Node2D positioned at the ship's cannon mount.
## It autofires bomb.tscn, spawning it a short distance in front of the ship.

@export var bomb_scene: PackedScene
@export var fire_rate: float = 0.7        ## shots per second (slower, heavier hit)
@export var spawn_distance: float = 40.0  ## how far in front of the ship the bomb starts
@export var damage: float = 30.0
@export var explosion_radius: float = 80.0
@export var fire_direction: Vector2 = Vector2.UP
@export var autofire: bool = true

var _fire_timer: float = 0.0

func _process(delta: float) -> void:
	if not autofire:
		return
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		fire()
		_fire_timer = 1.0 / fire_rate

func fire() -> void:
	if bomb_scene == null:
		push_warning("Cannon: no bomb_scene assigned")
		return

	var bomb := bomb_scene.instantiate()

	# Spawned into the main scene, not parented to the ship.
	get_tree().current_scene.add_child(bomb)

	var dir := fire_direction.normalized()
	bomb.global_position = global_position + dir * spawn_distance
	bomb.direction = dir
	bomb.damage = damage
	bomb.radius = explosion_radius
