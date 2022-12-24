require('algebra')

s=50 -- size

polygon_x={ -- x=0
  {z=0,y=0,x=0},
  {z=0,y=s,x=0},
  {z=s,y=s,x=0},
  {z=s,y=0,x=0},
  color={0,1,1},
}
polygon_x2={ -- x=s
  {z=s,y=0,x=s},
  {z=s,y=s,x=s},
  {z=0,y=s,x=s},
  {z=0,y=0,x=s},
  color={0,0,1}
}

polygon_y={ -- y=0
  {x=0,z=0,y=0},
  {x=0,z=s,y=0},
  {x=s,z=s,y=0},
  {x=s,z=0,y=0},
  color={1,1,1},
}
polygon_y2={ -- y=s
  {x=s,z=0,y=s},
  {x=s,z=s,y=s},
  {x=0,z=s,y=s},
  {x=0,z=0,y=s},
  color={0,0,1}
}

polygon_z={ -- z=0
  {x=s,y=0,z=0},
  {x=s,y=s,z=0},
  {x=0,y=s,z=0},
  {x=0,y=0,z=0},
  color={1,0,0}
}

polygon_z2={ -- z=s
  {x=0,y=0,z=s},
  {x=0,y=s,z=s},
  {x=s,y=s,z=s},
  {x=s,y=0,z=s},
  color={1,1,0},
}

polygons_original={
  polygon_x, polygon_x2,
  polygon_y, polygon_y2,
  polygon_z, polygon_z2,
}

