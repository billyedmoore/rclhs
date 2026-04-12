#ifndef C_WRAP_WRAP_H
#define C_WRAP_WRAP_H
#include "rcl/timer.h"
#include "rcl/node.h"
#include "rcl/publisher.h"
#include "rcl/subscription.h"
#include "rcl/service.h"
#include "rcl/client.h"

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

// callback(request) -> response
typedef HsOwnedPtr (*service_server_callback_t)(HsOwnedPtr);

// callback(response) -> void
typedef void (*service_client_callback_t)(HsOwnedPtr);


// Where possible messages are passed in as fully formed C Structs
// from Haskell.
// In order to do rcl_take the create_message_callback_t's are used.


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

typedef struct {
    rcl_service_t service;
    create_message_callback_t create_req;
    destroy_message_callback_t destroy_req;
    destroy_message_callback_t destroy_res;
    service_server_callback_t callback;
} ServiceServer;

typedef struct {
    rcl_client_t client;
    create_message_callback_t create_res;
    destroy_message_callback_t destroy_res;
} ServiceClient;

ServiceServer* create_service_server(
                Node* node,
                const struct rosidl_service_type_support_t* ts,
                const char* service_name,
                create_message_callback_t create_req_callback,
                destroy_message_callback_t destroy_req_callback,
                destroy_message_callback_t destroy_res_callback,
                service_server_callback_t callback);

void destroy_service_server(Node* node, ServiceServer* srv_server);

ServiceClient* create_service_client(
                Node* node,
                const struct rosidl_service_type_support_t* ts,
                const char* service_name,
                create_message_callback_t create_res_callback,
                destroy_message_callback_t destroy_res_callback);

void destroy_service_client(Node* node, ServiceClient* srv_client);

// Bool is did succesfully callback
bool call_service_server(
        Node* node,
        Context* context, 
        ServiceClient* service_client, 
        HsOwnedPtr req_msg_ptr, 
        service_client_callback_t callback,
        int64_t timeout_ns);


void send_request(ServiceClient* srv_client, HsOwnedPtr req_msg_ptr);

Node* create_node(const char *node_name,
                  const char *namespace,
                  Context *context);

void destroy_node(Node* node);


Publisher* create_publisher(
                Node* node,
                const rosidl_message_type_support_t* ts,
                const char* topic);

void destroy_publisher(Node* node, Publisher* pub);

Subscription* create_subscription(Node* node,
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

/* Spin the ROS2 subscriptions, timers and service_servers
   Either for:
    a) forever when `run_forever` == true
       (the value of `duration` is ignored)
    b) for duration if `run_forever` != true
*/
void spin(Context* context,
          void** v_subs,
          size_t n_subs,
          void** v_timers,
          size_t n_timers,
          void** v_service_servers,
          size_t n_service_servers,
          bool run_forever,
          uint64_t duration);

#endif
