shader_type canvas_item;
render_mode unshaded;

// Keep the silhouettes from UI.png; render them as clear floating controls.
varying vec4 control_tint;

void vertex() {
	control_tint = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	float luminance = dot(texel.rgb, vec3(0.299, 0.587, 0.114));
	float shade = mix(0.45, 1.0, smoothstep(0.15, 0.9, luminance));
	COLOR = vec4(control_tint.rgb * shade, texel.a * control_tint.a);
}
