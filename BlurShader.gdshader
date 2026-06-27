shader_type canvas_item;

uniform float blur_size : hint_range(0.0, 10.0) = 5.0;

void fragment() {
    // Basic box blur sampling
    vec2 size = TEXTURE_PIXEL_SIZE * blur_size;
    vec4 col = texture(TEXTURE, UV);
    col += texture(TEXTURE, UV + vec2(size.x, 0.0));
    col += texture(TEXTURE, UV - vec2(size.x, 0.0));
    col += texture(TEXTURE, UV + vec2(0.0, size.y));
    col += texture(TEXTURE, UV - vec2(0.0, size.y));
    col += texture(TEXTURE, UV + vec2(size.x, size.y));
    col += texture(TEXTURE, UV - vec2(size.x, size.y));
    col += texture(TEXTURE, UV + vec2(size.x, -size.y));
    col += texture(TEXTURE, UV - vec2(size.x, -size.y));
    
    COLOR = col / 9.0; // Average all 9 samples
}