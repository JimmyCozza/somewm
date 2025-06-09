#include "luaa.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>
#include <wayland-server-core.h>
// Cairo header will be included when needed

#include "util.h"

lua_State *L = NULL;

// Client reference tracking implementation
static ClientRef *client_refs_head = NULL;

void lua_client_refs_init(void) {
    client_refs_head = NULL;
}

void lua_client_refs_cleanup(void) {
    ClientRef *current = client_refs_head;
    int leaked_refs = 0;
    int leaked_clients = 0;
    
    while (current) {
        ClientRef *next = current->next;
        
        // Log potential leaks
        if (current->ref_count > 0) {
            leaked_refs += current->ref_count;
            leaked_clients++;
            fprintf(stderr, "Warning: Client %p has %d references at cleanup (valid=%s)\n",
                    current->client_ptr, current->ref_count, 
                    current->is_valid ? "yes" : "no");
        }
        
        free(current);
        current = next;
    }
    
    if (leaked_clients > 0) {
        fprintf(stderr, "Memory leak detected: %d clients with %d total references not properly cleaned up\n",
                leaked_clients, leaked_refs);
    }
    
    client_refs_head = NULL;
}

ClientRef *lua_client_ref_add(void *client_ptr) {
    if (!client_ptr) return NULL;
    
    // Check if already exists
    ClientRef *current = client_refs_head;
    while (current) {
        if (current->client_ptr == client_ptr) {
            current->ref_count++;
            return current;
        }
        current = current->next;
    }
    
    // Create new reference
    ClientRef *new_ref = malloc(sizeof(ClientRef));
    if (!new_ref) return NULL;
    
    new_ref->client_ptr = client_ptr;
    new_ref->ref_count = 1;
    new_ref->is_valid = 1;
    new_ref->next = client_refs_head;
    client_refs_head = new_ref;
    
    return new_ref;
}

void lua_client_ref_remove(void *client_ptr) {
    if (!client_ptr) return;
    
    ClientRef *current = client_refs_head;
    while (current) {
        if (current->client_ptr == client_ptr) {
            current->is_valid = 0;  // Mark as invalid, don't remove yet
            return;
        }
        current = current->next;
    }
}

int lua_client_ref_is_valid(void *client_ptr) {
    if (!client_ptr) return 0;
    
    ClientRef *current = client_refs_head;
    while (current) {
        if (current->client_ptr == client_ptr) {
            return current->is_valid;
        }
        current = current->next;
    }
    return 0;  // Not found = invalid
}

void lua_client_ref_increment(void *client_ptr) {
    if (!client_ptr) return;
    
    ClientRef *current = client_refs_head;
    while (current) {
        if (current->client_ptr == client_ptr) {
            current->ref_count++;
            return;
        }
        current = current->next;
    }
    
    // Create new reference if not found
    lua_client_ref_add(client_ptr);
}

void lua_client_ref_decrement(void *client_ptr) {
    if (!client_ptr) return;
    
    ClientRef **current = &client_refs_head;
    while (*current) {
        if ((*current)->client_ptr == client_ptr) {
            (*current)->ref_count--;
            if ((*current)->ref_count <= 0 && !(*current)->is_valid) {
                // Remove from list when no references and invalid
                ClientRef *to_remove = *current;
                *current = (*current)->next;
                free(to_remove);
                return;
            }
            return;
        }
        current = &(*current)->next;
    }
}

// Memory leak detection and debugging functions
void lua_client_refs_debug_print(void) {
    ClientRef *current = client_refs_head;
    int total_clients = 0;
    int total_refs = 0;
    int invalid_clients = 0;
    
    fprintf(stderr, "=== Client Reference Debug Info ===\n");
    
    while (current) {
        total_clients++;
        total_refs += current->ref_count;
        
        if (!current->is_valid) {
            invalid_clients++;
        }
        
        fprintf(stderr, "Client %p: refs=%d, valid=%s\n", 
                current->client_ptr, 
                current->ref_count,
                current->is_valid ? "yes" : "no");
        
        current = current->next;
    }
    
    fprintf(stderr, "Total clients tracked: %d\n", total_clients);
    fprintf(stderr, "Total references: %d\n", total_refs);
    fprintf(stderr, "Invalid clients: %d\n", invalid_clients);
    fprintf(stderr, "=== End Debug Info ===\n");
}

