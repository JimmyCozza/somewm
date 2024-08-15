#include "luaa.h"
#include <stdio.h>

static lua_State *L = NULL;

// This is the C function we want to expose to Lua
static int l_hello_world(lua_State *lua) {
  printf("Hello from C!\n");
  return 0; // number of return values
}

// This function registers our C functions to Lua
static void register_lua_functions(lua_State *lua) {
  lua_register(L, "hello_world", l_hello_world);
}

// This function initializes Lua and loads the rc.lua file
void init_lua(void) {
  if (L != NULL) {
    lua_close(L); // Close any existing Lua state
  }
  L = luaL_newstate();
  if (L == NULL) {
    fprintf(stderr, "Failed to create Lua state\n");
    return;
  }
  luaL_openlibs(L);

  register_lua_functions(L);

  if (luaL_dofile(L, "rc.lua") != LUA_OK) {
    fprintf(stderr, "Error loading rc.lua: %s\n", lua_tostring(L, -1));
    lua_close(L);
    L = NULL;
  }
    // Load and run the Lua script
    if (luaL_dofile(L, "basic_drawable.lua") != LUA_OK) {
        fprintf(stderr, "Error loading basic_drawable.lua: %s\n", lua_tostring(L, -1));
        lua_close(L);
        L = NULL;
    }
}

int get_config_bool(const char *key, int default_value) {
  int result;
  if (L == NULL) {
    fprintf(stderr, "Lua not initialized\n");
    return default_value;
  }

  lua_getglobal(L, "general_options");
  if (!lua_istable(L, -1)) {
    fprintf(stderr, "general_options is not a table\n");
    lua_pop(L, 1);
    return default_value;
  }

  lua_getfield(L, -1, key);
  if (!lua_isboolean(L, -1)) {
    fprintf(stderr, "%s is not a boolean\n", key);
    lua_pop(L, 2);
    return default_value;
  }

  result = lua_toboolean(L, -1);
  lua_pop(L, 2);
  return result;
}

// Function to cleanup Lua state
void cleanup_lua(void) {
  if (L != NULL) {
    lua_close(L);
    L = NULL;
  }
}
