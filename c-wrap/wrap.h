#ifndef C_WRAP_WRAP_H
#define C_WRAP_WRAP_H
#include "rcl/node.h"
#include "rcl/publisher.h"
#include "rcl/subscription.h"

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


typedef void (*string_callback_t)(const char*);

// A ROS2 subscriber.
typedef struct {
    rcl_subscription_t subscription;
    // Haskell function String -> IO ()
    string_callback_t callback;
} Subscription;

Node* create_node(const char *node_name,
                  const char *namespace,
                  Context *context);

void destroy_node(Node* node);


Publisher* create_publisher(
                Node* node,
                const char* topic);

void destroy_publisher(Node* node, Publisher* pub);

Subscription* create_subscription(
                Node* node,
                const char* topic,
                string_callback_t callback);

void destroy_subscription(Node* node, Subscription* sub);

void publish(Publisher* pub, const char* msg_content);

Context* create_context();

void shutdown_context(Context* context);

#endif
