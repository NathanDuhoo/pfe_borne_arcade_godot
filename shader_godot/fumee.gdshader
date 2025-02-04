shader_type spatial;

uniform sampler2D lava_texture;
uniform sampler2D noise_texture;
uniform float time_speed = 0.2;
uniform float distortion_strength = 0.2;

void fragment() {
    vec2 uv = UV;
    float time = TIME * time_speed;

    vec2 noise_uv = uv + vec2(time * 0.1, time * 0.1);
    vec2 distortion = texture(noise_texture, noise_uv).rg * distortion_strength;

    vec4 lava_color = texture(lava_texture, uv + distortion);

    ALBEDO = lava_color.rgb;
	EMISSION = lava_color.rgb * 0.01;
	}