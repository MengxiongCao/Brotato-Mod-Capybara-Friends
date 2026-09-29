extends "res://entities/units/enemies/enemy.gd"
var capybara_is_crystallized = false
var capybara_is_linked = false
var capybara_is_mutated = false
var capybara_is_duplicated_enemy = false
var capybara_crystal_boost = 0.0
var capybara_duplicated_timer = null
var capybara_max_duplicated = 1
var capybara_current_duplicated = 0
const CAPYBARA_MUTATION_SIZE_FACTOR := 1.1
var capybara_original_sprite_scale := Vector2.ONE
var capybara_original_collision_scale := Vector2.ONE
var capybara_original_hurtbox_scale := Vector2.ONE
var capybara_original_hitbox_scale := Vector2.ONE
var capybara_original_can_be_boosted := false
var capybara_mutation_hp_boost := 0
var capybara_mutation_damage_boost := 0
var capybara_mutation_speed_boost := 0
var capybara_mutation_scene = load("res://mods-unpacked/Dbear-Capybara/materials/capybara_flow_light.tscn")
var capybara_crystallization_scene = load("res://mods-unpacked/Dbear-Capybara/extensions/enemy_effect_behaviour/crystallized_enemy_effect_behavior.tscn")

	
func _ready() -> void:
	for player_index in RunData.get_player_count():
		if RunData.get_player_effect(Keys.generate_hash("capybara_curse_bosses"), player_index) > 0 and "is_elite" in self:
			capybara_manage_curse(self)
	capybara_original_sprite_scale = sprite.scale
	capybara_original_collision_scale = _collision.scale
	capybara_original_hurtbox_scale = _hurtbox.scale
	capybara_original_hitbox_scale = _hitbox.scale
	capybara_original_can_be_boosted = can_be_boosted
	var capybara_burning_cooldown = 0
	for player_index in RunData.get_player_count():
		var capybara_burning_cooldown_reduction = RunData.get_player_effect(Keys.generate_hash("capybara_burning_cooldown_reduction") , player_index)
		for effect in capybara_burning_cooldown_reduction:
			var stat = RunData.get_stat(effect[0], player_index)
			var per = effect[1] / 100.0
			capybara_burning_cooldown += stat * per
	_burning_timer.wait_time = max(0.1, _burning_timer.wait_time / (max(0.1,1 + capybara_burning_cooldown/100.0)))

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
	_capybara_reset_mutation()
	_capybara_manage_mutation()
	

func apply_burning(burning_data: BurningData) -> void:
	.apply_burning(burning_data)
	if dead or _burning == null or not is_instance_valid(_burning_particles):
		return
	var capybara_burning_color = capybara_get_burning_color(_burning)
	if capybara_burning_color == null:
		return
	var capybara_gradient = capybara_create_burning_shade_gradient(capybara_burning_color)
	_burning_particles.color_ramp = capybara_gradient
	if is_instance_valid(_burning_particles.secondary_particles):
		_burning_particles.secondary_particles.color_ramp = capybara_gradient
		_burning_particles.secondary_particles.color_initial_ramp = capybara_gradient

func capybara_get_burning_color(burning_data: BurningData):
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

func capybara_create_burning_shade_gradient(capybara_color: Color) -> Gradient:
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

func take_damage(value: int, args: TakeDamageArgs) -> Array:
	var crystal_hawk_effects = RunData.get_player_effect(Keys.generate_hash("capybara_gain_stat_when_killed_hunt"), args.from_player_index)
	var capybara_value = value
	if args.has_meta("capybara_burn_can_crit"):
		args.remove_meta("capybara_burn_can_crit")
	var cp_marked = get_node_or_null("capybara_marked")
	if cp_marked and cp_marked.visible and value >= current_stats.health and crystal_hawk_effects.size() > 0:
		print("capybara_hunted")
		if not args.has_meta("capybara_hunted"):
			args.set_meta("capybara_hunted",true)
	else:
		if args.has_meta("capybara_hunted"):
			args.remove_meta("capybara_hunted")
	
	if args.is_burning and not args.hitbox and args.from_player_index >= 0:
		capybara_manage_burning(value, args)
		var player_index = args.from_player_index
		var burn_crit_chance = RunData.get_player_effect(Keys.generate_hash("capybara_burning_can_crit"), player_index)
		if burn_crit_chance > 0:
			var crit_chance = Utils.get_stat(Keys.stat_crit_chance_hash, player_index)/100.0
			var crit_damage = burn_crit_chance
			if Utils.get_chance_success(crit_chance):
				capybara_value = crit_damage * value
				if not args.has_meta("capybara_burn_can_crit"):
					args.set_meta("capybara_burn_can_crit", true)
			elif args.has_meta("capybara_burn_can_crit"):
				args.remove_meta("capybara_burn_can_crit")
	var capybara_result = .take_damage(capybara_value, args)
	return capybara_result

