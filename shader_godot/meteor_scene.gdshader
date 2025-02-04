shader_type spatial;

// Uniforms pour les textures et paramètres
uniform sampler2D albedo_texture; // Texture de base
uniform sampler2D normal_texture; // Carte de normales
uniform vec3 emission_color = vec3(0.2, 1.0, 0.2); // Couleur d'émission verte pour effet poison
uniform float emission_strength = 1.5; // Force de l'émission augmentée pour un effet plus intense

void fragment() {
    vec3 albedo = texture(albedo_texture, UV).rgb;
    vec3 normal_map = texture(normal_texture, UV).rgb * 2.0 - 1.0;

    // Modification de la normale dans l'espace vue (sans TANGENT_TO_WORLD)
    vec3 new_normal = normalize(NORMAL + normal_map * 0.5); // Modifie légèrement les normales existantes

    // Ajout d'une teinte verte au matériau pour un effet empoisonné
    vec3 poison_tint = vec3(0.2, 1.0, 0.2);
    albedo = mix(albedo, poison_tint, 0.6); // Mélange l'albedo avec du vert à 30%

    // Appliquer les propriétés
    NORMAL = new_normal;
    ALBEDO = albedo;
    EMISSION = emission_color * emission_strength;
}
