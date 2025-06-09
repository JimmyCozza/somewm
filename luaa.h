#ifndef DWL_LUA_H
#define DWL_LUA_H

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <xkbcommon/xkbcommon.h>
#include <stdint.h>
#include <stddef.h>
#include "include/common.h"

// StackInsertMode is now defined in include/common.h

typedef struct {
    uint32_t mod;
    xkb_keysym_t keysym;
    const char *lua_function;
    int press_ref;
    int release_ref;
} LuaKey;

extern LuaKey *lua_keys;
extern size_t num_lua_keys;
extern lua_State *L;

int get_config_bool(const char *key, int default_value);

void init_lua(void);
void cleanup_lua(void);

// Add to existing get_config functions
int get_config_stack_mode(const char *key, enum StackInsertMode default_mode);

// Client access wrapper functions (implemented in dwl.c)
// Note: These use void* to avoid circular dependencies with Client struct
int lua_get_client_count(void);
void *lua_get_focused_client(void);
const char *lua_get_client_title(void *c);
const char *lua_get_client_appid(void *c);
int lua_get_client_pid(void *c);
void lua_get_client_geometry(void *c, int *x, int *y, int *w, int *h);
uint32_t lua_get_client_tags(void *c);
int lua_get_client_floating(void *c);
int lua_get_client_fullscreen(void *c);
void *lua_get_client_by_index(int index);

// Client manipulation wrapper functions (implemented in dwl.c)
void lua_client_focus(void *c);
void lua_client_close(void *c);
void lua_kill_client(void *c);
void lua_client_set_floating(void *c, int floating);
void lua_client_set_fullscreen(void *c, int fullscreen);
void lua_client_set_geometry(void *c, int x, int y, int w, int h);
void lua_client_set_tags(void *c, uint32_t tags);

// Monitor wrapper functions (implemented in dwl.c)
int lua_get_monitor_count(void);
void *lua_get_focused_monitor(void);
void *lua_get_monitor_by_index(int index);
const char *lua_get_monitor_name(void *monitor);
void lua_get_monitor_geometry(void *monitor, int *x, int *y, int *width, int *height);
void lua_get_monitor_workarea(void *monitor, int *x, int *y, int *width, int *height);
const char *lua_get_monitor_layout_symbol(void *monitor);
float lua_get_monitor_master_factor(void *monitor);
int lua_get_monitor_master_count(void *monitor);
uint32_t lua_get_monitor_tags(void *monitor);
int lua_get_monitor_enabled(void *monitor);
void lua_focus_monitor(void *monitor);
void lua_set_monitor_tags(void *monitor, uint32_t tags);
void lua_set_monitor_master_factor(void *monitor, float factor);
void lua_set_monitor_master_count(void *monitor, int count);

// Tag wrapper functions (implemented in dwl.c)
int lua_get_tag_count(void);
uint32_t lua_get_current_tags(void);
uint32_t lua_get_monitor_current_tags(void *monitor);
void lua_set_current_tags(uint32_t tags);
void lua_toggle_tag_view(uint32_t tags);
uint32_t lua_get_occupied_tags(void);
uint32_t lua_get_monitor_occupied_tags(void *monitor);
uint32_t lua_get_urgent_tags(void);

// Event system types and functions
typedef enum {
    LUA_EVENT_CLIENT_MAP = 0,
    LUA_EVENT_CLIENT_UNMAP,
    LUA_EVENT_CLIENT_FOCUS,
    LUA_EVENT_CLIENT_UNFOCUS,
    LUA_EVENT_CLIENT_TITLE_CHANGE,
    LUA_EVENT_CLIENT_FULLSCREEN,
    LUA_EVENT_CLIENT_FLOATING,
    LUA_EVENT_COUNT  // Must be last
} LuaEventType;

// Event callback management
void lua_event_init(void);
void lua_event_cleanup(void);
int lua_event_connect(LuaEventType event_type, int callback_ref);
void lua_event_disconnect(LuaEventType event_type, int callback_ref);
void lua_event_emit(LuaEventType event_type, void *client, void *data);

#endif
