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

static int l_log(lua_State *L) {
  const char *level = luaL_checkstring(L, 1);
  const char *message = luaL_checkstring(L, 2);
  
  // Call the Lua logger
  lua_getglobal(L, "logger");
  if (lua_isnil(L, -1)) {
    fprintf(stderr, "Error: logger module not loaded\n");
    lua_pop(L, 1);
    return 0;
  }
  
  lua_getfield(L, -1, level);
  if (lua_isnil(L, -1)) {
    fprintf(stderr, "Error: invalid log level: %s\n", level);
    lua_pop(L, 2);
    return 0;
  }
  
  lua_pushstring(L, message);
  if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
    fprintf(stderr, "Error calling logger.%s: %s\n", level, lua_tostring(L, -1));
    lua_pop(L, 2); // Error and logger table
    return 0;
  }
  
  lua_pop(L, 1); // Pop logger table
  return 0;
}

static int l_draw_widget(lua_State *L) {
  int width = luaL_checkinteger(L, 1);
  int height = luaL_checkinteger(L, 2);
  double x = luaL_checknumber(L, 3);
  double y = luaL_checknumber(L, 4);
  const char *draw_function = luaL_checkstring(L, 5);
  const char *text = lua_isstring(L, 6) ? lua_tostring(L, 6) : "Notification";
  char msg[256];
  
  // Log to the Lua logger
  lua_getglobal(L, "logger");
  if (!lua_isnil(L, -1)) {
    snprintf(msg, sizeof(msg), "C: Draw widget called - size=%dx%d, pos=%.1f,%.1f, drawer=%s", 
             width, height, x, y, draw_function);
    lua_getfield(L, -1, "info");
    lua_pushstring(L, msg);
    if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
      fprintf(stderr, "Error logging widget draw: %s\n", lua_tostring(L, -1));
      lua_pop(L, 1);  // Error message
    }
    lua_pop(L, 1);  // Logger table
  } else {
    fprintf(stderr, "Drawing widget at %f,%f with dimensions %dx%d using %s\n", x, y, width, height, draw_function);
    lua_pop(L, 1);  // nil
  }
  
  // Call the Lua function to draw the widget
  // Push the function name to get the actual function
  lua_getglobal(L, draw_function);
  
  if (lua_isnil(L, -1)) {
    lua_getglobal(L, "logger");
    if (!lua_isnil(L, -1)) {
      snprintf(msg, sizeof(msg), "C: ERROR - Draw function '%s' not found!", draw_function);
      lua_getfield(L, -1, "error");
      lua_pushstring(L, msg);
      lua_pcall(L, 1, 0, 0);
      lua_pop(L, 1);  // Logger table
    } else {
      fprintf(stderr, "ERROR: Draw function '%s' not found!\n", draw_function);
      lua_pop(L, 1);  // nil
    }
    lua_pop(L, 1);  // nil function
    return 1;
  }
  
  // Create a temporary Cairo surface for drawing
  // In a real implementation, this would be integrated with your Wayland compositor
  
  // Pass parameters to the Lua function
  lua_pushinteger(L, width);
  lua_pushinteger(L, height);
  lua_pushnil(L);  // We would pass a real surface pointer here in a full implementation
  lua_pushstring(L, text);
  
  // Call the Lua function (4 arguments, 0 returns)
  if (lua_pcall(L, 4, 0, 0) != LUA_OK) {
    lua_getglobal(L, "logger");
    if (!lua_isnil(L, -1)) {
      snprintf(msg, sizeof(msg), "C: ERROR calling Lua draw function: %s", lua_tostring(L, -2));
      lua_getfield(L, -1, "error");
      lua_pushstring(L, msg);
      lua_pcall(L, 1, 0, 0);
      lua_pop(L, 1);  // Logger table
    } else {
      fprintf(stderr, "Error calling Lua draw function: %s\n", lua_tostring(L, -1));
      lua_pop(L, 1);  // nil
    }
    lua_pop(L, 1);  // Error message
    return 1;
  }
  
  // In a real implementation, we would now add the surface to the Wayland scene
  // at position x,y and make it visible
  lua_getglobal(L, "logger");
  if (!lua_isnil(L, -1)) {
    snprintf(msg, sizeof(msg), "C: Widget '%s' drawing completed successfully", text);
    lua_getfield(L, -1, "info");
    lua_pushstring(L, msg);
    lua_pcall(L, 1, 0, 0);
    lua_pop(L, 1);  // Logger table
  } else {
    fprintf(stderr, "Widget with text '%s' would now be visible at %f,%f\n", text, x, y);
    lua_pop(L, 1);  // nil
  }
  
  return 0;
}

