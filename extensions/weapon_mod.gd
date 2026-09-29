extends "res://weapons/weapon.gd"

signal capybara_weapon_hit_something(thing_hit,damage_dealt)
signal capybara_weapon_killed_something(thing_killed,hitbox,player_index)

var capybara_master = false
var capybara_should_spawn_special_projectiles = false
var capybara_is_pet_weapon = false
var capybara_master_attack_speed = 15.0
var capybara_null_effect = load("res://mods-unpacked/Dbear-Capybara/contents/characters/capybara_null_effect.tres")
var capybara_min_master_cooldown = 0.3
var capybara_crystal_particles = load("res://mods-unpacked/Dbear-Capybara/contents/projectiles/capybara_crystal_particles.tscn")
var capybara_sword_projectile = []
var capybara_player = null
var capybara_can_shoot = true
var capybara_should_reload_stats = false

func _ready() -> void:
	capybara_is_pet_weapon = capybara_check_is_pet_weapon()
	for effect in effects:
		if effect is WeaponGainStatForEveryStatEffect:
			capybara_should_reload_stats = true
	var capybara_init_stats = RunData.get_player_effect(Keys.generate_hash("change_way_of_attack"), player_index)
	if capybara_init_stats.size() > 0:
		for effect in capybara_init_stats:
			if effect.custom_key == "master":
				capybara_should_spawn_special_projectiles = true
				capybara_master = true
				var size_mod = min(max(135.0/sprite.texture.get_width(), 0.8), 1.0)
				scale *= size_mod
				if RunData.get_player_item(Keys.generate_hash("item_master_swords_box"), player_index):
					visible = false
				

#				if current_stats is MeleeWeaponStats:
#					sprite.visible = false

	for effect in RunData.get_player_effect(Keys.generate_hash("capybara_gain_stat_when_attack_killed_enemies"), player_index):
		if effects.size() <= 0:
			effects.append(capybara_null_effect)

	for effect in RunData.get_player_effect(Keys.generate_hash("capybara_gain_box_when_crit"), player_index):
		if effects.size() <= 0:
			effects.append(capybara_null_effect)
	capybara_player = get_parent().get_parent()

	update_highlighting()


func capybara_get_muzzle() -> Vector2:
	return muzzle.global_position


func capybara_check_is_pet_weapon() -> bool:
	return false


func update_highlighting() -> void:
	.update_highlighting()

	for effect in effects:
		if effect.custom_key == "capybara_is_crystallized":
			var instance = capybara_crystal_particles.instance()
			var size_mod = max(1,(sprite.texture.get_size().x/100.0 - 1)/2 + 1)

			instance.scale = Vector2(0.6 * size_mod, 0.6 * size_mod)
			instance.position = Vector2(sprite.texture.get_size().x/8.0 , 0)
			instance.amount = tier + 1

			if tier <= 0:
				outline_shader_mat.set_shader_param("outline_color_0", Color.white)
			else:
				outline_shader_mat.set_shader_param("outline_color_1", Color.white)

			outline_shader_mat.set_shader_param("texture_size", sprite.texture.get_size())
			outline_shader_mat.set_shader_param("alpha", 1.0)
			outline_shader_mat.set_shader_param("desaturation", 0.0)

			sprite.material = outline_shader_mat

			if is_instance_valid(outline_sprite):
				outline_sprite.visible = true

			sprite.add_child(instance)


var _capybara_kill_count_by_attack_id = {}


