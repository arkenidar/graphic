function love.load()
  -- from: http://notebook.kulchenko.com/zerobrane/love2d-debugging
  if arg[#arg] == "-debug" then require("mobdebug").start() end
end

dofile('polygon.lua')

polygon={{x=50,y=50}, {x=50+100,y=50}, {x=40,y=10} }

degrees = 0.0

function love.update(dt)

  degrees = (degrees + dt*1000/60 ) % 360

  local radiants = (degrees/360)*(math.pi*2)
  
  function point_translate(point, x,y)
    return {
      x = point.x+x ,
      y = point.y+y }
  end
  
  function point_rotate(point, radiants)
    return {
      x = math.cos(radiants)*point.x - math.sin(radiants)*point.y ,
      y = math.cos(radiants)*point.y + math.sin(radiants)*point.x }
  end
  
  polygon_origin={}
  for i,point in ipairs(polygon) do
    table.insert( polygon_origin, point_translate(point, -50,-50) )
  end
  
  polygon_rotated={}
  for i,point in ipairs(polygon_origin) do
    table.insert( polygon_rotated, point_rotate(point, radiants) )
  end
  
  polygon_rotated_translated={}
  for i,point in ipairs(polygon_rotated) do
    table.insert( polygon_rotated_translated, point_translate(point, 150,150) )
  end
end

function love.draw()
  
  for px=0,500 do
    for py=0,500 do
      
      local check = false
      check = in_convex_polygon(px, py, polygon_rotated_translated)
      
      if check then
        -- draw pixel
        love.graphics.rectangle("fill", px,py, 1,1)
      end
      
    end
  end
  
end
