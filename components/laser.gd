extends Node2D
class_name Laser

## Attach this to an empty Node2D positioned at the ship's laser mount.
## Fires a laser_beam.tscn that lasts `beam_duration` seconds, then waits
## `cooldown` seconds before firing again.

@export var laser_scene: PackedScene
@export var beam_duration: float = 3.0
@export var cooldown: float = 1.5
@export var damage_per_second: float = 40.0
@export var fire_direction: Vector2 = Vector2.UP
@export var autofire: bool = true

enum State { READY, FIRING, COOLDOWN }
var _state: State = State.READY
var _timer: float = 0.0

func _process(delta: float) -> void:
	if not autofire:
		return

	match _state:
		State.READY:
			_start_beam()
		State.FIRING:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.COOLDOWN
				_timer = cooldown
		State.COOLDOWN:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.READY

func _start_beam() -> void:
	if laser_scene == null:
		push_warning("Laser: no laser_scene assigned")
		return

	var beam := laser_scene.instantiate()

	# Spawned into the main scene, not parented to the ship, so it stays
	# fixed in world space for its whole duration instead of following the ship.
	get_tree().current_scene.add_child(beam)

	beam.global_position = global_position
	beam.direction = fire_direction.normalized()
	beam.duration = beam_duration
	beam.damage_per_second = damage_per_second

	_state = State.FIRING
	_timer = beam_duration
