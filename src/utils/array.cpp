void memfill(void* dst, i32 size, void* pattern, i32 pattern_size) {
	char* cdst = (char*)dst;
	char* cptn = (char*)pattern;
	int i = 0;

	while (true) {
		if (i + pattern_size > size) return;
		memcpy(cdst + i, cptn, pattern_size);
		i += pattern_size;
	}
}

template<typename T>
fm_error arr_init(Array<T>* array, u64 capacity, MemoryAllocator* allocator) {
	array->size = 0;
	array->capacity = capacity;
	array->data = allocator->alloc<T>(capacity);
	
	if (array->data) return FM_ERR_SUCCESS;
	return FM_ERR_FAILED_ALLOC;
}

template<typename T>
fm_error arr_init(Array<T>* array, u64 capacity) {
	return arr_init(array, capacity, &standard_allocator);
}

template<typename T>
fm_error arr_init(Array<T>* array, u64 capacity, T fill) {
	auto error = arr_init(array, capacity, &standard_allocator);
	if (error) return error;
	
	arr_fill(array, T());
	return FM_ERR_SUCCESS;
}

template<typename T>
void arr_clear(Array<T>* array) {
	memset(array->data, 0, array->size * sizeof(T));
	array->size = 0;
}

template<typename T>
void arr_fastclear(Array<T>* array) {
	array->size = 0;
}

template<typename T>
void arr_clear_n(Array<T>* array, i32 n) {
	memset(array->data, 0, n * sizeof(T));
	array->size = 0;
}

template<typename T>
void arr_fill(Array<T>* array, T element) {
	memfill(array->data, arr_bytes(array), &element, sizeof(T));
	array->size = array->capacity; 
}

template<typename T>
void arr_fill(Array<T>* array, T element, u64 count) {
	memfill(array->data, count * sizeof(T), &element, sizeof(T));
	array->size = count;
}

template<typename T>
void arr_fill(Array<T>* array, u64 offset, u64 count, T element) {
	memfill(array->data + offset, count * sizeof(T), &element, sizeof(T));
	array->size = count;
	// You're on your own as far as the size here
}

template<typename T>
Array<T> arr_stack(T* data, u64 capacity) {
	fm_assert(data);

	Array<T> array;
	array.size = 0;
	array.capacity = capacity;
	array.data = data;
	return array;
}

template<typename T, u64 N>
Array<T> arr_stack(T (&c_array)[N]) {
	Array<T> array;
	array.size = 0;
	array.capacity = N;
	array.data = c_array;
	return array;
}

template<typename T>
Array<T> arr_slice(Array<T>* array, u64 index, u64 size) {
	fm_assert(index >= 0);
	fm_assert(index + size <= array->capacity);
	
	Array<T> view;
	view.size = size;
	view.capacity = size;
	view.data = array->data + index;
	
	return view;
}

template<typename T>
Array<T> arr_slice(T* data, u64 size) {
	Array<T> arr;
	arr.size = size;
	arr.capacity = size;
	arr.data = data;
	
	return arr; 
}

template<typename T, u64 N>
Array<T> arr_slice(T (&data)[N]) {
	Array<T> array;
	array.size = N;
	array.capacity = N;
	array.data = data;
	return array;
}

template<typename T>
i32 arr_indexof(Array<T>* array, T* element) {
	i32 index = element - array->data;
	fm_assert(index >= 0);
	fm_assert(index < array->size);
	return index;
}

template<typename T>
T* arr_at(Array<T>* array, u64 index) {
	return (*array)[index];
}

template<typename T>
bool arr_full(Array<T>* array) {
	return array->size ==  array->capacity;
}

template<typename T>
T* arr_push(Array<T>* array, const T* data, u64 count) {
	i32 remaining = array->capacity - array->size;
	assert(remaining >= count && "Insufficient space remaining!");

	if (remaining < count) return nullptr;
	
	memcpy(array->data + array->size, data, sizeof(T) * count);
	T* out = array->data + array->size;
	array->size += count;
	return out;
}

template<typename T>
T* arr_push(Array<T>* array, T* data, u64 count) {
	i32 remaining = array->capacity - array->size;
	assert(remaining >= count && "Insufficient space remaining!");
	
	memcpy(array->data + array->size, data, sizeof(T) * count);
	T* out = array->data + array->size;
	array->size += count;
	return out;
}

template<typename T>
T* arr_push(Array<T>* array, T element, u64 count) {
	auto back = array->data + array->size;
	memfill(back, count * sizeof(T), &element, sizeof(T));
	array->size += count;
	return back;
}