int lua_client_refs_get_count(void) {
    ClientRef *current = client_refs_head;
    int count = 0;
    
    while (current) {
        count++;
        current = current->next;
    }
    
    return count;
}

int lua_client_refs_get_total_refs(void) {
    ClientRef *current = client_refs_head;
    int total_refs = 0;
    
    while (current) {
        total_refs += current->ref_count;
        current = current->next;
    }
    
    return total_refs;
}

// Called from dwl.c when a client is mapped/created
void lua_client_mapped(void *client_ptr) {
    if (!client_ptr) return;
    
    // Ensure client is tracked in reference system
    lua_client_ref_add(client_ptr);
}

// Called from dwl.c when a client is destroyed
void lua_client_destroyed(void *client_ptr) {
    if (!client_ptr) return;
    
    // First emit the unmap event if we haven't already
    lua_event_emit(LUA_EVENT_CLIENT_UNMAP, client_ptr, NULL);
    
    // Mark client as invalid in reference tracking
    lua_client_ref_remove(client_ptr);
}

// Client userdata metatable name
#define CLIENT_USERDATA_METATABLE "SomeWM.Client"

// Garbage collection metamethod for client userdata
static int client_userdata_gc(lua_State *L) {
    ClientUserdata *udata = (ClientUserdata *)lua_touserdata(L, 1);
    if (udata && udata->client_ptr) {
        // Decrement reference count when Lua object is garbage collected
        lua_client_ref_decrement(udata->client_ptr);
    }
    return 0;
}

// Create and push client userdata with garbage collection
void lua_push_client_userdata(lua_State *L, void *client_ptr) {
    if (!client_ptr) {
        lua_pushnil(L);
        return;
    }
    
    // Create userdata
    ClientUserdata *udata = (ClientUserdata *)lua_newuserdata(L, sizeof(ClientUserdata));
    udata->client_ptr = client_ptr;
    
    // Increment reference count
    lua_client_ref_increment(client_ptr);
    
    // Set metatable for garbage collection
    luaL_getmetatable(L, CLIENT_USERDATA_METATABLE);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1);  // pop nil
        // Create metatable if it doesn't exist
        luaL_newmetatable(L, CLIENT_USERDATA_METATABLE);
        lua_pushcfunction(L, client_userdata_gc);
        lua_setfield(L, -2, "__gc");
    }
    lua_setmetatable(L, -2);
}

// Extract client pointer from userdata with validation
void *lua_check_client_userdata(lua_State *L, int index) {
    ClientUserdata *udata = (ClientUserdata *)luaL_checkudata(L, index, CLIENT_USERDATA_METATABLE);
    if (!udata) {
        // Fallback: try to get as light userdata for backward compatibility
        return lua_touserdata(L, index);
    }
    return udata->client_ptr;
}

// Safe client access with error handling
static void *lua_get_safe_client(lua_State *L, int index, const char *function_name) {
    void *client = lua_check_client_userdata(L, index);
    if (!client) {
        return NULL;  // Let caller handle nil
    }
    
    if (!lua_client_ref_is_valid(client)) {
        // Log error but don't crash - return NULL to indicate invalid client
        fprintf(stderr, "Warning: %s called with destroyed client pointer\n", function_name);
        return NULL;
    }
    
    return client;
}

// Event system implementation
#define MAX_CALLBACKS_PER_EVENT 32

typedef struct {
    int callback_refs[MAX_CALLBACKS_PER_EVENT];
    int count;
} EventCallbackList;

static EventCallbackList event_callbacks[LUA_EVENT_COUNT];

