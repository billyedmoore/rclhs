#ifndef C_WRAP_WRAP_H
#define C_WRAP_WRAP_H
#include "rcl/node.h"

typedef struct {
    rcl_node_t * node;
} Node;

Node* create_node(const char *node_name,
                  const char *namespace,
                  rcl_context_t *context);

void destroy_node(Node* node);

#endif
