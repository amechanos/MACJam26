extends Node

@export_group("Spawning Difficulty")
@export var base_spawn_interval: float = 3.0   # Time between spawns at 0 seconds
@export var min_spawn_interval: float = 0.4    # Fastest possible time between spawns
@export var difficulty_curve_rate: float = 0.015 # Higher = ramps up difficulty faster

@onready var ship: Node2D = $ship

var elapsed_time: float = 0.0
var spawn_timer: float = 0.0

# Preloaded enemy scenes
var enemy_scenes: Dictionary = {
	"gunner": preload("res://enemies/gunner-enemy.tscn"),
	"bomber": preload("res://enemies/bomber-enemy.tscn")
}

# Config: [unlock_time_in_seconds, weight]
# Higher weight = higher relative spawn frequency
var enemy_spawn_config: Dictionary = {
	"gunner": {"unlock_time": 0.0, "weight": 100.0},
	"bomber": {"unlock_time": 15.0, "weight": 40.0}
}

func _ready() -> void:
	randomize()

func _process(delta: float) -> void:
	elapsed_time += delta
	spawn_timer += delta
	
	# Calculate current interval based on time elapsed
	var current_interval: float = get_current_spawn_interval()
	
	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		spawn_random_enemy()

# Dynamic spawn rate calculation (exponential scaling down towards min interval)
func get_current_spawn_interval() -> float:
	return lerp(min_spawn_interval, base_spawn_interval, exp(-difficulty_curve_rate * elapsed_time))

func spawn_random_enemy() -> void:
	var chosen_enemy: String = pick_enemy_for_current_time()
	if chosen_enemy.is_empty():
		return
		
	spawn_enemy(chosen_enemy)

func pick_enemy_for_current_time() -> String:
	var available_enemies: Array[String] = []
	var weights: Array[float] = []
	var total_weight: float = 0.0
	
	for enemy_name in enemy_spawn_config.keys():
		var config: Dictionary = enemy_spawn_config[enemy_name]
		if elapsed_time >= config["unlock_time"]:
			# Scale weight slightly over time for tougher enemies
			var weight: float = config["weight"]
			available_enemies.append(enemy_name)
			weights.append(weight)
			total_weight += weight

	if available_enemies.is_empty():
		return ""

	# Weighted random choice
	var random_weight: float = randf_range(0.0, total_weight)
	var current_sum: float = 0.0
	
	for i in range(available_enemies.size()):
		current_sum += weights[i]
		if random_weight <= current_sum:
			return available_enemies[i]
			
	return available_enemies[0]

func spawn_enemy(enemy_name: String) -> void:
	if not enemy_scenes.has(enemy_name):
		push_error("Enemy scene not found: " + enemy_name)
		return
		
	var enemy_instance: Node2D = enemy_scenes[enemy_name].instantiate()
	
	# Position off-screen to the right at a random Y coordinate
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var spawn_x: float = viewport_rect.size.x + 80.0
	var spawn_y: float = randf_range(60.0, viewport_rect.size.y - 60.0)
	enemy_instance.global_position = Vector2(spawn_x, spawn_y)
	
	add_child(enemy_instance)