void lua_event_init(void) {
    for (int i = 0; i < LUA_EVENT_COUNT; i++) {
        event_callbacks[i].count = 0;
        for (int j = 0; j < MAX_CALLBACKS_PER_EVENT; j++) {
            event_callbacks[i].callback_refs[j] = LUA_REFNIL;
        }
    }
}

void lua_event_cleanup(void) {
    if (!L) return;
    
    for (int i = 0; i < LUA_EVENT_COUNT; i++) {
        for (int j = 0; j < event_callbacks[i].count; j++) {
            if (event_callbacks[i].callback_refs[j] != LUA_REFNIL) {
                luaL_unref(L, LUA_REGISTRYINDEX, event_callbacks[i].callback_refs[j]);
                event_callbacks[i].callback_refs[j] = LUA_REFNIL;
            }
        }
        event_callbacks[i].count = 0;
    }
}

int lua_event_connect(LuaEventType event_type, int callback_ref) {
    if (event_type >= LUA_EVENT_COUNT || event_callbacks[event_type].count >= MAX_CALLBACKS_PER_EVENT) {
        return -1;
    }
    
    int index = event_callbacks[event_type].count;
    event_callbacks[event_type].callback_refs[index] = callback_ref;
    event_callbacks[event_type].count++;
    return index;
}

void lua_event_disconnect(LuaEventType event_type, int callback_ref) {
    if (event_type >= LUA_EVENT_COUNT || !L) return;
    
    EventCallbackList *list = &event_callbacks[event_type];
    for (int i = 0; i < list->count; i++) {
        if (list->callback_refs[i] == callback_ref) {
            luaL_unref(L, LUA_REGISTRYINDEX, callback_ref);
            // Shift remaining callbacks down
            for (int j = i; j < list->count - 1; j++) {
                list->callback_refs[j] = list->callback_refs[j + 1];
            }
            list->callback_refs[list->count - 1] = LUA_REFNIL;
            list->count--;
            break;
        }
    }
}

void lua_event_emit(LuaEventType event_type, void *client, void *data) {
    if (event_type >= LUA_EVENT_COUNT || !L) return;
    
    EventCallbackList *list = &event_callbacks[event_type];
    for (int i = 0; i < list->count; i++) {
        if (list->callback_refs[i] != LUA_REFNIL) {
            // Get the callback function from registry
            lua_rawgeti(L, LUA_REGISTRYINDEX, list->callback_refs[i]);
            
            // Push client as first argument (or nil if no client)
            if (client) {
                lua_push_client_userdata(L, client);
            } else {
                lua_pushnil(L);
            }
            
            // Push event-specific data as second argument (or nil)
            if (data) {
                // For now, we'll pass simple data types
                // This can be expanded later based on event needs
                lua_pushlightuserdata(L, data);
            } else {
                lua_pushnil(L);
            }
            
            // Call the callback function
            if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
                const char *error = lua_tostring(L, -1);
                fprintf(stderr, "Error in event callback: %s\n", error);
                lua_pop(L, 1);
            }
        }
    }
}

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

