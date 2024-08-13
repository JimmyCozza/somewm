#ifndef DWL_LUA_H
#define DWL_LUA_H

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

// Function to initialize Lua and load rc.lua
void init_lua(void);

// Add any other function declarations here that you want to expose to dwl.c

#endif // DWL_LUA_H
