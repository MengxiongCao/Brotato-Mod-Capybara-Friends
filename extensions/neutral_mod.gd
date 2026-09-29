extends "res://entities/units/neutral/neutral.gd"

onready var capybara_collision:Area2D = $Hurtbox
onready var capybara_area:CollisionShape2D = $Collision
var capybara_lootworm = []
var capybara_trees_attack_timer = null
var capybara_forest_players = []
var capybara_tree_is_shooting = 10
var capybara_color = Color.aquamarine
var capybara_weapon_tree_color = Color.chartreuse
var capybara_trees_has_added_proj_to_weapon = [false, false, false, false]

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, players_ref: Array = [], entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, players_ref, entity_spawner_ref)
	var capybara_burning_cooldown = 0
	for player_index in RunData.get_player_count():

		var capybara_burning_cooldown_reduction = RunData.get_player_effect(Keys.generate_hash("capybara_burning_cooldown_reduction") , player_index)
		for effect in capybara_burning_cooldown_reduction:
			var stat = RunData.get_stat(effect[0], player_index)
			var per = effect[1] / 100.0
			capybara_burning_cooldown += stat * per
	_burning_timer.wait_time = max(0.1, _burning_timer.wait_time / (max(0.1, 1 + capybara_burning_cooldown/100.0)))
	for player in players_ref:
		var player_index = player.player_index
		capybara_forest_players.append(player)
		var capybara_no_hurt_tree_effect = RunData.get_player_effect(Keys.generate_hash("capybara_no_hurt_tree"), player_index)
		if capybara_no_hurt_tree_effect.size() > 0:
			capybara_collision.set_deferred("monitoring", false)
			capybara_area.set_deferred("disabled", true)
			dead = true
		var capybara_trees_can_attack = RunData.get_player_effect(Keys.generate_hash("capybara_trees_can_attack"), player_index)
		if capybara_trees_can_attack.size() > 0:
			for effect in capybara_trees_can_attack:
				capybara_trees_attack_timer = Timer.new()
				capybara_trees_attack_timer.wait_time = effect.value / rand_range(0.6,1.5)
				capybara_trees_attack_timer.connect("timeout", self, "capybara_tree_should_attack")
				add_child(capybara_trees_attack_timer)
				capybara_trees_attack_timer.start()
				if not _animation_player.has_animation("capybara_tree_attack"):
					var anim = Animation.new()

					anim.length = 0.3

					var track = anim.add_track(Animation.TYPE_VALUE)
					anim.track_set_path(track, ".:scale")

					anim.track_insert_key(track, 0.0, Vector2.ONE)
					anim.track_insert_key(track, 0.15, Vector2(0.6, 1.5))
					anim.track_insert_key(track, 0.3, Vector2.ONE)

					_animation_player.add_animation("capybara_tree_attack", anim)

func _physics_process(delta) -> void:
	if not (_animation_player.current_animation == "capybara_tree_attack" or _animation_player.current_animation == "idle" or _animation_player.current_animation == "death"):
		_animation_player.play("idle")
	for player in capybara_forest_players:
		var player_index = player.player_index
		if player.capybara_should_check_trees:
			if (player.global_position - global_position).length() > 300:
				if capybara_trees_has_added_proj_to_weapon[player_index] and has_outline(capybara_weapon_tree_color):
					remove_outline(capybara_weapon_tree_color)
					player.capybara_trees -= 1
					capybara_trees_has_added_proj_to_weapon[player_index] = false
			else:
				if not capybara_trees_has_added_proj_to_weapon[player_index] and not has_outline(capybara_weapon_tree_color):
					capybara_trees_has_added_proj_to_weapon[player_index] = true
					add_outline(capybara_weapon_tree_color)
					player.capybara_trees += 1
					
		var capybara_trees_can_attack = RunData.get_player_effect(Keys.generate_hash("capybara_trees_can_attack"), player_index)
		if capybara_trees_can_attack.size() > 0:
			for effect in capybara_trees_can_attack:
				if (player.global_position - global_position).length() > 500:
					if has_outline(capybara_color):
						remove_outline(capybara_color)
				else:
					if not has_outline(capybara_color):
						add_outline(capybara_color)

func capybara_tree_should_attack() -> void: 
	var main = get_tree().current_scene
	if main._cleaning_up:
		dead = false
		return
	for player in capybara_forest_players:
		var player_index = player.player_index
		var capybara_trees_can_attack = RunData.get_player_effect(Keys.generate_hash("capybara_trees_can_attack"), player_index)
		if capybara_trees_can_attack.size() > 0:
			if (player.global_position - global_position).length() <= 500:
				_animation_player.play("capybara_tree_attack")
				for effect in capybara_trees_can_attack:
					capybara_tree_is_shooting = 10
					modulate = Color.aquamarine
					var capybara_projectile_stats = effect.weapon_stats
					var capybara_args: = WeaponServiceInitStatsArgs.new()
					var capybara_current_weapon_stats = WeaponService.init_ranged_stats(capybara_projectile_stats, player_index, false, capybara_args)
					var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
					capybara_projectile_arg.from_player_index = player_index
					var capybara_direction = rand_range(0, 2 * PI)
					var projectile = WeaponService.manage_capybara_spawn_protect_projectile(
						self,
						capybara_current_weapon_stats, 
						capybara_direction, 
						effect.auto_target_enemy,
						player._entity_spawner_ref,
						player, 
						capybara_projectile_arg
						)

func take_damage(value: int, args: TakeDamageArgs) -> Array:
	var capybara_result = .take_damage(value, args)
	return capybara_result
