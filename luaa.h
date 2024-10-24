#ifndef DWL_LUA_H
#define DWL_LUA_H

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

// Function to initialize Lua and load rc.lua
void init_lua(void);

// Add any other function declarations here that you want to expose to dwl.c
int get_config_bool(const char *key, int default_value);

// Function to cleanup Lua state
void cleanup_lua(void);
#endif // DWL_LUA_H
