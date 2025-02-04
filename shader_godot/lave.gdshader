shader_type spatial;

uniform sampler2D lava_texture;
uniform sampler2D noise_texture;
uniform float time_speed = 0.1;
uniform float distortion_strength = 1.0;
uniform float emission_strength = 1.2; // Luminosité modérée pour éviter l'effet blanc
uniform float red_boost = 2.0;        // Amplification modérée du rouge
uniform float color_balance = 0.01;   // Réduction des tons trop clairs

void fragment() {
    vec2 uv = UV;
    float time = TIME * time_speed;

    // Calcul de la distorsion
    vec2 noise_uv = uv + vec2(time * 0.1, time * 0.1);
    vec2 distortion = texture(noise_texture, noise_uv).rg * distortion_strength;

    // Récupération de la couleur de la lave
    vec4 lava_color = texture(lava_texture, uv + distortion);

    // Amplification du rouge
    lava_color.r *= red_boost;

    // Réduction des tons clairs (balance des couleurs)
    lava_color.rgb = mix(lava_color.rgb * color_balance, lava_color.rgb, 0.5);

    // Ajustement de l'ALBEDO et de l'EMISSION
    ALBEDO = lava_color.rgb;
    EMISSION = lava_color.rgb * emission_strength;
}
