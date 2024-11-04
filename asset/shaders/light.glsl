struct Light {
    vec4 color;
    vec2 position;
    float radial_falloff;
    float angular_falloff;
    float intensity;
    float volumetric_intensity;
    float angle;
    float padding [1];
};

layout (std430, binding = 0) buffer LightBuffer {
	Light lights [16];
};

uniform int num_lights;

const float light_resolution = 64;
const float light_radius = 4;


float calc_radial_falloff(Light light, vec2 position) {
    float d = distance(position, light.position);
    float normalized_distance = distance(position, light.position) / light_radius;

    float radial_falloff_power = map_range(light.radial_falloff, 0.0, 1.0, 0.0, 2.0);
    float radial_falloff = 1.0 / (1.0 + pow(normalized_distance, radial_falloff_power));
    // float radial_falloff = smoothstep(light_radius, light_radius * light.radial_falloff, d);
    // radial_falloff = quantize(radial_falloff, light_resolution);

    return radial_falloff;
}


float calc_angular_falloff(Light light, vec2 position) {
  vec2 light_direction = normalize(position - light.position);

  float fragment_angle = atan_turns(light_direction.y, light_direction.x);
  fragment_angle = fragment_angle < 0.0 ? fragment_angle + 1.0 : fragment_angle;

  float angular_delta = fragment_angle - light.angle;
  angular_delta = angular_delta > 0.5 ? angular_delta - 1.0 : angular_delta;
  angular_delta = angular_delta < -0.5 ? angular_delta + 1.0 : angular_delta;
  angular_delta = abs(angular_delta);

  return smoothstep(1.0 - light.angular_falloff, 0, angular_delta);

  float max_angular_delta = light.angular_falloff / 2;
  float normalized_angular_delta = abs(angular_delta / max_angular_delta);

  return clamp(1.0 - normalized_angular_delta, 0.0, 1.0);
} 