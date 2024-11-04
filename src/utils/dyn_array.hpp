typedef struct dyn_array
{
    int32_t size;
    int32_t capacity;
} dyn_array;

#define dyn_array_head(__ARR)\
    ((dyn_array*)((uint8_t*)(__ARR) - sizeof(dyn_array)))

#define dyn_array_size(__ARR)\
    (__ARR == NULL ? 0 : dyn_array_head((__ARR))->size)

#define dyn_array_capacity(__ARR)\
    (__ARR == NULL ? 0 : dyn_array_head((__ARR))->capacity)

#define dyn_array_full(__ARR)\
    ((dyn_array_size((__ARR)) == dyn_array_capacity((__ARR))))    

#define dyn_array_byte_size(__ARR)\
    (dyn_array_size((__ARR)) * sizeof(*__ARR))

void*  dyn_array_resize_impl(void* arr, size_t sz, size_t amount);

#define dyn_array_need_grow(__ARR, __N)\
    ((__ARR) == 0 || dyn_array_size(__ARR) + (__N) >= dyn_array_capacity(__ARR))

#define dyn_array_grow(__ARR)\
    dyn_array_resize_impl((__ARR), sizeof(*(__ARR)), dyn_array_capacity(__ARR) ? dyn_array_capacity(__ARR) * 2 : 1)

#define dyn_array_grow_size(__ARR, __SZ  )\
    dyn_array_resize_impl((__ARR), (__SZ ), dyn_array_capacity(__ARR) ? dyn_array_capacity(__ARR) * 2 : 1)

void** dyn_array_init(void** arr, size_t val_len);

void dyn_array_push_data(void** arr, void* val, size_t val_len);

void dyn_array_set_data_i(void** arr, void* val, size_t val_len, uint32_t offset) {
    memcpy(((char*)(*arr)) + offset * val_len, val, val_len);
}

#define dyn_array_push(__ARR, __ARRVAL)\
    do {\
        dyn_array_init((void**)&(__ARR), sizeof(*(__ARR)));\
        if (!(__ARR) || ((__ARR) && dyn_array_need_grow(__ARR, 1))) {\
            *((void **)&(__ARR)) = dyn_array_grow(__ARR); \
        }\
        (__ARR)[dyn_array_size(__ARR)] = (__ARRVAL);\
        dyn_array_head(__ARR)->size++;\
    } while(0)

#define dyn_array_reserve(__ARR, __AMOUNT)\
    do {\
        if ((!__ARR)) dyn_array_init((void**)&(__ARR), sizeof(*(__ARR)));\
        if ((!__ARR) || (size_t)__AMOUNT > dyn_array_capacity(__ARR)) {\
            *((void **)&(__ARR)) = dyn_array_resize_impl(__ARR, sizeof(*__ARR), __AMOUNT);\
        }\
    } while(0)

#define dyn_array_empty(__ARR)\
    (dyn_array_init((void**)&(__ARR), sizeof(*(__ARR))), (dyn_array_size(__ARR) == 0))

#define dyn_array_pop(__ARR)\
    do {\
        if (__ARR && !dyn_array_empty(__ARR)) {\
            dyn_array_head(__ARR)->size -= 1;\
        }\
    } while (0)

#define dyn_array_back(__ARR)\
    *(__ARR + (dyn_array_size(__ARR) ? dyn_array_size(__ARR) - 1 : 0))

#define dyn_array_for(__ARR, __T, __IT_NAME)\
    for (__T* __IT_NAME = __ARR; __IT_NAME != dyn_array_back(__ARR); ++__IT_NAME)

#define dyn_array_new(__T)\
    ((__T*)dyn_array_resize_impl(NULL, sizeof(__T), 0))

#define dyn_array_clear(__ARR)\
    do {\
        if (__ARR) {\
            dyn_array_head(__ARR)->size = 0;\
        }\
    } while (0)

#define dyn_array(__T)   __T*

#define dyn_array_free(__ARR)\
    do {\
        if (__ARR) {\
            free(dyn_array_head(__ARR));\
            (__ARR) = NULL;\
        }\
    } while (0)

void* dyn_array_resize_impl(void* arr, size_t sz, size_t amount) 
{
    size_t capacity;

    if (arr) {
        capacity = amount;  
    } else {
        capacity = 0;
    }

    // Create new dyn_array with just the header information
    dyn_array* data = (dyn_array*)realloc(arr ? dyn_array_head(arr) : 0, capacity * sz + sizeof(dyn_array));

    if (data) {
        if (!arr) {
            data->size = 0;
        }
        data->capacity = (int32_t)capacity;
        return ((int32_t*)data + 2);
    }

    return NULL;
}

void** dyn_array_init(void** arr, size_t val_len)
{
    if (*arr == NULL) {
        dyn_array* data = (dyn_array*)malloc(val_len + sizeof(dyn_array));  // Allocate capacity of one
        data->size = 0;
        data->capacity = 1;
        *arr = ((int32_t*)data + 2);
    }
    return arr;
}

void dyn_array_push_data(void** arr, void* val, size_t val_len)
{
    if (*arr == NULL) {
        dyn_array_init(arr, val_len);
    }
    if (dyn_array_need_grow(*arr, 1)) 
    {
        int32_t capacity = dyn_array_capacity(*arr) * 2;

        // Create new dyn_array with just the header information
        dyn_array* data = (dyn_array*)realloc(dyn_array_head(*arr), capacity * val_len + sizeof(dyn_array));

        if (data) {
            data->capacity = capacity;
            *arr = ((int32_t*)data + 2);
        }
    }
    size_t offset = dyn_array_size(*arr);
    memcpy(((uint8_t*)(*arr)) + offset * val_len, val, val_len);
    dyn_array_head(*arr)->size++;
}