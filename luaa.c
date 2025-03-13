#include "luaa.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "util.h"

lua_State *L = NULL;

static int l_hello_world(lua_State *lua) {
  printf("Hello, world!\n");
  return 0;
}

static int l_restart(lua_State *lua) {
  printf("Restarting...\n");
  return 0;
}

static int l_quit(lua_State *lua) {
  printf("Quitting...\n");
  return 0;
}

// static int l_spawn(lua_State *lua) {
//   char *args[64];
//   const char *command = luaL_checkstring(L, 1);
//   char *cmd = strdup(command);
//   pid_t pid = fork();
//   fprintf(stderr, "C: Spawning command: %s\n", command);
//   if (pid == 0) {
//     dup2(STDERR_FILENO, STDOUT_FILENO);
//     setsid();
//
//     int i = 0;
//     args[i] = strtok(cmd, " ");
//     while (args[i] != NULL && i < 63) {
//       args[++i] = strtok(NULL, " ");
//     }
//     args[i] = NULL;
//
//     execvp(args[0], args);
//     fprintf(stderr, "dwl: execvp %s failed\n", args[0]);
//     exit(1);
//   } else if (pid < 0) {
//     lua_pushstring(L, "Failed to fork");
//     lua_error(L);
//     die("you yourself admit it yourself, that you suck");
//   }
//   return 0;
// }
static int l_spawn(lua_State *lua) {
  const char *command = luaL_checkstring(L, 1);
  pid_t pid = fork();

  if (pid == 0) {
    setsid();
    execl("/bin/sh", "sh", "-c", command, NULL);
    fprintf(stderr, "dwl: execl %s failed\n", command);
    exit(1);
  } else if (pid < 0) {
    lua_pushstring(L, "Failed to fork");
    lua_error(L);
    return 1;
  }

  return 0;
}

static int l_get_keysym(lua_State *L) {
  const char *key_name = luaL_checkstring(L, 1);
  xkb_keysym_t sym = xkb_keysym_from_name(key_name, XKB_KEYSYM_NO_FLAGS);
  lua_pushinteger(L, sym);
  return 1;
}

static int l_draw_widget(lua_State *L) {
  int width = luaL_checkinteger(L, 1);
  int height = luaL_checkinteger(L, 2);
  double x = luaL_checknumber(L, 3);
  double y = luaL_checknumber(L, 4);
  const char *draw_function = luaL_checkstring(L, 5);
  const char *text = lua_isstring(L, 6) ? lua_tostring(L, 6) : "Notification";
  
  // This is a simplified version that demonstrates the concept
  // In a real implementation, you would create a actual surface and render it to the Wayland scene
  fprintf(stderr, "Drawing widget at %f,%f with dimensions %dx%d using %s\n", x, y, width, height, draw_function);
  
  // Call the Lua function to draw the widget
  // Push the function name to get the actual function
  lua_getglobal(L, draw_function);
  
  // Create a temporary Cairo surface for drawing
  // In a real implementation, this would be integrated with your Wayland compositor
  
  // Pass parameters to the Lua function
  lua_pushinteger(L, width);
  lua_pushinteger(L, height);
  lua_pushnil(L);  // We would pass a real surface pointer here in a full implementation
  lua_pushstring(L, text);
  
  // Call the Lua function (4 arguments, 0 returns)
  if (lua_pcall(L, 4, 0, 0) != LUA_OK) {
    const char *error = lua_tostring(L, -1);
    fprintf(stderr, "Error calling Lua draw function: %s\n", error);
    lua_pop(L, 1);
    return 1;
  }
  
  // In a real implementation, we would now add the surface to the Wayland scene
  // at position x,y and make it visible
  fprintf(stderr, "Widget with text '%s' would now be visible at %f,%f\n", text, x, y);
  
  return 0;
}

static const struct luaL_Reg somelib[] = {{"hello_world", l_hello_world},
                                          {"spawn", l_spawn},
                                          {"restart", l_restart},
                                          {"quit", l_quit},
                                          {"draw_widget", l_draw_widget},
                                          {NULL, NULL}};

static int luaopen_some(lua_State *lua) {
  luaL_newlib(L, somelib);
  return 1;
}

static void register_libraries(lua_State *lua) {
  luaL_openlibs(L);
  luaL_requiref(L, "Some", luaopen_some, 1);
}

