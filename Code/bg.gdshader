shader_type canvas_item;

// ── Paleta ────────────────────────────────────────────────────────────
uniform vec4 color_a : source_color = vec4(1.000, 0.478, 0.180, 1.0);
uniform vec4 color_b : source_color = vec4(0.929, 0.157, 0.529, 1.0);
uniform vec4 color_c : source_color = vec4(0.231, 0.318, 1.000, 1.0);

// ── Forma del degradado ───────────────────────────────────────────────
uniform int modo : hint_enum("Lineal", "Radial", "Conico") = 0;
uniform float angulo : hint_range(0.0, 360.0) = 135.0;
uniform vec2 centro = vec2(0.5, 0.5);
uniform float repeticiones : hint_range(1.0, 6.0) = 1.0;
uniform bool ping_pong = false;

// ── Movimiento ────────────────────────────────────────────────────────
uniform float velocidad : hint_range(0.0, 2.0) = 0.10;
uniform float oscilacion : hint_range(0.0, 0.5) = 0.05;

// ── Acabado ───────────────────────────────────────────────────────────
uniform float brillo_banda : hint_range(0.0, 1.0) = 0.20;
uniform float banda_velocidad : hint_range(0.0, 3.0) = 0.30;
uniform float grano : hint_range(0.0, 0.20) = 0.025;
uniform float vineta : hint_range(0.0, 1.0) = 0.15;
uniform float alfa : hint_range(0.0, 1.0) = 1.0;

float hash21(vec2 p) {
	p = fract(p * vec2(120.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;

	float x;
	if (modo == 0) {
		float r = radians(angulo);
		vec2 dir = vec2(cos(r), sin(r));
		float extent = max(abs(dir.x) + abs(dir.y), 0.0001);
		x = dot(uv - centro, dir) / extent + 0.5;
	} else if (modo == 1) {
		x = length(uv - centro) * 1.41421356;
	} else {
		x = atan(uv.y - centro.y, uv.x - centro.x) / 6.2831853 + 0.5;
	}
	x = x * repeticiones + TIME * velocidad;
	float t = ping_pong ? abs(fract(x * 0.5) * 2.0 - 1.0) : fract(x);
	t = clamp(t + sin(TIME * 0.9) * oscilacion, 0.0, 1.0);

	vec3 col;
	if (t < 0.5) {
		col = mix(color_a.rgb, color_b.rgb, smoothstep(0.0, 0.5, t));
	} else {
		col = mix(color_b.rgb, color_c.rgb, smoothstep(0.5, 1.0, t));
	}
	float banda = 0.5 + 0.5 * cos((x - TIME * banda_velocidad) * 6.2831853);
	col += pow(banda, 6.0) * brillo_banda;

	float v = smoothstep(0.25, 0.85, length(uv - vec2(0.5)));
	col *= 1.0 - vineta * v;

	col += (hash21(uv * 2048.0 + fract(TIME) * 137.0) - 0.5) * grano;

	COLOR = vec4(clamp(col, 0.0, 1.0), COLOR.a * alfa);
}
