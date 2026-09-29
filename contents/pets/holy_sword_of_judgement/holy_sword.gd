extends Entity

export (float) var radius: = 150.0
export (float) var rotation_speed: = 3.0

onready var _hitbox: = $Hitbox as Hitbox
onready var cursed_particles: = $CursedUnitParticles as CPUParticles2D
onready var holy_light = $HolyLight
var player_index: = -1
var _owner_player: Player
var _angle = 0
var _phase = 0
var weapon_stats = load("res://mods-unpacked/Dbear-Capybara/contents/pets/holy_sword_of_judgement/holy_sword_stats.tres")
var holy_sword_effect
var self_item_data = null
var current_radius = 150.0



func _ready():
	get_tree().current_scene._pause_menu._menu_options.connect("pet_highlighting_changed", self, "update_highlight")
	get_tree().current_scene._pause_menu._menu_options.connect("pet_transparency_changed", self, "_update_transparency")
	update_highlight()
	_update_transparency(ProgressData.settings.pet_opacity)


func capybara_init_trajectory(id: int, count: int, owner_player: Player, effect: Array, item_data:Resource) -> void :
	_phase = (2 * PI / count) * id
	radius = (120 + (count - 6) * 10) * 2
	_owner_player = owner_player
	player_index = owner_player.player_index
	_owner_player.connect("capybara_holy_sword_added", self, "_capybara_die")
	_hitbox.from = owner_player
	_hitbox.damage_tracking_key_hash = Keys.generate_hash("item_golden_wings")
	var holy_sword_effects = RunData.get_player_effect(Keys.generate_hash("capybara_holy_sword_of_judgement"), _owner_player.player_index)
	if item_data.is_cursed:
		cursed_particles.visible = true
	else:
		cursed_particles.visible = false
	holy_sword_effect = effect
	_animation_player.play("hit")
	holy_light.visible = true
	self_item_data = item_data
	var args: = WeaponServiceInitStatsArgs.new()
	var cp_weapon_stats = holy_sword_effect[2]
	if not cp_weapon_stats is MeleeWeaponStats:
		for effect in self_item_data.effects:
			if effect.custom_key == "capybara_holy_sword_of_judgement":
				cp_weapon_stats = effect.weapon_stats
	var _current_weapon_stats = WeaponService.init_melee_pet_stats(cp_weapon_stats, player_index, args)
	_hitbox.damage = _current_weapon_stats.damage
	_hitbox.scaling_stats = _current_weapon_stats.scaling_stats
	_hitbox.crit_chance = _current_weapon_stats.crit_chance
	_hitbox.crit_damage = _current_weapon_stats.crit_damage
	_hitbox.damage_tracking_key_hash = Keys.generate_hash("item_golden_wings")

func _capybara_die() -> void:
	_hitbox.disable()
	_animation_player.play("death")
	holy_light.visible = false
	cursed_particles.visible = false

func _physics_process(delta: float) -> void :
	var size_mod = max(1.0, min(1 + Utils.get_stat(Keys.stat_range_hash, player_index)/300.0, 10.0))
	scale = _owner_player.scale * size_mod
	var original_mod = _owner_player.scale.x/scale.x as float
	current_radius = radius * size_mod * original_mod
	var rotation_speed_now = rotation_speed + 3 * (Utils.get_stat(Keys.stat_attack_speed_hash, player_index)/100 as float)
	if rotation_speed_now >= 6:
		rotation_speed_now = 6
	elif rotation_speed_now <= 3:
		rotation_speed_now = 3
	if is_instance_valid(_owner_player):
		rotation = (global_position - _owner_player.global_position).angle()
	_angle += delta * rotation_speed_now
	var player_position = _owner_player.global_position
	global_position = Vector2(player_position.x + cos(_angle + _phase) * current_radius, player_position.y + sin(_angle + _phase) * current_radius)
	

func _on_Hurtbox_area_entered(hitbox: Area2D) -> void :

	if hitbox.get_parent() is PlayerProjectile:
		return
	hitbox.hit_something(self, 0)

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
	var cp_weapon_stats = holy_sword_effect[2]
	if not cp_weapon_stats is MeleeWeaponStats:
		for effect in self_item_data.effects:
			if effect.custom_key == "capybara_holy_sword_of_judgement":
				cp_weapon_stats = effect.weapon_stats
	var _current_weapon_stats = WeaponService.init_melee_pet_stats(cp_weapon_stats, player_index, args)
	_hitbox.damage = _current_weapon_stats.damage
	_hitbox.scaling_stats = _current_weapon_stats.scaling_stats
	_hitbox.crit_chance = _current_weapon_stats.crit_chance
	_hitbox.crit_damage = _current_weapon_stats.crit_damage
	_hitbox.damage_tracking_key_hash = Keys.generate_hash("item_golden_wings")
