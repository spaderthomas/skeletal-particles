#version 450 core

// UNIFORMS
uniform float master_time;
uniform vec2 camera;
const vec2 render_target = vec2(1920.0, 1080.0);  
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
	return coefficient * sin(x) + offset;
}

float plot(vec2 uv, float pct){
  return  smoothstep( pct-0.02, pct, uv.y) -
          smoothstep( pct, pct+0.02, uv.y);
}

// SDF
#define SDF_CIRCLE 0
#define SDF_RING 1
