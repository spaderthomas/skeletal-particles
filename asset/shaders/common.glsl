#version 450 core

// UNIFORMS
uniform float master_time;
uniform vec2 camera;
uniform vec2 render_target;

//const vec2 render_target = vec2(1920.0, 1080.0) * vec2(.0375, .125);  

// COLORS
const vec4 red   = vec4(1.0, 0.0, 0.0, 1.0);
const vec4 green = vec4(0.0, 1.0, 0.0, 1.0);
const vec4 blue  = vec4(0.0, 0.0, 1.0, 1.0);
const vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 white = vec4(1.0, 1.0, 1.0, 1.0);
const vec4 clear = vec4(0.0, 0.0, 0.0, 0.0);

const vec4 gunmetal     = vec4(43.0 / 255.0, 61.0 / 255.0, 65.0 / 255.0, 255.0);
const vec4 paynes_gray  = vec4(76.0 / 255.0, 95.0 / 255.0, 107.0 / 255.0, 255.0);
const vec4 cadet_gray   = vec4(131.0 / 255.0, 160.0 / 255.0, 160.0 / 255.0, 255.0);
const vec4 celadon      = vec4(183.0 / 255.0, 227.0 / 255.0, 204.0 / 255.0, 255.0);
const vec4 spring_green = vec4(89.0 / 255.0, 255.0 / 255.0, 160.0 / 255.0, 255.0);
const vec4 mindaro      = vec4(188.0 / 255.0, 231.0 / 255.0, 132.0 / 255.0, 255.0);
const vec4 light_green  = vec4(161.0 / 255.0, 239.0 / 255.0, 139.0 / 255.0, 255.0);
const vec4 indian_red   = vec4(180.0 / 255.0, 101.0 / 255.0, 111.0 / 255.0, 255.0);

vec4 gray(float v) {
	return vec4(vec3(v), 1.0);
}

vec4 make_red(float r) {
	return vec4(r, 0.0, 0.0, 1.0);
}

vec4 make_green(float g) {
	return vec4(0.0, g, 0.0, 1.0);
}

vec4 sign_color(float value, vec4 positive, vec4 negative) {
	if (value >= 0) {
		return vec4(positive.xyz * value, positive.a);
	}
	else {
		return vec4(negative.xyz * abs(value), negative.a);
	}
}

vec4 color_255(float r, float g, float b, float a) {
	return vec4(r, g, b, a) / 255.0;
}

float calc_brightness(vec4 color) {
	const vec3 weights = vec3(0.2126, 0.7152, 0.0722);
	return dot(color.rgb, weights);
}

// All components are in the range [0…1], including hue.
vec3 rgb_to_hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec4 rgb_to_hsv_4(vec4 c) {
	return vec4(rgb_to_hsv(c.rgb), c.a);
}


// All components are in the range [0…1], including hue.
vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 hsv_to_rgb_4(vec4 c) {
	return vec4(hsv_to_rgb(c.rgb), c.a);
}

#define HSV_VALUE(color) ((color).z)
#define HSV_SATURATION(color) ((color).y)
#define HSV_HUE(color) ((color).x)

// CONSTANTS
const float pi = 3.14159265359;
#define THREADS_PER_WORKGROUP 32

// RNG
float random_float(vec2 seed, float min, float max) {
	const vec2 hash_vector = vec2(12.9898, 78.233);
	const float large_multiplier = 43758.5453;
	
	float hashed_seed = dot(seed, hash_vector) + mod(master_time, 1.1374);
	float value_01 = fract(sin(hashed_seed) * large_multiplier);

    return min + (max - min) * value_01;
}

void jitter_rng_seed(inout vec2 seed) {
	seed += random_float(seed, 12.8594, 23.9576);
}

#define RANDOM_FLOAT(seed, min, max) random_float((seed), (min), (max)); jitter_rng_seed(seed);


float ranged_sin(float x, float min, float max) {
	float coefficient = (max - min) / 2.0;
	float offset = (max + min) / 2.0;
	float sinx = sin(x);
	return coefficient * sinx + offset;
}

float triangle_wave(float x) {
    return clamp(1.0 - abs(x), 0.0, 1.0);
}

float map_range(float x, float min_a, float max_a, float min_b, float max_b) {
    float coefficient = (max_b - min_b) / (max_a - min_a);
    float offset = min_b - coefficient * min_a;
    return coefficient * x + offset;
}

