extends BaseProjectile

func _ready() -> void:
	damage = 50.0
	pierce = 1

func destroy_projectile():
	# Explosion logic
	queue_free()