static int set_lua_path(lua_State *L, const char *path) {
  char lua_path_command[512];

  lua_getglobal(L, "package");
  lua_getfield(L, -1, "path");
  const char *current_path = lua_tostring(L, -1);

  snprintf(lua_path_command, sizeof(lua_path_command), "package.path = '%s%s'",
           path, current_path);

  if (luaL_loadstring(L, lua_path_command) || lua_pcall(L, 0, 0, 0)) {
    fprintf(stderr, "Error setting Lua path: %s\n", lua_tostring(L, -1));
    lua_pop(L, 1);
    lua_pop(L, 1);
    lua_pop(L, 1);
    return 1;
  }
  lua_pop(L, 1);
  lua_pop(L, 1);
  return 0;
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

void cleanup_lua(void) {
  if (L != NULL) {
    lua_close(L);
    L = NULL;
  }
}

static int l_register_key_binding(lua_State *L) {
  uint32_t mods = lua_tointeger(L, 1);
  xkb_keysym_t keysym = lua_tointeger(L, 2);
  fprintf(stderr, "C: Registering binding - mods: %u, keysym: %u\n", mods,
          keysym);

  int press_ref = LUA_REFNIL;
  int release_ref = LUA_REFNIL;

  if (!lua_isnil(L, 3)) {
    lua_pushvalue(L, 3);
    press_ref = luaL_ref(L, LUA_REGISTRYINDEX);
  }

  if (!lua_isnil(L, 4)) {
    lua_pushvalue(L, 4);
    release_ref = luaL_ref(L, LUA_REGISTRYINDEX);
  }

  lua_keys = realloc(lua_keys, (num_lua_keys + 1) * sizeof(LuaKey));
  if (!lua_keys)
    return luaL_error(L, "out of memory");

  lua_keys[num_lua_keys] = (LuaKey){.mod = mods,
                                    .keysym = keysym,
                                    .press_ref = press_ref,
                                    .release_ref = release_ref};
  num_lua_keys++;

  return 0;
}

LuaKey *lua_keys = NULL;
size_t num_lua_keys = 0;

void init_lua(void) {
  const char *lua_path = "./lua/?.lua;./lua/?/init.lua;";
  if (L != NULL) {
    lua_close(L);
  }

  L = luaL_newstate();
  if (L == NULL) {
    fprintf(stderr, "Failed to create Lua state\n");
    return;
  }

  luaL_openlibs(L);

  if (set_lua_path(L, lua_path)) {
    fprintf(stderr, "Failed to set lua path, exiting\n");
    lua_close(L);
    L = NULL;
    return;
  }

  register_libraries(L);
  // TODO: Instead of setting these functions globally, let's register a "core"
  // or "root" library so we can easily tell from lualand which functions are
  // defined in C and which ones are defined in Lua
  lua_pushcfunction(L, l_register_key_binding);
  lua_setglobal(L, "register_key_binding");
  lua_pushcfunction(L, l_get_keysym);
  lua_setglobal(L, "get_keysym_native");

  if (luaL_dofile(L, "rc.lua") != LUA_OK) {
    fprintf(stderr, "Error loading rc.lua: %s\n", lua_tostring(L, -1));
    lua_close(L);
    L = NULL;
    return;
  }
}

int get_config_stack_mode(const char *key, enum StackInsertMode default_mode) {
  if (L == NULL) {
    return default_mode;
  }

  lua_getglobal(L, "general_options");
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1);
    return default_mode;
  }

  lua_getfield(L, -1, key);
  if (!lua_isstring(L, -1)) {
    lua_pop(L, 2);
    return default_mode;
  }

  const char *mode = lua_tostring(L, -1);
  enum StackInsertMode result = default_mode;

  if (strcmp(mode, "top") == 0) {
    result = STACK_INSERT_TOP;
  } else if (strcmp(mode, "bottom") == 0) {
    result = STACK_INSERT_BOTTOM;
  }

  lua_pop(L, 2);
  return result;
}

static void validate_stack_mode(const char *mode) {
  if (strcmp(mode, "top") != 0 && strcmp(mode, "bottom") != 0) {
    fprintf(
        stderr,
        "Warning: Invalid stack_insert_mode '%s'. Using default 'bottom'.\n",
        mode);
  }
}