func on_killed_something(_thing_killed: Node, hitbox: Hitbox) -> void:
	var cp_attack_id: = hitbox.player_attack_id

	if cp_attack_id >= 0:
		var main:Main = get_tree().current_scene
		var attack_kill_count = _capybara_kill_count_by_attack_id.get(cp_attack_id, 0)

		attack_kill_count += 1
		_capybara_kill_count_by_attack_id[cp_attack_id] = attack_kill_count

		for effect in RunData.get_player_effect(Keys.generate_hash("capybara_gain_stat_when_attack_killed_enemies"), player_index):
			assert(effect[0] is int)

			var stat_hash = effect[0]
			var stat_value = effect[1]

			if attack_kill_count % effect[2] == 0:
				RunData.add_stat(stat_hash, stat_value, player_index)

				if stat_hash == Keys.generate_hash("stat_capybara_gold") and RunData.get_player_character(player_index).my_id_hash == Keys.generate_hash("character_cp_comet_cowboy"):
					RunData.add_tracked_value(player_index, Keys.generate_hash("character_cp_comet_cowboy"), stat_value)

	.on_killed_something(_thing_killed, hitbox)

	emit_signal("capybara_weapon_killed_something",_thing_killed,hitbox,player_index)

	var player_id = player_index
	var capybara_weapons = RunData.get_player_weapons(player_id)
	var capybara_has_set = false
	var capybara_effects = RunData.get_player_effect(Keys.generate_hash("gain_stats_every_killed_enemy_with_weapon_class"), player_id)

	for weapon in capybara_weapons:
		if capybara_effects.size() > 0:
			for set in weapon_sets:
				for effect in capybara_effects:
					if set.my_id == Keys.hash_to_string[effect[0]].replace("weapon_class_", "set_"):
						capybara_has_set = true

	if capybara_has_set:
		for effect in capybara_effects:
			if _thing_killed is Looter:
				RunData.add_stat(effect[2], effect[1], player_id)
				RunData.add_tracked_value(player_index, Keys.generate_hash("item_enjoy_the_music"), effect[1])


func capybara_manage_bounce_hit(thing_hit, damage_dealt, damage_decrease:float, x:int, hitbox:Hitbox) -> void:
	var target = null

	if thing_hit is Enemy:
		for i in x:
			if not is_instance_valid(thing_hit):
				return

			yield(get_tree().create_timer(0.1),"timeout")

			target = thing_hit._entity_spawner_ref.get_rand_enemy(thing_hit)

			var args = TakeDamageArgs.new(player_index, hitbox)

			damage_dealt *= damage_decrease

			if is_instance_valid(target):
				target.take_damage(damage_dealt, args)

			thing_hit = target

	hitbox.remove_meta("capybara_bounce_hit")


func capybara_manage_x_hit(thing_hit, damage_dealt, damage_decrease:float, x:int, hitbox:Hitbox) -> void:
	if thing_hit is Enemy:
		for i in x:
			yield(get_tree().create_timer(0.1),"timeout")

			var args = TakeDamageArgs.new(player_index, hitbox)

			damage_dealt *= damage_decrease

			if is_instance_valid(thing_hit):
				thing_hit.take_damage(damage_dealt, args)

	hitbox.remove_meta("capybara_x_hit")


func capybara_temp_break() -> void:
	SoundManager.play(Utils.get_rand_element(WeaponService.breaking_sounds), -15, 0.1, true)

	var temp_m = modulate.a

	modulate.a = temp_m * 0.3
	if is_instance_valid(_range_shape):
		_range_shape.set_deferred("disabled", true)

	var wait_time = rand_range(0.5,1.0) + stats.cooldown/60.0

	yield(get_tree().create_timer(wait_time), "timeout")

	if not is_instance_valid(self):
		return

	if is_instance_valid(_range_shape):
		_range_shape.set_deferred("disabled", false)
	modulate.a = 1


func capybara_spawn_projectiles(thing_hit: Node, weapon_stats:RangedWeaponStats, value:int, auto_target_enemy:bool) -> void:
	for i in value:
		if thing_hit:
			var stats = weapon_stats

			stats = WeaponService.init_ranged_stats(weapon_stats, player_index, true)

			var main = get_parent().get_parent().get_tree().current_scene
			var from = main._players[player_index]
			var cp_args = WeaponServiceSpawnProjectileArgs.new()

			cp_args.from_player_index = player_index

			var _projectile = WeaponService.manage_special_spawn_projectile(
				thing_hit,
				stats,
				rand_range(-PI, PI),
				auto_target_enemy,
				main._entity_spawner,
				from,
				cp_args
			)


func _capybara_projectile_on_hit(_thing_hit:Node) -> void:
	pass


func capybara_spawn_special_projectiles(spawn_pos:Vector2, _thing_hit:Node) -> void:
	if not capybara_should_spawn_special_projectiles:
		return

	if "capybara_should_shot_sword_wave" in self:
		if self.capybara_should_shot_sword_wave:
			_capybara_projectile_on_hit(_thing_hit)