float plot(vec2 uv, float pct){
  return  smoothstep( pct-0.02, pct, uv.y) -
          smoothstep( pct, pct+0.02, uv.y);
}

float ease_in_out_cubic(float t) {
  return t < 0.5
    ? 4.0 * t * t * t
    : 0.5 * pow(2.0 * t - 2.0, 3.0) + 1.0;
}


float interp_in_out_cubic(float x, float y, float t) {
	return mix(x, y, ease_in_out_cubic(t));
}

float ease_out_quadratic(float t) {
	return 1.0 - pow(1.0 - t, 2);
}

float ease_out_cubic(float t) {
	return 1.0 - pow(1.0 - t, 3);
}

float ease_in_quadratic(float t) {
	return pow(t, 2);
}

float ease_in_cubic(float t) {
	return pow(t, 3);
}

float is_higher_than(float x, float threshold) {
	return step(threshold, x);
}

float high_pass(float x, float threshold) {
	return x * is_higher_than(x, threshold);
}

float low_pass(float x, float threshold) {
	return x * step(x, threshold);
}


vec4 sample_neighbor_h(sampler2D source_texture, vec2 uv, float pixel_offset) {
	const vec2 uv_per_px = 1.0 / render_target;

	uv.x += pixel_offset * uv_per_px.x;
	uv = clamp(uv, 0.0, 0.999);
	return texture(source_texture, uv);
}

vec4 box_blur_n_h(sampler2D source_texture, vec2 uv, int num_taps) {
	vec4 blurred_color = vec4(0.0);

	for (int i = 1; i <= num_taps / 2; i++) {
		blurred_color += sample_neighbor_h(source_texture, uv, i);
		blurred_color += sample_neighbor_h(source_texture, uv, -i);
	}
	blurred_color += sample_neighbor_h(source_texture, uv, 0);

	return blurred_color / num_taps;
}

float gauss(float x, float sigma) {
	float power = -(pow(x, 2) / 2 * pow(sigma, 2));
	return exp(power);
}

void add_gaussian_blur_h(sampler2D source_texture, vec2 uv, float sigma, int offset, inout float total_weights, inout vec4 blurred_color) {
	float weight = gauss(offset, sigma);
	blurred_color += weight * sample_neighbor_h(source_texture, uv, offset);
	total_weights += weight;
}

vec4 gaussian_blur_5_h(sampler2D source_texture, vec2 uv, float sigma) {
	float total_weights = 0.0;
	vec4 blurred_color = vec4(0.0);

	for (int i = 1; i <= 2; i++) {
		add_gaussian_blur_h(source_texture, uv, sigma, i, total_weights, blurred_color);
		add_gaussian_blur_h(source_texture, uv, sigma, -i, total_weights, blurred_color);
	}

	add_gaussian_blur_h(source_texture, uv, sigma, 0, total_weights, blurred_color);

	return blurred_color / total_weights;
}

vec4 gaussian_blur_n_h(sampler2D source_texture, vec2 uv, float sigma, uint num_taps) {
	float total_weights = 0.0;
	vec4 blurred_color = vec4(0.0);

	for (int i = 1; i <= num_taps / 2; i++) {
		add_gaussian_blur_h(source_texture, uv, sigma, i, total_weights, blurred_color);
		add_gaussian_blur_h(source_texture, uv, sigma, -i, total_weights, blurred_color);
	}

	add_gaussian_blur_h(source_texture, uv, sigma, 0, total_weights, blurred_color);

	return blurred_color / total_weights;
}


// vec4 gaussian_blur_5_h(sampler2D source_texture, vec2 uv, float sigma) {
// 	float total_weights = 0.0;
// 	vec4 blurred_color = vec4(0.0);

// 	for (int i = 1; i <= 2; i++) {
// 		float wr = gauss(i, sigma);
// 		blurred_color += wr * sample_neighbor_h(source_texture, uv, i);

// 		float wl = gauss(-i, sigma);
// 		blurred_color += wl * sample_neighbor_h(source_texture, uv, -i);
	
// 		total_weights += wl + wr;
// 	}

// 	float wc = gauss(0, sigma);
// 	blurred_color += wc * sample_neighbor_h(source_texture, uv, 0);
// 	total_weights += wc;

// 	return blurred_color / total_weights;
// }



// SDF
#define SDF_CIRCLE 0
#define SDF_RING 1
