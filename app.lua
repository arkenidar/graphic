-- app.lua is for SDL3 ... (https://libsdl.org/)
-- ... via LuaJIT's FFI (https://luajit.org/)

---require('common-preceding')

if type(jit) ~= "table" then
    -- not using LuaJIT
    print("USAGE ERROR: run it with LuaJIT (get it at luajit.org)")
    os.exit(1)
end

-- from: http://notebook.kulchenko.com/zerobrane/love2d-debugging
---if arg[#arg] == "-debug" then require("mobdebug").start() end
---require("mobdebug").start()

local ffi = require("ffi")
-- ffi_defs.h: minimal SDL3 declarations, handwritten for LuaJIT compatibility
ffi.cdef(io.open("ffi_defs.h", "r"):read("*a"))

local function ffi_load_any(...)
    local last_error
    for index = 1, select("#", ...) do
        local library_name = select(index, ...)
        local ok, library_or_error = pcall(ffi.load, library_name)
        if ok then
            return library_or_error
        end
        last_error = library_or_error
    end
    error(last_error)
end

local SDL = ffi_load_any("SDL3", "libSDL3.so.0", "libSDL3.so")

_G =
    setmetatable(
    _G,
    {
        __index = function(self, index) -- index function CASE
            if "SDL" == string.sub(index, 1, 3) then
                return SDL[index]
            end
        end
    }
)

SDL_Init(0)
local window = SDL_CreateWindow("[arkenidar/graphic] luajit app.lua", 300, 300, 0)
local window_surface = SDL_GetWindowSurface(window)

function rect_from_xywh(xywh)
    if xywh == nil then
        return nil
    end
    local rect = ffi.new("SDL_Rect")
    rect.x = xywh[1]
    rect.y = xywh[2]
    rect.w = xywh[3] or 1
    rect.h = xywh[4] or 1
    return rect
end

function surface_draw_rect(rgb, xywh)
    local fmt = SDL_GetPixelFormatDetails(window_surface.format)
    SDL_FillSurfaceRect(window_surface, rect_from_xywh(xywh), SDL_MapRGB(fmt, nil, rgb[1], rgb[2], rgb[3]))
end

local ws_ptr   -- uint8_t* to window_surface pixels
local ws_pitch -- bytes per row
local ws_bpp   -- bytes per pixel
local ws_fmt   -- SDL_PixelFormatDetails*, pre-fetched per frame

function draw_pixel(rgb, xy)
    local px, py = xy[1], xy[2]
    local packed = SDL.SDL_MapRGB(ws_fmt, nil,
        math.min(255, math.floor(rgb[1] * 255)),
        math.min(255, math.floor(rgb[2] * 255)),
        math.min(255, math.floor(rgb[3] * 255)))
    local offset = py * ws_pitch + px * ws_bpp
    if ws_bpp == 4 then
        ffi.cast("uint32_t*", ws_ptr + offset)[0] = packed
    else  -- 3 BPP
        ws_ptr[offset]     = bit.band(packed, 0xff)
        ws_ptr[offset + 1] = bit.band(bit.rshift(packed, 8), 0xff)
        ws_ptr[offset + 2] = bit.band(bit.rshift(packed, 16), 0xff)
    end
end

require("common")

-- Generate a 24-bit checkerboard BMP file (bottom-up rows, no compression)
local function create_checker_bmp(filename, size, sq_count)
    local w, h = size, size
    local row_padded = math.floor((w * 3 + 3) / 4) * 4
    local pixel_data_size = row_padded * h
    local file_size = 54 + pixel_data_size

    local function u32le(n)
        local b0 = n % 256; n = math.floor(n / 256)
        local b1 = n % 256; n = math.floor(n / 256)
        local b2 = n % 256; n = math.floor(n / 256)
        local b3 = n % 256
        return string.char(b0, b1, b2, b3)
    end
    local function u16le(n)
        return string.char(n % 256, math.floor(n / 256) % 256)
    end

    local f = io.open(filename, "wb")
    -- File header (14 bytes)
    f:write("BM")
    f:write(u32le(file_size))
    f:write(u16le(0)); f:write(u16le(0))   -- reserved
    f:write(u32le(54))                      -- pixel data offset
    -- BITMAPINFOHEADER (40 bytes)
    f:write(u32le(40))    -- header size
    f:write(u32le(w))
    f:write(u32le(h))
    f:write(u16le(1))     -- color planes
    f:write(u16le(24))    -- bits per pixel
    f:write(u32le(0))     -- no compression
    f:write(u32le(pixel_data_size))
    f:write(u32le(2835)); f:write(u32le(2835))  -- pixels per meter X/Y
    f:write(u32le(0)); f:write(u32le(0))         -- color table
    -- Pixel data: BMP is bottom-up (y=0 row stored last)
    local sq = size / sq_count
    for y = h - 1, 0, -1 do
        local row = {}
        for x = 0, w - 1 do
            local is_light = (math.floor(x / sq) + math.floor(y / sq)) % 2 == 0
            if is_light then
                row[#row + 1] = string.char(255, 255, 255)  -- BGR white
            else
                row[#row + 1] = string.char(180, 0, 0)       -- BGR dark blue
            end
        end
        local row_str = table.concat(row)
        while #row_str % 4 ~= 0 do row_str = row_str .. "\0" end
        f:write(row_str)
    end
    f:close()
end

create_checker_bmp("assets/checker.bmp", 128, 8)

local tex_surface = SDL_LoadBMP_IO(SDL_IOFromFile("assets/checker.bmp", "rb"), 1)
assert(tex_surface ~= nil, "Failed to load assets/checker.bmp")
local tex_fmt = SDL.SDL_GetPixelFormatDetails(tex_surface.format)

function sample_texture(u, v)
    -- wrap UV into [0, 1)
    u = u - math.floor(u)
    v = v - math.floor(v)
    local px = math.max(0, math.min(tex_surface.w - 1, math.floor(u * tex_surface.w)))
    local py = math.max(0, math.min(tex_surface.h - 1, math.floor(v * tex_surface.h)))
    local pixels = ffi.cast("uint8_t*", tex_surface.pixels)
    local bpp = tex_fmt.bytes_per_pixel
    local offset = py * tex_surface.pitch + px * bpp
    -- pack bytes little-endian into uint32 for SDL_GetRGB
    local pixel = 0
    for i = bpp - 1, 0, -1 do
        pixel = pixel * 256 + pixels[offset + i]
    end
    local r = ffi.new("Uint8[1]")
    local g = ffi.new("Uint8[1]")
    local b = ffi.new("Uint8[1]")
    SDL.SDL_GetRGB(pixel, tex_fmt, nil, r, g, b)
    return { r[0] / 255, g[0] / 255, b[0] / 255 }
end

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
local time_ticks = tonumber(SDL_GetTicks())
local event = ffi.new("SDL_Event")
local looping = true
local frame_count = 0
local fps_timer = tonumber(SDL_GetTicks())
while looping do
    while SDL_PollEvent(event) ~= 0 do
        if event.type == SDL_EVENT_QUIT or (event.type == SDL_EVENT_KEY_DOWN and event.key.key == SDLK_ESCAPE) then
            looping = false
        end
    end

    local dt  -- elapsed time in fractions of seconds
    local now_ticks = tonumber(SDL_GetTicks())
    delta_ticks = now_ticks - time_ticks
    time_ticks = now_ticks
    dt = delta_ticks / 1000 -- milliseconds to seconds

    update(dt)

    --SDL_FillRect(window_surface,nil,0)
    surface_draw_rect({0, 0, 0})

    ws_ptr   = ffi.cast("uint8_t*", window_surface.pixels)
    ws_pitch = window_surface.pitch
    ws_fmt   = SDL.SDL_GetPixelFormatDetails(window_surface.format)
    ws_bpp   = ws_fmt.bytes_per_pixel

    ---surface_draw_rect({0,255,0}, {50,50}) -- test pixel draw

    draw()

    SDL_UpdateWindowSurface(window)

    frame_count = frame_count + 1
    local now = tonumber(SDL_GetTicks())
    if now - fps_timer >= 1000 then
        io.write(string.format("FPS: %d\n", frame_count))
        io.flush()
        frame_count = 0
        fps_timer = now
    end
end

SDL_DestroyWindow(window)
SDL_Quit()