#	for effect in effects:
#		if effect.key == "capybara_lotus_text":
#			var capybara_args: = WeaponServiceInitStatsArgs.new()
#			var capybara_current_weapon_stats = WeaponService.init_ranged_stats(effect.weapon_stats, player_index, false, capybara_args)
#			var capybara_count:int = effect.value
#
#			for i in range(0,capybara_count):
#				var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
#
#				capybara_projectile_arg.from_player_index = player_index
#
#				var capybara_direction = rand_range(0, 2 * PI)
#
#				WeaponService.spawn_projectile(
#					spawn_pos,
#					capybara_current_weapon_stats,
#					capybara_direction,
#					self,
#					capybara_projectile_arg
#				)
#
#		if effect.key == "capybara_light_saber_text":
#			var capybara_args: = WeaponServiceInitStatsArgs.new()
#			var capybara_current_weapon_stats = WeaponService.init_ranged_stats(effect.weapon_stats, player_index, false, capybara_args)
#			var capybara_count:int = effect.value
#
#			for i in range(0,capybara_count):
#				var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
#				var capybara_rand_direction = (2.0*PI/capybara_count)*(i+1)
#
#				WeaponService.spawn_projectile(
#					spawn_pos,
#					capybara_current_weapon_stats,
#					capybara_rand_direction,
#					self,
#					capybara_projectile_arg
#				)


func on_weapon_hit_something(_thing_hit: Node, damage_dealt: int, hitbox: Hitbox) -> void:
	.on_weapon_hit_something(_thing_hit, damage_dealt, hitbox)

	capybara_spawn_special_projectiles(_thing_hit.global_position, _thing_hit)

	for effect in effects:
		if effect.key == "capybara_projectiles_on_hit":
			capybara_spawn_projectiles(_thing_hit, effect.weapon_stats, effect.value, effect.auto_target_enemy)

	if hitbox:
		emit_signal("capybara_weapon_hit_something",_thing_hit, hitbox.damage)

		for effect in effects:
			if effect.key_hash == Keys.generate_hash("capybara_x_hit"):
				if not hitbox.has_meta("capybara_x_hit"):
					hitbox.set_meta("capybara_x_hit", true)
					capybara_manage_x_hit(_thing_hit, hitbox.damage, effect.value2/100.0, effect.value, hitbox)

			if effect.key_hash == Keys.generate_hash("capybara_bounce_hit"):
				if not hitbox.has_meta("capybara_bounce_hit"):
					hitbox.set_meta("capybara_bounce_hit", true)

				capybara_manage_bounce_hit(_thing_hit, hitbox.damage, effect.value2/100.0, effect.value, hitbox)

			if effect.key_hash == Keys.generate_hash("capybara_break_on_hit"):
				if Utils.get_chance_success(effect.value/100.0):
					capybara_temp_break()

	var capybara_explosion_effect = RunData.get_player_effect(Keys.generate_hash("capybara_thunder"), player_index)
	var capybara_projectile_on_hit_effect = RunData.get_player_effect(Keys.generate_hash("capybara_fire"), player_index)

	if capybara_projectile_on_hit_effect.size() > 0:
		for effect in capybara_projectile_on_hit_effect:
			var chance = 0.5

			if effect.custom_key == "fire":
				chance = chance*(stats.cooldown/(5.0 + stats.cooldown))

			if stats is MeleeWeaponStats:
				chance *= 2

			if not Utils.get_chance_success(chance):
				continue

			for i in effect.value:
				var sp_capybara_args: = WeaponServiceInitStatsArgs.new()
				var sp_capybara_projectile_stats = effect.weapon_stats
				var sp_capybara_current_weapon_stats = WeaponService.init_ranged_stats(sp_capybara_projectile_stats, player_index, false, sp_capybara_args)
				var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()

				capybara_projectile_arg.from_player_index = player_index

				var cp_d:float = get_direction()

				cp_d = rand_range(cp_d - PI/3,cp_d + PI/3)

				var p:PlayerProjectile = WeaponService.spawn_projectile(
					_thing_hit.global_position,
					sp_capybara_current_weapon_stats,
					cp_d,
					self,
					capybara_projectile_arg
				)

				if effect.custom_key == "fire":
					var p_hitbox:Hitbox = p._hitbox

					p_hitbox.burning_data = WeaponService.init_burning_data(effect.burning_stats, player_index,false,false)
					p_hitbox.from = self

	if capybara_explosion_effect.size() > 0:
		for ex_effect in capybara_explosion_effect:
			if ex_effect.custom_key == "master":
				continue
			var args = WeaponServiceExplodeArgs.new()
			var capybara_main:Main = get_parent().get_parent().get_tree().current_scene
			var capybara_players = capybara_main._players
			var stats_arg = WeaponServiceInitStatsArgs.new()

