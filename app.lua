
-- app.lua is for SDL2 ... (https://libsdl.org/)
-- ... via LuaJIT's FFI (https://luajit.org/)

require('common-preceding')

if type(jit) ~= 'table' then
  -- not using LuaJIT
  print("USAGE ERROR: run it with LuaJIT (get it at luajit.org)")
  os.exit(1)
end

-- from: http://notebook.kulchenko.com/zerobrane/love2d-debugging
---if arg[#arg] == "-debug" then require("mobdebug").start() end
---require("mobdebug").start()

local ffi = require("ffi")
--[[
https://gist.github.com/creationix/1213280/a97d7051decb2f1d3e8844186bbff49b6442700a
-- Parse the C API header
-- It's generated with:
--
--     echo '#include <SDL.h>' > stub.c
--     gcc -I /usr/include/SDL -E stub.c | grep -v '^#' > ffi_SDL.h
--]]
ffi.cdef( io.open('ffi_defs.h','r'):read('*a') )

local SDL = ffi.load('SDL2')
local SDL_image ----= ffi.load('SDL2_image')

_G=setmetatable(_G, {
	__index = function(self, index) -- index function CASE
    if "SDL"==string.sub(index,1,3) then
      return SDL[index]
    end
    if "IMG"==string.sub(index,1,3) then
      return SDL_image[index]
    end
	end
})

SDL_Init(0)
local window = SDL_CreateWindow("", 50,50, render_width,render_height, 0)
local window_surface = SDL_GetWindowSurface(window)

function rect_from_xywh(xywh)
  if xywh == nil then return nil end
  local rect = ffi.new('SDL_Rect')
  rect.x = xywh[1]
  rect.y = xywh[2]
  rect.w = xywh[3] or 1
  rect.h = xywh[4] or 1
  return rect
end
function surface_draw_rect(rgb, xywh)
  SDL_FillRect(window_surface, rect_from_xywh(xywh), SDL_MapRGB(window_surface.format,rgb[1],rgb[2],rgb[3]))
end

--draw_pixel = surface_draw_rect
function draw_pixel(rgb,xy)
  local rgb255 = {
  rgb[1]*255 ,
  rgb[2]*255 ,
  rgb[3]*255 }
  surface_draw_rect(rgb255,xy)
end

require('common')

--[[
function draw()
  for px=0,500 do
    for py=0,500 do
      --for i,polygon_iterated in ipairs(polygons_transformed) do
        
        local polygon_iterated = {
          {x=0,y=0},
          {x=0,y=50},
          {x=50,y=0},
        }
        
        local check = false
        check = in_convex_polygon(px, py, polygon_iterated)
        if check then
          -- color pixel
          local rgb = {0,255,0}
          -- draw pixel
          draw_pixel(rgb, {px,py})
        end
        
      --end
    end
  end
end

--]]

local time_ticks = SDL_GetTicks()
local event = ffi.new("SDL_Event")
local looping = true
while looping do
  while SDL_PollEvent(event) ~= 0 do
    if event.type == SDL_QUIT or
    ( event.type == SDL_KEYDOWN and event.key.keysym.sym == SDLK_ESCAPE ) 
    then
        looping = false
    end
  end

  local dt -- elapsed time in fractions of seconds
  delta_ticks = SDL_GetTicks() - time_ticks
  time_ticks = SDL_GetTicks()
  dt = delta_ticks / 1000 -- milliseconds to seconds

  update(dt)
  
  --SDL_FillRect(window_surface,nil,0)
  surface_draw_rect({0,0,0})
  
  ---surface_draw_rect({0,255,0}, {50,50}) -- test pixel draw
  
  draw()
  
  SDL_UpdateWindowSurface(window)

end

SDL_DestroyWindow(window)
SDL_Quit()
