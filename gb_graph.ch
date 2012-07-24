@x owrk only with string.h
#ifdef SYSV
#include <string.h>
#else
#include <strings.h>
#endif
@y
#include <string.h>
@z

@x change the util type
typedef union {
  struct vertex_struct *V; /* pointer to \&{Vertex} */
  struct arc_struct *A; /* pointer to \&{Arc} */
  struct graph_struct *G; /* pointer to \&{Graph} */
  char *S; /* pointer to string */
  long I; /* integer */
} util;
@y
#define pixel_t short
typedef union {
  struct vertex_struct *V; /* pointer to \&{Vertex} */
  struct arc_struct *A; /* pointer to \&{Arc} */
  struct graph_struct *G; /* pointer to \&{Graph} */
  char *S; /* pointer to string */
  long I; /* integer */
  pixel_t PIX; /* pixel */
} util;
@z
