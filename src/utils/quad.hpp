enum class PrimitiveType {
	None,
	Rect,
	Circle,
	Line,
};

struct Rect {
	Vector2 position;
	Vector2 dimension;
};

struct Circle {
	Vector2 position;
	float32 radius;
	uint32 segments; // @hack: This should be with the draw code, not the representation of a circle
};

struct Line {
	Vector2 begin;
	Vector2 end;
};

struct Primitive {
	Primitive() { memset(this, 0, sizeof(Primitive)); }
		
	PrimitiveType type;
	union {
		Rect rect;
		Circle circle;
		Line line;
	};
};

#define fm_quad(top, bottom, left, right) \
    {                                     \
        { left, top },                    \
        { left, bottom },                 \
        { right, bottom },                \
                                          \
        { left, top },                    \
        { right, bottom },                \
        { right, top }                    \
    }                                     

#define fm_quad3(top, bottom, left, right, layer) \
    { \
        { left, top, layer }, \
		{ left, bottom, layer }, \
		{ right, bottom, layer }, \
                          \
        { left, top, layer }, \
		{ right, bottom, layer }, \
		{ right, top, layer } \
    }                                     

#define fm_quad_color(color) { color, color, color, color, color, color }

// Cast sets of six vertices to this to make editing easier
struct fm_quadview {
	Vector2 tl;
	Vector2 bl;
	Vector2 br;
	Vector2 tl2;
	Vector2 br2;
	Vector2 tr;
};

