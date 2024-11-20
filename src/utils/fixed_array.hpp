#ifndef FIXED_ARRAY_H
#define FIXED_ARRAY_H

////////////
// HEADER //
////////////
typedef struct {
	u8* data;
	u32 size;
	u32 capacity;

	u32 vertex_size;
} FixedArray;

void fixed_array_init(FixedArray* vertex_buffer, u32 max_vertices, u32 vertex_size);
u8*  fixed_array_push(FixedArray* vertex_buffer, void* data, u32 count);
u8*  fixed_array_reserve(FixedArray* vertex_buffer, u32 count);
void fixed_array_clear(FixedArray* vertex_buffer);
u32  fixed_array_byte_size(FixedArray* vertex_buffer);
u8*  fixed_array_at(FixedArray* vertex_buffer, u32 index);
#endif


#ifdef FIXED_ARRAY_IMPLEMENTATION
////////////////////
// IMPLEMENTATION //
////////////////////

void fixed_array_init(FixedArray* buffer, u32 max_vertices, u32 vertex_size) {
	assert(buffer);

	buffer->size = 0;
	buffer->capacity = max_vertices;
	buffer->vertex_size = vertex_size;
	buffer->data = (u8*)ma_alloc(&standard_allocator, max_vertices * vertex_size);
}

u8* fixed_array_at(FixedArray* buffer, u32 index) {
	assert(buffer);
	return buffer->data + (index * buffer->vertex_size);
}

u8* fixed_array_push(FixedArray* buffer, void* data, u32 count) {
	assert(buffer);
	assert(buffer->size < buffer->capacity);

	auto vertices = fixed_array_reserve(buffer, count);
	copy_memory(data, vertices, buffer->vertex_size * count);
	return vertices;
}

u8* fixed_array_reserve(FixedArray* buffer, u32 count) {
	assert(buffer);
	
	auto vertex = fixed_array_at(buffer, buffer->size);
	buffer->size += count;
	return vertex;
}

void fixed_array_clear(FixedArray* buffer) {
	assert(buffer);

	buffer->size = 0;
}

u32 fixed_array_byte_size(FixedArray* buffer) {
	assert(buffer);

	return buffer->size * buffer->vertex_size;
}
#endif