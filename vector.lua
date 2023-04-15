local key_mapping = { -- rgb xyz
  r=1, g=2, b=3,
  x=1, y=2, z=3,
}

local metatable_vector = {}
function metatable_vector.__index(table, key)
  return rawget(table, key_mapping[key] or key)
end
function metatable_vector.__newindex(table, key, value)
  return rawset(table, key_mapping[key] or key, value)
end

local function vector_new(vector_1)
  setmetatable(vector_1, metatable_vector)
  return vector_1
end
local vector_1 = vector_new({0,1,1})

print(vector_1.r)
vector_1.x = 1
print(vector_1.r)

print("end")