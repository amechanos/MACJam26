extends BaseEnemy
class_name GunnerEnemy

@export var gun_scene: PackedScene

func _ready() -> void:
	super._ready()
	
	if gun_scene == null:
		print("GunnerEnemy: 'gun_scene' is not assigned in the Inspector!")
		return
		
	var gun_instance = gun_scene.instantiate()
	if gun_instance is not WeaponBase:
		print("gun_instance is not a weapon!")
		return
	
	# Hide the gun
	var body = gun_instance.get_node_or_null("body") as ColorRect
	if body: body.hide()
	
	gun_instance.from_player = false
	add_child(gun_instance)
	
	gun_list.append(gun_instance)
	gun_orientation.append(0.0) # Aligned with enemy orientation

func _process(delta: float) -> void:
	super._process(delta)
	fire_gun()
