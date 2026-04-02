--require("lldebugger").start()

require('algebra')

s = 50        -- size

polygon_x = { -- x=0
  { z = 0, y = 0, x = 0 },
  { z = 0, y = s, x = 0 },
  { z = s, y = s, x = 0 },
  { z = s, y = 0, x = 0 },
  color = { 0, 1, 1 },
}
polygon_x2 = { -- x=s
  { z = s, y = 0, x = s },
  { z = s, y = s, x = s },
  { z = 0, y = s, x = s },
  { z = 0, y = 0, x = s },
  color = { 0, 0, 1 }
}

polygon_y = { -- y=0
  { x = 0, z = 0, y = 0 },
  { x = 0, z = s, y = 0 },
  { x = s, z = s, y = 0 },
  { x = s, z = 0, y = 0 },
  color = { 1, 1, 1 },
}
polygon_y2 = { -- y=s
  { x = s, z = 0, y = s },
  { x = s, z = s, y = s },
  { x = 0, z = s, y = s },
  { x = 0, z = 0, y = s },
  color = { 0, 0, 1 }
}

polygon_z = { -- z=0
  { x = s, y = 0, z = 0 },
  { x = s, y = s, z = 0 },
  { x = 0, y = s, z = 0 },
  { x = 0, y = 0, z = 0 },
  color = { 1, 0, 0 }
}

polygon_z2 = { -- z=s
  { x = 0, y = 0, z = s },
  { x = 0, y = s, z = s },
  { x = s, y = s, z = s },
  { x = s, y = 0, z = s },
  color = { 1, 1, 0 },
}

polygons_original = {
  polygon_x, polygon_x2,
  polygon_y, polygon_y2,
  polygon_z, polygon_z2,
}

function convert_polygons_to_triangles(polygons_original)
  local triangles_original = {}
  for _, polygon_iterated in ipairs(polygons_original) do
    if #polygon_iterated == 4 then
      local triangle1, triangle2
      triangle1 = {
        color = polygon_iterated.color,
        polygon_iterated[1],
        polygon_iterated[2],
        polygon_iterated[3],
      }
      triangle2 = {
        color = polygon_iterated.color,
        polygon_iterated[3],
        polygon_iterated[4],
        polygon_iterated[1],
      }
      table.insert(triangles_original, triangle1)
      table.insert(triangles_original, triangle2)
    end
  end
  return triangles_original
end

triangles_original = convert_polygons_to_triangles(polygons_original)

--*****************************************
require("loader")
local file_path = "assets/stl-ascii-teapot-axes.stl"
local vertices_bounds
---triangles_original= load_stl_file(file_path)
triangles_original = {}
----print("bounding box", string.format("x %f %f, y %f %f, z %f %f", unpack(vertices_bounds) ) )

---triangles_original= load_obj_file"assets/teapot.obj"

function mesh_center(triangles)
  local x_min, x_max = math.huge, -math.huge
  local y_min, y_max = math.huge, -math.huge
  local z_min, z_max = math.huge, -math.huge
  for _, tri in ipairs(triangles) do
    for _, v in ipairs(tri) do
      if v.x < x_min then x_min = v.x end
      if v.x > x_max then x_max = v.x end
      if v.y < y_min then y_min = v.y end
      if v.y > y_max then y_max = v.y end
      if v.z < z_min then z_min = v.z end
      if v.z > z_max then z_max = v.z end
    end
  end
  return { x = (x_min + x_max) / 2, y = (y_min + y_max) / 2, z = (z_min + z_max) / 2 }
end

--*****************************************
function point_translate(point, x, y, z)
  return {
    x = point.x + x,
    y = point.y + y,
    z = point.z + z
  }
end

--[[
function point_rotate(point, radiants)
  return {
    x = math.cos(radiants)*point.x - math.sin(radiants)*point.y ,
    y = math.cos(radiants)*point.y + math.sin(radiants)*point.x }
end --]]

function point_rotate_axes(axes, point_in, radiants)
  local point_out = { x = point_in.x, y = point_in.y, z = point_in.z }
  local one, two = string.sub(axes, 1, 1), string.sub(axes, 2, 2)
  point_out[one] = math.cos(radiants) * point_in[one] - math.sin(radiants) * point_in[two]
  point_out[two] = math.cos(radiants) * point_in[two] + math.sin(radiants) * point_in[one]
  return point_out
