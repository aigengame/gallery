shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 world_position;
uniform vec3 meadow_dark : source_color = vec3(0.19, 0.29, 0.075);
uniform vec3 meadow_light : source_color = vec3(0.30, 0.405, 0.13);
uniform vec3 path_dark : source_color = vec3(0.39, 0.34, 0.235);
uniform vec3 path_light : source_color = vec3(0.56, 0.485, 0.34);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float macro = noise(world_position.xz * 0.065);
	float detail = noise(world_position.xz * 4.0);
	vec3 green = mix(meadow_dark,meadow_light,macro);
	vec3 dirt = mix(path_dark,path_light,detail);
	ALBEDO = mix(dirt, green * (0.88 + detail*0.2), COLOR.r);
	ROUGHNESS = 0.97;
}
