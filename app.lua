-- from: http://notebook.kulchenko.com/zerobrane/love2d-debugging
---if arg[#arg] == "-debug" then require("mobdebug").start() end
---require("mobdebug").start()

local ffi = require("ffi")
ffi.cdef( io.open('ffi_defs.h','r'):read('*a') )
local SDL = ffi.load('SDL2')

SDL.SDL_Init(0)
local window = SDL.SDL_CreateWindow("title", 50,50, 400,300, 0)
local window_surface = SDL.SDL_GetWindowSurface(window)

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
  SDL.SDL_FillRect(window_surface, rect_from_xywh(xywh), SDL.SDL_MapRGB(window_surface.format,rgb[1],rgb[2],rgb[3]))
end

dofile('polygon.lua')

--draw_pixel = surface_draw_rect
function draw_pixel(rgb,xy)
  rgb[1] = rgb[1]*255
  rgb[2] = rgb[2]*255
  rgb[3] = rgb[3]*255
  surface_draw_rect(rgb,xy)
end

dofile('common.lua')

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

local time_ticks = SDL.SDL_GetTicks()
local event = ffi.new("SDL_Event")
local looping = true
while looping do
  while SDL.SDL_PollEvent(event) ~= 0 do
    if event.type == SDL.SDL_QUIT or
    ( event.type == SDL.SDL_KEYDOWN and event.key.keysym.sym == SDL.SDLK_ESCAPE ) 
    then
        looping = false
    end
  end

  local dt -- elapsed time in fractions of seconds
  delta_ticks = SDL.SDL_GetTicks() - time_ticks
  time_ticks = SDL.SDL_GetTicks()
  dt = delta_ticks / 1000 -- milliseconds to seconds

  update(dt)
  
  --SDL.SDL_FillRect(window_surface,nil,0)
  surface_draw_rect({0,0,0})
  
  surface_draw_rect({0,255,0}, {50,50})
  
  draw()
  
  SDL.SDL_UpdateWindowSurface(window)

end

SDL.SDL_DestroyWindow(window)
SDL.SDL_Quit()