func capybara_manage_burning(value: int, args:TakeDamageArgs) -> void:
	if args.has_meta("capybara_bonus_burning"):
		args.remove_meta("capybara_bonus_burning")
	var capybara_burning_cooldown = 0
	var capybara_burning_cooldown_reduction = RunData.get_player_effect(Keys.generate_hash("capybara_burning_cooldown_reduction") , args.from_player_index)
	for effect in capybara_burning_cooldown_reduction:
		var stat = Utils.get_stat(effect[0], args.from_player_index)
		var per = effect[1] / 100.0
		capybara_burning_cooldown += stat * per
	capybara_burning_cooldown /= 100.0
	var cp_burning_cooldown_reduction = RunData.sum_all_player_effects(Keys.burning_cooldown_reduction_hash) / 100.0
	var times = (cp_burning_cooldown_reduction + capybara_burning_cooldown) as int
	var ftimes = cp_burning_cooldown_reduction + capybara_burning_cooldown
	var damage_change = fmod(max(0.0, ftimes - 1.0), 1.0)
	if not damage_change > 0:
		return
	for i in times:
		if not dead:
			yield(get_tree().create_timer(0.1),"timeout")
			if dead:
				return
			args.set_meta("capybara_bonus_burning", true)
			args.is_burning = false
			var new_value = value
			if not i < times - 1:
				new_value = (value * damage_change) as int
			var new_result = take_damage(max(1,new_value), args)

func _capybara_manage_mutation() -> void:
	var capybara_mutation_chance = 0.0
	var capybara_total_crystal_stat = 0.0
	for player_id in RunData.get_player_count():
		var capybara_crystal_stat = Utils.get_stat(Keys.generate_hash("stat_capybara_crystal"), player_id)
		capybara_total_crystal_stat += capybara_crystal_stat
		capybara_mutation_chance += min(Utils.CAPYBARA_MUTATION_CAP_CHANCE, Utils.capybara_get_factor(capybara_crystal_stat))/100.0
	if Utils.get_chance_success(min(1.0, capybara_mutation_chance)):
		_capybara_crystal_boost_enemy(capybara_total_crystal_stat)
#	min(1.0, capybara_mutation_chance)

func respawn() -> void :
	.respawn()
	capybara_is_duplicated_enemy = false
	capybara_current_duplicated = 0
	if is_instance_valid(capybara_duplicated_timer):
		capybara_duplicated_timer.stop()
	var cp_marked = get_node_or_null("capybara_marked")
	if cp_marked:
		cp_marked.visible = false
	var cp_love_node = get_node_or_null("capybara_love_particles")
	if cp_love_node:
		cp_love_node.visible = false
	capybara_is_crystallized = false
	capybara_is_linked = false
	modulate = Color.white
	_capybara_reset_mutation()
	_capybara_manage_mutation()

func boost(boost_args: BoostArgs) -> void:
	if not capybara_is_mutated:
		.boost(boost_args)
		return

	var capybara_combined_boost_args := BoostArgs.new()
	capybara_combined_boost_args.hp_boost = boost_args.hp_boost + capybara_mutation_hp_boost
	capybara_combined_boost_args.damage_boost = boost_args.damage_boost + capybara_mutation_damage_boost
	capybara_combined_boost_args.speed_boost = boost_args.speed_boost + capybara_mutation_speed_boost
	capybara_combined_boost_args.range_boost = boost_args.range_boost
	capybara_combined_boost_args.attack_speed_boost = boost_args.attack_speed_boost
	capybara_combined_boost_args.show_outline = boost_args.show_outline
	.boost(capybara_combined_boost_args)

