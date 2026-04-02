-- main.lua is for Love2D (https://love2d.org)

-- Love2D: use "local-lua-debugger-vscode" only if launched through "ms-vscode"
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  -- don't use debugging unless launched through "lldebugger" (ms-vscode)
  require("lldebugger").start()
end

---require('common-preceding')

if love == nil then
  -- not using Love2D
  print("USAGE ERROR: run it with Love2D (get it at love2d.org)")
  os.exit(1)
end

local tex_imagedata

function sample_texture(u, v)
  u = u - math.floor(u)
  v = v - math.floor(v)
  local w, h = tex_imagedata:getDimensions()
  local px = math.max(0, math.min(w - 1, math.floor(u * w)))
  local py = math.max(0, math.min(h - 1, math.floor(v * h)))
  local r, g, b = tex_imagedata:getPixel(px, py)
  return { r, g, b }
end

function love.load()
  -- from: http://notebook.kulchenko.com/zerobrane/love2d-debugging
  if arg[#arg] == "-debug" then require("mobdebug").start() end

  love.window.setTitle("[arkenidar/graphic] love .")
  love.window.setMode(300, 300)

  tex_imagedata = love.image.newImageData("assets/checker.bmp")

  pixel_buffer = love.image.newImageData(300, 300)
  pixel_image  = love.graphics.newImage(pixel_buffer)
  pixel_image:setFilter("nearest", "nearest")
end

require('common')

--------------------------------------
-- love2d.org specificities
--------------------------------------

function love.update(dt)
  update(dt)
end

function draw_pixel(rgb, xy)
  local px, py = xy[1], xy[2]
  if px < 0 or px >= 300 or py < 0 or py >= 300 then return end
  pixel_buffer:setPixel(px, py, rgb[1], rgb[2], rgb[3], 1)
end

function love.draw()
  pixel_buffer:mapPixel(function() return 0, 0, 0, 1 end)
  draw()
  pixel_image:replacePixels(pixel_buffer)
  love.graphics.draw(pixel_image, 0, 0)
end
