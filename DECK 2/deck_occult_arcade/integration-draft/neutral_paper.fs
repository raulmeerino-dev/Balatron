// Neutral Balatro-like card stock; keep saturated illustration ink and alpha.
vec4 effect(vec4 colour, Image texture, vec2 uv, vec2 screen) {
    vec4 c = Texel(texture, uv);
    float low = min(c.r, min(c.g, c.b));
    float high = max(c.r, max(c.g, c.b));
    float paper = smoothstep(0.56, 0.73, low)
        * (1.0 - smoothstep(0.28, 0.44, high - low));
    float luminance = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    float stock = clamp(0.98 + (luminance - 0.9) * 0.15, 0.0, 1.0);
    return vec4(mix(c.rgb, vec3(stock), paper), c.a) * colour;
}