end

function point_rotate_z(point, radiants)
  return point_rotate_axes('xy', point, radiants)
end

function point_rotate_y(point, radiants)
  return point_rotate_axes('xz', point, radiants)
end

function polygon_transform(polygon, degrees, center)
  center = center or { x = 0, y = 0, z = 0 }
  local radiants = (degrees / 360) * (math.pi * 2)

  local polygon_origin = {}
  for i, point in ipairs(polygon) do
    table.insert(polygon_origin, point_translate(point,
      -center.x, -center.y, -center.z
    ))
  end

  --[[
  local polygon_rotated1={}
  for i,point in ipairs(polygon_origin) do
    table.insert( polygon_rotated1, point_rotate_z(point, 0 ) ) -- radiants | 0
  end
  --]]

  local polygon_rotated2 = {}
  for i, point in ipairs(polygon_origin) do                         --- polygon_rotated1
    table.insert(polygon_rotated2, point_rotate_y(point, radiants)) -- radiants | 0
  end

  local polygon_rotated_translated = {}
  for i, point in ipairs(polygon_rotated2) do
    table.insert(polygon_rotated_translated, point_translate(point, 150, 150, -400))
  end

  local polygon_transformed = polygon_rotated_translated
  polygon_transformed.color = polygon.color -- same color

  ---[[
  if polygon[1].normal then
    polygon_transformed[1].normal = point_rotate_y(polygon[1].normal, radiants) -- same normal WIP
    polygon_transformed[2].normal = point_rotate_y(polygon[2].normal, radiants) -- same normal WIP
    polygon_transformed[3].normal = point_rotate_y(polygon[3].normal, radiants) -- same normal WIP
  end

  if polygon[1].uv then
    polygon_transformed[1].uv = polygon[1].uv
    polygon_transformed[2].uv = polygon[2].uv
    polygon_transformed[3].uv = polygon[3].uv
  end
  --]]

  return polygon_transformed
end

degrees = 0.0

local obj_cube = load_obj_file("assets/head.obj")
obj_cube.center = mesh_center(obj_cube)
--obj_cube = {} -- WIP to simplify

local obj_uv_plane = load_obj_file("assets/uv_plane.obj")
obj_uv_plane.center = mesh_center(obj_uv_plane)

local obj_floor = load_obj_file("assets/floor_plane.obj")
obj_floor.center = { x = 0, y = 0, z = 0 } -- preserve y=-100 world position

function update(dt)
  local degrees_increment
  degrees_increment = dt * 45
  degrees = (degrees + degrees_increment) % 360

  local polygons_transformed = {}
  function polygons_transform(polygons, degrees)
    assert(polygons)
    local center = polygons.center or { x = 0, y = 0, z = 0 }
    for i, polygon in ipairs(polygons) do
      table.insert(polygons_transformed, polygon_transform(polygon, degrees, center))
    end
    return polygons_transformed
  end

  polygons_transformed = polygons_transform(triangles_original, degrees)
  ---polygons_transformed = triangles_original

  polygons_transformed = polygons_transform(obj_cube, (degrees + 180) % 360)
  polygons_transformed = polygons_transform(obj_floor, 0)
  ---polygons_transformed = polygons_transform(obj_uv_plane, 0)

  local s = 50
  local depth = 10
  local polygon_z2 = { -- z=s
    { x = 0, y = 0, z = depth },
    { x = 0, y = s, z = depth },
    { x = s, y = s, z = depth },
    { x = s, y = 0, z = depth },
    color = { 1, 1, 0 },
  }

  local polygons_transformed_addon
  polygons_transformed_addon = {
    polygon_z2, -- WIP TODO turno off this debug helper, comment-out this line
  }
  polygons_transformed_addon = convert_polygons_to_triangles(
    polygons_transformed_addon)

  -- polygons_transformed_addon = convert_polygons_to_triangles( { polygon_z2 } )

  local polygons_accumulator = polygons_transformed
  for i, polygon in ipairs(polygons_transformed_addon) do
    table.insert(polygons_accumulator, polygon)
  end
  polygons_to_render = polygons_accumulator
end

