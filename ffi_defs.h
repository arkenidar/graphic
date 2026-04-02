/* ffi_defs.h — minimal SDL3 declarations for LuaJIT FFI
   Handwritten for LuaJIT compatibility (no GCC extensions, no macros).
   Covers exactly the SDL3 API surface used by app.lua. */

typedef unsigned char      Uint8;
typedef unsigned short     Uint16;
typedef unsigned int       Uint32;
typedef unsigned long long Uint64;
typedef signed int         Sint32;

/* SDL_PixelFormat is an enum in SDL3; treat as int for FFI. */
typedef int SDL_PixelFormat;

typedef Uint32 SDL_SurfaceFlags;
typedef Uint64 SDL_WindowFlags;
typedef Uint32 SDL_WindowID;
typedef Uint32 SDL_KeyboardID;
typedef Sint32 SDL_Keycode;
typedef int    SDL_Scancode;
typedef Uint16 SDL_Keymod;

typedef struct SDL_PixelFormatDetails {
    SDL_PixelFormat format;
    Uint8  bits_per_pixel;
    Uint8  bytes_per_pixel;
    Uint8  padding[2];
    Uint32 Rmask;
    Uint32 Gmask;
    Uint32 Bmask;
    Uint32 Amask;
    Uint8  Rbits;
    Uint8  Gbits;
    Uint8  Bbits;
    Uint8  Abits;
    Uint8  Rshift;
    Uint8  Gshift;
    Uint8  Bshift;
    Uint8  Ashift;
} SDL_PixelFormatDetails;

typedef struct SDL_Palette {
    int   ncolors;
    void *colors;
    int   version;
    int   refcount;
} SDL_Palette;

typedef struct SDL_Surface {
    SDL_SurfaceFlags flags;
    SDL_PixelFormat  format;   /* enum value, not pointer */
    int   w;
    int   h;
    int   pitch;
    void *pixels;
    int   refcount;
    void *reserved;
} SDL_Surface;

typedef struct SDL_Rect { int x, y, w, h; } SDL_Rect;

typedef struct SDL_Window   SDL_Window;
typedef struct SDL_IOStream SDL_IOStream;

typedef struct SDL_CommonEvent {
    Uint32 type;
    Uint32 reserved;
    Uint64 timestamp;   /* nanoseconds */
} SDL_CommonEvent;

typedef struct SDL_KeyboardEvent {
    Uint32       type;
    Uint32       reserved;
    Uint64       timestamp;   /* nanoseconds */
    Uint32       windowID;
    Uint32       which;
    SDL_Scancode scancode;
    SDL_Keycode  key;         /* event.key.key — no keysym nesting in SDL3 */
    Uint16       mod;
    Uint16       raw;
    Uint8        down;
    Uint8        is_repeat;   /* named is_repeat to avoid Lua keyword 'repeat' */
} SDL_KeyboardEvent;

typedef union SDL_Event {
    Uint32            type;
    SDL_CommonEvent   common;
    SDL_KeyboardEvent key;
    Uint8             padding[128];
} SDL_Event;

enum {
    SDL_EVENT_QUIT     = 0x100,
    SDL_EVENT_KEY_DOWN = 0x300,
    SDL_EVENT_KEY_UP   = 0x301,
    SDLK_ESCAPE        = 0x1b
};

int          SDL_Init(Uint32 flags);
SDL_Window  *SDL_CreateWindow(const char *title, int w, int h, Uint64 flags);
SDL_Surface *SDL_GetWindowSurface(SDL_Window *window);
int          SDL_FillSurfaceRect(SDL_Surface *dst, const SDL_Rect *rect, Uint32 color);
const SDL_PixelFormatDetails *SDL_GetPixelFormatDetails(SDL_PixelFormat format);
Uint32       SDL_MapRGB(const SDL_PixelFormatDetails *format, const SDL_Palette *palette, Uint8 r, Uint8 g, Uint8 b);
void         SDL_GetRGB(Uint32 pixel, const SDL_PixelFormatDetails *format, const SDL_Palette *palette, Uint8 *r, Uint8 *g, Uint8 *b);
SDL_IOStream *SDL_IOFromFile(const char *file, const char *mode);
SDL_Surface  *SDL_LoadBMP_IO(SDL_IOStream *src, int closeio);
Uint64       SDL_GetTicks(void);
int          SDL_PollEvent(SDL_Event *event);
int          SDL_UpdateWindowSurface(SDL_Window *window);
void         SDL_DestroyWindow(SDL_Window *window);
void         SDL_Quit(void);
