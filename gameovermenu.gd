extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim_rect: ColorRect = $ColorRect
	dim_rect.process_mode = Node.PROCESS_MODE_ALWAYS
	dim_rect.color.a = 0.0

	var retry_btn: Button = get_node_or_null("Button")
	var quit_btn: Button = get_node_or_null("Button2")

	if retry_btn:
		retry_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		if not retry_btn.pressed.is_connected(_on_retry_pressed):
			retry_btn.pressed.connect(_on_retry_pressed)
	else:
		print("WARNING: Retry button 'Button' not found in gameovermenu.tscn")

	if quit_btn:
		quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		if not quit_btn.pressed.is_connected(_on_quit_pressed):
			quit_btn.pressed.connect(_on_quit_pressed)
	else:
		print("WARNING: Quit button 'Button2' not found in gameovermenu.tscn")

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(dim_rect, "color:a", 0.6, 1.0)

func _on_retry_pressed() -> void:
	print("RETRY pressed")
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	print("QUIT pressed")
	get_tree().paused = false
	Global.clear_assembly()

	var tree := get_tree()
	var root := tree.root
	var global_node := get_node_or_null("/root/Global")

	# Remove everything under root except the Global autoload
	for child in root.get_children():
		if child == global_node:
			continue
		root.remove_child(child)
		child.queue_free()

	var new_scene_resource: PackedScene = load("res://start_menu.tscn")
	var new_scene: Node = new_scene_resource.instantiate()
	root.add_child(new_scene)
	tree.current_scene = new_scene
