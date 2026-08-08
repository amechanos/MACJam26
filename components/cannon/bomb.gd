extends BaseProjectile

@export var explosion_scene: PackedScene

# Prevents the function from executing multiple times on simultaneous collisions
var _has_exploded: bool = false 

func _ready() -> void:
	damage = 50.0
	pierce = 1

func destroy_projectile() -> void:
	if _has_exploded:
		return
	_has_exploded = true

	if explosion_scene:
		var explosion = explosion_scene.instantiate() as Area2D
		explosion.global_position = global_position
		
		# Adding to parent ensures it spawns in the world properly, not attached to the dying bomb
		get_parent().add_child(explosion)

		# Force Godot to update the transform immediately so the collision query is accurate
		explosion.force_update_transform()
		
		# Await two physics frames. Godot's physics engine often requires a double-tick 
		# for newly spawned Area2Ds to reliably register overlaps via get_overlapping_areas()
		await get_tree().physics_frame
		await get_tree().physics_frame

		var aoe_damage: float = damage * 0.25
		var hit_targets: Array[Node] = []

		# Check overlapping Areas (like the Enemy's hurtbox)[cite: 1, 2]
		for area in explosion.get_overlapping_areas():
			_process_aoe_hit(area.get_parent(), hit_targets, aoe_damage)

		# Check overlapping Bodies (in case the collision mask is on the CharacterBody2D)[cite: 1, 2]
		for body in explosion.get_overlapping_bodies():
			_process_aoe_hit(body, hit_targets, aoe_damage)

		# Handle the fade animation
		var sprite = explosion.get_node_or_null("Sprite2D") as Sprite2D
		var fade_target: CanvasItem = sprite if sprite else explosion

		var tween = explosion.create_tween()
		tween.tween_property(fade_target, "modulate:a", 0.0, 1.0)
		tween.tween_callback(explosion.queue_free)

	# Free the bomb immediately so it stops colliding
	queue_free()

func _process_aoe_hit(target: Node, hit_targets: Array[Node], aoe_damage: float) -> void:
	if not target or target in hit_targets or not target.has_method("take_dmg"):
		return
		
	# If fired by the player, only damage enemies
	if from_player and target is BaseEnemy:
		hit_targets.append(target)
		target.take_dmg(aoe_damage)
		
	# If fired by an enemy, damage non-enemies (like the Player)[cite: 1, 3]
	elif not from_player and not target is BaseEnemy:
		hit_targets.append(target)
		target.take_dmg(aoe_damage)
