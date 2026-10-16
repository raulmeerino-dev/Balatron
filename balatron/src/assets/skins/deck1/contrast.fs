// Atlas rows: Hearts, Clubs, Diamonds, Spades. Preserve ink and alpha.
extern bool suit_tint;
vec4 effect(vec4 colour, Image texture, vec2 uv, vec2 screen) {
    vec4 c = Texel(texture, uv);
    vec3 rgb = clamp((c.rgb - 0.5) * 1.08 + 0.5, 0.0, 1.0);
    float row = floor(uv.y * 4.0);
    float red = smoothstep(0.08, 0.24, c.r - max(c.g, c.b));
    float ink = 1.0 - smoothstep(0.32, 0.68, max(c.r, max(c.g,c.b)));
    if (!suit_tint) {
        rgb = c.rgb;
    } else if (row < 0.5) {
        rgb = mix(rgb, vec3(max(0.67, rgb.r), rgb.g * 0.62, rgb.b * 0.65), red);
    } else if (row < 1.5) {
        // Distinct blue ink; leave the light stock out of the ink mask.
        float l = dot(rgb, vec3(0.299,0.587,0.114));
        rgb = mix(rgb, vec3(0.025+l*0.16, 0.16+l*0.28, 0.48+l*0.35), ink);
    } else if (row < 2.5) {
        rgb = mix(rgb, vec3(max(0.85,rgb.r), max(0.32,rgb.r*0.43), rgb.b*0.45), red);
    } else {
        float black = dot(rgb, vec3(0.299,0.587,0.114))*0.60;
        rgb = mix(rgb, vec3(black), ink);
    }
    // Lift warm, low-saturation paper without bleaching red/orange/gold ink.
    // Keep a small luminance variation so texture and pale details survive.
    float low = min(c.r, min(c.g, c.b));
    float high = max(c.r, max(c.g, c.b));
    float paper = smoothstep(0.60, 0.80, low)
        * (1.0 - smoothstep(0.20, 0.32, high - low));
    float white = 0.975 + (dot(c.rgb, vec3(0.299,0.587,0.114)) - 0.85) * 0.16;
    rgb = mix(rgb, vec3(white), paper);
    return vec4(rgb,c.a)*colour;
}