func _capybara_crystal_boost_enemy(boost: float) -> void :
	if dead:
		return

	var capybara_capped_boost = max(0.0, min(boost, Utils.CAPYBARA_MUTATION_CAP_BOOST))
	capybara_is_mutated = true
	capybara_mutation_hp_boost = int(300 + capybara_capped_boost * 10)
	capybara_mutation_speed_boost = 50
	can_be_boosted = true

	var boost_args: = BoostArgs.new()
	boost_args.hp_boost = capybara_mutation_hp_boost
	boost_args.damage_boost = capybara_mutation_damage_boost
	boost_args.speed_boost = capybara_mutation_speed_boost
	boost_args.show_outline = false
	if not sprite.get_node_or_null("capybara_mutation_flow_light"):
		var instance = capybara_mutation_scene.instance()
		instance.name = "capybara_mutation_flow_light"
		sprite.add_child(instance)
	capybara_set_mutation_size(true)
	if not capybara_is_duplicated_enemy and capybara_current_duplicated < capybara_max_duplicated:
		if not is_instance_valid(capybara_duplicated_timer):
			capybara_duplicated_timer = Timer.new()
			capybara_duplicated_timer.wait_time = 3
			capybara_duplicated_timer.connect("timeout", self, "capybara_manage_duplicated_enemy")
			add_child(capybara_duplicated_timer)
		capybara_crystal_boost = boost
		if capybara_duplicated_timer.is_stopped():
			capybara_duplicated_timer.start()
	.boost(boost_args)

func _capybara_reset_mutation() -> void:
	capybara_is_mutated = false
	capybara_mutation_hp_boost = 0
	capybara_mutation_damage_boost = 0
	capybara_mutation_speed_boost = 0
	can_be_boosted = capybara_original_can_be_boosted
	capybara_set_mutation_size(false)

	for child in sprite.get_children():
		if "capybara_mutation_flow_light" in child.name:
			sprite.remove_child(child)
			child.queue_free()

func capybara_set_mutation_size(is_mutated: bool) -> void:
	var size_factor := CAPYBARA_MUTATION_SIZE_FACTOR if is_mutated else 1.0
	var facing := -1.0 if sprite.scale.x < 0.0 else 1.0

	sprite.scale = Vector2(abs(capybara_original_sprite_scale.x) * facing, capybara_original_sprite_scale.y) * size_factor
	_collision.scale = capybara_original_collision_scale * size_factor
	_hurtbox.scale = capybara_original_hurtbox_scale * size_factor
	_hitbox.scale = capybara_original_hitbox_scale * size_factor

func capybara_manage_duplicated_enemy() -> void:
	if capybara_is_duplicated_enemy or not capybara_is_mutated or capybara_current_duplicated >= capybara_max_duplicated:
		if is_instance_valid(capybara_duplicated_timer):
			capybara_duplicated_timer.stop()
		return
	var boost = capybara_crystal_boost
	var main = get_tree().current_scene
	if not is_instance_valid(main) or main._cleaning_up:
		return
	var duplicated_enemy = main.capybara_spawn_enemy(self, global_position)
	if not is_instance_valid(duplicated_enemy):
		return
	capybara_current_duplicated += 1
	duplicated_enemy.capybara_is_duplicated_enemy = true
	duplicated_enemy.capybara_current_duplicated = duplicated_enemy.capybara_max_duplicated
	duplicated_enemy.can_drop_loot = false
	duplicated_enemy._capybara_crystal_boost_enemy(boost)

func _capybara_curse_enemy(enemy: Enemy, curse: float) -> void :
	if not is_instance_valid(enemy) or enemy.dead:
		return

	enemy.add_outline(Utils.CURSE_COLOR)

	var boost_args: = BoostArgs.new()
	boost_args.hp_boost = 200 + min(curse, 300) * 2
	boost_args.damage_boost = 50
	boost_args.speed_boost = 75
	boost_args.show_outline = false
	enemy.boost(boost_args)
	enemy.can_be_boosted = false

func capybara_manage_curse(enemy: Enemy) -> void :

	var curse = 0
	var curse_chance = 0.0
	var nb_players = RunData.get_player_count()
	enemy.can_be_boosted = true
	enemy.can_be_cursed = true

	for player_index in nb_players:
		var curse_stat = max(0, Utils.get_max_capped_stat(Keys.stat_curse_hash, player_index)) as int
		var player_curse_stat = curse_stat
		curse += player_curse_stat
		var player_curse_chance = min(1.0, (Utils.get_curse_factor(player_curse_stat) / 100.0 / 2.0) * (1.0 + (RunData.get_endless_factor() / 2.0)))
		curse_chance += player_curse_chance

	if (Utils.get_chance_success(curse_chance / nb_players) or DebugService.always_curse or DebugService.curse_enemy_spawn) and enemy.can_be_cursed:
		_capybara_curse_enemy(enemy, curse)
