extends "res://dlcs/dlc_1/effect_behaviors/enemy/curse_enemy_effect_behavior.gd"

func get_bonus_damage(hitbox: Hitbox, from_player_index: int) -> int:
	var capybara_bonus_damage = .get_bonus_damage(hitbox, from_player_index)
	return capybara_bonus_damage + RunData.get_player_effect(Keys.generate_hash("capybara_bonus_damage_against_cursed"), from_player_index) as int