#			if ex_effect is int :
#				var weapon_stats_new = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/thunder/explosion_stats.tres")
#				var weapon_stats = WeaponService.init_melee_stats(weapon_stats_new, player_index, stats_arg)
#				ex_effect = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/thunder/junior_sister_effect_0.tres")
#				var value = 0
#				for effect in capybara_explosion_effect:
#					value += 1
#					print(value)
#				capybara_players[player_index].capybara_explode(weapon_stats, ex_effect, value, _thing_hit.global_position, args)
#			else:

			var weapon_stats = WeaponService.init_melee_stats(ex_effect.stats, player_index, stats_arg)
			var exploding_dmg_bonus = (Utils.get_stat(Keys.explosion_damage_hash, player_index) / 100.0)
			var explode_weapon_stats:MeleeWeaponStats = MeleeWeaponStats.new()

			explode_weapon_stats = weapon_stats
			explode_weapon_stats.damage = max(1, round(weapon_stats.damage * (1.0 + exploding_dmg_bonus))) as int
			
			capybara_players[player_index].capybara_explode(explode_weapon_stats, ex_effect, ex_effect.value, _thing_hit.global_position, args, stats)


func _on_weapon_critically_hit_something(_thing_hit, _damage_dealt) -> void:
	._on_weapon_critically_hit_something(_thing_hit, _damage_dealt)

	if _thing_hit is Enemy:
		var capybara_crit_gain_box_effects = RunData.get_player_effect(Keys.generate_hash("capybara_gain_box_when_crit"), player_index)

		if capybara_crit_gain_box_effects.size() <= 0:
			return

		for effect in capybara_crit_gain_box_effects:
			var chance = effect[1]/100.0 * Utils.get_stat(effect[0], player_index)

			if chance > effect[2]:
				chance = effect[2]

			if Utils.get_chance_success(chance/100.0):
				var main:Main = get_parent().get_parent().get_tree().current_scene
				var _consumable_pool_id = main._consumable_pool_id
				var _consumables_container = main._consumables_container
				var unit = _thing_hit
				var consumable_scene = main.consumable_scene
				var consumable_to_spawn: ConsumableData = ItemService.get_consumable_for_tier(Tier.UNCOMMON)

				if consumable_to_spawn != null:
					if consumable_to_spawn.my_id_hash == Keys.consumable_item_box_hash or consumable_to_spawn.my_id_hash == Keys.consumable_legendary_item_box_hash:
						main._items_spawned_this_wave += 1

					var consumable: Consumable = main.get_node_from_pool(
						_consumable_pool_id,
						_consumables_container
					)

					if consumable == null:
						consumable = consumable_scene.instance()
						_consumables_container.call_deferred("add_child", consumable)

						var _error = consumable.connect("picked_up", self, "capybara_on_consumable_picked_up")

						yield(consumable, "ready")

					if consumable.is_connected("picked_up", main, "on_consumable_picked_up"):
						consumable.disconnect("picked_up", main, "on_consumable_picked_up")

					if not consumable.is_connected("picked_up", self, "capybara_on_consumable_picked_up"):
						consumable.connect("picked_up", self, "capybara_on_consumable_picked_up")

					consumable.already_picked_up = false
					consumable.consumable_data = consumable_to_spawn
					consumable.set_texture(load("res://mods-unpacked/Dbear-Capybara/icons/cp_golden_star_icon.png"))

					var pos = _thing_hit.global_position
					var dist: = rand_range(50, 100 + unit.stats.gold_spread)
					var push_back_destination: Vector2 = ZoneService.get_rand_pos_in_area(pos, dist, 0)

					consumable.drop(pos, 0, push_back_destination)

					main._consumables.push_back(consumable)


const capybara_lucky_projectile_stats = [
	"res://weapons/ranged/gatling_laser/4/gatling_laser_4_stats.tres",
	"res://weapons/ranged/nuclear_launcher/4/nuclear_launcher_4_stats.tres",
	"res://weapons/ranged/obliterator/4/obliterator_4_stats.tres",
	"res://weapons/ranged/particle_accelerator/4/particle_accelerator_4_stats.tres",
	"res://weapons/ranged/sniper_gun/4/sniper_gun_4_stats.tres",
	"res://weapons/melee/thunder_sword/thunder_sword_projectile_stats.tres",
]


