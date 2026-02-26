#ifndef C_WRAP_WRAP_H
#define C_WRAP_WRAP_H
#include "rcl/node.h"
#include "rcl/publisher.h"

// The global context of the ROS2 session.
typedef struct {
    rcl_context_t context;
} Context;

// A ROS2 node.
typedef struct {
    rcl_node_t node;
} Node;

// A ROS2 publisher.
typedef struct {
    rcl_publisher_t publisher;
} Publisher;

Node* create_node(const char *node_name,
                  const char *namespace,
                  Context *context);

void destroy_node(Node* node);


Publisher* create_publisher(
                Node* node,
                const char* topic);

void destroy_publisher(Node* node, Publisher* pub);

void publish(Publisher* pub, const char* msg_content);

Context* create_context();

void shutdown_context(Context* context);

#endif
