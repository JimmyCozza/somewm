#include "luaa.h"
#include <stdio.h>

// This is the C function we want to expose to Lua
static int l_hello_world(lua_State *L) {
    printf("Hello from C!\n");
    return 0;  // number of return values
}

// This function registers our C functions to Lua
static void register_lua_functions(lua_State *L) {
    lua_register(L, "hello_world", l_hello_world);
}

// This function initializes Lua and loads the rc.lua file
void init_lua(void) {
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    
    register_lua_functions(L);
    
    if (luaL_dofile(L, "rc.lua") != LUA_OK) {
        fprintf(stderr, "Error loading rc.lua: %s\n", lua_tostring(L, -1));
    }
    
    lua_close(L);
}
