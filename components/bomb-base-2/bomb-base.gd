extends WeaponBase
class_name BombBase

@onready var fire_sfx: AudioStreamPlayer2D = $FireSFX
@onready var voice_lines = [$voice1, $voice2, $voice3]

func _ready() -> void:
	fire_delay = 4.0
	super_fire_delay = 8.0
	bullet_speed = 100.0
	fire_delay_jitter = Vector2(-2.0, 1.0)
	super_fire_delay_jitter = Vector2(-2.0, 3.0)

	if from_player:
		fire_delay = 2.0
		bullet_speed = 200.0
		fire_delay_jitter = Vector2.ZERO

func fire() -> void:
	if not from_player:
		super_fire()
	
	if time_to_next_shot > 0:
		return
	if bullet_scene == null:
		print("Bullet not found!")
		return
	
	fire_sfx.play()

	var new_bomb = bullet_scene.instantiate()
	new_bomb.from_player = from_player
	
	var spawn_offset = Vector2(body.size.x * 2.25, body.size.y * 1.5)
	new_bomb.global_position = global_position + spawn_offset.rotated(global_rotation)

	# Add directly to root tree so it moves independently of the enemy node
	get_tree().root.add_child(new_bomb)
	time_to_next_shot = fire_delay + randf_range(fire_delay_jitter[0], fire_delay_jitter[1])
	var direction: Vector2 = Vector2.RIGHT.rotated(global_rotation)

	if new_bomb.has_method("setup"):
		new_bomb.setup(direction, bullet_speed)


func super_fire() -> void:
	if time_to_next_super_shot > 0:
		return
	
	if bullet_scene == null:
		print("Bullet not found!")
		return
	
	fire_sfx.play()
	voice_lines.pick_random().play()
	
	var bombs = [bullet_scene.instantiate(), bullet_scene.instantiate()]
	for bomb in bombs:
		bomb.from_player = from_player
		
		var spawn_offset = Vector2(body.size.x, body.size.y)
		bomb.global_position = global_position + spawn_offset.rotated(global_rotation)

		# Add directly to root tree so it moves independently of the enemy node
		get_tree().root.add_child(bomb)
	time_to_next_super_shot = super_fire_delay + randf_range(super_fire_delay_jitter[0], super_fire_delay_jitter[1])

	var super_shot_spread = 0.25
	bombs[0].setup(Vector2.RIGHT.rotated(global_rotation - super_shot_spread), bullet_speed)
	bombs[1].setup(Vector2.RIGHT.rotated(global_rotation + super_shot_spread), bullet_speed)
	
	# Add voice lines here
