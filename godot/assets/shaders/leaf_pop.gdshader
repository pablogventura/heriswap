shader_type canvas_item;

uniform float pop : hint_range(0.0, 1.5) = 0.0;
uniform vec4 pop_color : source_color = vec4(1.0, 1.0, 0.85, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float sat = 1.0 + pop * 0.85;
	float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 boosted = mix(vec3(gray), tex.rgb, sat);
	boosted = mix(boosted, pop_color.rgb, pop * 0.35 * tex.a);
	boosted += vec3(0.15 * pop) * tex.a;
	COLOR = vec4(boosted, tex.a);
}