static const struct luaL_Reg somelib[] = {{"hello_world", l_hello_world},
                                          {"spawn", l_spawn},
                                          {"restart", l_restart},
                                          {"quit", l_quit},
                                          {"draw_widget", l_draw_widget},
                                          {"log", l_log},
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
  char msg[256];
  snprintf(msg, sizeof(msg), "Registering binding - mods: %u, keysym: %u", mods, keysym);
  
  // Log the registration
  lua_getglobal(L, "logger");
  if (!lua_isnil(L, -1)) {
    lua_getfield(L, -1, "info");
    lua_pushstring(L, msg);
    lua_pcall(L, 1, 0, 0);
    lua_pop(L, 1); // Pop logger table
  } else {
    fprintf(stderr, "%s\n", msg);
    lua_pop(L, 1); // Pop nil
  }

  int press_ref = LUA_REFNIL;
  int release_ref = LUA_REFNIL;

  if (!lua_isnil(L, 3)) {
    lua_pushvalue(L, 3);
    press_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    
    lua_getglobal(L, "logger");
    if (!lua_isnil(L, -1)) {
      lua_getfield(L, -1, "debug");
      lua_pushstring(L, "Registered press callback");
      lua_pcall(L, 1, 0, 0);
      lua_pop(L, 1); // Pop logger table
    }
  }

  if (!lua_isnil(L, 4)) {
    lua_pushvalue(L, 4);
    release_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    
    lua_getglobal(L, "logger");
    if (!lua_isnil(L, -1)) {
      lua_getfield(L, -1, "debug");
      lua_pushstring(L, "Registered release callback");
      lua_pcall(L, 1, 0, 0);
      lua_pop(L, 1); // Pop logger table
    }
  }

  lua_keys = realloc(lua_keys, (num_lua_keys + 1) * sizeof(LuaKey));
  if (!lua_keys)
    return luaL_error(L, "out of memory");

  lua_keys[num_lua_keys] = (LuaKey){.mod = mods,
                                    .keysym = keysym,
                                    .press_ref = press_ref,
                                    .release_ref = release_ref};
  num_lua_keys++;
  
  snprintf(msg, sizeof(msg), "Binding registered successfully, total bindings: %zu", num_lua_keys);
  lua_getglobal(L, "logger");
  if (!lua_isnil(L, -1)) {
    lua_getfield(L, -1, "info");
    lua_pushstring(L, msg);
    lua_pcall(L, 1, 0, 0);
    lua_pop(L, 1); // Pop logger table
  } else {
    fprintf(stderr, "%s\n", msg);
    lua_pop(L, 1); // Pop nil
  }

  return 0;
}

LuaKey *lua_keys = NULL;
size_t num_lua_keys = 0;

void init_lua(void) {
  const char *lua_path = "./lua/?.lua;./lua/?/init.lua;";
  if (L != NULL) {
    lua_close(L);
  }

  fprintf(stderr, "Initializing Lua environment...\n");
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

  fprintf(stderr, "Loading rc.lua...\n");
  if (luaL_dofile(L, "rc.lua") != LUA_OK) {
    fprintf(stderr, "Error loading rc.lua: %s\n", lua_tostring(L, -1));
    lua_close(L);
    L = NULL;
    return;
  }

  fprintf(stderr, "Lua initialization complete\n");
  
  // Let's log a startup message if the logger is available
  lua_getglobal(L, "logger");
  if (!lua_isnil(L, -1)) {
    lua_getfield(L, -1, "info");
    lua_pushstring(L, "C: Lua environment initialized successfully");
    if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
      fprintf(stderr, "Error logging startup: %s\n", lua_tostring(L, -1));
      lua_pop(L, 1);  // Error message
    }
    lua_pop(L, 1);  // Logger table
  } else {
    lua_pop(L, 1);  // nil
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
