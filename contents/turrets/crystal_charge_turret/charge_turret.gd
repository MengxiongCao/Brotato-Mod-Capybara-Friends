class_name CapybaraChargeTurret
extends "res://entities/structures/turret/turret.gd"

var capybara_white_outline_added: bool = false
var capybara_cooldown: float = 0.0
var capybara_cooldown_duration: float = 0.0


func _physics_process(delta: float) -> void:
	var capybara_in_range: bool = capybara_owner_in_range()
	if capybara_in_range and not has_outline(Color.white):
		add_outline(Color.white)
		capybara_white_outline_added = true
	elif not capybara_in_range and capybara_white_outline_added:
		if has_outline(Color.white):
			remove_outline(Color.white)
		capybara_white_outline_added = false
	if dead or not capybara_in_range:
		return
	capybara_cooldown -= 60 * delta
	if should_shoot():
		_is_shooting = true
		_animation_player.playback_speed = _shooting_speed
		_animation_player.play("shoot")


func capybara_owner_in_range() -> bool:
	var capybara_main = get_tree().current_scene
	if dead or _pending_die or not is_instance_valid(capybara_main) or not "_players" in capybara_main:
		return false
	if player_index < 0 or player_index >= capybara_main._players.size() or not is_instance_valid(_range_shape) or stats == null:
		return false
	var capybara_owner = capybara_main._players[player_index]
	if not is_instance_valid(capybara_owner) or capybara_owner.dead:
		return false
	var capybara_distance: float = _range_shape.global_position.distance_to(capybara_owner.global_position)
	return capybara_distance >= stats.min_range and capybara_distance <= stats.max_range


func shoot() -> void :
	if not capybara_owner_in_range():
		return
	_nb_shots_taken += 1
	var main = get_tree().current_scene
	SoundManager2D.play(Utils.get_rand_element(stats.shooting_sounds), global_position, stats.sound_db_mod, 0.2)
	main.capybara_spawn_consumable(global_position, [Keys.generate_hash("item_crystal_turret_charge")])
	if reset_shooting_speed_on_shoot:
		set_shooting_speed()
		reset_shooting_speed_on_shoot = false


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "shoot" and not dead:
		_is_shooting = false
		capybara_cooldown = _get_next_cooldown()
		capybara_cooldown_duration = max(0.0, capybara_cooldown)
		_animation_player.playback_speed = 1.0
		_animation_player.play("idle")


func should_shoot() -> bool:
	return capybara_cooldown <= 0 and not _is_shooting and capybara_owner_in_range()
