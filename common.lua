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
  
  polygons_transformed_addon = {
    polygon_z2,
  }

  local polygons_accumulator = polygons_transformed
  for i,polygon in ipairs(polygons_transformed_addon) do
    table.insert(polygons_accumulator,polygon)
  end
  polygons_to_render = polygons_accumulator
  
end

function draw()
  for py=0,render_height do
    for px=0,render_width do
      for i,polygon_iterated in ipairs(polygons_to_render) do
        
        local check = false
        check = in_convex_polygon(px, py, polygon_iterated)
        
        if check then
          
          if not polygon_iterated.normal then
            polygon_iterated.normal = polygon_normal(polygon_iterated)
          end

          x=px
          y=py
          x1=polygon_iterated[1].x
          y1=polygon_iterated[1].y
          z1=polygon_iterated[1].z
          a=polygon_iterated.normal.x
          b=polygon_iterated.normal.y
          c=polygon_iterated.normal.z
          
          z = -(a*x +b*y -(a*x1 +b*y1 +c*z1) )/c
          
          --[[
          shaded_color=color*(dot(facing_direction,light_direction))
          i.e. face_color scaled to cos_angle obtained as
          vector dot product of face_normal and to_light vectors
          --]]
          
          if not polygon_iterated.color_diffuse then
            local color = polygon_iterated.color
            
            local face_normal = polygon_iterated.normal
            
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
          
          local rgb = polygon_iterated.color_diffuse
          
          if z>0 then
            draw_pixel(rgb, {px,py})
          end
        end
        
      end
    end
  end
end