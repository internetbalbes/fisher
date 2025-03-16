shader_type spatial;

uniform float height_scale = 2;
uniform sampler2D noise;
uniform sampler2D normalmap;

varying vec2 tex_position;

void vertex() {
  	tex_position = VERTEX.xz / 2.0 + 0.5;
  	float height = texture(noise, tex_position).x;
  	VERTEX.y += height * height_scale;
}

void fragment() {
  	RIM = 0.2;
  	METALLIC = 0.0;
  	ROUGHNESS = 0.01;
  	ALBEDO = vec3(0.1, 0.3, 0.5);
}
