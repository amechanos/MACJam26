extends Node

var wave_number: int = 0
var base_wave_cost: int = 40
var cost_scaling: int = 10
var active_enemies: int = 0
@onready var ship: Node2D = $ship

# Preloading scenes based on main.tscn
var enemy_scenes: Dictionary = {
	"gunner": preload("res://enemies/gunner-enemy.tscn"),
	"bomber": preload("res://enemies/bomber-enemy.tscn")
}

var enemy_costs: Dictionary = {
	"gunner": 10,
	"bomber": 15
}

func _ready() -> void:
	# Initialize random number generator
	randomize()
	
	# Start the first wave
	start_next_wave()

func start_next_wave() -> void:
	wave_number += 1
	print("Wave ", wave_number)
	
	# Calculate total allowed cost for this wave
	var current_wave_target_cost: int = base_wave_cost + (wave_number - 1) * cost_scaling
	spawn_wave(current_wave_target_cost)

func spawn_wave(target_cost: int) -> void:
	var current_cost: int = 0
	var available_enemies: Array = enemy_costs.keys()
	
	# Determine the minimum cost to prevent an infinite loop 
	# if the remaining budget is smaller than any enemy's cost.
	var min_cost: int = enemy_costs[available_enemies[0]]
	for key in available_enemies:
		if enemy_costs[key] < min_cost:
			min_cost = enemy_costs[key]

	# Loop until the remaining budget cannot afford the cheapest enemy
	while current_cost + min_cost <= target_cost:
		# Randomly select an enemy
		var random_index: int = randi() % available_enemies.size()
		var chosen_enemy: String = available_enemies[random_index]
		var cost: int = enemy_costs[chosen_enemy]
		
		# If the chosen enemy's cost fits in the remaining budget, spawn it
		if current_cost + cost <= target_cost:
			spawn_enemy(chosen_enemy)
			current_cost += cost

func spawn_enemy(enemy_name: String) -> void:
	if not enemy_scenes.has(enemy_name):
		push_error("Enemy type not found: " + enemy_name)
		return
		
	var enemy_instance: CharacterBody2D = enemy_scenes[enemy_name].instantiate()
	
	# Track active enemies for wave progression
	active_enemies += 1
	
	# Bind the enemy instance to the tree_exited signal callback
	enemy_instance.dead.connect(_on_enemy_defeated.bind(enemy_instance))
	
	# Add the enemy to the scene tree
	add_child(enemy_instance)

func _on_enemy_defeated(enemy: CharacterBody2D) -> void:
	if not is_inside_tree():
		return
	if not is_instance_valid(ship):
		print("Invalid ship instance!")
		return
	if ship.has_method("defeated_enemy"):
		ship.defeated_enemy(enemy)
	active_enemies -= 1
	
	if active_enemies <= 0:
		if ship.has_method("heal"):
			ship.heal(99999)
		var tree = get_tree()
		if tree:
			tree.create_timer(1.5).timeout.connect(start_next_wave)
