#define SDF_CIRCLE 0
#define SDF_RING 1
#define SDF_BOX 2   
#define SDF_ORIENTED_BOX 3

#define SDF_COMBINE 100

layout (std430, binding = 0) readonly buffer SdfBuffer {
    float sdf_data [];
};

layout (std430, binding = 1) readonly buffer SdfCombineBuffer {
    uint sdf_combine_data [];
};

///////////////
// SDF INDEX //
///////////////
struct SdfIndex {
    uint shape;
    uint buffer_index;
};

SdfIndex decode_sdf_index(uint index) {
    SdfIndex sdf_index;
    sdf_index.shape = index & 0xFFFFu;
	sdf_index.buffer_index = (index >> 16) & 0xFFFFu;
    return sdf_index;
}


////////////////
// SDF HEADER //
////////////////
struct SdfHeader {
    vec3 color;
    vec2 position;
    float rotation;
    float edge_thickness;
};

SdfHeader pull_header(inout uint buffer_index) {
    SdfHeader header;
    header.color          = PULL_VEC3(sdf_data, buffer_index);
    header.position       = PULL_VEC2(sdf_data, buffer_index);
    header.rotation       = PULL_F32(sdf_data, buffer_index);
    header.edge_thickness = PULL_F32(sdf_data, buffer_index);
    return header;
}


////////////////
// SDF CIRCLE //
////////////////
struct SdfCircle {
    float radius;
};

SdfCircle pull_circle(inout uint buffer_index) {
    SdfCircle circle;
    circle.radius = PULL_F32(sdf_data, buffer_index);
    return circle;
}

float sdf_circle(vec2 point, vec2 center, float radius) {
	return length(point - center) - radius;	
}


//////////////
// SDF RING //
//////////////
struct SdfRing {
    float inner_radius;
    float outer_radius;
};

SdfRing pull_ring(inout uint buffer_index) {
    SdfRing ring;
    ring.inner_radius = PULL_F32(sdf_data, buffer_index);
    ring.outer_radius = PULL_F32(sdf_data, buffer_index);
    return ring;
}

float sdf_ring(vec2 world_point, vec2 center, float inner_radius, float outer_radius) {
    float dist_to_center = length(world_point - center);
    float dist_to_outer = dist_to_center - outer_radius;
    float dist_to_inner = inner_radius - dist_to_center;
    return max(dist_to_outer, dist_to_inner);
}


//////////////////////
// SDF ORIENTED BOX //
//////////////////////
struct SdfOrientedBox {
    vec2 size;
};

SdfOrientedBox pull_oriented_box(inout uint buffer_index) {
    SdfOrientedBox box;
    box.size = PULL_VEC2(sdf_data, buffer_index);
    return box;
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