const capybara_lucky_stats_hash = [
	"stat_luck",
	"stat_melee_damage",
	"stat_armor",
	"stat_max_hp",
	"stat_ranged_damage",
	"stat_attack_speed",
	"stat_elemental_damage",
	"stat_range",
]


func capybara_on_consumable_picked_up(consumable: Node, player_index: int) -> void:
	if consumable.already_picked_up:
		return

	var main = get_parent().get_parent().get_tree().current_scene
	if Utils.get_chance_success(0.1):
		if consumable.is_connected("picked_up", self, "capybara_on_consumable_picked_up"):
			consumable.disconnect("picked_up", self, "capybara_on_consumable_picked_up")

		if not consumable.is_connected("picked_up", main, "on_consumable_picked_up"):
			consumable.connect("picked_up", main, "on_consumable_picked_up")

		main.on_consumable_picked_up(consumable, player_index)
		return

	if Utils.get_chance_success(0.01):
		main._floating_text_manager.capybara_text("CAPYBARA_BIG_PRIZE", player_index)

		var key:int = rand_range(0,3)

		if key == 0:
			for i in 8:
				var stat = Keys.generate_hash(Utils.get_rand_element(capybara_lucky_stats_hash))

				RunData.add_stat(stat, 1, player_index)

		elif key == 1:
			RunData.add_stat(Keys.weapon_slot_hash, 1, player_index)

		elif key == 2:
			main.spawn_gold(100, consumable.global_position, 200)
		consumable.already_picked_up = true
		main._consumables.erase(consumable)
		consumable.queue_free()

		return

	RunData.handle_explode_effect(Keys.explode_on_consumable_hash, consumable.global_position, player_index)
	RunData.handle_explode_effect(Keys.explode_on_consumable_burning_hash, consumable.global_position, player_index, true)
	RunData.apply_item_effects(consumable.consumable_data, player_index)

	if Utils.get_chance_success(0.4):
		var rand_num = rand_range(10, 15) as int

		for i in rand_num:
			var sp_capybara_args: = WeaponServiceInitStatsArgs.new()
			var stats_path = Utils.get_rand_element(capybara_lucky_projectile_stats)
			var sp_capybara_projectile_stats = load(stats_path)
			var sp_capybara_current_weapon_stats = WeaponService.init_ranged_stats(sp_capybara_projectile_stats, player_index, false, sp_capybara_args)
			var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
			capybara_projectile_arg.deferred = true
			var cp_d = rand_range(0, 2 * PI)

			if _current_target.size() > 0:
				if is_instance_valid(_current_target[0]):
					cp_d = (_current_target[0].global_position - consumable.global_position).angle() + rand_range(-PI/3,PI/3)

			WeaponService.spawn_projectile(
				consumable.global_position,
				sp_capybara_current_weapon_stats,
				cp_d,
				self,
				capybara_projectile_arg
			)
		consumable.already_picked_up = true
		main._consumables.erase(consumable)
		consumable.queue_free()

		return

	if Utils.get_chance_success(0.5):
		var stat = Keys.generate_hash(Utils.get_rand_element(capybara_lucky_stats_hash))

		RunData.add_stat(stat, 1, player_index)
		consumable.already_picked_up = true
		main._consumables.erase(consumable)
		consumable.queue_free()
		return

	if consumable.consumable_data.my_id_hash == Keys.consumable_item_box_hash:
		main.spawn_gold(15.0, consumable.global_position, 50)
		consumable.already_picked_up = true
		main._consumables.erase(consumable)
		consumable.queue_free()
		return


