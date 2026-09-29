class_name CapybaraWanderingTurret
extends "res://entities/structures/turret/turret.gd"

var distance = rand_range(200, 400)
var base_distance
var rotation_speed = rand_range(1.2, 2.1)
var _players: = []
var _angle = rand_range(0, 2 * PI)
var distance_change_d = true
var distance_change = 200
var change_speed = 3
onready var _capybara_wt_s = $Animation/Sprite
var zone_min = Vector2.ZERO
var zone_max = Vector2.ZERO

export (Resource) var slow_sound

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, players_ref: Array = [], _entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, players_ref, _entity_spawner_ref)
	_players = players_ref
	base_distance = distance
	var capybara_main_for_entity:Main = get_tree().current_scene
	zone_min = zone_min_pos
	zone_max = zone_max_pos

func _physics_process(delta: float) -> void :
#	if distance_change_d and distance < distance_change + base_distance:
#		distance += change_speed
#	elif distance_change_d:
#		distance_change_d = false
#	if not distance_change_d and distance > base_distance - distance_change:
#		distance -= change_speed
#	elif not distance_change_d:
#		distance_change_d = true
	if _is_shooting:
		_capybara_wt_s.modulate = Color.aqua
	else:
		_capybara_wt_s.modulate = Color.white
	rotation = (global_position - _players[player_index].global_position).angle() + PI/2
	if not _is_shooting:
		_angle += delta * rotation_speed
	else:
		_angle += delta * rotation_speed/3.0
	var player_position = _players[player_index].global_position
	var pos_x = clamp(player_position.x + cos(_angle) * distance, zone_min.x, zone_max.x)
	var pos_y = clamp(player_position.y + sin(_angle) * distance, zone_min.y, zone_max.y)
	global_position = Vector2(pos_x, pos_y)

