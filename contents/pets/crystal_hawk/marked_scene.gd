extends Node2D

var _parent

func _ready() -> void:
	_parent = get_parent()

func _physics_process(delta)->void:
	if _parent and is_instance_valid(_parent) and "dead" in _parent:
		if _parent.dead:
			visible = false
