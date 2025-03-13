#ifndef DWL_COMMON_H
#define DWL_COMMON_H

#include <stdint.h>

/* Utility macros */
#define MAX(A, B) ((A) > (B) ? (A) : (B))
#define MIN(A, B) ((A) < (B) ? (A) : (B))
#define LENGTH(X) (sizeof X / sizeof X[0])
#define END(A) ((A) + LENGTH(A))
#define CLEANMASK(mask) (mask & ~WLR_MODIFIER_CAPS)

/* Cursor states */
enum {
    CurNormal,
    CurPressed,
    CurMove,
    CurResize
};

/* Client types */
enum {
    XDGShell,
    LayerShell,
    X11
};

/* Argument union for function parameters */
typedef union {
    int i;
    uint32_t ui;
    float f;
    const void *v;
} Arg;

/* Stack insert modes */
enum StackInsertMode {
    STACK_INSERT_TOP,    // New windows go on top/left 
    STACK_INSERT_BOTTOM  // New windows go on bottom/right
};

#endif /* DWL_COMMON_H */
