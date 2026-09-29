class_name CapybaraForestBow
extends "res://weapons/ranged/ranged_weapon.gd"

onready var cp_forest_bow_arrow = $Sprite/arrow
var cp_forest_bow_player = null
var cp_forest_bow_angle = PI/3.0
var cp_forest_bow_arrows = []
var cp_forest_bow_muzzle_position = Vector2.ZERO

func _ready() -> void:
	cp_forest_bow_player = get_parent().get_parent()
	cp_forest_bow_arrows.append(cp_forest_bow_arrow)
	cp_forest_bow_muzzle_position = muzzle.position

func _physics_process(_delta) -> void:
	var nb_proj = current_stats.nb_projectiles
	if is_instance_valid(cp_forest_bow_player):
		nb_proj += cp_forest_bow_player.capybara_trees
	nb_proj = max(int(nb_proj), 1)

	_capybara_update_arrow_count(nb_proj)
	_capybara_update_arrow_display(nb_proj)


func _capybara_update_arrow_count(nb_proj: int) -> void:
	while cp_forest_bow_arrows.size() < nb_proj:
		var new_arrow = cp_forest_bow_arrow.duplicate()
		cp_forest_bow_arrows.append(new_arrow)
		sprite.add_child(new_arrow)

	while cp_forest_bow_arrows.size() > nb_proj:
		var arrow_to_remove = cp_forest_bow_arrows.pop_back()
		if arrow_to_remove != cp_forest_bow_arrow and is_instance_valid(arrow_to_remove):
			arrow_to_remove.queue_free()


func _capybara_update_arrow_display(nb_proj: int) -> void:
	var arrows_are_visible = sprite.texture != stats.custom_on_cooldown_sprite
	var displayed_muzzle_position = cp_forest_bow_muzzle_position

	# Sprite.flip_v只翻转贴图，不会镜像Muzzle和箭矢这些子节点。
	if sprite.flip_v:
		displayed_muzzle_position.y = -displayed_muzzle_position.y

	muzzle.position = displayed_muzzle_position
	var angle_step = cp_forest_bow_angle / (nb_proj + 1)

	for arrow_id in cp_forest_bow_arrows.size():
		var arrow = cp_forest_bow_arrows[arrow_id]
		arrow.position = muzzle.position
		arrow.rotation = -cp_forest_bow_angle / 2.0 + (arrow_id + 1) * angle_step
		arrow.flip_v = sprite.flip_v
		arrow.visible = arrows_are_visible
