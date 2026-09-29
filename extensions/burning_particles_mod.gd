extends "res://particles/burning/burning_particles.gd"

func _update_color() -> void:
	var capybara_burning_color = capybara_get_burning_color()
	._update_color()
	if capybara_burning_color:
		var capybara_gradient = capybara_create_shade_gradient(capybara_burning_color)
		color_ramp = capybara_gradient
		secondary_particles.color_ramp = capybara_gradient
		secondary_particles.color_initial_ramp = capybara_gradient


func capybara_get_burning_color():
	if burning_data == null:
		return null
	var stat_key = Utils.get_first_scaling_stat(burning_data.scaling_stats)
	if stat_key == Keys.stat_harvesting_hash or stat_key == Keys.stat_armor_hash or stat_key == Keys.stat_melee_damage_hash:
		return Color.gold
	elif stat_key == Keys.stat_hp_regeneration_hash or stat_key == Keys.stat_max_hp_hash or stat_key == Keys.generate_hash("stat_capybara_gold"):
		return Color.green
	elif stat_key == Keys.stat_curse_hash or stat_key == Keys.stat_ranged_damage_hash or stat_key == Keys.stat_range_hash or stat_key == Keys.generate_hash("stat_capybara_enemies_killed"):
		return Color.purple
	elif stat_key == Keys.stat_percent_damage_hash or stat_key == Keys.stat_crit_chance_hash or stat_key == Keys.stat_crit_damage_hash or stat_key == Keys.stat_lifesteal_hash:
		return Color.red
	elif stat_key == Keys.stat_dodge_hash:
		return Color.cornflower
	elif stat_key == Keys.stat_luck_hash or stat_key == Keys.generate_hash("stat_capybara_crystal") or stat_key == Keys.stat_speed_hash or stat_key == Keys.stat_attack_speed_hash:
		return Color.aliceblue
	return null

func capybara_create_shade_gradient(capybara_color: Color) -> Gradient:
	var capybara_gradient: Gradient = Gradient.new()
	var capybara_hue: float = capybara_color.h
	var capybara_saturation: float = capybara_color.s
	var capybara_brightness: float = capybara_color.v
	var capybara_alpha: float = capybara_color.a
	var capybara_darkest: Color = Color.from_hsv(capybara_hue, capybara_saturation, clamp(capybara_brightness * 0.25, 0.0, 1.0), capybara_alpha)
	var capybara_dark: Color = Color.from_hsv(capybara_hue, capybara_saturation, clamp(capybara_brightness * 0.55, 0.0, 1.0), capybara_alpha)
	var capybara_light: Color = Color.from_hsv(capybara_hue, capybara_saturation * 0.75, lerp(capybara_brightness, 1.0, 0.45), capybara_alpha)
	var capybara_lightest: Color = Color.from_hsv(capybara_hue, capybara_saturation * 0.4, lerp(capybara_brightness, 1.0, 0.8), 0.0)
	capybara_gradient.offsets = PoolRealArray([0.0, 0.25, 0.55, 0.8, 1.0])
	capybara_gradient.colors = PoolColorArray([capybara_darkest, capybara_dark, capybara_color, capybara_light, capybara_lightest])
	return capybara_gradient
