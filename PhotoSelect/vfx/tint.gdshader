shader_type spatial;
uniform vec4 tint_colour: source_color = vec4(1.0, 1.0, 1.0, 0.5);

void fragment() {
	ALBEDO = tint_colour.rgb;
	ALPHA = tint_colour.a;
}
