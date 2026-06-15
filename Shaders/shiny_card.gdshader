shader_type canvas_item;

uniform vec4 shine_color : source_color = vec4(1.0);
uniform float sweep_pos = 0.0;
uniform float intensity = 0.25;
uniform float width = 0.5;

void fragment() {
	vec4 col = COLOR;

	float diag = UV.x + UV.y;

	float shine = smoothstep(
		sweep_pos - width,
		sweep_pos,
		diag
	) * (1.0 - smoothstep(
		sweep_pos,
		sweep_pos + width,
		diag
	));

	shine = pow(shine, 2.5);

	vec3 result = col.rgb + shine_color.rgb * shine * intensity;

	COLOR = vec4(result, col.a);
}