shader_type spatial;

// 🔴 Couleur principale du laser (rouge intense réglable dans l'éditeur)
uniform vec4 laser_color = vec4(1.0, 0.0, 0.0, 1.0); 

// ✨ Intensité du Glow (réglable entre 0 et 10 dans l'éditeur)
uniform float glow_intensity : hint_range(0.0, 10.0) = 5.0;

// 🚀 Vitesse d'animation
uniform float speed = 3.0;

// 🎶 Fréquence des oscillations
uniform float frequency = 20.0;

void fragment() {
    vec2 uv_offset = UV;
    
    // Ajout d'un dégradé radial pour uniformiser l'effet lumineux
    float radial_gradient = smoothstep(0.1, 0.9, length(uv_offset - vec2(0.5, 0.5)));
    
    // Effet de pulsation animé
    float pulse = sin(TIME * speed) * 0.3 + 0.7;

    // Ajout d'un dégradé horizontal (plus intense au centre)
    float horizontal_fade = smoothstep(0.2, 0.8, uv_offset.x);

    // Couleur principale du laser (rouge intense)
    vec3 base_color = mix(vec3(1.0, 0.0, 0.0), vec3(1.0, 0.3, 0.3), horizontal_fade);
    base_color *= pulse; // Animation de la luminosité

    // Intensité du glow
    vec3 emission = base_color * glow_intensity * radial_gradient;

    // Application des couleurs
    ALBEDO = base_color;
    EMISSION = emission;
    ALPHA = laser_color.a;
}
