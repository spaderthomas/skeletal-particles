struct Vector2;
struct Vector2I;
struct Vector3;
struct Vector4;

struct Vector2 {
	float x = 0;
	float y = 0;
};

struct Vector2I {
	int32 x = 0;
	int32 y = 0;
};

struct Vector3 {
	float x = 0;
	float y = 0;
	float z = 0;
};

struct Vector4 {
	union {
		float x = 0;
		float r;
		float bottom;
	};
	union {
		float y = 0;
		float g;
		float top;
	};
	union {
		float z = 0;
		float b;
		float left;
	};
	union {
		float w = 0;
		float a;
		float right;
	};

	float& operator[](int32 index) {
		fm_assert(index >= 0);
		fm_assert(index < 4);
		float* data = (float*)this;
		return *(data + index);
	}
};

bool v2_equal(Vector2 a, Vector2 b) {
	return a.x == b.x && a.y == b.y;
}

Vector2 v2_add(Vector2 a, Vector2 b) {
	return { a.x + b.x, a.y + b.y };
}

Vector2 v2_scale(Vector2 vector, float scalar) {
	return { vector.x * scalar, vector.y * scalar};
}

Vector2 v2_subtract(Vector2 a, Vector2 b) {
	return { a.x - b.x, a.y - b.y };
}

float v2_dot(Vector2 a, Vector2 b) {
	return (a.x * b.x + a.y * b.y);
}

float v2_length(Vector2 vector) {
	return std::sqrt(std::pow(vector.x, 2) + std::pow(vector.y, 2));
}

Vector2 v2_normal(Vector2 vector) {
	float length = v2_length(vector);
	if (length > 0) return Vector2(vector.x / length, vector.y / length);
		
	return Vector2();
}
