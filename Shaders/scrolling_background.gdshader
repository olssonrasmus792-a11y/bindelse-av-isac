shader_type canvas_item;
uniform vec4 bg_color : source_color = vec4(0.03, 0.03, 0.07, 1.0);
uniform vec4 line_color : source_color = vec4(0.1, 0.1, 0.3, 1.0);
uniform vec4 glow_color : source_color = vec4(0.2, 0.4, 1.0, 1.0);
uniform float grid_size : hint_range(0.01, 0.2) = 0.06;
uniform float line_thickness : hint_range(0.0, 0.05) = 0.002;
uniform float scroll_speed : hint_range(0.0, 0.2) = 0.06;
uniform float motion_strength : hint_range(0.0, 0.02) = 0.007;
uniform float motion_speed1 : hint_range(0.0, 0.1) = 0.03;
uniform float motion_speed2 : hint_range(0.0, 0.1) = 0.015;

void fragment() {
	vec2 uv = UV;
	float wave1 = sin((uv.x + uv.y) * 10.0 + TIME * motion_speed1);
	float wave2 = sin((uv.x - uv.y) * 50.0 + TIME * motion_speed2);
	float subtle = (wave1 + wave2) * 0.5 * motion_strength;
	vec2 warped_uv = uv + vec2(subtle, subtle);
	vec2 scrolled = warped_uv + vec2(TIME * scroll_speed, TIME * scroll_speed);
	vec2 grid = fract(scrolled / grid_size);
	float lineX = step(1.0 - line_thickness / grid_size, grid.x);
	float lineY = step(1.0 - line_thickness / grid_size, grid.y);
	float lines = max(lineX, lineY);
	vec2 centered = uv - vec2(0.5);
	float dist = length(centered);
	float pulse = sin(TIME * 0.4) * 0.5 + 0.5;
	float glow = smoothstep(0.9, 0.0, dist) * 0.1 * pulse;
	vec4 col = bg_color;
	col = mix(col, line_color, lines * 0.5);
	col += glow_color * glow;
	COLOR = col;
}