// Simplified widget-related functions
static int l_create_notification(lua_State *L) {
  const char *text = luaL_checkstring(L, 1);
  int timeout = luaL_optinteger(L, 2, 3);  // Default timeout: 3 seconds
  char msg[256];
  
  // Log the notification creation
  lua_getglobal(L, "logger");
  if (!lua_isnil(L, -1)) {
    snprintf(msg, sizeof(msg), "Creating notification with text: '%s'", text);
    lua_getfield(L, -1, "info");
    lua_pushstring(L, msg);
    lua_pcall(L, 1, 0, 0);
    lua_pop(L, 1);  // Logger table
  } else {
    fprintf(stderr, "Creating notification with text: '%s'\n", text);
    lua_pop(L, 1);  // nil
  }
  
  // In a real implementation, we'd create a notification widget here
  // For now, just print to the console
  fprintf(stderr, "NOTIFICATION: %s (timeout: %d seconds)\n", text, timeout);
  
  // Return success
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
  
  // For now, just call the Lua function to draw the widget
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

// Dummy function for now
static int l_destroy_widget(lua_State *L) {
  fprintf(stderr, "destroy_widget called\n");
  return 0;
}

// Layer surface creation for wibar
static int l_create_layer_surface(lua_State *L) {
  int width = luaL_checkinteger(L, 1);
  int height = luaL_checkinteger(L, 2);
  int x = luaL_optinteger(L, 3, 0);
  int y = luaL_optinteger(L, 4, 0);
  const char *layer_name = luaL_optstring(L, 5, "top");
  int exclusive_zone = luaL_optinteger(L, 6, height);
  const char *anchor = luaL_optstring(L, 7, "top");
  
  // Map layer name to layer enum (will be passed to dwl.c)
  int layer_level = 2; // Default to top layer
  if (strcmp(layer_name, "background") == 0) layer_level = 0;
  else if (strcmp(layer_name, "bottom") == 0) layer_level = 1;
  else if (strcmp(layer_name, "top") == 0) layer_level = 2;
  else if (strcmp(layer_name, "overlay") == 0) layer_level = 3;
  
  // Map anchor string to anchor flags (simplified for now)
  uint32_t anchor_flags = 0;
  if (strstr(anchor, "top")) anchor_flags |= 1;
  if (strstr(anchor, "bottom")) anchor_flags |= 2;
  if (strstr(anchor, "left")) anchor_flags |= 4;
  if (strstr(anchor, "right")) anchor_flags |= 8;
  
  // Log the layer surface creation
  lua_getglobal(L, "logger");
  if (!lua_isnil(L, -1)) {
    char msg[256];
    snprintf(msg, sizeof(msg), "Creating layer surface: %dx%d at (%d,%d), layer=%s, exclusive=%d, anchor=%s", 
             width, height, x, y, layer_name, exclusive_zone, anchor);
    lua_getfield(L, -1, "info");
    lua_pushstring(L, msg);
    lua_pcall(L, 1, 0, 0);
    lua_pop(L, 1);
  } else {
    fprintf(stderr, "Creating layer surface: %dx%d at (%d,%d), layer=%s, exclusive=%d\n", 
            width, height, x, y, layer_name, exclusive_zone);
    lua_pop(L, 1);
  }
  
  // Call the dwl.c wrapper function to create actual layer surface
  void *layer_surface = lua_create_layer_surface(width, height, layer_level, exclusive_zone, anchor_flags);
  
  if (layer_surface) {
    lua_pushlightuserdata(L, layer_surface);
    return 1;
  } else {
    lua_pushnil(L);
    return 1;
  }
}

// Destroy layer surface
static int l_destroy_layer_surface(lua_State *L) {
  void *layer_surface = lua_touserdata(L, 1);
  if (layer_surface) {
    lua_destroy_layer_surface(layer_surface);
    
    lua_getglobal(L, "logger");
    if (!lua_isnil(L, -1)) {
      lua_getfield(L, -1, "info");
      lua_pushstring(L, "Layer surface destroyed");
      lua_pcall(L, 1, 0, 0);
      lua_pop(L, 1);
    } else {
      fprintf(stderr, "Layer surface destroyed\n");
      lua_pop(L, 1);
    }
  }
  return 0;
}

// Client wrapper functions are now declared in luaa.h

// Client API functions
static int l_client_get_all(lua_State *L) {
  int count = lua_get_client_count();
  lua_newtable(L);
  
  for (int i = 0; i < count; i++) {
    void *c = lua_get_client_by_index(i);
    if (c) {
      lua_push_client_userdata(L, c);
      lua_rawseti(L, -2, i + 1);  // Lua arrays are 1-indexed
    }
  }
  
  return 1;
}

static int l_client_get_focused(lua_State *L) {
  void *c = lua_get_focused_client();
  lua_push_client_userdata(L, c);
  return 1;
}

static int l_client_get_title(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, "client_get_title");
  if (!c) {
    lua_pushnil(L);
    return 1;
  }
  
  const char *title = lua_get_client_title(c);
  if (title) {
    lua_pushstring(L, title);
  } else {
    lua_pushnil(L);
  }
  return 1;
}

