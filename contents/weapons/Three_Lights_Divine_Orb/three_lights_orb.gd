extends "res://weapons/ranged/ranged_weapon.gd"

onready var _capybara_timer = $Timer
onready var _capybara_animation_player = $AnimationPlayer
var cp_one_second_timer = 0
var cp_weapon_index:int = 0
var cp_weapon_stats_array:Array = []
var cp_effect_array:Array = []
onready var _cp_sprite = $Sprite
onready var _cp_sprite_2 = $Sprite/Sprite2
var speed_added = false
var fire_texture = load("res://mods-unpacked/Dbear-Capybara/contents/weapons/Three_Lights_Divine_Orb/cp_fire_orb.png")
var wind_texture = load("res://mods-unpacked/Dbear-Capybara/contents/weapons/Three_Lights_Divine_Orb/cp_wind_orb.png")
var thunder_texture = load("res://mods-unpacked/Dbear-Capybara/contents/weapons/Three_Lights_Divine_Orb/cp_thunder_orb.png")

func _ready() -> void:
	_capybara_timer.start()
	cp_weapon_stats_array = [
	stats,
	self.effects[0].weapon_stats_1,
	self.effects[0].weapon_stats_2,
	]
	cp_effect_array = [
		self.effects[1],
		self.effects[2],
		self.effects[3],
	]
	self.effects = [self.effects[0]]
	

func _process(_delta: float) -> void :
	update_sprite_flipv()
	# 关键：让Sprite反向旋转，抵消父节点rotation，保持直立
	sprite.rotation = -rotation

func update_sprite_flipv() -> void :
	sprite.flip_v = false
	if not _capybara_animation_player.current_animation == "change":
		_capybara_animation_player.play("idle")

func _on_Timer_timeout():
	cp_one_second_timer += 1
	if cp_one_second_timer % effects[0].value == 0:
		if cp_weapon_index == 2:
			var effect = cp_effect_array[cp_weapon_index]
			TempStats.remove_stat(effect.key_hash, effect.value, player_index)
		self.effects = [self.effects[0]]
		cp_weapon_index = (cp_weapon_index + 1) % 3
		stats = cp_weapon_stats_array[cp_weapon_index]
		_capybara_animation_player.play("change")
		if cp_weapon_index == 0:
			_cp_sprite_2.texture = fire_texture
			self.effects.append(cp_effect_array[cp_weapon_index])
		elif cp_weapon_index == 1:
			_cp_sprite_2.texture = thunder_texture
			self.effects.append(cp_effect_array[cp_weapon_index])
		elif cp_weapon_index == 2:
			_cp_sprite_2.texture = wind_texture
			var effect = cp_effect_array[cp_weapon_index]
			TempStats.add_stat(effect.key_hash, effect.value, player_index)
		var args = WeaponServiceInitStatsArgs.new()
		current_stats = WeaponService.init_ranged_stats(stats, player_index, false, args)
		
