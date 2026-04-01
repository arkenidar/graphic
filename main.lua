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

local function create_checker_imagedata(size, sq_count)
  local imagedata = love.image.newImageData(size, size)
  local sq = size / sq_count
  for y = 0, size - 1 do
    for x = 0, size - 1 do
      local is_light = (math.floor(x / sq) + math.floor(y / sq)) % 2 == 0
      if is_light then
        imagedata:setPixel(x, y, 1, 1, 1, 1)
      else
        imagedata:setPixel(x, y, 0, 0, 180 / 255, 1)
      end
    end
  end
  return imagedata
end

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

  tex_imagedata = create_checker_imagedata(128, 8)
end

require('common')

--------------------------------------
-- love2d.org specificities
--------------------------------------

function love.update(dt)
  update(dt)
end

function draw_pixel(rgb, xy)
  love.graphics.setColor(rgb[1], rgb[2], rgb[3], 1)

  -- draw pixel
  local px, py = xy[1], xy[2]
  love.graphics.rectangle("fill", px, py, 1, 1)
end

function love.draw()
  draw()
end