static int l_client_get_appid(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, "client_get_appid");
  if (!c) {
    lua_pushnil(L);
    return 1;
  }
  
  const char *appid = lua_get_client_appid(c);
  if (appid) {
    lua_pushstring(L, appid);
  } else {
    lua_pushnil(L);
  }
  return 1;
}

static int l_client_get_pid(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, "client_get_pid");
  if (!c) {
    lua_pushnil(L);
    return 1;
  }
  
  int pid = lua_get_client_pid(c);
  if (pid > 0) {
    lua_pushinteger(L, pid);
  } else {
    lua_pushnil(L);
  }
  return 1;
}

static int l_client_kill(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, __func__);
  if (!c) {
    return 0;
  }
  
  lua_kill_client(c);
  return 0;
}

static int l_client_get_geometry(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, __func__);
  if (!c) {
    lua_pushnil(L);
    return 1;
  }
  
  int x, y, w, h;
  lua_get_client_geometry(c, &x, &y, &w, &h);
  
  lua_newtable(L);
  lua_pushinteger(L, x);
  lua_setfield(L, -2, "x");
  lua_pushinteger(L, y);
  lua_setfield(L, -2, "y");
  lua_pushinteger(L, w);
  lua_setfield(L, -2, "width");
  lua_pushinteger(L, h);
  lua_setfield(L, -2, "height");
  
  return 1;
}

static int l_client_get_tags(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, __func__);
  if (!c) {
    lua_pushinteger(L, 0);
    return 1;
  }
  
  uint32_t tags = lua_get_client_tags(c);
  lua_pushinteger(L, tags);
  return 1;
}

static int l_client_get_floating(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, __func__);
  if (!c) {
    lua_pushboolean(L, 0);
    return 1;
  }
  
  int floating = lua_get_client_floating(c);
  lua_pushboolean(L, floating);
  return 1;
}

static int l_client_get_fullscreen(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, __func__);
  if (!c) {
    lua_pushboolean(L, 0);
    return 1;
  }
  
  int fullscreen = lua_get_client_fullscreen(c);
  lua_pushboolean(L, fullscreen);
  return 1;
}

// Client manipulation functions
static int l_client_focus(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, __func__);
  if (!c) {
    return 0;
  }
  
  lua_client_focus(c);
  return 0;
}

static int l_client_close(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, __func__);
  if (!c) {
    return 0;
  }
  
  lua_client_close(c);
  return 0;
}

static int l_client_set_floating(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, __func__);
  if (!c) {
    return 0;
  }
  
  int floating = lua_toboolean(L, 2);
  lua_client_set_floating(c, floating);
  return 0;
}

static int l_client_set_fullscreen(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, __func__);
  if (!c) {
    return 0;
  }
  
  int fullscreen = lua_toboolean(L, 2);
  lua_client_set_fullscreen(c, fullscreen);
  return 0;
}

static int l_client_set_geometry(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, __func__);
  if (!c) {
    return 0;
  }
  
  int x = luaL_checkinteger(L, 2);
  int y = luaL_checkinteger(L, 3);
  int w = luaL_checkinteger(L, 4);
  int h = luaL_checkinteger(L, 5);
  lua_client_set_geometry(c, x, y, w, h);
  return 0;
}

static int l_client_set_tags(lua_State *L) {
  void *c = lua_get_safe_client(L, 1, __func__);
  if (!c) {
    return 0;
  }
  
  uint32_t tags = luaL_checkinteger(L, 2);
  lua_client_set_tags(c, tags);
  return 0;
}

