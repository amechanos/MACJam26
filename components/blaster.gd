extends Node2D
class_name Blaster

@export var bullet_scene: PackedScene
@export var fire_rate: float = 4.0        ## shots per second
@export var bullet_speed: float = 800.0
@export var damage: float = 10.0
@export var fire_direction: Vector2 = Vector2.RIGHT
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
	if bullet_scene == null:
		push_warning("Blaster: no bullet_scene assigned")
		return

	var bullet := bullet_scene.instantiate()

	# IMPORTANT: add to the main scene, not to the ship (self).
	# This is what keeps the bullet independent of the ship's transform.
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = global_position
	bullet.direction = fire_direction.normalized()
	bullet.speed = bullet_speed
	bullet.damage = damage
