shader_type canvas_item;

uniform float glow : hint_range(0.0, 2.5) = 0.0;
uniform vec4 glow_color : source_color = vec4(0.95, 0.82, 0.45, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float a = tex.a;
	vec2 px = TEXTURE_PIXEL_SIZE * (2.2 + glow * 2.8);
	float neighbor = 0.0;
	neighbor += texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	neighbor += texture(TEXTURE, UV + vec2(-px.x, 0.0)).a;
	neighbor += texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	neighbor += texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
	neighbor += texture(TEXTURE, UV + vec2(px.x, px.y)).a * 0.6;
	neighbor += texture(TEXTURE, UV + vec2(-px.x, -px.y)).a * 0.6;
	neighbor /= 5.2;
	float rim = clamp(neighbor - a, 0.0, 1.0) * glow;
	vec3 rgb = tex.rgb + glow_color.rgb * (0.45 * glow) * a;
	rgb = mix(rgb, glow_color.rgb, rim * 0.9);
	COLOR = vec4(rgb, max(a, rim * glow_color.a));
}
