#define fm_assert(expr) do { \
	if (!(expr)) { \
		printf("ASSERT: %s\n", __func__); \
	} \
} while (0)
