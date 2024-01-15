function clamp_generic(n, low, high) return math.min(math.max(n, low), high) end

function unit_clamp(n) return clamp_generic(n, 0, 1) end

-- vector algebra

string_indices_point = { 'x', 'y', 'z' }
zero3 = { x = 0, y = 0, z = 0 }

function voperation(v1, v2, op, string_indices_option) -- abstract vector operation (then specialized)
  local string_indices

  if not string_indices_option then
    string_indices = string_indices_point
  else
    string_indices = string_indices_option
  end

  local result = {}
  for index = 1, #string_indices do
    local string_index = string_indices[index]
    local n = op(v1[string_index], v2[string_index])
    result[string_index] = n
  end
  return result
end

function vadd(v1, v2) -- addition (sum)
  return voperation(v1, v2, function(a, b) return a + b end)
end

function vsubtract(v1, v2) -- subtraction (difference)
  return voperation(v1, v2, function(a, b) return a - b end)
end

function vminus(v1) -- apply minus (-v1)
  return vsubtract(zero3, v1)
end

function vscale(scalar, v1) -- multiply (scale)
  return voperation(zero3, v1, function(_, b) return scalar * b end)
end

function vdivide(v1, scalar) -- divide
  return voperation(v1, zero3, function(a, _) return a / scalar end)
end

function vmagnitude(v1) -- magnitude (length) of the vector
  return math.sqrt(v1.x * v1.x + v1.y * v1.y + v1.z * v1.z)
end

function vunit(v1) -- set unit magnitude (vector normalization)
  return vdivide(v1, vmagnitude(v1))
end

function vcross(v1, v2) -- vector cross product
  return {
    x = v1.y * v2.z - v1.z * v2.y,
    y = v1.z * v2.x - v1.x * v2.z,
    z = v1.x * v2.y - v1.y * v2.x
  }
end

function vdot(v1, v2) -- vector dot product
  return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

function vstringify(v) -- xyz vector to string
  return "(" .. v.x .. "," .. v.y .. "," .. v.z .. ")"
end

-- function color_scale

function scale3(scalar, vec3)
  return { vec3[1] * scalar, vec3[2] * scalar, vec3[3] * scalar }
end

function sum3(vec3_a, vec3_b)
  return { vec3_a[1] + vec3_b[1], vec3_a[2] + vec3_b[2], vec3_a[3] + vec3_b[3] }
end

function clamp3(vec3)
  return { unit_clamp(vec3[1]), unit_clamp(vec3[2]), unit_clamp(vec3[3]) }
end

--[[
string_indices_color = {'r','g','b'}
color_zero={r=0,g=0,b=0}

function color_scale(scalar,color) -- multiply (scale)
  return voperation(color_zero,color,function(_,b_color_component) return scalar*b_color_component end, string_indices_color)
end
--]]

-- *********************************

function polygon_normal(polygon)
  local v1 = vsubtract(polygon[2], polygon[1])
  local v2 = vsubtract(polygon[3], polygon[1])
  local normal = vcross(v1, v2)
  return vunit(normal)
end

function barycentric_coordinates(point, polygon)
  local a = polygon[1]
  local b = polygon[2]
  local c = polygon[3]
  local ra = ((b.y - c.y) * (point.x - c.x) + (c.x - b.x) * (point.y - c.y)) / ((b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y))
  local rb = ((c.y - a.y) * (point.x - c.x) + (a.x - c.x) * (point.y - c.y)) / ((b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y))
  local rc = 1 - ra - rb
  return ra, rb, rc
end

function color_interpolate(point, polygon)
  local ra, rb, rc = barycentric_coordinates(point, polygon)
  local a = polygon[1]
  local b = polygon[2]
  local c = polygon[3]
  return sum3(scale3(ra, a.color), sum3(scale3(rb, b.color), scale3(rc, c.color)))
end

-- with pre-calculation per-polygon

function barycentric_coords_precalculated_for_polygon(polygon)
  local a = polygon[1]
  local b = polygon[2]
  local c = polygon[3]
  local pre_baryc_coords = {}
  pre_baryc_coords.common = (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
  pre_baryc_coords.ax = b.y - c.y
  pre_baryc_coords.ay = c.x - b.x
  pre_baryc_coords.bx = c.y - a.y
  pre_baryc_coords.by = a.x - c.x
  pre_baryc_coords.cx = c.x
  pre_baryc_coords.cy = c.y
  return pre_baryc_coords
end

function barycentric_coordinates_cache_by_polygon(point, pre)
  local ra = (pre.ax * (point.x - pre.cx) + pre.ay * (point.y - pre.cy)) / pre.common
  local rb = (pre.bx * (point.x - pre.cx) + pre.by * (point.y - pre.cy)) / pre.common
  local rc = 1 - ra - rb
  return { ra = ra, rb = rb, rc = rc }
end

function color_interpolate_precalc(point, polygon, pre)
  local coords = barycentric_coordinates_cache_by_polygon(point, pre)
  local ra, rb, rc = coords.ra, coords.rb, coords.rc
  local a = polygon[1]
  local b = polygon[2]
  local c = polygon[3]
  return sum3(scale3(ra, a.color), sum3(scale3(rb, b.color), scale3(rc, c.color)))     -- ra*a + rb*b + rc*c
end

function position_interpolate_precalc(point, polygon, pre)
  local coords = barycentric_coordinates_cache_by_polygon(point, pre)
  local ra, rb, rc = coords.ra, coords.rb, coords.rc
  local a = polygon[1]
  local b = polygon[2]
  local c = polygon[3]
  return vadd(vscale(ra, a), vadd(vscale(rb, b), vscale(rc, c)))     -- ra*a + rb*b + rc*c
end

-- *********************************

function algebra_module_test()
  local cross = vcross({ x = 1, y = 0, z = 0 }, { x = 0, y = 1, z = 0 }) -- (0,0,1)
  print(vstringify(cross))
  local result1 = vscale(2, vminus(cross))
  local result2 = vadd(result1, cross) -- (0,0,-1)
  print(vstringify(result2))

  local polygon_reference = {
    { x = 0, y = 0, z = 0 }, { x = 0, y = 50, z = 0 }, { x = 50, y = 0, z = 0 },
  }
  local normal = polygon_normal(polygon_reference)
  print(vstringify(normal))   -- (0,0,-1)
end

if not ... then
  algebra_module_test()
else
  print('algebra_module_test skipped')
end
