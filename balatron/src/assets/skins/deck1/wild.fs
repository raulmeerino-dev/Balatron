// Reveal the existing Wild substrate beneath the custom ink. Its markings
// come from the native enhancement atlas, not a replacement illustration.
extern Image centers;
extern vec2 cell_size;
extern vec2 wild_pos;
extern vec2 base_pos;

vec4 effect(vec4 colour, Image texture, vec2 uv, vec2 screen) {
    vec4 c = Texel(texture, uv);
    vec2 p = fract(uv * vec2(13.0, 4.0));
    float marker = 0.0;
    // A little horizontal clearance hides the wider custom suit symbol too.
    // Do not expand vertically into the rank index above the native marking.
    for (int x = -4; x <= 4; x++) {
        vec2 q = p + vec2(float(x) / 71.0, 0.0);
        if (q.x > 0.03 && q.x < 0.97 && q.y > 0.03 && q.y < 0.97) {
            vec3 wild = Texel(centers, (wild_pos + q) * cell_size).rgb;
            vec3 base = Texel(centers, (base_pos + q) * cell_size).rgb;
            vec3 delta = abs(wild - base);
            marker = max(marker, smoothstep(0.08, 0.16, max(delta.r, max(delta.g, delta.b))));
        }
    }
    return vec4(c.rgb, c.a * (1.0 - marker)) * colour;
}
