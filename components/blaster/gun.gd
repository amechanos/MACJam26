extends WeaponBase
class_name GunBase

func _ready() -> void:
	fire_rate = 0.5
	bullet_speed = 300.0
	
	if from_player:
		fire_rate = 0.25
		bullet_speed = 600.0
		

func fire() -> void:
	if time_since_last_shot < fire_rate:
		return
	if bullet_scene == null:
		return
		
	var new_bullet = bullet_scene.instantiate()
	new_bullet.from_player = from_player
	
	# Calculate muzzle spawn offset based on gun body size (if present)
	var spawn_offset: Vector2 = Vector2.ZERO
	if body and "size" in body:
		spawn_offset = Vector2(body.size.x * 0.67, body.size.y * 0.5)
	
	# Rotate local offset by global_rotation so bullets spawn from gun tip regardless of orientation
	new_bullet.global_position = global_position + spawn_offset.rotated(global_rotation)
	
	get_tree().root.add_child(new_bullet)
	time_since_last_shot = 0.0
	
	# Facing vector pointing in the gun's global rotation direction
	var direction: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	
	if new_bullet.has_method("setup"):
		new_bullet.setup(direction, bullet_speed)