// Event system Lua bridge functions
static int l_client_connect_signal(lua_State *L) {
  const char *signal_name = luaL_checkstring(L, 1);
  luaL_checktype(L, 2, LUA_TFUNCTION);
  
  // Map signal names to event types
  LuaEventType event_type;
  if (strcmp(signal_name, "map") == 0) {
    event_type = LUA_EVENT_CLIENT_MAP;
  } else if (strcmp(signal_name, "unmap") == 0) {
    event_type = LUA_EVENT_CLIENT_UNMAP;
  } else if (strcmp(signal_name, "focus") == 0) {
    event_type = LUA_EVENT_CLIENT_FOCUS;
  } else if (strcmp(signal_name, "unfocus") == 0) {
    event_type = LUA_EVENT_CLIENT_UNFOCUS;
  } else if (strcmp(signal_name, "title_change") == 0) {
    event_type = LUA_EVENT_CLIENT_TITLE_CHANGE;
  } else if (strcmp(signal_name, "fullscreen") == 0) {
    event_type = LUA_EVENT_CLIENT_FULLSCREEN;
  } else if (strcmp(signal_name, "floating") == 0) {
    event_type = LUA_EVENT_CLIENT_FLOATING;
  } else {
    lua_pushstring(L, "Unknown signal name");
    lua_error(L);
    return 0;
  }
  
  // Store the callback function in the registry
  lua_pushvalue(L, 2);  // Copy the function to top of stack
  int callback_ref = luaL_ref(L, LUA_REGISTRYINDEX);
  
  // Connect the callback
  int result = lua_event_connect(event_type, callback_ref);
  if (result < 0) {
    luaL_unref(L, LUA_REGISTRYINDEX, callback_ref);
    lua_pushstring(L, "Failed to connect signal - too many callbacks");
    lua_error(L);
    return 0;
  }
  
  return 0;
}

static int l_client_disconnect_signal(lua_State *L) {
  const char *signal_name = luaL_checkstring(L, 1);
  int callback_ref = luaL_checkinteger(L, 2);
  
  // Map signal names to event types (same as above)
  LuaEventType event_type;
  if (strcmp(signal_name, "map") == 0) {
    event_type = LUA_EVENT_CLIENT_MAP;
  } else if (strcmp(signal_name, "unmap") == 0) {
    event_type = LUA_EVENT_CLIENT_UNMAP;
  } else if (strcmp(signal_name, "focus") == 0) {
    event_type = LUA_EVENT_CLIENT_FOCUS;
  } else if (strcmp(signal_name, "unfocus") == 0) {
    event_type = LUA_EVENT_CLIENT_UNFOCUS;
  } else if (strcmp(signal_name, "title_change") == 0) {
    event_type = LUA_EVENT_CLIENT_TITLE_CHANGE;
  } else if (strcmp(signal_name, "fullscreen") == 0) {
    event_type = LUA_EVENT_CLIENT_FULLSCREEN;
  } else if (strcmp(signal_name, "floating") == 0) {
    event_type = LUA_EVENT_CLIENT_FLOATING;
  } else {
    lua_pushstring(L, "Unknown signal name");
    lua_error(L);
    return 0;
  }
  
  lua_event_disconnect(event_type, callback_ref);
  return 0;
}

// Monitor API bridge functions
static int l_monitor_get_all(lua_State *L) {
  int count = lua_get_monitor_count();
  lua_newtable(L);
  
  for (int i = 0; i < count; i++) {
    void *m = lua_get_monitor_by_index(i);
    if (m) {
      lua_pushlightuserdata(L, m);
      lua_rawseti(L, -2, i + 1);
    }
  }
  
  return 1;
}

static int l_monitor_get_focused(lua_State *L) {
  void *m = lua_get_focused_monitor();
  if (m) {
    lua_pushlightuserdata(L, m);
  } else {
    lua_pushnil(L);
  }
  return 1;
}

