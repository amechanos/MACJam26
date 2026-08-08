# Core.gd
extends Node2D
class_name Core

@export var component_size: Vector2 = Vector2(1, 1)
var rotation_index: int = 0
var grid_pos: Vector2i
var movable: bool = false
