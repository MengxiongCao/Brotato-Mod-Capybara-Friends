extends "res://dlcs/dlc_1/effect_behaviors/enemy/charm_enemy_effect_behavior.gd"

var capybara_charm_timer = null
var capybara_charm_shoot_timer = null
var cp_boost_charm_color = Color("#C8A0AA")
var love_particles = load("res://mods-unpacked/Dbear-Capybara/contents/projectiles/love_particles.tscn")
var capybara_player = null

func charm(from_player_index: int) -> void:
	var capybara_charmed_enemies_attack = RunData.get_player_effect(Keys.generate_hash("capybara_charmed_enemies_attack"), from_player_index)
	var capybara_charm_time = RunData.get_player_effect(Keys.generate_hash("capybara_charm_time"), from_player_index)
	_charm_timer.wait_time = max(1, Utils.CHARM_DURATION + capybara_charm_time)
	if capybara_charm_time > 0:
		capybara_charm_timer = Timer.new()
		capybara_charm_timer.wait_time = Utils.CHARM_DURATION
		capybara_charm_timer.connect("timeout", self, "capybara_charm_boost_time_timeout")
		add_child(capybara_charm_timer)
		capybara_charm_timer.start()
	if capybara_charmed_enemies_attack.size() > 0:
		capybara_manage_charm_projectile(from_player_index)
	.charm(from_player_index)
	var capybara_main = _parent.get_tree().current_scene
	capybara_player = capybara_main._players[from_player_index]
	var capybara_call_for_love = RunData.get_player_effect(Keys.generate_hash("capybara_call_for_love"), from_player_index)
	if capybara_call_for_love.size() > 0:
		for effect in capybara_call_for_love:
			if effect[0] == Keys.generate_hash("stat_capybara_gold"):
				capybara_main.spawn_gold(effect[1], global_position, 50)
				RunData.add_tracked_value(from_player_index, Keys.generate_hash("item_cp_call_for_love"), effect[1])
			else:
				RunData.add_stat(effect[0], effect[1], from_player_index)

func capybara_manage_charm_projectile(player_index:int) -> void:
	var capybara_charmed_enemies_attack = RunData.get_player_effect(Keys.generate_hash("capybara_charmed_enemies_attack"), player_index)
	for effect in capybara_charmed_enemies_attack:
		capybara_charm_shoot_timer = Timer.new()
		capybara_charm_shoot_timer.wait_time = effect.value
		capybara_charm_shoot_timer.connect("timeout", self, "capybara_charm_shoot_time_timeout")
		add_child(capybara_charm_shoot_timer)
		capybara_charm_shoot_timer.start()
		break

func capybara_charm_shoot_time_timeout() -> void:
	var player_index = capybara_player.player_index
	var capybara_charmed_enemies_attack = RunData.get_player_effect(Keys.generate_hash("capybara_charmed_enemies_attack"), player_index)
	for effect in capybara_charmed_enemies_attack:
		if capybara_player and is_instance_valid(capybara_player) and is_instance_valid(_parent) and _parent.current_target and is_instance_valid(_parent.current_target):
			var capybara_args: = WeaponServiceInitStatsArgs.new()
			var weapon_stats = effect.weapon_stats
			var capybara_current_weapon_stats = WeaponService.init_ranged_stats(weapon_stats, player_index, false, capybara_args)
			var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
			capybara_projectile_arg.damage_tracking_key_hash = Keys.generate_hash(effect.custom_key)
			capybara_projectile_arg.from_player_index = player_index
			var capybara_direction = rand_range(0, 2*PI)
			var entity_from = self
			if not _parent.current_target is Player:
				entity_from = _parent.current_target
			var projectile = WeaponService.manage_capybara_spawn_projectile(
			entity_from,
			capybara_current_weapon_stats, 
			capybara_direction, 
			false,
			capybara_player._entity_spawner_ref,
			capybara_player, 
			capybara_projectile_arg
			)

func capybara_charm_boost_time_timeout() -> void:
	var love_particles_instance = love_particles.instance()
	love_particles_instance.name = "capybara_love_particles"
	if not _parent.has_node("capybara_love_particles"):
		_parent.add_child(love_particles_instance)
	var love_node = _parent.get_node_or_null("capybara_love_particles")
	if love_node:
		love_node.visible = true

func should_add_on_spawn() -> bool:
	var capybara_should_add = .should_add_on_spawn()
	var capybara_angel = []
	for player_index in RunData.get_player_count():
		capybara_angel.append(RunData.get_player_item(Keys.generate_hash("item_darkfish"), player_index))

	return capybara_should_add or capybara_angel.size() > 0

func _on_CharmTimer_timeout() -> void :
	._on_CharmTimer_timeout()
	if capybara_charm_shoot_timer:
		capybara_charm_shoot_timer.stop()
