class_name CrystalTree
extends "res://entities/units/enemies/enemy.gd"

var attack_time = 3
var main = null
var open_texture = load("res://mods-unpacked/Dbear-Capybara/contents/enemies/crystal_tree/cp_crystal_tree_attack.png")
var close_texture = load("res://mods-unpacked/Dbear-Capybara/contents/enemies/crystal_tree/cp_crystal_tree.png")
func _ready() -> void:
	main = get_tree().current_scene
	_can_move = false
	_attack_behavior.connect("shot", self, "capybara_on_shoot")

func capybara_on_shoot() -> void:
	if get_tree():
		yield(get_tree().create_timer(0.5),"timeout")
		sprite.texture = open_texture
	if get_tree():
		yield(get_tree().create_timer(1),"timeout")
		sprite.texture = close_texture

func respawn() -> void :
	.respawn()
	_can_move = false


func die(args: = Utils.default_die_args) -> void :
	.die(args)
	if args.enemy_killed_by_player and args.killed_by_player_index >= 0 and args.killed_by_player_index < players_ref.size() and is_instance_valid(players_ref[args.killed_by_player_index]):
		RunData.add_stat(Keys.generate_hash("stat_capybara_crystal"), 1, args.killed_by_player_index)
