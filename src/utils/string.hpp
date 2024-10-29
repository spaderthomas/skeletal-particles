typedef char* tstring;
typedef char* string;
typedef const char* const_string;

char* copy_string(const_string str, u32 length, MemoryAllocator* allocator = nullptr);
char* copy_string(const_string str, MemoryAllocator* allocator = nullptr);
char* copy_string(const std::string& str, MemoryAllocator* allocator = nullptr);

FM_LUA_EXPORT void copy_string(const_string str, string buffer, u32 buffer_length);
FM_LUA_EXPORT void copy_string_n(const_string str, u32 length, string buffer, u32 buffer_length);
void copy_string_std(const std::string& str, string buffer);
