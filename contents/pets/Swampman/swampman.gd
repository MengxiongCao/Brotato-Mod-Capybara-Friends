extends Pet
var _owner_player: Player
var _angle = 0
var _phase = 0
var weapons:Array
onready var capybara_animation = $Animation/Viewport/offset/sp_body
onready var capybara_shadow = $Animation/Viewport/offset/sp_shadow
onready var capybara_head = $Animation/Viewport/offset/sp_body/sp_head
var capybara_damage_shrink = 0.25
var capybara_effect = null

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
	_owner_player = get_tree().current_scene._players[player_index]
	capybara_head.visible = false
	capybara_shadow.visible = false
	for sprite in _owner_player._sprites:
		var duplicate_sprite = sprite.duplicate()
		if not sprite.name == "Legs":
			if sprite.scale.x < 0:
				duplicate_sprite.scale.x = - duplicate_sprite.scale.x
			capybara_animation.add_child(duplicate_sprite)

func capybara_hit_something(thing_hit, damage_dealt):
	RunData.add_tracked_value(player_index, Keys.generate_hash("item_strange_bottle"), damage_dealt)

func _capybara_pet_move_weapons(delta:float) -> void:
	if not _owner_player:
		return
	
	if _owner_player.capybara_change_attack or _owner_player.capybara_round_weapons:
		_phase += 2 * delta
		if _phase > 2*PI:
			_phase = 0
		if not _owner_player.capybara_is_master:
			for i in weapons.size():
				var r = (60 + (weapons.size() - 6) * 5) * 2
				var angle = i * ((2 * PI) / weapons.size())
				if is_instance_valid(weapons[i]):
					weapons[i].global_position = Vector2(r * cos(angle + _phase), r * sin(angle + _phase)) + global_position
		else:
			for i in weapons.size():
				var r = (90 + (weapons.size() - 6) * 5) * 2
				var angle = i * ((2 * PI) / weapons.size())
				if is_instance_valid(weapons[i]):
					weapons[i].global_position = Vector2(r * cos(angle + _phase), 0.4 * r * sin(angle + _phase)) + global_position

func _physics_process(delta) -> void:
	if dead:
		return
	if _end_of_wave:
		return
	if weapons.size() <= 0:
		return
	for i in weapons.size():
		if weapons.size() > 6:
			var r = (60 + (weapons.size() - 6) * 5) * 2
			var angle = i * ((2 * PI) / weapons.size())
			if is_instance_valid(weapons[i]):
				weapons[i].global_position = Vector2(r * cos(angle), r * sin(angle)) + global_position
		else:
			var r = 60
			var angle = 2*PI/3 - PI/3 * i
			if weapons.size() == 1:
				angle = PI/2
				r = 20
			elif weapons.size() == 2:
				angle = 5*PI/6 - 2*PI/3 * i
				r = 40
			elif weapons.size() == 3:
				angle = 5*PI/6 - 2*PI/3 * i
				r = 50
			elif weapons.size() == 4:
				angle = 3*PI/4 - PI/2 * i
			elif weapons.size() == 5:
				angle = 7*PI/10 - 2*PI/5 * i
			if is_instance_valid(weapons[i]):
				weapons[i].global_position = Vector2(r * cos(angle), r * sin(angle)) + global_position
	_capybara_pet_move_weapons(delta)
func update_animation(movement: Vector2) -> void :
	.update_animation(movement)
	if movement.length() > 0.1:
		if not (_animation_player.current_animation == "move" or _animation_player.current_animation == "pet_the_swamp_man"):
			_animation_player.play("move")
	elif movement.length() <= 0.1:
		if not (_animation_player.current_animation == "idle" or _animation_player.current_animation == "pet_the_swamp_man"):
			_animation_player.play("idle")

func update_data(effect: PetEffect) -> void :
	.update_data(effect)
	capybara_effect = effect
	var cp_weapons = RunData.get_player_weapons(player_index)
	if cp_weapons.size() <= 0:
		cp_weapons = []
		for i in 6:
			cp_weapons.append(Utils.get_rand_element(ItemService.weapons))
	if capybara_effect:
		capybara_damage_shrink = capybara_effect.damage_shrink/100.0
	weapons = _owner_player.swampman_add_weapon(cp_weapons, global_position, capybara_damage_shrink)
	for weapon in weapons:
		_owner_player._weapons_container.add_child(weapon)
		weapon.set_as_toplevel(true)
		weapon.connect("capybara_weapon_hit_something", self ,"capybara_hit_something")
	_hurtbox.disable()
	

func _can_pet():
	# 宠物没了就直接退出，不执行后面的代码
	if not is_instance_valid(self):
		return

	yield(get_tree().create_timer(0.1), "timeout")

	if not is_instance_valid(self):
		return
	_animation_player.play("pet_the_swamp_man")

	yield(get_tree().create_timer(2), "timeout")

	if not is_instance_valid(self):
		return
	_animation_player.play("idle_pet")
