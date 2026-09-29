shader_type canvas_item;

uniform vec4 opaque_color : hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 partial_alpha_color : hint_color = vec4(0.25, 0.25, 0.25, 1.0);


void fragment() {
	vec4 source_color = texture(TEXTURE, UV);

	if (source_color.a <= 0.0) {
		COLOR = vec4(0.0);
	} else if (source_color.a >= 0.99) {
		COLOR = vec4(opaque_color.rgb, source_color.a * opaque_color.a);
	} else {
		COLOR = vec4(partial_alpha_color.rgb, source_color.a * partial_alpha_color.a);
	}
}
