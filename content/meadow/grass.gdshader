shader_type spatial;
render_mode cull_disabled, world_vertex_coords, diffuse_burley;

uniform bool wind_enabled = true;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.65;
uniform vec3 root_color : source_color = vec3(0.075, 0.185, 0.045);
uniform vec3 leaf_color : source_color = vec3(0.245, 0.425, 0.10);
uniform vec3 tip_color : source_color = vec3(0.48, 0.60, 0.22);
uniform float fade_start = 62.0;
uniform float fade_end = 72.0;
uniform float near_distance = 23.0;
uniform float mid_distance = 44.0;
uniform vec3 player_position = vec3(10000.0);
uniform float player_bend_radius = 0.8;

varying float blade_height;
varying float color_variation;
varying float field_variation;
varying float breeze_light;

void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;
	blade_height = UV.y;
	color_variation = INSTANCE_CUSTOM.r;
	field_variation = 0.5 + 0.5 * sin(root.x * 0.127 + sin(root.z * 0.089) * 2.1);
	// Shadow passes use a light view. Keep blade LOD tied to the player camera
	// so every shadow cascade renders the same geometry as the color pass.
	float distance_to_camera = distance(root.xz, MAIN_CAM_INV_VIEW_MATRIX[3].xz);
	float fade = 1.0 - smoothstep(fade_start, fade_end, distance_to_camera);
	// Remove only the blades absent from the next mesh, before its chunk switches.
	// Shared blades retain the same seeded root, center curve, width, and tip.
	float blade_fade = 1.0;
	if (UV2.x >= 4.0) {
		blade_fade = 1.0 - smoothstep(near_distance - 8.0, near_distance - 4.0, distance_to_camera);
	} else if (UV2.x >= 3.0) {
		blade_fade = 1.0 - smoothstep(mid_distance - 8.0, mid_distance - 4.0, distance_to_camera);
	}
	fade *= blade_fade;
	VERTEX.y = mix(root.y, VERTEX.y, fade);
	VERTEX.xz = mix(root.xz, VERTEX.xz, blade_fade);
	float root_weight = UV.y * UV.y;
	float wave = sin(root.x * 0.34 + root.z * 0.23 - TIME * 1.8);
	float broad_wave = sin(root.x * 0.085 - root.z * 0.12 - TIME * 0.85);
	float flutter = sin(TIME * 4.1 + INSTANCE_CUSTOM.g * 6.283 + root.x * 0.7);
	float wind = (0.10 + wave * 0.075 + broad_wave * 0.055 + flutter * 0.018) * wind_strength;
	breeze_light = wind_enabled ? wave * 0.025 : 0.0;
	if (wind_enabled) {
		VERTEX.xz += vec2(0.92, 0.39) * wind * root_weight * fade;
		VERTEX.y -= abs(wind) * root_weight * 0.16 * fade;
	}
	vec2 away = root.xz - player_position.xz;
	float local_bend = (1.0 - smoothstep(0.1, player_bend_radius, length(away))) * 0.22;
	VERTEX.xz += away / max(length(away), 0.01) * local_bend * root_weight * fade;
}

void fragment() {
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	vec3 leaf = mix(root_color, leaf_color, smoothstep(0.0, 0.50, blade_height));
	leaf = mix(leaf, tip_color, smoothstep(0.40, 1.0, blade_height) * 0.70);
	float tint = mix(0.82, 1.11, color_variation) * mix(0.93, 1.08, field_variation);
	float vein = 1.0 - 0.11 * exp(-abs(UV.x - 0.5) * 35.0);
	ALBEDO = leaf * tint * vein + vec3(breeze_light) * blade_height;
	ROUGHNESS = 0.92;
	SPECULAR = 0.16;
	BACKLIGHT = ALBEDO * 0.26 * smoothstep(0.12, 0.7, blade_height);
	AO = mix(0.62, 1.0, smoothstep(0.0, 0.65, blade_height));
}
