extends WeaponBase
class_name GunBase

func _ready() -> void:
	fire_delay = 0.5
	super_fire_delay = 5.0
	bullet_speed = 300.0
	fire_delay_jitter = Vector2(-0.05, 0.05)
	super_fire_delay_jitter = Vector2(-0.5, 2.5)
	
	if from_player:
		fire_delay = 0.25
		super_fire_delay = 999999.0
		bullet_speed = 600.0
		fire_delay_jitter = Vector2.ZERO
		super_fire_delay_jitter = Vector2.ZERO
		

func fire() -> void:
	super_fire()
	
	if time_to_next_shot > 0:
		return
	if bullet_scene == null:
		print("Bullet scene is null!")
		return
		
	var new_bullet = bullet_scene.instantiate()
	new_bullet.from_player = from_player
	
	# Calculate muzzle spawn offset based on gun body size (if present)
	var spawn_offset = Vector2(body.size.x * 0.67, body.size.y * 0.5)
	
	# Rotate local offset by global_rotation so bullets spawn from gun tip regardless of orientation
	new_bullet.global_position = global_position + spawn_offset.rotated(global_rotation)
	
	get_tree().root.add_child(new_bullet)
	time_to_next_shot = fire_delay + randf_range(fire_delay_jitter[0], fire_delay_jitter[1])
	
	# Facing vector pointing in the gun's global rotation direction
	var direction: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	
	if new_bullet.has_method("setup"):
		new_bullet.setup(direction, bullet_speed)

func super_fire() -> void:
	if time_to_next_super_shot > 0:
		return
	if bullet_scene == null:
		print("Bullet scene is null!")
		return
		
	var bullets = [bullet_scene.instantiate(), bullet_scene.instantiate(), bullet_scene.instantiate()]
	for bullet in bullets:
		bullet.from_player = from_player
		
		# Calculate muzzle spawn offset based on gun body size (if present)
		var spawn_offset = Vector2(body.size.x * 0.67, body.size.y * 0.5)
		
		# Rotate local offset by global_rotation so bullets spawn from gun tip regardless of orientation
		bullet.global_position = global_position + spawn_offset.rotated(global_rotation)
		
		get_tree().root.add_child(bullet)
		time_to_next_super_shot = super_fire_delay + randf_range(super_fire_delay_jitter[0], super_fire_delay_jitter[1])
		
	var super_fire_spread = 0.25
	bullets[0].setup(Vector2.RIGHT.rotated(global_rotation - super_fire_spread), bullet_speed)
	bullets[1].setup(Vector2.RIGHT.rotated(global_rotation), bullet_speed)
	bullets[2].setup(Vector2.RIGHT.rotated(global_rotation + super_fire_spread), bullet_speed)
	
	# Add voice lines here
