extends WeaponBase
class_name BombBase

func _ready() -> void:
	fire_delay = 4.0
	bullet_speed = 100.0
	fire_delay_jitter = Vector2(-2.0, 1.0)

	if from_player:
		fire_delay = 2.0
		bullet_speed = 200.0
		fire_delay_jitter = Vector2(0.0, 0.0)

func fire() -> void:
	if time_to_next_shot > 0:
		return
		
	if bullet_scene == null:
		print("Bullet not found!")
		return

	var new_bomb = bullet_scene.instantiate()
	new_bomb.from_player = from_player
	
	var spawn_offset = Vector2(body.size.x, 0)
	new_bomb.global_position = global_position + spawn_offset.rotated(global_rotation)

	# Add directly to root tree so it moves independently of the enemy node
	get_tree().root.add_child(new_bomb)
	time_to_next_shot = fire_delay + randf_range(fire_delay_jitter[0], fire_delay_jitter[1])
	var direction: Vector2 = Vector2.RIGHT.rotated(global_rotation)

	if new_bomb.has_method("setup"):
		new_bomb.setup(direction, bullet_speed)
