shader_type canvas_item;
render_mode blend_add;

uniform vec4 flow_color : hint_color = vec4(0.45, 0.90, 1.00, 0.85);
uniform vec4 flow_color_end : hint_color = vec4(0.90, 0.45, 1.00, 0.85);
uniform sampler2D flow_gradient_texture;
uniform float flow_gradient_enabled = 0.0;
uniform float flow_speed = 0.35;
uniform float flow_angle = 0.785398;
uniform float flow_width = 0.12;
uniform float flow_softness = 0.08;
uniform float flow_interval = 1.40;
uniform float flow_intensity = 0.80;
uniform float flow_enabled = 1.0;


void fragment() {
	vec4 source_color = texture(TEXTURE, UV);
	vec2 centered_uv = UV - vec2(0.5);
	vec2 flow_direction = vec2(cos(flow_angle), sin(flow_angle));
	float axis_position = dot(centered_uv, flow_direction);
	float period = max(flow_interval, 0.001);
	float half_period = period * 0.5;
	float wrapped_position = mod(axis_position - TIME * flow_speed + half_period, period) - half_period;
	float distance_to_light = abs(wrapped_position);
	float light_band = 1.0 - smoothstep(flow_width * 0.5, flow_width * 0.5 + flow_softness, distance_to_light);
	float gradient_range = max(flow_width + flow_softness * 2.0, 0.001);
	float gradient_position = clamp(wrapped_position / gradient_range + 0.5, 0.0, 1.0);
	vec4 gradient_color = mix(flow_color, flow_color_end, gradient_position);
	if (flow_gradient_enabled > 0.5) {
		gradient_color = texture(flow_gradient_texture, vec2(gradient_position, 0.5));
	}
	float light_alpha = source_color.a * gradient_color.a * light_band * flow_enabled;
	vec3 light_color = gradient_color.rgb * flow_intensity;

	COLOR = vec4(light_color, clamp(light_alpha, 0.0, 1.0));
}
