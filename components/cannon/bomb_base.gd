extends WeaponBase
class_name BombBase

func _ready() -> void:
	fire_rate = 4.0
	bullet_speed = 100.0

	if from_player:
		fire_rate = 2.0
		bullet_speed = 200.0

func fire() -> void:
	if bullet_scene == null:
		return

	var bomb = bullet_scene.instantiate()

	get_tree().current_scene.add_child(bomb)

	# BombBase의 SpawnPoint에서 Bomb 등장
	bomb.global_position = body.global_position + Vector2(
		body.size.x * 0.67,
		body.size.y / 2
	)
