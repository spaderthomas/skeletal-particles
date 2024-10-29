// It's a unity build, so there are no compilation units. Don't include anything in individual files. Rather,
// include everything here and order them by hand. This sounds tedious until you try it; as long as you put
// function prototypes and structs in a header and implementations in a source file, the worst you'll have
// to do is a forward declaration for circular dependencies.
#include "user/user_callbacks.hpp"

#include "user/user_callbacks.cpp"
