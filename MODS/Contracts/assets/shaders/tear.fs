extern number progress;
extern vec4 texture_details;
extern vec2 image_details;
vec4 effect(vec4 colour, Image texture, vec2 tc, vec2 screen_coords) {
    vec2 cell = texture_details.zw / image_details;
    vec2 origin = texture_details.xy * cell;
    vec2 uv = (tc - origin) / cell;
    float seam = 0.5 + 0.025 * sin(floor(uv.y * 28.0) * 2.4);
    float side = uv.x < seam ? -1.0 : 1.0;
    vec2 source = uv - vec2(side * progress * 0.17, side * progress * 0.08);
    if (source.x < 0.0 || source.x > 1.0 || source.y < 0.0 || source.y > 1.0) return vec4(0.0);
    float cut = 0.5 + 0.025 * sin(floor(source.y * 28.0) * 2.4);
    if ((source.x - cut) * side < 0.0) return vec4(0.0);
    vec4 pixel = Texel(texture, origin + source * cell) * colour;
    pixel.a *= 1.0 - progress * 0.25;
    return pixel;
}
