shader_type canvas_item;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_tex;
uniform vec4 burn_color : source_color = vec4(1.0, 0.3, 0.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float noise = texture(noise_tex, UV).r;
	float edge = smoothstep(burn_progress - 0.05, burn_progress, noise);
	float dissolve = step(burn_progress, noise);
	vec4 final_color = tex;

    // Glow edge
	if (edge > 0.0 && dissolve < 1.0) {
		final_color = mix(final_color, burn_color, 1.0);
	}

    // Dissolve
	final_color.a *= dissolve;

COLOR = final_color;
}