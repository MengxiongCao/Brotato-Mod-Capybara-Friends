class_name CapybaraCrystalTurretEnegyBar
extends TextureProgress


# 自动更新间隔。
export(float, 0.1, 60.0) var update_interval: float = 0.2

# 是否进入场景后立即刷新显示。
export(bool) var update_immediately: bool = true

# 最大能量。
export(float, 0.01, 999999.0) var capybara_max_energy: float = 600.0

# 每次定时器触发时减少的能量。
export(float, 0.0, 999999.0) var capybara_energy_decrease_per_update: float = 1.0

# 进度条渐变色。
export(Gradient) var progress_gradient: Gradient

# 渐变纹理精度。
export(int, 2, 2048) var gradient_width: int = 512


var capybara_update_timer: Timer = null
var capybara_energy_change_timer: Timer = null
var capybara_flash_tween: Tween = null
var capybara_gradient_texture: ImageTexture = null
var capybara_progress_mask_texture: Texture = null

var capybara_progress_mask_inset: int = 1
var capybara_normal_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)

var capybara_current_energy: float = 0.0
var capybara_last_charged_energy: float = 0.0
var capybara_energy_active: bool = false
var capybara_energy_empty_triggered: bool = false
var capybara_initial_max_energy: float = 0.0
var capybara_initial_bar_width: float = 0.0
var capybara_initial_bar_left: float = 0.0

var player_index: int = -1
var player: Player = null
var _parent = null

onready var _level_label = get_node_or_null("%CrystalProgressLabel")


func _ready() -> void:
	_parent = get_parent()
	capybara_initial_max_energy = max(0.01, capybara_max_energy)
	capybara_initial_bar_width = rect_size.x
	capybara_initial_bar_left = rect_position.x
	capybara_progress_mask_texture = texture_progress

	if capybara_progress_mask_texture == null:
		capybara_progress_mask_texture = texture_under

	rect_clip_content = true
	capybara_setup_progress_gradient()
	capybara_create_flash_tween()
	capybara_create_update_timer()
	capybara_create_energy_change_timer()
	

	capybara_current_energy = max(0.0, capybara_max_energy)

	if update_immediately:
		capybara_refresh_energy_bar()


func capybara_set_player(main_player: Player) -> void:
	if not is_instance_valid(main_player):
		return

	player = main_player
	player_index = main_player.player_index
	capybara_energy_active = true
	
	capybara_reset_energy()

	# 重新开始计时，保证绑定玩家后等待完整的update_interval再减少。
	if is_instance_valid(capybara_update_timer):
		capybara_update_timer.start()
	if is_instance_valid(capybara_energy_change_timer):
		capybara_energy_change_timer.start()


# ============================================================
# 渐变能量条
# ============================================================

func capybara_setup_progress_gradient() -> void:
	if progress_gradient == null:
		progress_gradient = capybara_create_default_gradient()

	capybara_gradient_texture = capybara_create_masked_gradient_texture()
	texture_progress = capybara_gradient_texture
	tint_progress = Color(1.0, 1.0, 1.0, 1.0)
	fill_mode = TextureProgress.FILL_LEFT_TO_RIGHT
	nine_patch_stretch = true


func capybara_create_default_gradient() -> Gradient:
	var capybara_gradient: Gradient = Gradient.new()

	capybara_gradient.offsets = PoolRealArray([0.0, 0.17, 0.34, 0.50, 0.67, 0.84, 1.0])
	capybara_gradient.colors = PoolColorArray([
		Color(1.00, 0.68, 0.78, 1.0),
		Color(0.94, 0.70, 1.00, 1.0),
		Color(0.66, 0.78, 1.00, 1.0),
		Color(0.58, 0.94, 1.00, 1.0),
		Color(0.62, 1.00, 0.80, 1.0),
		Color(1.00, 0.94, 0.58, 1.0),
		Color(1.00, 0.72, 0.64, 1.0)
	])

	return capybara_gradient


func capybara_create_masked_gradient_texture() -> ImageTexture:
	if capybara_progress_mask_texture == null:
		return capybara_create_fallback_gradient_texture()

	var capybara_mask_image: Image = capybara_progress_mask_texture.get_data()

	if capybara_mask_image == null or capybara_mask_image.get_width() <= 0 or capybara_mask_image.get_height() <= 0:
		return capybara_create_fallback_gradient_texture()

	capybara_mask_image.convert(Image.FORMAT_RGBA8)

	var capybara_width: int = capybara_mask_image.get_width()
	var capybara_height: int = capybara_mask_image.get_height()
	var capybara_result_image: Image = Image.new()

	capybara_result_image.create(capybara_width, capybara_height, false, Image.FORMAT_RGBA8)
	capybara_mask_image.lock()
	capybara_result_image.lock()

	for capybara_y in range(capybara_height):
		for capybara_x in range(capybara_width):
			var capybara_position: float = float(capybara_x) / float(max(1, capybara_width - 1))
			var capybara_mask_alpha: float = capybara_get_mask_alpha(capybara_mask_image, capybara_x, capybara_y, capybara_width, capybara_height)
			var capybara_color: Color = progress_gradient.interpolate(capybara_position)

			capybara_color.a *= capybara_mask_alpha
			capybara_result_image.set_pixel(capybara_x, capybara_y, capybara_color)

	capybara_result_image.unlock()
	capybara_mask_image.unlock()

	var capybara_texture: ImageTexture = ImageTexture.new()
	capybara_texture.create_from_image(capybara_result_image, Texture.FLAG_FILTER)

	return capybara_texture