func _capybara_spawn_sword_projectile(weapon_stats:RangedWeaponStats) -> void:
	if RunData.get_player_item(Keys.generate_hash("item_master_swords_box"), player_index):
		yield(get_tree().create_timer(0.5 * weapon_pos),"timeout")
	if capybara_is_pet_weapon:
		if not _range.monitoring:
			_range.set_deferred("monitoring", true)
			sprite.visible = true
		return
	var player = get_parent().get_parent()

	if is_instance_valid(player):
		if player.cp_main()._cleaning_up:
			return

	if is_instance_valid(player) and (current_stats is MeleeWeaponStats):
		weapon_stats = weapon_stats.duplicate()
		weapon_stats.damage = stats.damage
		weapon_stats.scaling_stats = current_stats.scaling_stats
		weapon_stats.crit_chance = current_stats.crit_chance
		weapon_stats.crit_damage = current_stats.crit_damage
		weapon_stats.shooting_sounds = current_stats.shooting_sounds
		weapon_stats.max_range = current_stats.max_range + 1000.0
		weapon_stats.projectile_speed *= max((1.0 + Utils.get_stat(Keys.stat_attack_speed_hash,player_index)/100.0), 1.0)
		if weapon_stats.projectile_speed > 1800:
			weapon_stats.projectile_speed = 1800

		var capybara_projectile_stats = weapon_stats.duplicate()
		var capybara_args: = WeaponServiceInitStatsArgs.new()

		capybara_args.effects = effects

		var capybara_current_weapon_stats = WeaponService.init_ranged_stats(capybara_projectile_stats, player_index, false, capybara_args)
		var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()

		capybara_projectile_arg.from_player_index = player_index
		capybara_projectile_arg.effects = effects

		var capybara_direction = rand_range(0, 2 * PI)
		var cp_from = null
		if _current_target and is_instance_valid(_current_target[0]):
			cp_from = _current_target[0]
		else:
			cp_from = player
		if not is_instance_valid(cp_from):
			return
		var projectile = WeaponService.manage_capybara_spawn_sword_projectile(
			cp_from,
			self,
			capybara_current_weapon_stats,
			capybara_direction,
			true,
			player._entity_spawner_ref,
			self,
			capybara_projectile_arg
		)
		capybara_sword_projectile.append(projectile)
		projectile.scale = capybara_player.scale

		var projectile_p:Sprite = projectile.get_node_or_null("Sprite")

		if projectile_p:
			projectile_p.texture = sprite.texture
			projectile_p.scale = sprite.scale
			
			for child in sprite.get_children():
				if child is CPUParticles2D:
					if not projectile_p.get_node_or_null("cp_particles" + weapon_id + str(abs(weapon_pos) as int)):
						var new_instance = child.duplicate()
						new_instance.name = "cp_particles" + weapon_id + str(abs(weapon_pos) as int)
						projectile_p.add_child(new_instance)
					else:
						var node = projectile_p.get_node_or_null("cp_particles" + weapon_id + str(abs(weapon_pos) as int))
						node.visible = child.visible
			for child in projectile_p.get_children():
				if not child.name.begins_with("cp_particles" + weapon_id + str(abs(weapon_pos) as int)) and child.name.begins_with("cp_particles"):
					child.visible = false

		if projectile.has_method("capybara_update_highlighting"):
			projectile.capybara_update_highlighting(tier, is_cursed)
			if not projectile.is_connected("capybara_stop", self, "capybara_on_sword_projectile_fade"):
				projectile.connect("capybara_stop", self, "capybara_on_sword_projectile_fade", [projectile])

		call_deferred("capybara_manage_sword_projectile", projectile)

	for effect in effects:
		if effect.key_hash == Keys.reload_turrets_on_shoot_hash:
			emit_signal("wanted_to_reset_turrets_cooldown")


func capybara_manage_sword_projectile(projectile:PlayerProjectile) -> void:
	yield(get_tree(), "idle_frame")

	if not is_instance_valid(projectile):
		return

	if projectile._hitbox == null:
		yield(get_tree(), "idle_frame")

	if not is_instance_valid(projectile):
		return

	if projectile._hitbox == null:
		return

	if effects.size() > 0 or RunData.get_player_effect(Keys.gain_stat_when_attack_killed_enemies_hash, player_index).size() > 0:
		if not projectile.killed_something_connected:
			projectile._hitbox.connect("killed_something", self, "on_killed_something", [projectile._hitbox])
			projectile.killed_something_connected = true

	if not projectile.hit_something_connected:
		projectile.connect("hit_something", self, "on_weapon_hit_something", [projectile._hitbox])
		projectile.connect("hit_something", self, "capybara_manage_break_effects", [projectile._hitbox])
		projectile.hit_something_connected = true

	if not projectile.critically_hit_something_connected:
		projectile.connect("critically_hit_something", self, "_on_weapon_critically_hit_something")
		projectile.critically_hit_something_connected = true


