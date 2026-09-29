extends "res://singletons/entity_service.gd"

func sort_turrets_by_strength(a: TurretEffect, b: TurretEffect) -> bool:
	var custom_order = [
		"effect_builder_turret_alt",
		"effect_turret_rocket",
		"effect_turret_laser",
		"effect_tyler",
		"effect_turret_flame",
		"effect_turret",
		"effect_turret_healing",
		"EFFECT_TURRET_FAIRY",
		"EFFECT_CAPYBARA_WT",
		"EFFECT_WEAPON_CAPYBARA_WT",
		"EFFECT_CAPYBARA_CRYSTAL_TURRET",
		"FANTASY_PRISM_TOWER_MAIN",
		"EFFECT_CAPYBARA_CHARGE_TURRET",
	]

	# 安全查找
	var ai = custom_order.find(a.text_key)
	var bi = custom_order.find(b.text_key)

	# ✅ 关键：找不到就返回原版排序，绝对不崩
	if ai == -1 or bi == -1:
		return .sort_turrets_by_strength(a, b)

	return ai < bi
