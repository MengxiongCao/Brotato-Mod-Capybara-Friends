class_name CapybaraEnemiesKilledCounter
extends Entity

var capybara_god_of_death_item = load("res://mods-unpacked/Dbear-Capybara/contents/items/soul_wheat/soul_wheat_data.tres")
var _owner:Player
onready var capybara_animation_enemies_counter = $Animation
onready var capybara_label = $Control/Label
var capybara_fade_speed = 3.0
onready var animation_player = $AnimationPlayer
onready var heart_rate_sp = $"%heart_rate"
onready var heart_rate_label = $"%heart_rate_label"
var capybara_enemies_killed:int = 0
var capybara_gain_stat_for_enemies_killed = []
onready var capybara_update_timer:Timer = $Timer
onready var _heart_rate_ani = $HeartRateAnimationPlayer
var last_capybara_enemies_killed:int = 0
var capybara_extra_boss_for_x_enemies:int = 0
var capybara_hit_protection_for_x_enemies:int = 0
var capybara_spawn_pets_for_x_enemies = null
var capybara_pet_spawned = {}
var capybara_boss_killed = 0
var capybara_cursed_enemies_killed = 0
var capybara_projectile_when_x_cursed_killed = []
var player_index = -1
var heart_rate:int = 60

func _ready() -> void:
	capybara_update_timer.start()
	
func capybara_init(owner_player: Player) -> void :
	_owner = owner_player
	capybara_animation_enemies_counter.modulate.a = 0
	heart_rate_label.text = str(heart_rate)
	capybara_label.modulate.a = 0
	call_deferred("capybara_init_player")

func capybara_init_player() -> void:
	capybara_gain_stat_for_enemies_killed = RunData.get_player_effect(Keys.generate_hash("capybara_gain_stat_for_enemies_killed"),_owner.player_index)
	capybara_extra_boss_for_x_enemies = RunData.get_player_effect(Keys.generate_hash("capybara_extra_boss_for_x_enemies"), _owner.player_index)
	capybara_hit_protection_for_x_enemies = RunData.get_player_effect(Keys.generate_hash("capybara_hit_protection_for_x_enemies"), _owner.player_index)
	capybara_spawn_pets_for_x_enemies = RunData.get_player_effect(Keys.generate_hash("capybara_spawn_pets_for_x_enemies"), _owner.player_index)
	_owner.connect("capybara_player_killed_enemy", self, "capybara_update_value")
	_owner.connect("capybara_is_dodge", self, "capybara_update_heart_rate")
	player_index = _owner.player_index
	if not RunData.get_player_character(player_index).my_id == "character_cp_dragontato":
		heart_rate_label.visible = false
		heart_rate_sp.visible = false
	capybara_projectile_when_x_cursed_killed = RunData.get_player_effect(Keys.generate_hash("capybara_projectile_when_x_cursed_killed"), player_index)

func _physics_process(delta) -> void:
	if is_instance_valid(_owner):
		var x_mod = str(capybara_enemies_killed).length()
		global_position = _owner.global_position + Vector2(0, -120) + Vector2(-5 * x_mod, 0)
		if capybara_animation_enemies_counter.modulate.a > 0:
			capybara_animation_enemies_counter.modulate.a -= capybara_fade_speed * delta
			capybara_label.modulate.a -= capybara_fade_speed * delta
		if capybara_animation_enemies_counter.modulate.a <= 0:
			heart_rate_label.rect_position.x = 3
			heart_rate_sp.position.x = -21
		else:
			heart_rate_label.rect_position.x = -103
			heart_rate_sp.position.x = -127

func capybara_get_nb_of_item(my_id_hash:int, player_index:int) -> int:
	var result = 0
	for item in RunData.get_player_items(player_index):
		if item.my_id_hash == my_id_hash:
			result += 1
	return result

func _capybara_get_current_target(current_enemy:Enemy) -> Array:
	var main:Main = get_tree().current_scene
	if main._cleaning_up:
		return []
	var enemies = []
	var pos = Vector2(0,0)
	if _owner and is_instance_valid(_owner):
		if _owner is Player:
			var _entity_spawner = _owner._entity_spawner_ref
			if _entity_spawner is EntitySpawner:
				enemies = _entity_spawner.get_all_enemies(false)
	if enemies.size() > 1:
		enemies.erase(current_enemy)
	if _owner and is_instance_valid(_owner):
		pos = _owner.global_position
	return Utils.capybara_get_highest_health_enemy(enemies, pos)

func _capybara_get_nb_of_cursed_enemies() -> int:
	var nb_of_cursed_enemies = 0
	var enemies = []
	if _owner and is_instance_valid(_owner):
		if _owner is Player:
			var _entity_spawner = _owner._entity_spawner_ref
			if _entity_spawner is EntitySpawner:
				enemies = _entity_spawner.get_all_enemies()
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy is Enemy:
			if enemy.has_outline(Utils.CURSE_COLOR):
				nb_of_cursed_enemies += 1
	return nb_of_cursed_enemies

