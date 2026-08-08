extends BaseEnemy
class_name GunnerEnemy

@export var gun_scene: PackedScene

func _ready() -> void:
	super._ready()
	
	if gun_scene == null:
		print("GunnerEnemy: 'gun_scene' is not assigned in the Inspector!")
		return
		
	var gun_instance = gun_scene.instantiate()
	if gun_instance is GunBase:
		gun_instance.from_player = false
		add_child(gun_instance)
		
		gun_list.append(gun_instance)
		gun_orientation.append(0.0) # Aligned with enemy orientation

func _process(delta: float) -> void:
	super._process(delta)
	fire_gun()
