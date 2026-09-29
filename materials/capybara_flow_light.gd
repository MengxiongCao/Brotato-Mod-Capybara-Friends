extends Sprite


const FLOW_LIGHT_MATERIAL = preload("res://mods-unpacked/Dbear-Capybara/materials/capybara_flow_light_material.tres")

export(bool) var enabled = true setget set_enabled
export(Color) var flow_color = Color(0.45, 0.90, 1.00, 0.85) setget set_flow_color
export(Color) var flow_color_end = Color(0.90, 0.45, 1.00, 0.85) setget set_flow_color_end
export(Gradient) var flow_gradient = null setget set_flow_gradient
export(float, -3.0, 3.0, 0.01) var flow_speed = 0.35 setget set_flow_speed
export(float, -180.0, 180.0, 1.0) var flow_angle_degrees = 45.0 setget set_flow_angle_degrees
export(float, 0.01, 1.0, 0.01) var flow_width = 0.12 setget set_flow_width
export(float, 0.001, 0.5, 0.001) var flow_softness = 0.08 setget set_flow_softness
export(float, 0.1, 4.0, 0.05) var flow_interval = 1.40 setget set_flow_interval
export(float, 0.0, 2.0, 0.01) var flow_intensity = 0.80 setget set_flow_intensity

var _flow_material: ShaderMaterial = null
var _flow_gradient_texture: GradientTexture = null
var _target: Sprite = null


func _ready() -> void:
	_setup_overlay()


func _process(_delta: float) -> void:
	_sync_with_parent()


func _setup_overlay() -> void:
	var parent = get_parent()
	if not parent is Sprite:
		push_warning("CapybaraFlowLight must be added as a direct child of a Sprite.")
		visible = false
		set_process(false)
		return

	_target = parent
	_flow_material = FLOW_LIGHT_MATERIAL.duplicate(true) as ShaderMaterial
	use_parent_material = false
	material = _flow_material
	position = Vector2.ZERO
	rotation = 0.0
	scale = Vector2.ONE
	_sync_with_parent(true)
	_update_shader_parameters()


func _sync_with_parent(force: bool = false) -> void:
	if not is_instance_valid(_target):
		visible = false
		set_process(false)
		return

	if force or texture != _target.texture:
		texture = _target.texture
	if force or centered != _target.centered:
		centered = _target.centered
	if force or offset != _target.offset:
		offset = _target.offset
	if force or flip_h != _target.flip_h:
		flip_h = _target.flip_h
	if force or flip_v != _target.flip_v:
		flip_v = _target.flip_v
	if force or hframes != _target.hframes:
		hframes = _target.hframes
	if force or vframes != _target.vframes:
		vframes = _target.vframes
	if force or frame != _target.frame:
		frame = _target.frame
	if force or region_enabled != _target.region_enabled:
		region_enabled = _target.region_enabled
	if force or region_rect != _target.region_rect:
		region_rect = _target.region_rect
	if force or region_filter_clip != _target.region_filter_clip:
		region_filter_clip = _target.region_filter_clip

	var target_alpha = _target.self_modulate.a
	if force or not is_equal_approx(self_modulate.a, target_alpha):
		self_modulate = Color(1.0, 1.0, 1.0, target_alpha)


func _update_shader_parameters() -> void:
	if not is_instance_valid(_flow_material):
		return
	_flow_material.set_shader_param("flow_enabled", 1.0 if enabled else 0.0)
	_flow_material.set_shader_param("flow_color", flow_color)
	_flow_material.set_shader_param("flow_color_end", flow_color_end)
	_update_flow_gradient_parameter()
	_flow_material.set_shader_param("flow_speed", flow_speed)
	_flow_material.set_shader_param("flow_angle", deg2rad(flow_angle_degrees))
	_flow_material.set_shader_param("flow_width", flow_width)
	_flow_material.set_shader_param("flow_softness", flow_softness)
	_flow_material.set_shader_param("flow_interval", flow_interval)
	_flow_material.set_shader_param("flow_intensity", flow_intensity)


func _update_flow_gradient_parameter() -> void:
	if not is_instance_valid(_flow_material):
		return
	if flow_gradient == null:
		_flow_material.set_shader_param("flow_gradient_enabled", 0.0)
		return
	if not is_instance_valid(_flow_gradient_texture):
		_flow_gradient_texture = GradientTexture.new()
	_flow_gradient_texture.gradient = flow_gradient
	_flow_material.set_shader_param("flow_gradient_texture", _flow_gradient_texture)
	_flow_material.set_shader_param("flow_gradient_enabled", 1.0)


func _on_flow_gradient_changed() -> void:
	_update_flow_gradient_parameter()


func set_enabled(value: bool) -> void:
	enabled = value
	_update_shader_parameters()


func set_flow_color(value: Color) -> void:
	flow_color = value
	_update_shader_parameters()


func set_flow_color_end(value: Color) -> void:
	flow_color_end = value
	_update_shader_parameters()


func set_flow_gradient(value: Gradient) -> void:
	if flow_gradient != null and flow_gradient.is_connected("changed", self, "_on_flow_gradient_changed"):
		flow_gradient.disconnect("changed", self, "_on_flow_gradient_changed")
	flow_gradient = value
	if flow_gradient != null and not flow_gradient.is_connected("changed", self, "_on_flow_gradient_changed"):
		flow_gradient.connect("changed", self, "_on_flow_gradient_changed")
	_update_flow_gradient_parameter()


func set_flow_speed(value: float) -> void:
	flow_speed = value
	_update_shader_parameters()


func set_flow_angle_degrees(value: float) -> void:
	flow_angle_degrees = value
	_update_shader_parameters()


func set_flow_width(value: float) -> void:
	flow_width = value
	_update_shader_parameters()


func set_flow_softness(value: float) -> void:
	flow_softness = value
	_update_shader_parameters()


func set_flow_interval(value: float) -> void:
	flow_interval = value
	_update_shader_parameters()


func set_flow_intensity(value: float) -> void:
	flow_intensity = value
	_update_shader_parameters()