func capybara_update_value(thing_killed, args):
	if thing_killed is Enemy:
		if thing_killed is Boss:
			capybara_boss_killed += 1
		if thing_killed.has_outline(Utils.CURSE_COLOR):
			capybara_cursed_enemies_killed += 1
		for effect in capybara_projectile_when_x_cursed_killed:
			if capybara_cursed_enemies_killed % effect.value == 0 and not capybara_cursed_enemies_killed == 0 and thing_killed.has_outline(Utils.CURSE_COLOR):
				if _owner and is_instance_valid(_owner):
					var target = _capybara_get_current_target(thing_killed)
					var pos = thing_killed.global_position
					if target.size() > 0:
						pos = target[0].global_position
						print("target_exist")
					_owner._capybara_spawn_pos_projectile(effect, null, pos, true)
		var players_ref = thing_killed.players_ref
		if args.enemy_killed_by_player and args.killed_by_player_index == _owner.player_index and args.killed_by_player_index < players_ref.size() and is_instance_valid(players_ref[args.killed_by_player_index]):
			animation_player.play("count_changed")
			capybara_enemies_killed += 1
			capybara_label.text = str("x",capybara_enemies_killed)
			RunData.capybara_killed_enemies[_owner.player_index] = capybara_enemies_killed
			var should_run_authoritative_logic = _owner.capybara_should_run_authoritative_logic()
			if should_run_authoritative_logic and capybara_extra_boss_for_x_enemies > 0:
				if capybara_enemies_killed % capybara_extra_boss_for_x_enemies == 0:
					_owner._capybara_spawn_bosses(thing_killed.global_position, 1)
			if capybara_hit_protection_for_x_enemies > 0:
				if capybara_enemies_killed % capybara_hit_protection_for_x_enemies == 0:
					_owner._hit_protection += 1
			if should_run_authoritative_logic and typeof(capybara_spawn_pets_for_x_enemies) == TYPE_ARRAY and capybara_spawn_pets_for_x_enemies.size() > 0:
				var i = 0
				for effect in capybara_spawn_pets_for_x_enemies:
					var current_spawned = capybara_pet_spawned.get(i, 0)
					if effect.custom_key == "capybara_god_of_death":
						var item_count = capybara_get_nb_of_item(capybara_god_of_death_item.my_id_hash, _owner.player_index)
						if capybara_boss_killed >= (max(1,effect.stat_scaled) as int) and capybara_boss_killed > 0 and current_spawned < effect.max_num and item_count < effect.max_num:
							capybara_boss_killed -= (max(1,effect.stat_scaled) as int)
							capybara_pet_spawned[i] = current_spawned + effect.value
							RunData.add_item(capybara_god_of_death_item, _owner.player_index)
							_owner._capybara_spawn_pets(thing_killed.global_position, effect.value, effect.effect.scene, effect.effect)
					elif capybara_enemies_killed % (max(1,effect.stat_scaled) as int) == 0 and current_spawned < effect.max_num:
						capybara_pet_spawned[i] = current_spawned + effect.value
						_owner._capybara_spawn_pets(thing_killed.global_position, effect.value, effect.effect.scene, effect.effect)
					i += 1

func capybara_update_heart_rate() -> void:
	_heart_rate_ani.play("heart_rate_changed")
	heart_rate += rand_range(3, 10) as int
	heart_rate_label.text = str(heart_rate)
	yield(_heart_rate_ani,"animation_finished")
	_heart_rate_ani.play("heart_rate_idle")

func capybara_update_heart_rate_m() -> void:
	if heart_rate <= 60:
		return
	_heart_rate_ani.play("heart_rate_changed")
	heart_rate = max(heart_rate -1, 60) as int
	heart_rate_label.text = str(heart_rate)
	yield(_heart_rate_ani,"animation_finished")
	_heart_rate_ani.play("heart_rate_idle")

func _on_Timer_timeout():
	if player_index >= 0:
		RunData.capybara_cursed_enemies = _capybara_get_nb_of_cursed_enemies()
	for effect in capybara_gain_stat_for_enemies_killed:
		var stat_to_tweak = effect[0]
		var value = effect[1] as float
		var stat_scaled = effect[2]
		var nb_stat_scaled = effect[3] as float
		var amount_to_add = (last_capybara_enemies_killed/nb_stat_scaled * value) as int
		TempStats.remove_stat(stat_to_tweak, amount_to_add, _owner.player_index)
	for effect in capybara_gain_stat_for_enemies_killed:
		var stat_to_tweak = effect[0]
		var value = effect[1] as float
		var stat_scaled = effect[2]
		var nb_stat_scaled = effect[3] as float
		var amount_to_add = (capybara_enemies_killed/nb_stat_scaled * value) as int
		TempStats.add_stat(stat_to_tweak, amount_to_add, _owner.player_index)
		last_capybara_enemies_killed = capybara_enemies_killed
