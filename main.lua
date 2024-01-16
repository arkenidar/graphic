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

function love.load()
  -- from: http://notebook.kulchenko.com/zerobrane/love2d-debugging
  if arg[#arg] == "-debug" then require("mobdebug").start() end

  love.window.setTitle("[arkenidar/graphic] love .")
  love.window.setMode(300, 300)
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