func capybara_get_mask_alpha(capybara_image: Image, capybara_x: int, capybara_y: int, capybara_width: int, capybara_height: int) -> float:
	var capybara_alpha: float = 1.0
	var capybara_inset: int = max(0, capybara_progress_mask_inset)

	for capybara_offset_y in range(-capybara_inset, capybara_inset + 1):
		for capybara_offset_x in range(-capybara_inset, capybara_inset + 1):
			var capybara_sample_x: int = capybara_x + capybara_offset_x
			var capybara_sample_y: int = capybara_y + capybara_offset_y

			if capybara_sample_x < 0 or capybara_sample_x >= capybara_width:
				return 0.0

			if capybara_sample_y < 0 or capybara_sample_y >= capybara_height:
				return 0.0

			capybara_alpha = min(capybara_alpha, capybara_image.get_pixel(capybara_sample_x, capybara_sample_y).a)

	return capybara_alpha


func capybara_create_fallback_gradient_texture() -> ImageTexture:
	var capybara_width: int = max(2, gradient_width)
	var capybara_height: int = max(2, int(round(max(rect_size.y, rect_min_size.y))))
	var capybara_image: Image = Image.new()

	capybara_image.create(capybara_width, capybara_height, false, Image.FORMAT_RGBA8)
	capybara_image.lock()

	for capybara_y in range(capybara_height):
		for capybara_x in range(capybara_width):
			var capybara_position: float = float(capybara_x) / float(max(1, capybara_width - 1))
			var capybara_color: Color = progress_gradient.interpolate(capybara_position)
			var capybara_inside: bool = capybara_x >= capybara_progress_mask_inset and capybara_x < capybara_width - capybara_progress_mask_inset and capybara_y >= capybara_progress_mask_inset and capybara_y < capybara_height - capybara_progress_mask_inset

			if not capybara_inside:
				capybara_color.a = 0.0

			capybara_image.set_pixel(capybara_x, capybara_y, capybara_color)

	capybara_image.unlock()

	var capybara_texture: ImageTexture = ImageTexture.new()
	capybara_texture.create_from_image(capybara_image, Texture.FLAG_FILTER)

	return capybara_texture


func capybara_refresh_progress_gradient() -> void:
	if progress_gradient == null:
		progress_gradient = capybara_create_default_gradient()

	capybara_gradient_texture = capybara_create_masked_gradient_texture()
	texture_progress = capybara_gradient_texture
	tint_progress = Color(1.0, 1.0, 1.0, 1.0)


# ============================================================
# 能量耗尽闪烁
# ============================================================

func capybara_create_flash_tween() -> void:
	capybara_normal_modulate = modulate
	capybara_flash_tween = Tween.new()
	capybara_flash_tween.name = "CapybaraFlashTween"
	add_child(capybara_flash_tween)


