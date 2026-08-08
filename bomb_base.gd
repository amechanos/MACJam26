extends Node2D

@export var bomb_scene: PackedScene
@export var spawn_rate: float = 2.0

@onready var body = $ColorRect

var time_since_last_bomb: float = 0.0


func _process(delta: float) -> void:
	time_since_last_bomb += delta

	if time_since_last_bomb >= spawn_rate:
		spawn_bomb()
		time_since_last_bomb = 0.0


func spawn_bomb() -> void:
	if bomb_scene == null:
		return

	var bomb = bomb_scene.instantiate()

	get_tree().current_scene.add_child(bomb)

	# BombBase의 SpawnPoint에서 Bomb 등장
	bomb.global_position = body.global_position + Vector2(
		body.size.x * 0.67,
		body.size.y / 2
	)
