#ifndef C_WRAP_WRAP_H
#define C_WRAP_WRAP_H
#include "rcl/node.h"

// The global context of the ROS2 session.
typedef struct {
    rcl_context_t context;
} Context;

// An ROS2 node.
typedef struct {
    rcl_node_t node;
} Node;

Node* create_node(const char *node_name,
                  const char *namespace,
                  Context *context);

void destroy_node(Node* node);

Context* create_context();

void shutdown_context(Context* context);

#endif
