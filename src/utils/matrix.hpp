struct Matrix4 {
	Vector4 rows [4];

	void transpose();
	void zero();
	Vector4& operator[](int32 index);
	bool operator==(Matrix4& other);

	static Matrix4 identity();
	static Matrix4 transform(float32 x, float32 y, float32 z);
};

void Matrix4::zero() {
	memset(this->rows, 0, sizeof(this->rows));
}

Vector4& Matrix4::operator[](int32 index) {
	return this->rows[index];
}

bool Matrix4::operator==(Matrix4& other) {
	return std::memcmp(rows, other.rows, sizeof(rows));
}

// I'm too lazy to implement operator [] right now
void Matrix4::transpose() {
	float32 tmp;

	auto swap = [&](float32& i, float32& j) { tmp = i; i = j; j = tmp; };
	swap(rows[0][1], rows[1][0]);
	swap(rows[0][2], rows[2][0]);
	swap(rows[0][3], rows[3][0]);
	swap(rows[1][2], rows[2][1]);
	swap(rows[1][3], rows[3][1]);
	swap(rows[2][3], rows[3][2]);
}

Matrix4 Matrix4::identity() {
	Matrix4 matrix;
	matrix[0][0] = 1;
	matrix[1][1] = 1;
	matrix[2][2] = 1;
	matrix[3][3] = 1;
	return matrix;
}

Matrix4 Matrix4::transform(float32 x, float32 y, float32 z) {
	Matrix4 matrix = Matrix4::identity();
	matrix[3][0] = x;
	matrix[3][1] = y;
	matrix[3][2] = z;
	return matrix;
}
