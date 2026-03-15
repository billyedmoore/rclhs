#ifndef C_WRAP_WRAP_H
#define C_WRAP_WRAP_H
#include "rcl/timer.h"
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

// Pointer owned by Haskell, normally as a StablePtr
// To be considered as a void* in C world and only
// passed into Haskell functions.
typedef void* HsOwnedPtr;

// String -> IO()
typedef HsOwnedPtr (*string_callback_t)(HsOwnedPtr,const char*,bool);

// a -> IO (a)
typedef HsOwnedPtr (*timer_callback_t)(HsOwnedPtr,bool);

// A ROS2 subscriber.
typedef struct {
    rcl_subscription_t subscription;
    // Haskell function String -> IO ()
    string_callback_t callback;
    HsOwnedPtr inital_acc;
} Subscription;

typedef struct {
    rcl_timer_t timer;
    rcl_clock_t clock; 
    timer_callback_t callback;
    HsOwnedPtr inital_acc;
} Timer;

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
                HsOwnedPtr initial_acc,
                string_callback_t callback);

void destroy_subscription(Node* node, Subscription* sub);

void publish(Publisher* pub, const char* msg_content);

Timer* create_timer(Context *context, timer_callback_t callback,
                    uint64_t period, HsOwnedPtr inital_acc);

void destroy_timer(Timer* timer);

Context* create_context();

void shutdown_context(Context* context);

void spin(Context* context,
          void** subs,
          size_t n_subs,
          void** timers,
          size_t n_timers);

#endif