static int l_monitor_get_name(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  const char *name = lua_get_monitor_name(m);
  if (name) {
    lua_pushstring(L, name);
  } else {
    lua_pushnil(L);
  }
  return 1;
}

static int l_monitor_get_geometry(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  int x, y, w, h;
  lua_get_monitor_geometry(m, &x, &y, &w, &h);
  
  lua_newtable(L);
  lua_pushinteger(L, x);
  lua_setfield(L, -2, "x");
  lua_pushinteger(L, y);
  lua_setfield(L, -2, "y");
  lua_pushinteger(L, w);
  lua_setfield(L, -2, "width");
  lua_pushinteger(L, h);
  lua_setfield(L, -2, "height");
  
  return 1;
}

static int l_monitor_get_workarea(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  int x, y, w, h;
  lua_get_monitor_workarea(m, &x, &y, &w, &h);
  
  lua_newtable(L);
  lua_pushinteger(L, x);
  lua_setfield(L, -2, "x");
  lua_pushinteger(L, y);
  lua_setfield(L, -2, "y");
  lua_pushinteger(L, w);
  lua_setfield(L, -2, "width");
  lua_pushinteger(L, h);
  lua_setfield(L, -2, "height");
  
  return 1;
}

static int l_monitor_get_layout_symbol(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  const char *symbol = lua_get_monitor_layout_symbol(m);
  if (symbol) {
    lua_pushstring(L, symbol);
  } else {
    lua_pushnil(L);
  }
  return 1;
}

static int l_monitor_get_master_factor(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  float factor = lua_get_monitor_master_factor(m);
  lua_pushnumber(L, factor);
  return 1;
}

static int l_monitor_get_master_count(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  int count = lua_get_monitor_master_count(m);
  lua_pushinteger(L, count);
  return 1;
}

static int l_monitor_get_tags(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  uint32_t tags = lua_get_monitor_tags(m);
  lua_pushinteger(L, tags);
  return 1;
}

static int l_monitor_get_enabled(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  int enabled = lua_get_monitor_enabled(m);
  lua_pushboolean(L, enabled);
  return 1;
}

static int l_monitor_focus(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  lua_focus_monitor(m);
  return 0;
}

static int l_monitor_set_tags(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  uint32_t tags = luaL_checkinteger(L, 2);
  lua_set_monitor_tags(m, tags);
  return 0;
}

static int l_monitor_set_master_factor(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  float factor = luaL_checknumber(L, 2);
  lua_set_monitor_master_factor(m, factor);
  return 0;
}

static int l_monitor_set_master_count(lua_State *L) {
  void *m = lua_touserdata(L, 1);
  int count = luaL_checkinteger(L, 2);
  lua_set_monitor_master_count(m, count);
  return 0;
}

// Tag API bridge functions
static int l_tag_get_count(lua_State *L) {
  int count = lua_get_tag_count();
  lua_pushinteger(L, count);
  return 1;
}

static int l_tag_get_current(lua_State *L) {
  uint32_t tags = lua_get_current_tags();
  lua_pushinteger(L, tags);
  return 1;
}

static int l_tag_set_current(lua_State *L) {
  uint32_t tags = luaL_checkinteger(L, 1);
  lua_set_current_tags(tags);
  return 0;
}

static int l_tag_toggle_view(lua_State *L) {
  uint32_t tags = luaL_checkinteger(L, 1);
  lua_toggle_tag_view(tags);
  return 0;
}

static int l_tag_get_occupied(lua_State *L) {
  uint32_t occupied = lua_get_occupied_tags();
  lua_pushinteger(L, occupied);
  return 1;
}

static int l_tag_get_urgent(lua_State *L) {
  uint32_t urgent = lua_get_urgent_tags();
  lua_pushinteger(L, urgent);
  return 1;
}

// Memory debugging functions for Lua
static int l_client_refs_debug_print(lua_State *L) {
  lua_client_refs_debug_print();
  return 0;
}

static int l_client_refs_get_count(lua_State *L) {
  int count = lua_client_refs_get_count();
  lua_pushinteger(L, count);
  return 1;
}

