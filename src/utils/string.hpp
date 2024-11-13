typedef char* tstring;
typedef char* string;
typedef const char* const_string;

char* copy_string(const_string str, u32 length, MemoryAllocator* allocator = nullptr);
char* copy_string(const_string str, MemoryAllocator* allocator = nullptr);
char* copy_string(const std::string& str, MemoryAllocator* allocator = nullptr);

FM_LUA_EXPORT void copy_string(const_string str, string buffer, u32 buffer_length);
FM_LUA_EXPORT void copy_string_n(const_string str, u32 length, string buffer, u32 buffer_length);
void copy_string_std(const std::string& str, string buffer);

bool compare_bytes(void* b0, void* b1, size_t len) {
    return 0 == memcmp(b0, b1, len);
}

void copy_memory(void* source, void* dest, u32 num_bytes) {
    std::memcpy(dest, source, num_bytes);
}

void fill_memory(void* buffer, u32 buffer_size, void* fill, u32 fill_size) {
	u8* current_byte = (u8*)buffer;

	int i = 0;
	while (true) {
		if (i + fill_size > buffer_size) return;
		memcpy(current_byte + i, (u8*)fill, fill_size);
		i += fill_size;
	}
}

void fill_memory_u8(void* buffer, u32 buffer_size, u8 fill) {
	fill_memory(buffer, buffer_size, &fill, sizeof(u8));
}
