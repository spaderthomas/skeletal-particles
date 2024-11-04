float sdf_circle(vec2 point, vec2 center, float radius) {
	return length(point - center) - radius;	
}

float sdf_ring(vec2 point, vec2 center, float inner_radius, float outer_radius) {
    float dist_to_center = length(point - center);
    float dist_to_outer = dist_to_center - outer_radius;
    float dist_to_inner = inner_radius - dist_to_center;
    return max(dist_to_outer, dist_to_inner);
}

float sdf_box(vec2 point, vec2 size) {
    vec2 d = abs(point) - size;
    return length(max(d, 0.0)) + min(max(d.x,d.y),0.0);
}

float sdf_triangle_isosceles(vec2 point, vec2 size) {
	size.y = -size.y;
    point.x = abs(point.x);
    vec2 a = point - size * clamp(dot(point, size) / dot(size, size), 0.0, 1.0);
    vec2 b = point - size * vec2(clamp(point.x / size.x, 0.0, 1.0), 1.0);
    float s = -sign(size.y);

		vec2 da = vec2(dot(a, a), s * (point.x * size.y - point.y * size.x));
		vec2 db = vec2(dot(b, b), s * (point.y - size.y));
    vec2 d = min(da, db);
                  
    return -sqrt(d.x) * sign(d.y);
}