static int l_client_refs_get_total_refs(lua_State *L) {
  int total_refs = lua_client_refs_get_total_refs();
  lua_pushinteger(L, total_refs);
  return 1;
}

// Force garbage collection for testing
static int l_gc_collect(lua_State *L) {
  lua_gc(L, LUA_GCCOLLECT, 0);
  return 0;
}

static const struct luaL_Reg somelib[] = {{"hello_world", l_hello_world},
                                          {"spawn", l_spawn},
                                          {"restart", l_restart},
                                          {"quit", l_quit},
                                          {"create_notification", l_create_notification},
                                          {"draw_widget", l_draw_widget},
                                          {"destroy_widget", l_destroy_widget},
                                          {"create_widget", l_create_notification},
                                          {"create_layer_surface", l_create_layer_surface},
                                          {"destroy_layer_surface", l_destroy_layer_surface},
                                          {"log", l_log},
                                          {"client_get_all", l_client_get_all},
                                          {"client_get_focused", l_client_get_focused},
                                          {"client_get_title", l_client_get_title},
                                          {"client_get_appid", l_client_get_appid},
                                          {"client_get_pid", l_client_get_pid},
                                          {"client_get_geometry", l_client_get_geometry},
                                          {"client_get_tags", l_client_get_tags},
                                          {"client_get_floating", l_client_get_floating},
                                          {"client_get_fullscreen", l_client_get_fullscreen},
                                          {"client_focus", l_client_focus},
                                          {"client_close", l_client_close},
                                          {"client_kill", l_client_kill},
                                          {"client_set_floating", l_client_set_floating},
                                          {"client_set_fullscreen", l_client_set_fullscreen},
                                          {"client_set_geometry", l_client_set_geometry},
                                          {"client_set_tags", l_client_set_tags},
                                          {"client_connect_signal", l_client_connect_signal},
                                          {"client_disconnect_signal", l_client_disconnect_signal},
                                          // Monitor API
                                          {"monitor_get_all", l_monitor_get_all},
                                          {"monitor_get_focused", l_monitor_get_focused},
                                          {"monitor_get_name", l_monitor_get_name},
                                          {"monitor_get_geometry", l_monitor_get_geometry},
                                          {"monitor_get_workarea", l_monitor_get_workarea},
                                          {"monitor_get_layout_symbol", l_monitor_get_layout_symbol},
                                          {"monitor_get_master_factor", l_monitor_get_master_factor},
                                          {"monitor_get_master_count", l_monitor_get_master_count},
                                          {"monitor_get_tags", l_monitor_get_tags},
                                          {"monitor_get_enabled", l_monitor_get_enabled},
                                          {"monitor_focus", l_monitor_focus},
                                          {"monitor_set_tags", l_monitor_set_tags},
                                          {"monitor_set_master_factor", l_monitor_set_master_factor},
                                          {"monitor_set_master_count", l_monitor_set_master_count},
                                          // Tag API
                                          {"tag_get_count", l_tag_get_count},
                                          {"tag_get_current", l_tag_get_current},
                                          {"tag_set_current", l_tag_set_current},
                                          {"tag_toggle_view", l_tag_toggle_view},
                                          {"tag_get_occupied", l_tag_get_occupied},
                                          {"tag_get_urgent", l_tag_get_urgent},
                                          // Memory debugging functions
                                          {"client_refs_debug_print", l_client_refs_debug_print},
                                          {"client_refs_get_count", l_client_refs_get_count},
                                          {"client_refs_get_total_refs", l_client_refs_get_total_refs},
                                          {"gc_collect", l_gc_collect},
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
    // Cleanup systems before closing Lua state
    lua_event_cleanup();
    lua_client_refs_cleanup();
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

// Forward declarations will be added when needed

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
  
  // Initialize systems
  lua_client_refs_init();
  lua_event_init();

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
  
  // Widget initialization happens on demand

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