func capybara_reset_cooldown() -> float:
	var multiplier = current_stats.additional_cooldown_multiplier if is_big_reload_active() else 1

	_current_cooldown = min(_current_cooldown, current_stats.cooldown * multiplier)

	return _current_cooldown


func capybara_manage_break_effects(_thing_hit: Node, damage_dealt: int, hitbox: Hitbox) -> void:
	if hitbox:
		for effect in effects:
			if effect.key_hash == Keys.break_on_hit_hash:
				if Utils.get_chance_success(effect.value/100.0) and is_instance_valid(_parent):
					hitbox.from = _parent
					emit_signal("wanted_to_break", self, effect.value2)

func _capybara_manage_thunder_master() -> void:
	var capybara_explosion_effect = RunData.get_player_effect(Keys.generate_hash("capybara_thunder"), player_index)
	if capybara_explosion_effect.size() > 0:
		for ex_effect in capybara_explosion_effect:
			if not ex_effect.custom_key == "master":
				continue
			var args = WeaponServiceExplodeArgs.new()
			var capybara_main:Main = get_parent().get_parent().get_tree().current_scene
			var capybara_players = capybara_main._players
			var stats_arg = WeaponServiceInitStatsArgs.new()

			var weapon_stats = WeaponService.init_melee_stats(ex_effect.stats, player_index, stats_arg)
			var exploding_dmg_bonus = (Utils.get_stat(Keys.explosion_damage_hash, player_index) / 100.0)
			var explode_weapon_stats:MeleeWeaponStats = MeleeWeaponStats.new()

			explode_weapon_stats = weapon_stats
			explode_weapon_stats.damage = max(1, round(weapon_stats.damage * (1.0 + exploding_dmg_bonus))) as int
			if _current_target and is_instance_valid(_current_target[0]):
				capybara_players[player_index].capybara_explode(explode_weapon_stats, ex_effect, ex_effect.value, _current_target[0].global_position, args, stats)

func _capybara_manage_special_proj_master() -> void:
		var capybara_init_stats = RunData.get_player_effect(Keys.generate_hash("change_way_of_attack"), player_index)
		for effect in effects:
			if effect.key == "capybara_lotus_text":
				var capybara_args: = WeaponServiceInitStatsArgs.new()
				var capybara_current_weapon_stats = WeaponService.init_ranged_stats(effect.weapon_stats, player_index, false, capybara_args)
				var capybara_count:int = effect.value

				for i in range(0,capybara_count):
					var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()

					capybara_projectile_arg.from_player_index = player_index
					var spawn_pos = muzzle.global_position
					var capybara_direction = get_direction()
					var capybara_rand_direction = capybara_direction - (PI/6.0)*(capybara_count-1) + PI/(3.0*capybara_count)*i
					if capybara_master:
						capybara_rand_direction = rand_range(0, 2 * PI)
					if _current_target and _current_target[0] and is_instance_valid(_current_target[0]):
						spawn_pos = _current_target[0].global_position
					WeaponService.spawn_projectile(
						spawn_pos,
						capybara_current_weapon_stats,
						capybara_rand_direction,
						self,
						capybara_projectile_arg
					)

			if effect.key == "capybara_light_saber_text":
				var capybara_args: = WeaponServiceInitStatsArgs.new()
				var capybara_current_weapon_stats = WeaponService.init_ranged_stats(effect.weapon_stats, player_index, false, capybara_args)
				var capybara_count:int = effect.value

				for i in range(0,capybara_count):
					var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
					var capybara_rand_direction = (2.0*PI/capybara_count)*(i+1)
					var a = get_direction()
					var r = current_stats.max_range
					var pos = Vector2(r * cos(a), r * sin(a)) + global_position

					if _current_target and is_instance_valid(_current_target[0]):
						pos = _current_target[0].global_position

					WeaponService.spawn_projectile(
						pos,
						capybara_current_weapon_stats,
						capybara_rand_direction,
						self,
						capybara_projectile_arg
					)
		if capybara_init_stats.size() > 0:
			for effect in capybara_init_stats:
				if effect.custom_key == "senior_sister":
					var sp_capybara_args: = WeaponServiceInitStatsArgs.new()
					var sp_capybara_projectile_stats = effect.weapon_stats
					var sp_capybara_current_weapon_stats = WeaponService.init_ranged_stats(sp_capybara_projectile_stats, player_index, false, sp_capybara_args)
					var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()

					capybara_projectile_arg.from_player_index = player_index

					var rand_target = Utils.get_rand_element(_targets_in_range)
					var cp_d:float = get_direction()

					cp_d = rand_range(cp_d - PI/6,cp_d + PI/6)

					if rand_target:
						cp_d = (rand_target.global_position - muzzle.global_position).angle()

					WeaponService.spawn_projectile(
						muzzle.global_position,
						sp_capybara_current_weapon_stats,
						cp_d,
						self,
						capybara_projectile_arg
					)

