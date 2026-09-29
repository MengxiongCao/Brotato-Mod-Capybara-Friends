class_name CapybaraExperienceBar
extends TextureProgress


export(float, 0.1, 60.0) var update_interval: float = 1.0
export(bool) var update_immediately: bool = true
export(float) var capybara_max_xp: float = 10.0
export(Gradient) var progress_gradient: Gradient
export(int, 2, 2048) var gradient_width: int = 512


var capybara_update_timer: Timer = null
var capybara_flash_tween: Tween = null
var capybara_gradient_texture: ImageTexture = null
var capybara_progress_mask_texture: Texture = null

var capybara_progress_mask_inset: int = 1
var capybara_last_completed_xp_count: int = 0
var capybara_normal_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)

var player_index: int = -1
var player: Player = null

onready var _level_label = $"%CrystalProgressLabel"


func _ready() -> void:
	capybara_progress_mask_texture = texture_progress

	if capybara_progress_mask_texture == null:
		capybara_progress_mask_texture = texture_under

	rect_clip_content = true
	capybara_setup_progress_gradient()
	capybara_create_flash_tween()
	capybara_create_update_timer()

	if update_immediately and player_index >= 0:
		capybara_update_experience_bar()


func capybara_set_player(main_player: Player) -> void:
	if not is_instance_valid(main_player):
		return

	player = main_player
	player_index = main_player.player_index
	player._capybara_manage_crystallized()

	# 以已经实际结算的晶化等级作为起点，而不是以当前晶化度推算。
	# 这样角色初始拥有 10 点（或更多）晶化度、但等级仍为 0 时，
	# 下方的首次更新仍会正确补发升级。
	capybara_last_completed_xp_count = max(
		0,
		int(RunData.get_stat(Keys.generate_hash("stat_capybara_crystal_state"), player_index))
	)

	capybara_update_experience_bar()


# ============================================================
# 渐变经验条
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
# 升级闪烁
# ============================================================

func capybara_create_flash_tween() -> void:
	capybara_normal_modulate = modulate
	capybara_flash_tween = Tween.new()
	capybara_flash_tween.name = "CapybaraFlashTween"
	add_child(capybara_flash_tween)


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
	capybara_update_experience_bar()


# ============================================================
# 更新经验值
# ============================================================

func capybara_update_experience_bar() -> void:
	if capybara_max_xp <= 0.0 or player_index < 0:
		return

	var capybara_total_experience: float = float(RunData.get_stat(Keys.generate_hash("stat_capybara_crystal"), player_index))
	var capybara_completed_xp_count: int = int(floor(capybara_total_experience / capybara_max_xp))
	var capybara_current_experience: float = fmod(capybara_total_experience, capybara_max_xp)
	var capybara_previous_crystal_state: int = int(RunData.get_stat(Keys.generate_hash("stat_capybara_crystal_state"), player_index))
	var capybara_max_crystal_state: int = int(Utils.CAPYBARA_DAMAGE_TAKEN_TO_BREAK)

	if capybara_current_experience < 0.0:
		capybara_current_experience += capybara_max_xp

	if capybara_completed_xp_count > capybara_last_completed_xp_count:
		capybara_last_completed_xp_count = capybara_completed_xp_count

		# 满级后只同步已经处理的晶化度档位，不再重复执行升级和闪烁。
		if capybara_previous_crystal_state < capybara_max_crystal_state and is_instance_valid(player):
			player._capybara_manage_crystallized()

			# 只有实际等级发生提升时才播放一次升级闪烁。
			var capybara_updated_crystal_state: int = int(RunData.get_stat(Keys.generate_hash("stat_capybara_crystal_state"), player_index))
			if capybara_updated_crystal_state > capybara_previous_crystal_state:
				capybara_play_level_up_flash()

	elif capybara_completed_xp_count < capybara_last_completed_xp_count:
		capybara_last_completed_xp_count = capybara_completed_xp_count

	var current_crystal_state: int = int(RunData.get_stat(Keys.generate_hash("stat_capybara_crystal_state"), player_index))
	if _level_label:
		if current_crystal_state >= capybara_max_crystal_state:
			capybara_current_experience = capybara_max_xp
			_level_label.text = "max"
		else:
			_level_label.text = str(current_crystal_state)

	min_value = 0.0
	max_value = capybara_max_xp
	value = clamp(capybara_current_experience, min_value, max_value)