function convert_polygons_to_triangles(polygons_original)
  local triangles_original = {}
  for _, polygon_iterated in ipairs(polygons_original) do
    if #polygon_iterated == 4 then
      local triangle1, triangle2
      triangle1={
        color=polygon_iterated.color,
        polygon_iterated[1],
        polygon_iterated[2],
        polygon_iterated[3],
      }
      triangle2={
        color=polygon_iterated.color,
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

function polygon_transform(polygon)
  local radiants = (degrees/360)*(math.pi*2)
  
  function point_translate(point, x,y,z)
    return {
      x = point.x + x ,
      y = point.y + y ,
      z = point.z + z }
  end
  
  --[[
  function point_rotate(point, radiants)
    return {
      x = math.cos(radiants)*point.x - math.sin(radiants)*point.y ,
      y = math.cos(radiants)*point.y + math.sin(radiants)*point.x }
  end --]]
  
  function point_rotate_axes(axes, point_in, radiants)
    local point_out = {x=point_in.x, y=point_in.y, z=point_in.z}
    local one, two = string.sub(axes, 1,1), string.sub(axes, 2,2)
    point_out[one] = math.cos(radiants)*point_in[one] - math.sin(radiants)*point_in[two]
    point_out[two] = math.cos(radiants)*point_in[two] + math.sin(radiants)*point_in[one]
    return point_out
  end
  
  function point_rotate_z(point, radiants)
    return point_rotate_axes('xy', point, radiants)
  end
  
  function point_rotate_y(point, radiants)
    return point_rotate_axes('xz', point, radiants)
  end
  
  local polygon_origin={}
  for i,point in ipairs(polygon) do
    table.insert( polygon_origin, point_translate(point, -25,-25,-25) )
  end
  
  local polygon_rotated1={}
  for i,point in ipairs(polygon_origin) do
    table.insert( polygon_rotated1, point_rotate_z(point, radiants) )
  end
  
  local polygon_rotated2={}
  for i,point in ipairs(polygon_rotated1) do
    table.insert( polygon_rotated2, point_rotate_y(point, radiants) )
  end
  
  local polygon_rotated_translated={}
  for i,point in ipairs(polygon_rotated2) do
    table.insert( polygon_rotated_translated, point_translate(point, 50,50,0) )
  end
  
  local polygon_transformed = polygon_rotated_translated
  polygon_transformed.color = polygon.color -- same color
  
  return polygon_transformed
end

degrees = 0.0

function update(dt)
  degrees = (degrees + dt*5000/60 ) % 360
  
  function polygons_transform(polygons)
    local polygons_transformed = {}
    for i,polygon in ipairs(polygons) do
      table.insert(polygons_transformed, polygon_transform(polygon) )
    end
    return polygons_transformed
  end
  
  polygons_transformed = polygons_transform(triangles_original)
  
  local s = 50
  local depth = 10
  local polygon_z2={ -- z=s
    {x=0,y=0,z=depth},
    {x=0,y=s,z=depth},
    {x=s,y=s,z=depth},
    {x=s,y=0,z=depth},
    color={1,1,0},
  }
  
  local polygons_transformed_addon
  polygons_transformed_addon = { polygon_z2, }
  polygons_transformed_addon = convert_polygons_to_triangles(
    polygons_transformed_addon )
  
  -- polygons_transformed_addon = convert_polygons_to_triangles( { polygon_z2 } )

  local polygons_accumulator = polygons_transformed
  for i,polygon in ipairs(polygons_transformed_addon) do
    table.insert(polygons_accumulator,polygon)
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

  --[[
  shaded_color=color*(dot(facing_direction,light_direction))
  i.e. face_color scaled to cos_angle obtained as
  vector dot product of face_normal and to_light vectors
  --]]
  
  if not polygon_iterated.color_diffuse then
    local color = polygon_iterated.color
    
    local face_normal = normal_vector -- not cached
    
    local to_light = vunit({x=-1,y=-1,z=-1})
    
    local cos_angle = vdot(face_normal, to_light)
    cos_angle = unit_clamp(cos_angle)
    
    color = scale3(cos_angle, color)
    
    local ambient_light_intensity = 0.2
    local ambient_light_color = {
      ambient_light_intensity,
      ambient_light_intensity,
      ambient_light_intensity}
    
    color = sum3(color,ambient_light_color)
    color = clamp3(color)
    
    polygon_iterated.color_diffuse = color
  end
end

function perspective(polygon_iterated)
  local vanishing_point = { x=render_width/2, y=render_height/2 }
  
  for i,vertex in ipairs(polygon_iterated) do
    local z_scaling = (-vertex.z+100)/100
    vertex.x = (vertex.x-vanishing_point.x)/z_scaling+vanishing_point.x
    vertex.y = (vertex.y-vanishing_point.y)/z_scaling+vanishing_point.y
  end
end

function draw()
  
  for i,polygon_iterated in ipairs(polygons_to_render) do
    shading(polygon_iterated)
  end
  
  for i,polygon_iterated in ipairs(polygons_to_render) do
    perspective(polygon_iterated)
  end
  
  -- z-buffer
  local depth_buffer={}
  for py=0,render_height do
    local line={}
    for px=0,render_width do
      table.insert(line, px, -math.huge) -- reset value
    end
    table.insert(depth_buffer, py, line)
  end
  
  function inside_polygon(polygon, point)
    local last = polygon[#polygon]
    for i = 1, #polygon do
      local current = polygon[i]
      if side(point, last, current) > 0 then
        return false
      end
      last = current
    end
    return true
  end
  
  for i,polygon_iterated in ipairs(polygons_to_render) do
    
    local x_min = math.huge
    local x_max = -math.huge
    local y_min = math.huge
    local y_max = -math.huge
    for i,point in ipairs(polygon_iterated) do
      if point.x < x_min then x_min=point.x end
      if point.x > x_max then x_max=point.x end
      if point.y < y_min then y_min=point.y end
      if point.y > y_max then y_max=point.y end
    end
    
    x_min=math.max(x_min,0)
    x_max=math.min(x_max,render_width)
    
    y_min=math.max(y_min,0)
    y_max=math.min(y_max,render_height)
    
    x_min=math.floor(x_min)
    x_max=math.floor(x_max)
    y_min=math.floor(y_min)
    y_max=math.floor(y_max)
    
    for py = y_min,y_max do
      for px = x_min,x_max do
        
        local check = false
        ---check = in_convex_polygon(px, py, polygon_iterated)
        check = inside_polygon(polygon_iterated, {x=px, y=py})
        
        if check then
          
          local rgb = polygon_iterated.color_diffuse
          
          local z = polygon_iterated.depth(px,py)
          
          local current_depth = depth_buffer[py][px]
          if z > current_depth then
            
            draw_pixel(rgb, {px,py})
            
            depth_buffer[py][px] = z -- successive depth
          end
        end
        
      end
    end
  end
end