function shading(polygon_iterated)
  --[[
  if not polygon_iterated.normal then  -- caching
    polygon_iterated.normal = polygon_normal(polygon_iterated)
  end
  --]]

  local normal_vector = polygon_normal(polygon_iterated) -- not cached

  --[[
  function polygon_iterated.depth(px, py)

    if not polygon_iterated.normal then -- caching, it's cached
      polygon_iterated.normal = polygon_normal(polygon_iterated)
    end

    local x,y,z,x1,y1,z1,a,b,c
    local normal_vector = polygon_iterated.normal -- cached
    x=px
    y=py
    x1=polygon_iterated[1].x
    y1=polygon_iterated[1].y
    z1=polygon_iterated[1].z
    a=normal_vector.x
    b=normal_vector.y
    c=normal_vector.z

    z = -(a*x +b*y -(a*x1 +b*y1 +c*z1) )/c

    return z
  end
  --]]

  --[[
  shaded_color=color*(dot(facing_direction,light_direction))
  i.e. face_color scaled to cos_angle obtained as
  vector dot product of face_normal and to_light vectors
  --]]

  if not polygon_iterated.color_diffuse then
    local color = polygon_iterated.color or { 1, 1, 0 } -- default if missing

    local face_normal = normal_vector                   -- not cached

    local to_light = vunit({ x = -1, y = -1, z = -1 })

    local cos_angle = vdot(face_normal, to_light)
    cos_angle = unit_clamp(cos_angle)

    color = scale3(cos_angle, color)

    local ambient_light_intensity = 0.4
    local ambient_light_color = {
      ambient_light_intensity,
      ambient_light_intensity,
      ambient_light_intensity }

    color = sum3(color, ambient_light_color)
    color = clamp3(color)

    polygon_iterated.color_diffuse = color
  end
end

function perspective(polygon_iterated)
  local cx, cy = 150, 150  -- screen center (matches window 300x300)
  local focal = 200         -- focal length; objects at z=-200 appear at natural size
  for i, vertex in ipairs(polygon_iterated) do
    vertex.inv_z = 1.0 / (-vertex.z)   -- store for perspective-correct UV
    vertex.x = (vertex.x - cx) * (focal * vertex.inv_z) + cx
    vertex.y = (vertex.y - cy) * (focal * vertex.inv_z) + cy
    -- vertex.z left unchanged (used for depth testing)
  end
end

function vertex_color_from_vertex_normal(triangle, vertex, color, to_light, ambient_light_color)
  local normal
  if vertex.normal then
    normal = vertex.normal
  else
    normal = polygon_normal(triangle)
  end

  local cos_angle = vdot(normal, to_light)
  cos_angle = unit_clamp(cos_angle)
  color = scale3(cos_angle, color)
  color = sum3(color, ambient_light_color)
  color = clamp3(color)
  vertex.color = color
end

function shading_smooth_preset1(triangle)
  local ambient_light_intensity = 0.4
  local ambient_light_color = {
    ambient_light_intensity,
    ambient_light_intensity,
    ambient_light_intensity }

  local surface_color = { 1, 0.5, 0.5 }

  local lights = {
    vunit({ x = -1, y = -1, z = -1 }), -- top-left-back
    vunit({ x =  1, y =  0, z = -1 }), -- right-front
    vunit({ x =  0, y =  1, z =  0 }), -- top-down (illuminates floor)
  }

  for _, vertex in ipairs({ triangle[1], triangle[2], triangle[3] }) do
    local normal = vertex.normal or polygon_normal(triangle)
    local diffuse = { 0, 0, 0 }
    for _, to_light in ipairs(lights) do
      local cos = unit_clamp(vdot(normal, to_light))
      diffuse = sum3(diffuse, scale3(cos, surface_color))
    end
    vertex.color = clamp3(sum3(diffuse, ambient_light_color))
  end
end

local render_width, render_height = 300, 300
local depth_buffer = {}
do
  for py = 0, render_height do
    depth_buffer[py] = {}
    for px = 0, render_width do depth_buffer[py][px] = -math.huge end
  end
end

