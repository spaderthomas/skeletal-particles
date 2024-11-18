#define SDF_CIRCLE 0
#define SDF_RING 1
#define SDF_BOX 2
#define SDF_ORIENTED_BOX 3

layout (std430, binding = 0) readonly buffer SdfBuffer {
    float sdf_data [];
}

float sdf_circle(vec2 point, vec2 center, float radius) {
	return length(point - center) - radius;	
}

float sdf_ring(vec2 world_point, vec2 center, float inner_radius, float outer_radius) {
    float dist_to_center = length(world_point - center);
    float dist_to_outer = dist_to_center - outer_radius;
    float dist_to_inner = inner_radius - dist_to_center;
    return max(dist_to_outer, dist_to_inner);
}

float sdf_box(vec2 world_point, vec2 top_left, vec2 size) {
    vec2 edge_distances = abs(world_point - top_left) - size;
    float edge_distance = max(edge_distances.x, edge_distances.y);
    edge_distance = min(edge_distance, 0.0);
    return length(max(edge_distances, 0.0)) + edge_distance;
}

float sdf_oriented_box(vec2 p, vec2 a, vec2 b, float th)
{
    float l = length(b-a);
    vec2  d = (b-a)/l;
    vec2  q = (p-(a+b)*0.5);
          q = mat2(d.x,-d.y,d.y,d.x)*q;
          q = abs(q)-vec2(l,th)*0.5;
    return length(max(q,0.0)) + min(max(q.x,q.y),0.0);    
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