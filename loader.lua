
function load_stl_file(file_path)
  local triangles = {}
  local triangle = {}
  
  local x_min, x_max, y_min, y_max, z_min, z_max
  
  local lines_iterator
  if love then
    lines_iterator = love.filesystem.lines(file_path)
  else
    lines_iterator = io.lines(file_path)
  end
  
  for line in lines_iterator do

    local x,y,z = line:match "vertex (%S+) (%S+) (%S+)"

    if x ~= nil then
      
      local point={ x=tonumber(x), y=tonumber(y), z=tonumber(z) }
      
      -- bounds (bounding box)
      if x_min==nil or point.x < x_min then x_min=point.x end
      if x_max==nil or point.x > x_max then x_max=point.x end
      
      if y_min==nil or point.y < y_min then y_min=point.y end
      if y_max==nil or point.y > y_max then y_max=point.y end
      
      if z_min==nil or point.z < z_min then z_min=point.z end
      if z_max==nil or point.z > z_max then z_max=point.z end
      -- /bounds
      
      table.insert(triangle, point)
      
      if #triangle==3 then
        table.insert(triangles, triangle)
        triangle = {}
      end
    
    end -- /if
  end -- /for
  
  return triangles, {x_min, x_max, y_min, y_max, z_min, z_max}
  
end

function loader_module_test()
  local file_path = "assets/stl-ascii-teapot-axes.stl"
  
  local triangles_original, bounds = load_stl_file(file_path)
  print("bounding box", string.format("x %f %f, y %f %f, z %f %f", unpack(bounds) ) )
end

if not ... then loader_module_test() else
  print('loader_module_test skipped')
end