# 保留原来的函数名称，避免已有代码调用失效。
func capybara_play_level_up_flash() -> void:
	if not is_instance_valid(capybara_flash_tween):
		return

	capybara_flash_tween.stop_all()
	capybara_flash_tween.remove_all()
	modulate = capybara_normal_modulate

	var capybara_flash_color: Color = Color(1.0, 1.0, 1.0, 0.18)

	capybara_flash_tween.interpolate_property(self, "modulate", capybara_normal_modulate, capybara_flash_color, 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
	capybara_flash_tween.interpolate_property(self, "modulate", capybara_flash_color, capybara_normal_modulate, 0.14, Tween.TRANS_SINE, Tween.EASE_IN, 0.07)
	capybara_flash_tween.interpolate_property(self, "modulate", capybara_normal_modulate, capybara_flash_color, 0.06, Tween.TRANS_SINE, Tween.EASE_OUT, 0.21)
	capybara_flash_tween.interpolate_property(self, "modulate", capybara_flash_color, capybara_normal_modulate, 0.18, Tween.TRANS_SINE, Tween.EASE_IN, 0.27)
	capybara_flash_tween.start()


# ============================================================
# 定时更新
# ============================================================

func capybara_create_update_timer() -> void:
	if is_instance_valid(capybara_update_timer):
		return

	capybara_update_timer = Timer.new()
	capybara_update_timer.name = "CapybaraUpdateTimer"
	capybara_update_timer.wait_time = max(0.1, update_interval)
	capybara_update_timer.one_shot = false
	add_child(capybara_update_timer)

	if not capybara_update_timer.is_connected("timeout", self, "_on_capybara_update_timer_timeout"):
		capybara_update_timer.connect("timeout", self, "_on_capybara_update_timer_timeout")

	capybara_update_timer.start()


func _on_capybara_update_timer_timeout() -> void:
	capybara_update_energy_bar()


func capybara_create_energy_change_timer() -> void:
	if is_instance_valid(capybara_energy_change_timer):
		return

	capybara_energy_change_timer = Timer.new()
	capybara_energy_change_timer.name = "CapybaraEnergyChangeTimer"
	capybara_energy_change_timer.wait_time = 0.3
	capybara_energy_change_timer.one_shot = false
	add_child(capybara_energy_change_timer)

	if not capybara_energy_change_timer.is_connected("timeout", self, "_on_capybara_energy_change_timer_timeout"):
		capybara_energy_change_timer.connect("timeout", self, "_on_capybara_energy_change_timer_timeout")

	capybara_energy_change_timer.start()


func _on_capybara_energy_change_timer_timeout() -> void:
	if not capybara_energy_active:
		return

	capybara_update_charged_energy_change()


# ============================================================
# 更新能量
# ============================================================

func capybara_update_energy_bar() -> void:
	if not capybara_energy_active:
		return

	if capybara_max_energy <= 0.0:
		return

	if capybara_current_energy <= 0.0:
		return
	var new_capybara_energy_decrease_per_update = ( _parent.crystal_level + 1.0 ) * capybara_energy_decrease_per_update
	capybara_reduce_energy(new_capybara_energy_decrease_per_update)


# 每次更新时读取能量属性，并把属性的变化量同步到当前能量。
func capybara_update_charged_energy_change() -> void:
	if player_index < 0:
		return

	var capybara_charged_energy: float = float(RunData.get_stat(
		Keys.generate_hash("capybara_crystal_turret_energy"),
		player_index
	))
	var capybara_energy_change: int = capybara_charged_energy - capybara_last_charged_energy

	if capybara_current_energy <= 0:
		get_parent().capybara_has_shoot = false
	capybara_last_charged_energy = capybara_charged_energy

	if capybara_charged_energy > capybara_max_energy:
		capybara_max_energy = capybara_charged_energy
	capybara_current_energy += capybara_energy_change

	capybara_set_energy(capybara_current_energy)


func capybara_refresh_energy_bar() -> void:
	capybara_max_energy = max(capybara_initial_max_energy, capybara_current_energy)
	capybara_current_energy = clamp(capybara_current_energy, 0.0, max(0.0, capybara_max_energy))
	var capybara_bar_width: float = capybara_initial_bar_width * capybara_max_energy / capybara_initial_max_energy
	rect_size = Vector2(capybara_bar_width, rect_size.y)
	rect_position = Vector2(capybara_initial_bar_left - (capybara_bar_width - capybara_initial_bar_width) * rect_scale.x / 2.0, rect_position.y)

	min_value = 0.0
	max_value = max(0.01, capybara_max_energy)
	value = clamp(capybara_current_energy, min_value, max_value)

	if is_instance_valid(_level_label):
		_level_label.text = str(int(ceil(capybara_current_energy)))


# 重新充满能量。
func capybara_reset_energy() -> void:
	var capybara_charged_energy: float = float(RunData.get_stat(Keys.generate_hash("capybara_crystal_turret_energy"), player_index))
	capybara_last_charged_energy = capybara_charged_energy
	capybara_current_energy = max(1.0, capybara_charged_energy)
	if capybara_charged_energy > capybara_max_energy:
		capybara_max_energy = capybara_charged_energy
	capybara_energy_empty_triggered = false
	capybara_refresh_energy_bar()


# 直接设置当前能量。
func capybara_set_energy(capybara_energy: float) -> void:
	var capybara_previous_energy: float = capybara_current_energy

	capybara_max_energy = max(capybara_max_energy, capybara_energy)
	capybara_current_energy = clamp(capybara_energy, 0.0, max(0.0, capybara_max_energy))

	if capybara_current_energy > 0.0:
		capybara_energy_empty_triggered = false

	if capybara_previous_energy > 0.0 and capybara_current_energy <= 0.0 and not capybara_energy_empty_triggered:
		capybara_energy_empty_triggered = true
		capybara_play_level_up_flash()
		capybara_on_energy_empty()

	capybara_refresh_energy_bar()


# 减少能量。
func capybara_reduce_energy(capybara_amount: float) -> void:
	if capybara_amount <= 0.0:
		return

	if capybara_current_energy <= 0.0:
		return

	capybara_set_energy(capybara_current_energy - capybara_amount)


# 恢复能量。
func capybara_restore_energy(capybara_amount: float) -> void:
	if capybara_amount <= 0.0:
		return

	capybara_set_energy(capybara_current_energy + capybara_amount)


# 开启或暂停自动递减。
func capybara_set_energy_active(capybara_active: bool) -> void:
	capybara_energy_active = capybara_active


# 获取当前能量比例。
func capybara_get_energy_ratio() -> float:
	if capybara_max_energy <= 0.0:
		return 0.0

	return clamp(capybara_current_energy / capybara_max_energy, 0.0, 1.0)


# 能量归零时调用一次，可以在这里填充炮塔停止攻击等逻辑。
func capybara_on_energy_empty() -> void:
	if _parent and is_instance_valid(_parent):
		_parent.capybara_disabled_crystal_turret()
