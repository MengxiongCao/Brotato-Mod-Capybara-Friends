extends "res://entities/structures/turret/turret.gd"

var capybara_radius:float = 0.0
var capybara_count = 0
var capybara_angle:float = 0.0
var capybara_players:Array = []
var capybara_player = null
var cp_rotation_speed:float = 1.5
var capybara_check = false
var capybara_attack_speed_boost = 1.0
var capybara_future_particles = load("res://mods-unpacked/Dbear-Capybara/contents/projectiles/future_particles.tscn")
var capybara_future_particles_scene = null
var capybara_is_spawning = false

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, players_ref: Array = [], _entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, players_ref, _entity_spawner_ref)
	capybara_players = players_ref
	capybara_radius = rand_range(100, 200)
	cp_rotation_speed = rand_range(1.5, 3.0)
	capybara_future_particles_scene = capybara_future_particles.instance()
	add_child(capybara_future_particles_scene)
	capybara_future_particles_scene.visible = false
	capybara_player = capybara_players[player_index]
	if capybara_player and is_instance_valid(capybara_player):
		capybara_player.capybara_turrets.push_back(self)

func _physics_process(delta: float) -> void :
	var capybara_turretato_effects = RunData.get_player_effect(Keys.generate_hash("capybara_move_the_turret_when_pass"), player_index)
	if capybara_turretato_effects.size() > 0:
		for effect in capybara_turretato_effects:
			capybara_angle += delta * cp_rotation_speed
			var cp_player_position = capybara_players[player_index].global_position
			if (cp_player_position - global_position).length() <= 50 or capybara_check:
				if not capybara_check:
					TempStats.add_stat(effect[0], effect[1], player_index)
					TempStats.add_stat(effect[2], effect[3], player_index)
				capybara_check = true
				global_position = Vector2(cp_player_position.x + cos(capybara_angle) * capybara_radius, cp_player_position.y + sin(capybara_angle) * capybara_radius)
	var capybara_future_effects = RunData.get_player_effect(Keys.generate_hash("capybara_boost_turret_when_nearby"), player_index)
	if capybara_future_effects.size() > 0:
		for effect in capybara_future_effects:
			var cp_player_position = capybara_players[player_index].global_position
			if (cp_player_position - global_position).length() <= 400:
				capybara_attack_speed_boost = effect[1] as float
				if not capybara_future_particles_scene.visible:
					TempStats.add_stat(effect[0],effect[2], player_index)
					_cooldown /= capybara_attack_speed_boost
				capybara_future_particles_scene.visible = true
				if not has_outline(Color.aqua):
					add_outline(Color.aqua)
			else:
				capybara_attack_speed_boost = 1.0
				if capybara_future_particles_scene.visible:
					TempStats.remove_stat(effect[0], effect[2], player_index)
				capybara_future_particles_scene.visible = false
				if has_outline(Color.aqua):
					remove_outline(Color.aqua)

#func _get_next_cooldown(at_wave_begin: bool = false) -> float:
#	var capybara_next_cooldown = ._get_next_cooldown(at_wave_begin)
#	return capybara_next_cooldown/capybara_attack_speed_boost

func _get_max_cooldown() -> int:
	var capybara_max_cooldown = max(1,._get_max_cooldown()/capybara_attack_speed_boost)
	return capybara_max_cooldown

func set_data(data):
	.set_data(data)
	if "effects" in data:
		for effect in data.effects:
			if "is_spawning" in effect:
				if effect.is_spawning:
					capybara_is_spawning = true
