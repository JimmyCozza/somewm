#include "luaa.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "util.h"

static lua_State *L = NULL;

static int l_hello_world(lua_State *lua) {
  printf("Hello, world!\n");
  return 0;
}

// SOMEWM Library Functions
//  Implementation of the 'some' library functions
static int l_restart(lua_State *lua) {
  printf("Restarting...\n");
  // Add your restart logic here
  return 0;
}

static int l_quit(lua_State *lua) {
  printf("Quitting...\n");
  // Add your quit logic here
  return 0;
}

static int l_spawn(lua_State *lua) {
  const char *command = luaL_checkstring(L, 1);
  pid_t pid = fork();
  if (pid == 0) {
    // Child process
    dup2(STDERR_FILENO, STDOUT_FILENO);
    setsid();

    // Split the command into arguments
    char *args[64]; // Adjust size as needed
    char *cmd = strdup(command);
    int i = 0;
    args[i] = strtok(cmd, " ");
    while (args[i] != NULL && i < 63) {
      args[++i] = strtok(NULL, " ");
    }
    args[i] = NULL;

    execvp(args[0], args);
    fprintf(stderr, "dwl: execvp %s failed\n", args[0]);
    exit(1);
  } else if (pid < 0) {
    // Fork failed
    lua_pushstring(L, "Failed to fork");
    lua_error(L);
    die("you yourself admit it yourself, that you suck");
  }
  return 0;
}

static const struct luaL_Reg somelib[] = {
    {"hello_world", l_hello_world},
    {"restart", l_restart},
    {"quit", l_quit},
    {NULL, NULL} // sentinel
};

// Awful library functions
// Kill Client Function
static int l_killclient(lua_State *lua) {
  // killclient(0);
  return 0;
}

static const struct luaL_Reg awfullib[] = {
    {"spawn", l_spawn}, {"killclient", l_killclient}, {NULL, NULL}};

// Function to register the some library
static int luaopen_some(lua_State *lua) {
  luaL_newlib(L, somelib);
  return 1;
}

// Function to register the some library
static int luaopen_awful(lua_State *lua) {
  luaL_newlib(L, awfullib);
  return 1;
}

static void register_libraries(lua_State *lua) {
  luaL_openlibs(L);
  luaL_requiref(L, "some", luaopen_some, 1);
  luaL_requiref(L, "awful", luaopen_awful, 1);
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

  // luaL_openlibs(L);
  // luaL_requiref(L, "some", luaopen_some, 1);
  register_libraries(L);
  lua_pop(L, 1); // remove the module from the stack (we don't need it anymore)
  // register_lua_functions(L);

  if (luaL_dofile(L, "rc.lua") != LUA_OK) {
    fprintf(stderr, "Error loading rc.lua: %s\n", lua_tostring(L, -1));
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
