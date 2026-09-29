class_name CrystalParticleAcceleratorProjectile
extends PlayerProjectile


onready var contents = $Contents
onready var sprite2 = $"%Sprite2"
onready var target_trigger = $"%TargetTriggerHitbox"

export(int) var shooting_range = 10000

# 数值越大，转向越快
export(float) var turn_smoothing = 10.0

# 素材默认朝向为右时保持0
export(float) var rotation_offset = 0.0

# 光线围绕目标摆动的最大半径
export(float) var target_sway_radius = 100.0

# 每隔多少秒更换一次随机偏移位置
export(float) var target_sway_change_interval = 0.15

# 随机偏移自身的平滑速度，数值越大摆动越灵敏
export(float) var target_sway_smoothing = 8.0

# 用于控制持续伤害的循环动画名称
export(String) var damage_animation_name = "fire"

# 武器冷却以物理帧为单位，通常每秒60帧
export(float) var cooldown_units_per_second = 60.0

export(Resource) var crystal_mat = preload(
	"res://mods-unpacked/Dbear-Capybara/contents/projectiles/crystal_projectile_outline_shadermat.tres"
)


var cp_node = null
var current_target = null

var cp_cooldown = 0.0
var current_cooldown = 0.0

var _materials_initialized = false
var targets_in_range = []

# 当前实际使用的随机偏移
var _current_sway_offset = Vector2.ZERO

# 下一次要平滑移动到的随机偏移
var _target_sway_offset = Vector2.ZERO

# 更换随机偏移的计时器
var _sway_change_timer = 0.0

# 记录当前摆动所对应的敌人
var _sway_tracked_target = null


func shoot() -> void:
	_cache_nodes()

	if contents == null:
		print("找不到 Contents")
		return
	.shoot()
	if is_instance_valid(_animation_player):
		_animation_player.stop(true)

		if _animation_player.has_animation("RESET"):
			_animation_player.play("RESET")
			_animation_player.seek(0.0, true)

		if _animation_player.has_animation(damage_animation_name):
			_animation_player.play(damage_animation_name)
			_animation_player.seek(0.0, true)
	velocity = Vector2.ZERO
	_materials_initialized = false

	_setup_crystal_materials()
	_update_material_parameters()
	_update_beam_length()


func shoot_ex(
	p_from: Node,
	pos: Vector2,
	p_velocity: Vector2,
	p_rotation: float,
	p_weapon_stats: WeaponStats,
	damage_tracking_key: int,
	effects: Array,
	hitbox_args: Hitbox.HitboxArgs,
	knockback_direction: Vector2
) -> void:
	.shoot_ex(
		p_from,
		pos,
		p_velocity,
		p_rotation,
		p_weapon_stats,
		damage_tracking_key,
		effects,
		hitbox_args,
		knockback_direction
	)
	if p_weapon_stats is RangedWeaponStats:
		target_sway_radius = 100 * p_weapon_stats.nb_projectiles

	cp_node = p_from

	cp_cooldown = float(p_weapon_stats.cooldown)
	current_cooldown = cp_cooldown

	current_target = null
	targets_in_range.clear()

	_reset_target_sway()
	_update_animation_speed_from_cooldown()


func capybara_manage_hitbox() -> void:
	_hitbox.enable()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(cp_node):
		return
	modulate.a = max(0, modulate.a - 0.03)

	current_cooldown = max(0.0, current_cooldown - 1.0)

	if current_cooldown <= 0.0:
		capybara_manage_hitbox()
	var capy_pos = cp_node.global_position
	if cp_node.has_method("capybara_get_muzzle"):
		capy_pos = cp_node.capybara_get_muzzle()
	# 光束始终跟随释放者
	global_position = capy_pos

	if not current_target:
		_find_new_target()

		if not current_target:
			return

	if current_target.empty():
		_find_new_target()

		if not current_target:
			return

	if not is_instance_valid(current_target[0]):
		_find_new_target()

	if not current_target:
		return

	if current_target.empty():
		return

	if not is_instance_valid(current_target[0]):
		return

	_update_target_sway(delta)
	_smooth_rotate_to_target(delta)


# =========================================================
# 目标附近随机摆动
# =========================================================

func _update_target_sway(delta: float) -> void:
	if not current_target:
		return

	if current_target.empty():
		return

	var target = current_target[0]

	if not is_instance_valid(target):
		return

	# 切换目标时重新初始化摆动
	if _sway_tracked_target != target:
		_sway_tracked_target = target
		_current_sway_offset = Vector2.ZERO
		_target_sway_offset = _get_random_sway_offset()
		_sway_change_timer = max(target_sway_change_interval, 0.01)

	_sway_change_timer -= delta

	if _sway_change_timer <= 0.0:
		_target_sway_offset = _get_random_sway_offset()
		_sway_change_timer = max(target_sway_change_interval, 0.01)

	var sway_weight = clamp(target_sway_smoothing * delta, 0.0, 1.0)

	_current_sway_offset = _current_sway_offset.linear_interpolate(
		_target_sway_offset,
		sway_weight
	)


func _get_random_sway_offset() -> Vector2:
	if target_sway_radius <= 0.0:
		return Vector2.ZERO

	var random_angle = rand_range(0.0, PI * 2.0)

	# 使用平方根让随机点较均匀地分布在圆形区域内
	var random_distance = sqrt(randf()) * target_sway_radius

	return Vector2.RIGHT.rotated(random_angle) * random_distance


func _reset_target_sway() -> void:
	_current_sway_offset = Vector2.ZERO
	_target_sway_offset = Vector2.ZERO
	_sway_change_timer = 0.0
	_sway_tracked_target = null


# =========================================================
# 根据武器冷却调整动画速度
# =========================================================

