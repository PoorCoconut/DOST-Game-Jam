shader_type canvas_item;

void fragment() {
    // Calculate the distance of the current pixel uv coordinate from the center (0.5, 0.5)
    vec2 center_offset = UV - vec2(0.5);
    float distance_from_center = length(center_offset);
    
    // Smooth out the circular alpha edges slightly to prevent aliased jagged lines
    float circle_alpha = smoothstep(0.5, 0.49, distance_from_center);
    
    // Sample the raw pixel data from your texture image file
    vec4 raw_color = texture(TEXTURE, UV);
    
    // Inject the clipped circle mask transparency calculation rule directly back into the color output step
    COLOR = vec4(raw_color.rgb, raw_color.a * circle_alpha);
}