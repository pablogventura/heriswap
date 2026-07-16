shader_type canvas_item;

## Cheap separable-ish box blur for far backdrop layers.
uniform float blur_amount : hint_range(0.0, 2.0) = 0.6;

void fragment() {
	vec4 center = texture(TEXTURE, UV);
	if (blur_amount < 0.01) {
		COLOR = center;
		return;
	}
	vec2 px = TEXTURE_PIXEL_SIZE * (1.2 + blur_amount * 2.8);
	vec4 acc = center * 0.22;
	acc += texture(TEXTURE, UV + vec2(px.x, 0.0)) * 0.12;
	acc += texture(TEXTURE, UV - vec2(px.x, 0.0)) * 0.12;
	acc += texture(TEXTURE, UV + vec2(0.0, px.y)) * 0.12;
	acc += texture(TEXTURE, UV - vec2(0.0, px.y)) * 0.12;
	acc += texture(TEXTURE, UV + px) * 0.075;
	acc += texture(TEXTURE, UV - px) * 0.075;
	acc += texture(TEXTURE, UV + vec2(px.x, -px.y)) * 0.075;
	acc += texture(TEXTURE, UV + vec2(-px.x, px.y)) * 0.075;
	COLOR = mix(center, acc, clamp(blur_amount, 0.0, 1.0));
}
