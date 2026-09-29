extends TextureProgress

export(Gradient) var progress_gradient: Gradient

var capybara_turret = null
var capybara_fill_mask: Texture = null


func _ready() -> void:
	capybara_turret = get_parent()
	capybara_fill_mask = texture_progress
	min_value = 0.0
	max_value = 100.0
	fill_mode = TextureProgress.FILL_LEFT_TO_RIGHT
	nine_patch_stretch = true
	visible = false
	capybara_refresh_gradient()


func _process(_delta: float) -> void:
	if not is_instance_valid(capybara_turret) or not capybara_turret.has_method("capybara_owner_in_range"):
		visible = false
		return
	visible = capybara_turret.capybara_owner_in_range()
	if not visible:
		return
	if capybara_turret._is_shooting:
		value = 0.0
	elif capybara_turret.capybara_cooldown_duration <= 0.0:
		value = 100.0
	else:
		value = clamp(1.0 - capybara_turret.capybara_cooldown / capybara_turret.capybara_cooldown_duration, 0.0, 1.0) * 100.0


func capybara_refresh_gradient() -> void:
	if progress_gradient == null:
		progress_gradient = Gradient.new()
		progress_gradient.colors = PoolColorArray([Color(0.57, 0.82, 1.0), Color(0.94, 0.62, 1.0)])
	if capybara_fill_mask == null:
		return
	var capybara_mask: Image = capybara_fill_mask.get_data()
	if capybara_mask == null or capybara_mask.get_width() <= 0 or capybara_mask.get_height() <= 0:
		return
	capybara_mask.convert(Image.FORMAT_RGBA8)
	var capybara_width: int = capybara_mask.get_width()
	var capybara_height: int = capybara_mask.get_height()
	var capybara_image: Image = Image.new()
	capybara_image.create(capybara_width, capybara_height, false, Image.FORMAT_RGBA8)
	capybara_mask.lock()
	capybara_image.lock()
	for capybara_y in range(capybara_height):
		for capybara_x in range(capybara_width):
			var capybara_color: Color = progress_gradient.interpolate(float(capybara_x) / float(max(1, capybara_width - 1)))
			capybara_color.a *= capybara_mask.get_pixel(capybara_x, capybara_y).a
			capybara_image.set_pixel(capybara_x, capybara_y, capybara_color)
	capybara_image.unlock()
	capybara_mask.unlock()
	var capybara_texture: ImageTexture = ImageTexture.new()
	capybara_texture.create_from_image(capybara_image, Texture.FLAG_FILTER)
	texture_progress = capybara_texture
	tint_progress = Color.white
