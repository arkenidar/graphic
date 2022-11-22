function love.load()
  -- from: http://notebook.kulchenko.com/zerobrane/love2d-debugging
  if arg[#arg] == "-debug" then require("mobdebug").start() end
end

dofile('polygon.lua')

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

function polygon_transform(polygon)
  
  local radiants = (degrees/360)*(math.pi*2)
  
  for i,point in ipairs(polygon) do
    point.color = polygon.color
  end
  
  function point_translate(point, x,y,z)
    return {
      x = point.x + x ,
      y = point.y + y ,
      z = point.z + z ,
      color = point.color }
  end
  
  --[[
  function point_rotate(point, radiants)
    return {
      x = math.cos(radiants)*point.x - math.sin(radiants)*point.y ,
      y = math.cos(radiants)*point.y + math.sin(radiants)*point.x }
  end --]]
  
  function point_rotate_axes(axes, point_in, radiants)
    local point_out = {x=point_in.x, y=point_in.y, z=point_in.z, color=point_in.color}
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
    table.insert( polygon_origin, point_translate(point, -50,-50,0) )
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
    table.insert( polygon_rotated_translated, point_translate(point, 150,150,0) )
  end
  
  local polygon_transformed = polygon_rotated_translated
  
  return polygon_transformed
end

degrees = 0.0

function love.update(dt)
  degrees = (degrees + dt*1000/60 ) % 360
  
  function polygons_transform(polygons)
    local polygons_transformed = {}
    for i,polygon in ipairs(polygons) do
      table.insert(polygons_transformed, polygon_transform(polygon) )
    end
    return polygons_transformed
  end
  
  polygons_transformed = polygons_transform(polygons_original)
end

function love.draw()
  
  for px=0,500 do
    for py=0,500 do
      for i,polygon_iterated in ipairs(polygons_transformed) do
        
        local check = false
        check = in_convex_polygon(px, py, polygon_iterated)
        
        if check then
          
          -- color pixel (vertex color, not polygon color!)
          local rgb = polygon_iterated[1].color or {0,1,0} -- default if missing
          love.graphics.setColor( rgb[1], rgb[2], rgb[3], 1 )
          
          -- draw pixel
          love.graphics.rectangle("fill", px,py, 1,1)
        end
        
      end
    end
  end
  
end
