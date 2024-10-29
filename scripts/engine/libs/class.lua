function tdengine.is_instance_of(self, class)
  if type(class) == 'table' then
    class = class.name
  end

  local mt = getmetatable(self)
  return mt.__type == class
end

function tdengine.class.define(name)
  tdengine.types[name] = {
    name = name,
    -- Static methods manipulate the class itself, like SomeClass:new()
    __static = {
      include = function(__class, mixin)
        for method_name, method in pairs(mixin) do
          tdengine.types[name].__instance[method_name] = method
        end
      end,

      include_lifecycle = function(__class, enum)
        tdengine.types[name].__static:include_enum(tdengine.enums.LifecycleCallback)
      end,

      include_update = function(__class, enum)
        tdengine.types[name].__static:include_enum(tdengine.enums.UpdateCallback)
      end,

      include_enum = function(__class, enum)
        for as_enum, as_string, as_number in enum:iterate() do
          tdengine.types[name].__instance[as_string] = function() end
        end
      end,

      include_fields = function(__class, fields)
        for field_name, field in pairs(fields) do
          tdengine.types[name].__fields[field_name] = field
        end
      end,



      allocate = function(__class, ...)
        local instance = {}
        for field_name, field in pairs(tdengine.types[name].__fields) do
          instance[field_name] = field
        end
    
        setmetatable(instance, {
          __index = function(__instance, key)
            -- If some key isn't found on the instance, check the class' instance methods
            -- Look up the class in the global type table, so that it's not stale when hotloaded
            return tdengine.types[name].__instance[key]
          end,
          __type = name
        })
    
        return instance
      end,

      new = function(__class, ...)
        local instance = tdengine.types[name].__static.allocate(__class)
        return tdengine.types[name].__static.construct(__class, instance, ...)
      end,

      construct = function(__class, instance, ...)
        if tdengine.types[name].__static.init then
          tdengine.types[name].__static.init(instance, ...)
        end
    
        return instance
      end
    },

    -- Instance methods manipulate an instance of the class, like some_instance:do_something()
    __instance = {
      is_instance_of = function(self, class)
        if type(class) == 'table' then
          class = class.name
        end

        local mt = getmetatable(self)
        return mt.__type == class
      end,

      class = function(self)
        return getmetatable(self).__type
      end
    },

    -- Fields are handled just a bit different; adding them to the __instance table, like methods, works
    -- fine for lookups, but then the fields wouldn't be visible in the editor. Instead, we copy all
    -- the base class' fields when we allocate an instance.
    __fields = {

    }
  }

  setmetatable(tdengine.types[name].__static, {
    __index = function(_, key)
      -- If we can't find a static method, then we'll see if it's an instance method
      return rawget(tdengine.types[name].__instance, key)
    end
  })

  setmetatable(tdengine.types[name], {
    -- Point missing keys to the static method table (which will in turn point still-missing keys to the instasnce method table)
    __index = function(_, key)
      return tdengine.types[name].__static[key]
    end,

    -- Any members you define on the class are instance methods
    __newindex = function(__class, member_name, member)
      tdengine.types[name].__instance[member_name] = member
    end
  })

  return tdengine.types[name]
end

function tdengine.class.find(name)
  return tdengine.types[name]
end

function tdengine.add_class_metamethod(class, name, fn)
  local metatable = getmetatable(class)
  metatable[name] = fn
  setmetatable(class, metatable)
end
