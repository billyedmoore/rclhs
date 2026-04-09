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

typedef HsOwnedPtr (*sub_callback_t)(HsOwnedPtr,HsOwnedPtr,bool);

typedef HsOwnedPtr (*timer_callback_t)(HsOwnedPtr,bool);

typedef HsOwnedPtr (*create_message_callback_t)();

typedef void (*destroy_message_callback_t)(HsOwnedPtr);

// A ROS2 subscriber.
typedef struct {
    rcl_subscription_t subscription;
    create_message_callback_t create_msg;
    destroy_message_callback_t destroy_msg;
    sub_callback_t callback;
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
                const rosidl_message_type_support_t* ts,
                const char* topic);

void destroy_publisher(Node* node, Publisher* pub);

Subscription* create_subscription(
                Node* node,
                const rosidl_message_type_support_t* ts,
                const char* topic,
                HsOwnedPtr initial_acc,
                create_message_callback_t create_msg_callback,
                destroy_message_callback_t destroy_msg_callback,
                sub_callback_t callback);

void destroy_subscription(Node* node, Subscription* sub);

void publish(Publisher* pub, const void* msg_ptr);

Timer* create_timer(Context *context, timer_callback_t callback,
                    uint64_t period, HsOwnedPtr inital_acc);

void destroy_timer(Timer* timer);

Context* create_context();

void shutdown_context(Context* context);

/* Spin the ROS2 subscriptions and timers
   Either for:
    a) forever when `run_forever` == true
       (the value of `duration` is ignored)
    b) for duration if `run_forever` != true
*/
void spin(Context* context,
          void** subs,
          size_t n_subs,
          void** timers,
          size_t n_timers,
          bool run_forever,
          uint64_t duration);

#endif
