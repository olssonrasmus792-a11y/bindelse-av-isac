shader_type particles;
render_mode keep_data;

uniform float ground_y = 120.0;
uniform float bounce = 0.0;

void process() {
    vec2 pos = TRANSFORM[3].xy;

    if (pos.y >= ground_y) {
        pos.y = ground_y;
        TRANSFORM[3].xy = pos;

        if (VELOCITY.y > 0.0) {
            VELOCITY.y = -VELOCITY.y * bounce;
        }
    }
}