func shoot() -> void:
	if capybara_should_reload_stats:
		init_stats(false)
	if not capybara_master:
		_capybara_manage_special_proj_master()
	var capybara_init_stats = RunData.get_player_effect(Keys.generate_hash("change_way_of_attack"), player_index)
	if capybara_init_stats.size() > 0 and stats is MeleeWeaponStats and not capybara_is_pet_weapon:
		for effect in capybara_init_stats:
			if effect.custom_key == "master":
				if capybara_sword_projectile.size() <= 0:
					_capybara_spawn_sword_projectile(effect.weapon_stats)
					_capybara_manage_thunder_master()
					_capybara_manage_special_proj_master()
					_current_cooldown = get_next_cooldown()
					capybara_fade_node(self, 0.1 , true)
				return
	var capybara_proj = 0
	for effect in effects:
		if effect.key == "capybara_trees_add_proj_to_weapon":
			capybara_player.capybara_should_check_trees = true
			if current_stats is RangedWeaponStats:
				capybara_proj += capybara_player.capybara_trees * effect.value
				current_stats.nb_projectiles += capybara_player.capybara_trees * effect.value
	.shoot()
	if capybara_proj > 0:
		if current_stats is RangedWeaponStats:
			current_stats.nb_projectiles -= capybara_proj

	for effect in effects:
		if effect.key_hash == Keys.generate_hash("capybara_take_time_for_x_shot"):
			if _nb_shots_taken % effect.value == 0:
				var main = get_parent().get_parent().get_tree().current_scene
				var time_left = main._wave_timer.time_left
				var new_time_left = max(1, time_left - 1)
				if new_time_left > 9:
					main._wave_timer.start(new_time_left)
func should_shoot() -> bool:
	capybara_can_shoot = _range.monitoring
	var capybara_temp_range = current_stats.max_range
	var capybara_ranged_melee_attack = RunData.get_player_effect(Keys.generate_hash("capybara_ranged_melee_attack"), player_index)

	for effect in capybara_ranged_melee_attack:
		if "capybara_crystal_attack" in _shooting_behavior and _shooting_behavior.capybara_crystal_attack:
			current_stats.max_range = effect.weapon_stats.max_range

	var capybara_should_shoot = .should_shoot()

	current_stats.max_range = capybara_temp_range

	return capybara_should_shoot and capybara_can_shoot

func get_direction_and_calculate_target() -> float:
	var capy_result = .get_direction_and_calculate_target()
	if capybara_master and not capybara_is_pet_weapon and not stats is RangedWeaponStats:
		return - PI/2

	return capy_result

func get_direction() -> float:
	var capy_result = .get_direction()
	if capybara_master and not capybara_is_pet_weapon and not stats is RangedWeaponStats:
		return - PI/2

	return capy_result
	
func capybara_fade_node(node:CanvasItem, duration:float, fade_out:bool) -> void:
	if capybara_is_pet_weapon:
		return
	if not is_instance_valid(node):
		return

	if not node.has_meta("capybara_original_modulate"):
		node.set_meta("capybara_original_modulate", node.modulate)

	var tween = node.get_node_or_null("CapybaraFadeTween")

	if not tween or not is_instance_valid(tween):
		tween = Tween.new()
		tween.name = "CapybaraFadeTween"
		node.add_child(tween)

	tween.stop_all()
	tween.remove_all()

	var target_color = node.modulate

	if fade_out:
		target_color.a = 0.0
	else:
		target_color = node.get_meta("capybara_original_modulate")

	tween.interpolate_property(node, "modulate", node.modulate, target_color, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func capybara_on_sword_projectile_fade(projectile) -> void:
	capybara_fade_node(self, 0.3, false)
	capybara_sword_projectile.erase(projectile)
	_is_shooting = false
