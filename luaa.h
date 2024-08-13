#ifndef DWL_LUA_H
#define DWL_LUA_H

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <xkbcommon/xkbcommon.h>
#include <stdint.h>
#include <stddef.h>

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
#endif
