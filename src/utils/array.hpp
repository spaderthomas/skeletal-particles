void memfill(void* dst, i32 size, void* pattern, i32 pattern_size);

template<typename T>
struct Array {
	u64 size      = 0;
	u64 capacity  = 0;
	T* data         = nullptr;

	T* operator[](u64 index) { fm_assert(index < size); return data + index; }
	operator bool() { return data; }
};

template<typename T>
fm_error arr_init(Array<T>* array, u64 capacity, MemoryAllocator* allocator);

template<typename T>
fm_error arr_init(Array<T>* array, u64 capacity);

template<typename T>
fm_error arr_init(Array<T>* array, u64 capacity, T fill);

template<typename T>
void arr_clear(Array<T>* array);

template<typename T>
void arr_fastclear(Array<T>* array);

template<typename T>
void arr_clear_n(Array<T>* array, i32 n);

template<typename T>
void arr_fill(Array<T>* array, T element);

template<typename T>
void arr_fill(Array<T>* array, T element, u64 count);

template<typename T>
void arr_fill(Array<T>* array, u64 offset, u64 count, T element);

// Use case: You declare some array on the stack. It's empty, and you only want to modify its elements
// using an Array. Call this to wrap it in an empty Array of the correct capacity.
template<typename T>
Array<T> arr_stack(T* data, u64 capacity);

template<typename T, u64 N>
Array<T> arr_stack(T (&c_array)[N]);

// Use case: You have some contiguous data filled out somewhere (maybe in another Array, maybe in a C
// array). You want to RW a subarray using Array functions. Call this to wrap the subarray. 
template<typename T>
Array<T> arr_slice(Array<T>* array, u64 index, u64 size);

template<typename T>
Array<T> arr_slice(T* data, u64 size);

template<typename T, u64 N>
Array<T> arr_slice(T (&data)[N]);

template<typename T>
i32 arr_indexof(Array<T>* array, T* element);

template<typename T>
T* arr_at(Array<T>* array, u64 index);

template<typename T>
bool arr_full(Array<T>* array);

template<typename T>
T* arr_push(Array<T>* array, const T* data, u64 count);

template<typename T>
T* arr_push(Array<T>* array, T* data, u64 count);

template<typename T>
T* arr_push(Array<T>* array, T element, u64 count);

template<typename T>
T* arr_push(Array<T>* array, T* data);

template<typename T>
T* arr_push(Array<T>* array, T data);

template<typename T>
T* arr_push(Array<T>* array);

template<typename T>
void arr_pop(Array<T>* array);

// "Preallocate" space in the array without the cost of zeroing memory or default constructing
// entities. For example, if you want to push 16 elements to an array and modify the elements
// in-place -- reserve the space with this function, then just use the memory blocks.
template<typename T>
T* arr_reserve(Array<T>* array, u64 count);

template<typename T>
T* arr_concat(Array<T>* dest, Array<T>* source);

template<typename T>
T* arr_concat(Array<T>* dest, Array<T>* source, u64 count);

template<typename T>
T* arr_back(Array<T>* array);

template<typename T>
T* arr_next(Array<T>* array);

template<typename T>
void arr_free(Array<T>* array);

template<typename T>
i32 arr_bytes(Array<T>* array);

template<typename T>
i32 arr_bytes_used(Array<T>* array);

#define arr_for(array, it) for (auto (it) = (array).data; (it) != ((array).data + (array).size); (it)++)
#define arr_rfor(array, it) for (auto (it) = (array).data + array.size - 1; (it) >= ((array).data); (it)--)



template<typename T>
struct ArrayView {
	u64 size      = 0;
	u64 capacity  = 0;
	T* data         = nullptr;

	// @spader could make this const correct, whatever
	T* operator[](u64 index) { fm_assert(index < size); return data + index; }
};

template<typename T>
ArrayView<T> arr_view(T* data, u64 size);

template<typename T>
ArrayView<T> arr_view(Array<T>* array);

template<typename T>
ArrayView<T> arr_view(Array<T>* array, u64 index, u64 count);

template<typename T, u64 N>
ArrayView<T> arr_view(T (&array)[N]);

template<typename T>
i32 arr_indexof(ArrayView<T>* array, T* element);


template<typename T>
struct ArrayMarker {
	u64 begin = 0;
	u64 frozen_size = -1;
	Array<T>* array  = nullptr;
};

template<typename T>
ArrayMarker<T> arr_marker_make(Array<T>* array);

template<typename T>
void arr_marker_init(ArrayMarker<T>* marker, Array<T>* array);

template<typename T>
void arr_marker_freeze(ArrayMarker<T>* marker);

template<typename T>
i32 arr_marker_count(ArrayMarker<T>* marker);
