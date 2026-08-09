extends BaseEnemy
class_name BomberEnemy

@export var cannon_scene: PackedScene

func _ready() -> void:
	health = 200.0
	speed = 1.0
	min_interval = 2.0
	max_interval = 4.0
	min_angle_degrees = 165.0
	max_angle_degrees = 205.0
	angular_velocity = 0.35
	min_offset = Vector2(-100.0, -100.0)
	max_offset = Vector2(100.0, 100.0)
	scroll_speed = 35.0
	xp = 3.0
	
	super._ready()
	if cannon_scene == null:
		print("GunnerEnemy: 'cannon_scene' is not assigned in the Inspector!")
		return
		
	var cannon_instance = cannon_scene.instantiate()
	if cannon_instance is not WeaponBase:
		print("cannon_instance is not a weapon!")
		return
	
	# Hide the weapon
	var body = cannon_instance.get_node_or_null("body") as ColorRect
	var head = cannon_instance.get_node_or_null("head") as ColorRect
	if body: body.hide()
	if head: head.hide()
	
	cannon_instance.from_player = false
	add_child(cannon_instance)
	
	gun_list.append(cannon_instance)
	gun_orientation.append(0.0)

func _process(delta: float) -> void:
	super._process(delta)
	fire_gun()
