class_name FairyTurret
extends "res://entities/structures/turret/turret.gd"

var distance = rand_range(100, 200)
var rotation_speed = rand_range(2, 2.5)

var _players := []
var _angle = rand_range(0, 2 * PI)

var zone_min = Vector2.ZERO
var zone_max = Vector2.ZERO

onready var fairy_sprite = $Animation/Sprite

var float_time = 0.0
var float_amplitude := 50.0 # 浮动高度
var float_speed := 8.0     # 浮动速度


func init(
	zone_min_pos: Vector2,
	zone_max_pos: Vector2,
	players_ref: Array = [],
	_entity_spawner_ref = null
) -> void:
	.init(zone_min_pos, zone_max_pos, players_ref, _entity_spawner_ref)

	_players = players_ref
	zone_min = zone_min_pos
	zone_max = zone_max_pos


func _physics_process(delta: float) -> void:
	if _players.empty():
		return

	if _is_shooting:
		fairy_sprite.modulate = Color.aquamarine
	else:
		fairy_sprite.modulate = Color.white

	# 环绕角度
	_angle += delta * rotation_speed
	if _angle > 2 * PI:
		_angle -= 2 * PI

	# 上下浮动时间
	float_time += delta * float_speed
	
	if float_time > 2*PI:
		float_time -= 2*PI

	var player_position = _players[player_index].global_position

	var float_offset_y = sin(float_time) * float_amplitude

	var pos_x = clamp(
		player_position.x + cos(_angle) * distance * 1.5,
		zone_min.x,
		zone_max.x
	)

	var pos_y = clamp(
		player_position.y + sin(_angle) * distance + float_offset_y,
		zone_min.y,
		zone_max.y
	)

	if _angle > PI and _angle < 2 * PI:
		fairy_sprite.flip_h = false
	else:
		fairy_sprite.flip_h = true

	global_position = Vector2(pos_x, pos_y)

