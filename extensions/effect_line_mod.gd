extends "res://items/global/effect_line.gd"


func _display_effect(player_index: int, _effect: Effect, colored: bool = true, activate_tab: bool = true):
	if _effect == null or not is_instance_valid(_effect):
		queue_free()
		return

	._display_effect(player_index, _effect, colored, activate_tab)
