shader_type spatial;

uniform sampler2D lava_texture;
uniform sampler2D noise_texture;
uniform float time_speed = 1.0;
uniform float distortion_strength = 0.2;
uniform float glow_intensity = 2.0;

void fragment() {
    vec2 uv = UV;
    float time = TIME * time_speed;

    // Répétition fluide de la noise texture
    vec2 noise_uv = fract(uv + vec2(time * 0.1, time * 0.1));
    vec2 distortion = (texture(noise_texture, noise_uv).rg - 0.5) * distortion_strength;

    // Répétition fluide de la lave
    vec4 lava_color = texture(lava_texture, fract(uv + distortion));

    // Effet de pulsation sur l'émission
    float pulse = sin(time * 2.0) * 0.5 + 0.5;

    ALBEDO = lava_color.rgb;
    EMISSION = lava_color.rgb * (glow_intensity + pulse);
}
