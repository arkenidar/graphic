
-- main.lua is for Love2D (http://love2d.org)

require('common-preceding')

function love.load()
  -- from: http://notebook.kulchenko.com/zerobrane/love2d-debugging
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
  love.window.setTitle("")
  love.window.setMode(800,600)
  
end

require('polygon')

require('common')

--------------------------------------
-- love2d.org specificities
--------------------------------------

function love.update(dt)
  update(dt)
end

function draw_pixel(rgb, xy)
  love.graphics.setColor( rgb[1], rgb[2], rgb[3], 1 )

  -- draw pixel
  local px, py = xy[1], xy[2]
  love.graphics.rectangle("fill", px,py, 1,1)
end

function love.draw()
  draw()
end