func _update_animation_speed_from_cooldown() -> void:
	if not is_instance_valid(_animation_player):
		return

	if cp_cooldown <= 0.0:
		return

	if cooldown_units_per_second <= 0.0:
		return

	if not _animation_player.has_animation(damage_animation_name):
		print("找不到动画: ", damage_animation_name)
		return

	var damage_animation = _animation_player.get_animation(damage_animation_name)

	if damage_animation == null:
		return

	if damage_animation.length <= 0.0:
		return

	var cooldown_seconds = cp_cooldown / cooldown_units_per_second
	cooldown_seconds = max(cooldown_seconds, 0.001)

	# 让动画完整播放一轮所需时间等于武器冷却时间
	_animation_player.playback_speed = damage_animation.length / cooldown_seconds


# =========================================================
# 平滑转向
# =========================================================

func _smooth_rotate_to_target(delta: float) -> void:
	if not current_target:
		return

	if current_target.empty():
		return

	if not is_instance_valid(current_target[0]):
		return

	# 目标位置加上随机摆动偏移
	var aim_position = current_target[0].global_position + _current_sway_offset
	var target_direction = aim_position - global_position

	if target_direction.length_squared() <= 0.001:
		return

	var target_rotation = target_direction.angle() + rotation_offset
	var rotation_weight = clamp(turn_smoothing * delta, 0.0, 1.0)

	rotation = lerp_angle(rotation, target_rotation, rotation_weight)


# =========================================================
# 目标选择
# =========================================================

func _find_new_target() -> void:
	_clear_invalid_targets()
	
	if not is_instance_valid(cp_node):
		current_target = null
		_reset_target_sway()
		return

	if targets_in_range.empty():
		current_target = null
		_reset_target_sway()
		return

	current_target = Utils.capybara_get_nearest_boss(
		targets_in_range,
		cp_node.global_position
	)


func _clear_invalid_targets() -> void:
	for index in range(targets_in_range.size() - 1, -1, -1):
		var target = targets_in_range[index]

		if not is_instance_valid(target):
			targets_in_range.remove(index)
			continue

		if target.is_queued_for_deletion():
			targets_in_range.remove(index)


# =========================================================
# 光束长度
# =========================================================

func _update_beam_length() -> void:
	if not is_instance_valid(_sprite):
		return

	if _sprite.texture == null:
		return

	var sprite_width = float(_sprite.texture.get_width())

	if sprite_width <= 0.0:
		return

	var range_value = float(shooting_range)
	var base_scale_x = max(1.0, range_value / sprite_width)

	var hitbox_scale_x = max(
		1.0,
		(range_value + sprite_width * 2.0) / sprite_width
	)

	_sprite.scale.x = base_scale_x
	_hitbox.scale.x = hitbox_scale_x

	_hitbox.position.x = 0.0
	contents.position.x = 0.0


# =========================================================
# 材质
# =========================================================

func _setup_crystal_materials() -> void:
	if _materials_initialized:
		return

	_setup_sprite_material(sprite2)
	_setup_sprite_material(_sprite)

	_materials_initialized = true


func _setup_sprite_material(target_sprite) -> void:
	if not is_instance_valid(target_sprite):
		return

	var source_material = target_sprite.material

	if source_material == null:
		source_material = crystal_mat

	if source_material == null:
		return

	target_sprite.material = source_material.duplicate()


func _update_material_parameters() -> void:
	_update_sprite_material_parameter(sprite2)
	_update_sprite_material_parameter(_sprite)

func capybara_set_current_stats(weapon_stats:RangedWeaponStats):
	_hitbox.damage = weapon_stats.damage
	cp_cooldown = weapon_stats.cooldown

func _update_sprite_material_parameter(target_sprite) -> void:
	if not is_instance_valid(target_sprite):
		return

	if target_sprite.material == null:
		return

	if not target_sprite.material is ShaderMaterial:
		return

	var texture_size = Vector2.ZERO

	if ProgressData.settings.projectile_highlighting:
		if target_sprite.texture != null:
			texture_size = target_sprite.texture.get_size()

	target_sprite.material.set_shader_param("texture_size", texture_size)


# =========================================================
# 节点检查
# =========================================================

func _cache_nodes() -> void:
	if contents == null:
		contents = get_node_or_null("Contents")

	if sprite2 == null:
		sprite2 = get_node_or_null("%Sprite2")

	if target_trigger == null:
		target_trigger = get_node_or_null("%TargetTriggerHitbox")


# =========================================================
# 动画
# =========================================================

func capybara_stop() -> void:
	if not _animation_player.current_animation == "end":
		_animation_player.play("end")



# =========================================================
# 目标范围
# =========================================================

func on_target_died(target: Node, _args: Entity.DieArgs) -> void:
	targets_in_range.erase(target)

	if current_target:
		if not current_target.empty():
			if current_target[0] == target:
				current_target = null
				_reset_target_sway()


func _on_TargetTriggerHitbox_hit_something(thing_hit, _damage_dealt) -> void:
	if not thing_hit is Enemy:
		return

	if not is_instance_valid(thing_hit):
		return

	if thing_hit.is_queued_for_deletion():
		return

	if not thing_hit in targets_in_range:
		targets_in_range.append(thing_hit)

	if thing_hit.has_signal("died"):
		if not thing_hit.is_connected("died", self, "on_target_died"):
			thing_hit.connect("died", self, "on_target_died")


# =========================================================
# 实际造成伤害
# =========================================================

func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
	emit_signal("hit_something", thing_hit, damage_dealt)
	RunData.manage_life_steal(_weapon_stats, _get_player_index())

	_hitbox.disable()
	current_cooldown = cp_cooldown
	modulate.a = ProgressData.settings.projectile_opacity