template<typename T>
T* arr_push(Array<T>* array, T* data) {
	assert(array->size < array->capacity && "Insufficient space remaining!");
	array->data[array->size] = *data;
	T* out = array->data + array->size;
	array->size += 1;
	return out;
}

template<typename T>
T* arr_push(Array<T>* array, T data) {
	assert(array->size < array->capacity && "Insufficient space remaining!");
	array->data[array->size] = data;
	T* out = array->data + array->size;
	array->size += 1;
	return out;
}

template<typename T>
T* arr_push(Array<T>* array) {
	assert(array->size < array->capacity && "Insufficient space remaining!");
	array->data[array->size] = T();
	T* out = array->data + array->size;
	array->size += 1;
	return out;
}

template<typename T>
void arr_pop(Array<T>* array) {
	fm_assert(array->size && "cannot pop / what has not / been pushed");
	array->size -= 1;
	return;
}

template<typename T>
T* arr_reserve(Array<T>* array, u64 count) {
	fm_assert(array->size <= array->capacity + count && "Insufficient space remaining!");
	T* out = array->data + array->size;
	array->size += count;
	return out;
}


template<typename T>
T* arr_concat(Array<T>* dest, Array<T>* source) {
	fm_assert(dest->size + source->size < dest->capacity);
	memcpy(dest->data + dest->size, source->data, sizeof(T) * source->count);
	T* out = dest->data + dest->size;
	dest->size += source->size;
	return out;
}

template<typename T>
T* arr_concat(Array<T>* dest, Array<T>* source, u64 count) {
	fm_assert(dest->size + count < dest->capacity);
	memcpy(dest->data + dest->size, source->data, sizeof(T) * count);
	T* out = dest->data + dest->size;
	dest->size += count;
	return out;
}


template<typename T>
T* arr_back(Array<T>* array) {
	if (!array->size) return array->data;
	return array->data + (array->size - 1);
}

template<typename T>
T* arr_next(Array<T>* array) {
	fm_assert(array->size != array->capacity);
	return array->data + (array->size);
}

template<typename T>
void arr_free(Array<T>* array) {
	if (!array->data) return;
	
	free(array->data);
	
	array->data = nullptr;
	array->size = 0;
	array->capacity = 0;
	return;
}

template<typename T>
i32 arr_bytes(Array<T>* array) {
	return array->capacity * sizeof(T);
}

template<typename T>
i32 arr_bytes_used(Array<T>* array) {
	return array->size * sizeof(T);
}

#define arr_for(array, it) for (auto (it) = (array).data; (it) != ((array).data + (array).size); (it)++)
#define arr_rfor(array, it) for (auto (it) = (array).data + array.size - 1; (it) >= ((array).data); (it)--)



////////////////
// ARRAY VIEW //
////////////////
template<typename T>
ArrayView<T> arr_view(T* data, u64 size) {
	ArrayView<T> view;
	view.size = size;
	view.capacity = size;
	view.data = data;
	
	return view;
}

template<typename T>
ArrayView<T> arr_view(Array<T>* array) {
	ArrayView<T> view;
	view.size = array->size;
	view.capacity = array->size;
	view.data = array->data;
	
	return view;
}

template<typename T>
ArrayView<T> arr_view(Array<T>* array, u64 index, u64 count) {
	fm_assert(index >= 0);
	fm_assert(index + count <= array->capacity);

	ArrayView<T> view;
	view.size = count;
	view.capacity = count;
	view.data = array->data + index;
	
	return view;
}

template<typename T, u64 N>
ArrayView<T> arr_view(T (&array)[N]) {
	ArrayView<T> view;
	view.size = N;
	view.capacity = N;
	view.data = array;
	
	return view;
}


template<typename T>
i32 arr_indexof(ArrayView<T>* array, T* element) {
	i32 index = element - array->data;
	fm_assert(index >= 0);
	fm_assert(index < array->size);
	return index;
}


//////////////////
// ARRAY MARKER //
//////////////////
template<typename T>
ArrayMarker<T> arr_marker_make(Array<T>* array) {
	ArrayMarker<T> marker;
	arr_marker_init(&marker, array);
	return marker;
}

template<typename T>
void arr_marker_init(ArrayMarker<T>* marker, Array<T>* array) {
	marker->begin = array->size;
	marker->array = array;
}

template<typename T>
void arr_marker_freeze(ArrayMarker<T>* marker) {
	assert(marker->array);
	marker->frozen_size = marker->array->size;
}

template<typename T>
i32 arr_marker_count(ArrayMarker<T>* marker) {
	if (marker->frozen_size >= 0) return marker->frozen_size - marker->begin;
	return marker->array->size - marker->begin;
}
