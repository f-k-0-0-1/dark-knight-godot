shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float vortex_strength : hint_range(0.0, 10.0) = 6.0;
uniform float blur_strength : hint_range(0.0, 0.02) = 0.008;
uniform vec4 glow_color : source_color = vec4(0.3, 0.7, 1.0, 1.0);

// --- New Hyper-Realistic Nether Portal Control Parameters ---
uniform float pixelation_amount : hint_range(64.0, 512.0) = 128.0; // Controls the "blocky" resolution
uniform float wave_speed : hint_range(0.0, 10.0) = 4.0;
uniform float distortion_scale : hint_range(0.0, 0.2) = 0.05;

// Simple pseudo-noise to create the shifting nether-grid pattern
float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment()
{
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5);
	
	//---------------------------------------------------
	// Animated Reality Warp (Nether Portal Waves)
	//---------------------------------------------------
	// This warps the grid dynamically over time *before* calculations
	float time_wave = sin(TIME * wave_speed + uv.y * 10.0) * cos(TIME * wave_speed * 0.5 + uv.x * 10.0);
	uv += vec2(time_wave) * distortion_scale * progress;

	vec2 delta = uv - center;
	float dist = length(delta);
	float angle = atan(delta.y, delta.x);
	float p = smoothstep(0.0, 1.0, progress);

	//---------------------------------------------------
	// Spiral Twist
	//---------------------------------------------------
	float twist = (1.0 - smoothstep(0.0, 0.9, dist)) * vortex_strength * p;
	angle += twist * (1.0 + dist * 6.0);

	//---------------------------------------------------
	// Radial Pull & Barrel Distortion
	//---------------------------------------------------
	float radius = dist;
	radius *= mix(1.0, 0.15, p);
	radius -= pow(1.0 - radius, 3.0) * p * 0.25;
	radius *= 1.0 + p * dist * 0.4;

	vec2 vortex_uv = center + vec2(cos(angle), sin(angle)) * radius;

	//---------------------------------------------------
	// Minecraft-Style Quantization (Pixelation)
	//---------------------------------------------------
	// Dynamically step down screen resolution as progress increases
	float current_res = mix(1024.0, pixelation_amount, p);
	vortex_uv = floor(vortex_uv * current_res) / current_res;
	
	// Quantize delta as well to keep chromatic effects aligned to blocks
	vec2 blocky_delta = floor(delta * current_res) / current_res;

	//---------------------------------------------------
	// Blur / Fragment Shifting
	//---------------------------------------------------
	float blur = blur_strength * (0.5 + p * 2.5);
	vec3 col = vec3(0.0);

	col += texture(screen_texture, vortex_uv).rgb * 4.0;
	col += texture(screen_texture, vortex_uv + vec2(blur, 0.0)).rgb;
	col += texture(screen_texture, vortex_uv + vec2(-blur, 0.0)).rgb;
	col += texture(screen_texture, vortex_uv + vec2(0.0, blur)).rgb;
	col += texture(screen_texture, vortex_uv + vec2(0.0, -blur)).rgb;
	col += texture(screen_texture, vortex_uv + vec2(blur, blur)).rgb;
	col += texture(screen_texture, vortex_uv + vec2(-blur, blur)).rgb;
	col += texture(screen_texture, vortex_uv + vec2(blur, -blur)).rgb;
	col += texture(screen_texture, vortex_uv + vec2(-blur, -blur)).rgb;
	col /= 12.0;

	//---------------------------------------------------
	// Chromatic Aberration (Aligned to Grid)
	//---------------------------------------------------
	float rgb_shift = p * 0.008;
	float r = texture(screen_texture, vortex_uv + blocky_delta * rgb_shift).r;
	float g = col.g;
	float b = texture(screen_texture, vortex_uv - blocky_delta * rgb_shift).b;
	col = vec3(r, g, b);

	//---------------------------------------------------
	// Portal Energy Glow & Texture Noise
	//---------------------------------------------------
	// Infuses a sharp texture overlay to simulate dimensional static
	float block_noise = rand(floor(vortex_uv * pixelation_amount));
	float glow = exp(-dist * 10.0);
	
	vec3 dimensional_glow = glow_color.rgb * (glow * 2.0 + block_noise * 0.4);
	col += dimensional_glow * p;

	//---------------------------------------------------
	// Edge Fade & Dimensional Horizon (Black Hole)
	//---------------------------------------------------
	float fade = smoothstep(1.0, 0.2, dist);
	col *= mix(1.0, fade, p * 0.9);

	// Shifting portal event horizon at the dead center
	float hole_radius = mix(0.0, 0.22, p);
	float hole = smoothstep(hole_radius, hole_radius * 0.5, dist);
	col = mix(col, vec3(0.02, 0.0, 0.05), hole * p); // Replaced pure black with a deep cosmic violet

	COLOR = vec4(col, 1.0);
}