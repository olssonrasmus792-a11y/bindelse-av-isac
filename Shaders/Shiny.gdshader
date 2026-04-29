shader_type canvas_item;

uniform float sweep_pos : hint_range(-1.0, 2.0) = -1.0;
uniform float width : hint_range(0.01, 0.5) = 0.15;
uniform float intensity : hint_range(0.0, 2.0) = 1.2;
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	float line = (UV.x + UV.y) * 0.5;

	float shine = smoothstep(sweep_pos - width, sweep_pos, line) *
				  (1.0 - smoothstep(sweep_pos, sweep_pos + width, line));

	vec3 final_color = tex.rgb + shine * intensity * shine_color.rgb;

	COLOR = vec4(final_color, tex.a);
}