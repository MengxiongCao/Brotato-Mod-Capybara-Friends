extends Entity

export (float) var radius: = 150
export (float) var rotation_speed: = 1.1
var capybara_hit_time = 0

onready var _hitbox: = $Hitbox as Hitbox
onready var cursed_particles: = $CursedUnitParticles as CPUParticles2D
var player_index: = - 1
var _owner_player: Player
var _angle = 0
var _phase = 0
var burning_data = load("res://mods-unpacked/Dbear-Capybara/contents/pets/fox_fire/foxfire_burning_data.tres")
var weapon_stats = load("res://mods-unpacked/Dbear-Capybara/contents/pets/fox_fire/foxfire_stats_1.tres")
var fox_fire_effect
var self_item_data = null
var current_radius = 150



func _ready():
	get_tree().current_scene._pause_menu._menu_options.connect("pet_highlighting_changed", self, "update_highlight")
	get_tree().current_scene._pause_menu._menu_options.connect("pet_transparency_changed", self, "_update_transparency")
	update_highlight()
	_update_transparency(ProgressData.settings.pet_opacity)


func capybara_init_trajectory(id: int, count: int, owner_player: Player, effect: Array, item_data:Resource) -> void :
	_phase = (2 * PI / count) * id
	_owner_player = owner_player
	player_index = owner_player.player_index
	_hitbox.from = owner_player
	_hitbox.damage_tracking_key_hash = Keys.generate_hash("item_foxfire")
	var fox_fire_effects = RunData.get_player_effect(Keys.generate_hash("foxfire_count"), _owner_player.player_index)
	if item_data.is_cursed:
		cursed_particles.visible = true
	else:
		cursed_particles.visible = false
	fox_fire_effect = effect
	self_item_data = item_data
	capybara_hit_time = 0
	var args: = WeaponServiceInitStatsArgs.new()
	var cp_weapon_stats = fox_fire_effect[2]
	var cp_burning_data = fox_fire_effect[3]
	if not cp_weapon_stats is MeleeWeaponStats:
		for effect in self_item_data.effects:
			if effect.custom_key == "foxfire_count":
				cp_weapon_stats = effect.weapon_stats
	if not cp_burning_data is BurningData:
		for effect in self_item_data.effects:
			if effect.custom_key == "foxfire_count":
				cp_burning_data = effect.burning_data
	var _current_weapon_stats = WeaponService.init_melee_pet_stats(cp_weapon_stats, player_index, args)
	var current_burning_data: BurningData = WeaponService.init_burning_data(cp_burning_data, player_index, false, true)
	_hitbox.damage = _current_weapon_stats.damage
	_hitbox.scaling_stats = _current_weapon_stats.scaling_stats
	_hitbox.crit_chance = _current_weapon_stats.crit_chance
	_hitbox.crit_damage = _current_weapon_stats.crit_damage
	current_burning_data.from = _owner_player
	_hitbox.burning_data = current_burning_data
	_hitbox.burning_data.damage = current_burning_data.damage
	_hitbox.burning_data.scaling_stats = current_burning_data.scaling_stats
		

func _physics_process(delta: float) -> void :
	var original_mod = _owner_player.scale.x/scale.x as float
	current_radius = radius * original_mod
	var rotation_speed_now = rotation_speed + 8 * (Utils.get_stat(Keys.stat_attack_speed_hash, player_index)/100 as float)
	if rotation_speed_now >= 8.1:
		rotation_speed_now = 8.1
	elif rotation_speed_now <= 1.1:
		rotation_speed_now = 1.1
	_angle += delta * rotation_speed_now
	var player_position = _owner_player.global_position
	global_position = Vector2(player_position.x + cos(_angle + _phase) * current_radius, player_position.y + sin(_angle + _phase) * current_radius)
	

func _on_Hurtbox_area_entered(hitbox: Area2D) -> void :

	if hitbox.get_parent() is PlayerProjectile:
		return
	var is_add_stat = RunData.get_player_effect(Keys.generate_hash("foxfire_block"), _owner_player.player_index)
	hitbox.hit_something(self, 0)
	if is_add_stat.size() > 0:
		if capybara_hit_time == 0:
			_animation_player.play("hit")
			capybara_hit_time += 1
		elif capybara_hit_time == 1:
			_animation_player.play("hit_1")
			capybara_hit_time += 1
		else:
			_animation_player.play("hit_2")
			capybara_hit_time = 0
			var stat = is_add_stat[0][0]
			RunData.add_stat(stat, 1 , _owner_player.player_index)
			RunData.add_tracked_value(player_index, Keys.generate_hash("character_Daji"), 1)
	else:
		_animation_player.play("block")
	

func update_highlight(_value: bool = true):
	if dead: return

	var value = ProgressData.settings.pet_highlighting
	var highlight_color: Color = CoopService.get_player_color(player_index) if RunData.is_coop_run else Utils.HIGHLIGHT_COLOR
	highlight_color.a = 0.5

	if not value:
		if has_outline(highlight_color):
			remove_outline(highlight_color)
	else:
		if not has_outline(highlight_color):
			add_outline(highlight_color)


func _update_transparency(value):
	sprite.modulate.a = value
	



func _on_Hitbox_hit_something(thing_hit, damage_dealt):
	var args: = WeaponServiceInitStatsArgs.new()
	var cp_weapon_stats = fox_fire_effect[2]
	var cp_burning_data = fox_fire_effect[3]
	if not cp_weapon_stats is MeleeWeaponStats:
		for effect in self_item_data.effects:
			if effect.custom_key == "foxfire_count":
				cp_weapon_stats = effect.weapon_stats
	if not cp_burning_data is BurningData:
		for effect in self_item_data.effects:
			if effect.custom_key == "foxfire_count":
				cp_burning_data = effect.burning_data
	var _current_weapon_stats = WeaponService.init_melee_pet_stats(cp_weapon_stats, player_index, args)
	var current_burning_data: BurningData = WeaponService.init_burning_data(cp_burning_data, player_index, false, true)
	_hitbox.damage = _current_weapon_stats.damage
	_hitbox.scaling_stats = _current_weapon_stats.scaling_stats
	_hitbox.crit_chance = _current_weapon_stats.crit_chance
	_hitbox.crit_damage = _current_weapon_stats.crit_damage
	current_burning_data.from = _owner_player
	_hitbox.burning_data = current_burning_data
	_hitbox.burning_data.damage = current_burning_data.damage
	_hitbox.burning_data.scaling_stats = current_burning_data.scaling_stats
	_hitbox.from = _owner_player
	RunData.manage_life_steal(_current_weapon_stats, player_index)