function draw()
  for i, polygon_iterated in ipairs(polygons_to_render) do
    shading_smooth_preset1(polygon_iterated)
  end

  for i, polygon_iterated in ipairs(polygons_to_render) do
    perspective(polygon_iterated)
  end

  -- z-buffer reset
  for py = 0, render_height do
    local line = depth_buffer[py]
    for px = 0, render_width do line[px] = -math.huge end
  end

  --[[
  -- pixels
  for py=0,render_height do
    for px=0,render_width do
      for i,polygon_iterated in ipairs(polygons_to_render) do

        local check = false
        check = in_convex_polygon(px, py, polygon_iterated)
        --]]

  function inside_polygon(polygon, point)
    local last = polygon[#polygon]
    for i = 1, #polygon do
      local current = polygon[i]

      --[[
      if side(point, last, current) > 0 then
        return false
      end
      --]]

      function halfplane(px, p1, p2)
        return ((p2.x - p1.x) * (px.y - p1.y) - (p2.y - p1.y) * (px.x - p1.x)) < 0
      end

      if halfplane(point, last, current) then
        return false
      end

      last = current
    end
    return true
  end

  -- testing: function color_interpolate(point, polygon)
  --polygons_to_render = {}

  --[[
  table.insert(polygons_to_render,
    {
      {x=300, y=10, z=10, color={1,1,0}},
      {x=10,  y=10, z=10, color={1,0,0}},
      {x=10,  y=300,z=10, color={0,1,0}},
    }
  )
  --]]

  for i, polygon_iterated in ipairs(polygons_to_render) do
    local x_min = math.huge
    local x_max = -math.huge
    local y_min = math.huge
    local y_max = -math.huge
    for i, point in ipairs(polygon_iterated) do
      if point.x < x_min then x_min = point.x end
      if point.x > x_max then x_max = point.x end
      if point.y < y_min then y_min = point.y end
      if point.y > y_max then y_max = point.y end
    end

    x_min = math.max(x_min, 0)
    x_max = math.min(x_max, render_width)

    y_min = math.max(y_min, 0)
    y_max = math.min(y_max, render_height)

    x_min = math.floor(x_min)
    x_max = math.floor(x_max)
    y_min = math.floor(y_min)
    y_max = math.floor(y_max)

    local pre_baryc_coords = barycentric_coords_precalculated_for_polygon(polygon_iterated)

    for py = y_min, y_max do
      for px = x_min, x_max do
        local point = { x = px, y = py }
        local polygon = polygon_iterated

        local function check_polygon()
          return inside_polygon(polygon, point)
        end

        local function check_wireframe()
          local ra, rb, rc = barycentric_coordinates(point, polygon)
          function quasi_zero(number) return math.abs(number) <= 0.05 end

          return quasi_zero(ra) or quasi_zero(rb) or quasi_zero(rc)
        end

        if check_polygon() then
          local rgb = polygon_iterated.color_diffuse

          local function depth(px, py, polygon_iterated)
            if not polygon_iterated.normal then -- caching, it's cached
              polygon_iterated.normal = polygon_normal(polygon_iterated)
            end

            local x, y, z, x1, y1, z1, a, b, c
            local normal_vector = polygon_iterated.normal -- cached
            x = px
            y = py
            x1 = polygon_iterated[1].x
            y1 = polygon_iterated[1].y
            z1 = polygon_iterated[1].z
            a = normal_vector.x
            b = normal_vector.y
            c = normal_vector.z

            z = -(a * x + b * y - (a * x1 + b * y1 + c * z1)) / c

            return z
          end

          local point = { x = px, y = py }

          ---local z = depth(px,py, polygon_iterated) -- NOT precalc
          local z = position_interpolate_precalc(point, polygon, pre_baryc_coords).z

          local current_depth = depth_buffer[py][px]
          if z > current_depth then
            ---if not rgb then rgb = color_interpolate({x=px, y=py}, polygon_iterated) end -- NOT precalc
            if not rgb then rgb = color_interpolate_precalc(point, polygon, pre_baryc_coords) end

            -- texture mapping: blend diffuse texture with Gouraud color
            if polygon[1].uv then
              local uv = uv_interpolate_precalc(point, polygon, pre_baryc_coords)
              local tex = sample_texture(uv[1], uv[2])
              rgb = { rgb[1] * tex[1], rgb[2] * tex[2], rgb[3] * tex[3] }
            end

            draw_pixel(rgb, { px, (render_height - 1) - py }) -- mirrored y axis

            depth_buffer[py][px] = z                          -- successive depth
          end
        end
      end
    end
  end
end
