#include "wrap.h"
#include "rcl/allocator.h"
#include "rcl/context.h"
#include "rcl/init.h"
#include "rcl/init_options.h"
#include "rcl/node.h"
#include "rcl/publisher.h"
#include "rcl/subscription.h"
#include "rcl/time.h"
#include "rcl/timer.h"
#include "rcl/types.h"
#include "rcl/wait.h"
#include "rcl/graph.h"
#include <unistd.h>
#include <stdio.h>
#include <rcutils/error_handling.h>
#include <rcutils/time.h>
#include <rosidl_runtime_c/message_type_support_struct.h>
#include <rosidl_runtime_c/string_functions.h>
#include <std_msgs/msg/string.h>
#include "RclHs_stub.h"

/*
 * Init ROS and return the new Context.
 *
 * Lifecycle of a context can be seen:
 *  https://docs.ros.org/en/rolling/p/rcl/generated/structrcl__context__s.html
*/
Context* create_context(){
    rcl_ret_t return_code = RCL_RET_OK;

    rcl_context_t rcl_context = rcl_get_zero_initialized_context();
    Context *context  = malloc(sizeof(Context));
    context->context = rcl_context;

    rcl_allocator_t allocator = rcl_get_default_allocator();
    rcl_init_options_t init_options = rcl_get_zero_initialized_init_options();
    return_code = rcl_init_options_init(&init_options, allocator);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to init init options ERR - %s.\n",
                rcutils_get_error_string().str);
        free(context);
        return NULL; 
    }

    // Argc and Argv not passed for now
    return_code = rcl_init(0, NULL, &init_options, &context->context);

    if (return_code != RCL_RET_OK){
        return_code = rcl_init_options_fini(&init_options);
        if (return_code != RCL_RET_OK){
            fprintf(stderr,"[C] Failed to finalize init options ERR - %s.\n",
                rcutils_get_error_string().str);
        }
        free(context);
        return NULL;
    }

    return_code = rcl_init_options_fini(&init_options);

    if (return_code != RCL_RET_OK){
        shutdown_context(context);
        return NULL; 
    }

    return context;
}

/*
 * Shutdown ROS and destroy the Context.
 */
void shutdown_context(Context* context){
    rcl_ret_t return_code = RCL_RET_OK;

    return_code = rcl_shutdown(&context->context);
    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to shutdown ERR - %s.\n",
            rcutils_get_error_string().str);
    }
    return_code = rcl_context_fini(&context->context);
    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to finalize context ERR - %s.\n",
            rcutils_get_error_string().str);
    }

    free(context);
}

Node* create_node(const char *node_name,
                  const char *namespace,
                  Context *context){
    rcl_ret_t return_code = RCL_RET_OK;

    Node *node = malloc(sizeof(Node));
    node->node =  rcl_get_zero_initialized_node();
    rcl_node_options_t node_opt = rcl_node_get_default_options();
    return_code = rcl_node_init(&node->node,node_name,namespace,&context->context,&node_opt);


    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to init node (name - \"%s\", namespace - \"%s\") ERR - %s.\n",
                node_name,namespace,rcutils_get_error_string().str);
        destroy_node(node);
        return NULL;
    }
    
    fprintf(stderr,"[C] Successfully created node.\n");

    return node;
}

void destroy_node(Node* node){
    rcl_ret_t return_code = RCL_RET_OK;
    return_code = rcl_node_fini(&node->node);
    free(node);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to destroy node, ERR - %s.\n",rcutils_get_error_string().str);
    }
    else {
        fprintf(stderr,"[C] Successfully destroyed node.\n");
    }

}

Publisher* create_publisher(
                Node* node,
                const rosidl_message_type_support_t* ts,
                const char* topic){
    rcl_ret_t return_code = RCL_RET_OK;
    Publisher *pub  = malloc(sizeof(Publisher));
    pub->publisher = rcl_get_zero_initialized_publisher();


    rcl_publisher_options_t pub_options = rcl_publisher_get_default_options();
    return_code = rcl_publisher_init(&pub->publisher, &node->node, ts, topic, &pub_options);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to init publisher, ERR - %s.\n",rcutils_get_error_string().str);
        destroy_publisher(node, pub);
        return NULL;
    }

    fprintf(stderr,"[C] Successfully created publisher.\n");

    return pub;
}

void destroy_publisher(Node* node, Publisher* pub){
    rcl_ret_t return_code = RCL_RET_OK;

    // Does NOT fini the node just the publisher
    return_code = rcl_publisher_fini(&pub->publisher,&node->node);

    free(pub);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to destroy publisher, ERR - %s.\n",rcutils_get_error_string().str);
    }
    else {
        fprintf(stderr,"[C] Successfully destroyed publisher.\n");
    }
}

Subscription* create_subscription(
                Node* node,
                const rosidl_message_type_support_t* ts,
                const char* topic,
                HsOwnedPtr initial_acc,
                create_message_callback_t create_msg_callback,
                destroy_message_callback_t destroy_msg_callback,
                sub_callback_t callback){
    rcl_ret_t return_code = RCL_RET_OK;
    Subscription *sub  = malloc(sizeof(Subscription));

    sub->create_msg = create_msg_callback;
    sub->destroy_msg = destroy_msg_callback;
    sub->subscription = rcl_get_zero_initialized_subscription();
    sub->inital_acc = initial_acc;

    rcl_subscription_options_t sub_options = rcl_subscription_get_default_options();

    return_code = rcl_subscription_init(&sub->subscription, &node->node, ts, topic, &sub_options);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to init subscription, ERR - %s.\n",rcutils_get_error_string().str);
        destroy_subscription(node, sub);
        return NULL;
    }

    sub->callback = callback;

    fprintf(stderr,"[C] Successfully created subscription.\n");
    
    return sub;
}

void destroy_subscription(Node* node, Subscription* sub){
    rcl_ret_t return_code = RCL_RET_OK;

    // Does NOT fini the node just the sub
    return_code = rcl_subscription_fini(&sub->subscription, &node->node);

    free(sub);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to destroy subscription, ERR - %s.\n",rcutils_get_error_string().str);
    }
    else {
        fprintf(stderr,"[C] Successfully destroyed subscription.\n");
    }
}


// Timer callback is not directly used so this is a nop placeholder. 
void nop_timer_callback(rcl_timer_t * timer, long last_call_time) {
    // shh the compiler
    (void)timer;
    (void)last_call_time;
}

Timer* create_timer(Context *context,
                    timer_callback_t callback,
                    uint64_t period, // nanoseconds
                    HsOwnedPtr inital_acc
                    ){
    rcl_ret_t return_code = RCL_RET_OK;

    rcl_allocator_t allocator = rcl_get_default_allocator();

    Timer *timer = malloc(sizeof(Timer));

    rcl_ret_t rc = rcl_clock_init(RCL_SYSTEM_TIME, &timer->clock, &allocator);

    timer->timer =  rcl_get_zero_initialized_timer();
    timer->callback = callback;
    timer->inital_acc = inital_acc;
    rcl_node_options_t node_opt = rcl_node_get_default_options();
    return_code = rcl_timer_init2(&timer->timer,
                    &timer->clock,
                    &context->context,
                    period,
                    nop_timer_callback,
                    allocator,
                    true);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to init timer ERR - %s.\n",
                rcutils_get_error_string().str);
        destroy_timer(timer);
        return NULL;
    }
    
    fprintf(stderr,"[C] Successfully created timer.\n");

    return timer;
}

void destroy_timer(Timer* timer){
    rcl_ret_t return_code = RCL_RET_OK;

    return_code = rcl_timer_fini(&timer->timer);

    free(timer);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to destroy timer, ERR - %s.\n",rcutils_get_error_string().str);
    }
    else {
        fprintf(stderr,"[C] Successfully destroyed timer.\n");
    }
    
}


// Publish a message (fire and forget)
void publish(Publisher* pub, const void* msg_ptr){
    rcl_ret_t return_code = RCL_RET_OK;

    return_code = rcl_publish(&pub->publisher,msg_ptr,NULL);
    
    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to publish to \"%s\", ERR - %s.\n",
                rcl_publisher_get_topic_name(&pub->publisher),
                rcutils_get_error_string().str);
    } else {
        fprintf(stderr,"[C] Successfully published to \"%s\"\n",
                rcl_publisher_get_topic_name(&pub->publisher));
    }
}

ServiceServer* create_service_server(
                Node* node,
                const struct rosidl_service_type_support_t* ts,
                const char* service_name,
                create_message_callback_t create_req_callback,
                destroy_message_callback_t destroy_req_callback,
                destroy_message_callback_t destroy_res_callback,
                service_server_callback_t callback) {
    rcl_ret_t return_code = RCL_RET_OK;
    ServiceServer *srv_server = malloc(sizeof(ServiceServer));

    srv_server->create_req = create_req_callback;
    srv_server->destroy_req = destroy_req_callback;
    srv_server->destroy_res = destroy_res_callback;
    srv_server->service = rcl_get_zero_initialized_service();

    rcl_service_options_t srv_options = rcl_service_get_default_options();

    return_code = rcl_service_init(&srv_server->service, &node->node, ts, service_name, &srv_options);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to init service server, ERR - %s.\n", rcutils_get_error_string().str);
        destroy_service_server(node, srv_server);
        return NULL;
    }

    srv_server->callback = callback;
    fprintf(stderr,"[C] Successfully created service server '%s'.\n", service_name);
    return srv_server;
}

void destroy_service_server(Node* node, ServiceServer* srv_server) {
    rcl_ret_t return_code = rcl_service_fini(&srv_server->service, &node->node);
    free(srv_server);
    if (return_code != RCL_RET_OK) {
        fprintf(stderr,"[C] Failed to destroy service server, ERR - %s.\n", rcutils_get_error_string().str);
    }
}


ServiceClient* create_service_client(
                Node* node,
                const rosidl_service_type_support_t* ts,
                const char* service_name,
                create_message_callback_t create_res_callback,
                destroy_message_callback_t destroy_res_callback
                ) {
    rcl_ret_t return_code = RCL_RET_OK;
    ServiceClient *service_client = malloc(sizeof(ServiceClient));

    service_client->create_res = create_res_callback;
    service_client->destroy_res = destroy_res_callback;
    service_client->client = rcl_get_zero_initialized_client();

    rcl_client_options_t client_options = rcl_client_get_default_options();

    return_code = rcl_client_init(&service_client->client, &node->node, ts, service_name, &client_options);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to init service client, ERR - %s.\n", rcutils_get_error_string().str);
        destroy_service_client(node, service_client);
        return NULL;
    }

    fprintf(stderr,"[C] Successfully created service client '%s'.\n", service_name);
    return service_client;
}

void destroy_service_client(Node* node, ServiceClient* srv_client) {
    rcl_ret_t return_code = rcl_client_fini(&srv_client->client, &node->node);
    free(srv_client);
    if (return_code != RCL_RET_OK) {
        fprintf(stderr,"[C] Failed to destroy service client, ERR - %s.\n", rcutils_get_error_string().str);
    }
}

// Sychronusly call a service server
bool call_service_server(
            Node* node,
            Context* context, 
            ServiceClient* service_client, 
            HsOwnedPtr req_msg_ptr, 
            service_client_callback_t callback,
            int64_t timeout_ns) {
    rcl_ret_t return_code = RCL_RET_OK;
    int64_t sequence_number;

    rcutils_time_point_value_t start_time;
    return_code = rcutils_system_time_now(&start_time);

    bool is_ready;

    while (!is_ready && rcl_context_is_valid(&context->context)) {

        return_code = rcl_service_server_is_available(&node->node, &service_client->client, &is_ready);

        if (!is_ready) {
            // 0.01 seconds
            usleep(10000);
        }

        rcutils_time_point_value_t now;
        return_code = rcutils_system_time_now(&now);
        if ((now - start_time) > timeout_ns) {
            fprintf(stderr, "[C] Timed out waiting for service server to exist.\n");
            return false;
        }
    }


    return_code = rcl_send_request(&service_client->client, req_msg_ptr, &sequence_number);

    if (return_code != RCL_RET_OK) {
        fprintf(stderr, "[C] Failed to send request to service server, ERR - %s\n", rcutils_get_error_string().str);
        return false;
    } else{
        fprintf(stderr, "[C] Successfully sent request to service server.\n");
    }

    rcl_allocator_t allocator = rcl_get_default_allocator();
    rcl_wait_set_t wait_set = rcl_get_zero_initialized_wait_set();

    return_code = rcl_wait_set_init(&wait_set, 0, 0, 0, 1, 0, 0, &context->context, allocator);

    if (return_code != RCL_RET_OK) {
        fprintf(stderr, "[C] Failed to init wait_set when sending request, ERR - %s\n", rcutils_get_error_string().str);
        return false;
    }

    bool callback_called = false;

    while (rcl_context_is_valid(&context->context)) {

        rcutils_time_point_value_t now;
        return_code = rcutils_system_time_now(&now);
        if ((now - start_time) > timeout_ns) {
            fprintf(stderr, "[C] Timed out waiting for service server response.\n");
            break;
        }

        return_code = rcl_wait_set_clear(&wait_set);
        return_code = rcl_wait_set_add_client(&wait_set, &service_client->client, NULL);

        return_code = rcl_wait(&wait_set, RCL_MS_TO_NS(10));

        if (return_code == RCL_RET_TIMEOUT) continue;
        if (return_code != RCL_RET_OK) {
            fprintf(stderr, "[C] Failed to wait for service server response, ERR - %s\n", rcutils_get_error_string().str);
            break;
        }

        if (wait_set.clients[0] != NULL) {
            rmw_request_id_t req_id;

            HsOwnedPtr res_msg_ptr = service_client->create_res();

            return_code = rcl_take_response(&service_client->client, &req_id, res_msg_ptr);

            if (return_code == RCL_RET_OK) {
                if (req_id.sequence_number == sequence_number) {
                    callback(res_msg_ptr);
                    callback_called = true;
                    break;
                } else {
                    // A different response, shouldnt be here so just destroy.
                    service_client->destroy_res(res_msg_ptr);
                    res_msg_ptr = service_client->create_res();
                }
            } else {
                service_client->destroy_res(res_msg_ptr);
            }
        }
    }

    return_code = rcl_wait_set_fini(&wait_set);
    if (return_code != RCL_RET_OK){
        fprintf(stderr, "[C] Failed to fini_wait_set for service server response, ERR - %s\n", rcutils_get_error_string().str);
    }

    return callback_called;
}



void check_return_code(rcl_ret_t rc, const char* f_name){

    if (rc != RCL_RET_OK && rc != RCL_RET_TIMEOUT){
        fprintf(stderr,"[C] ERR - %s (%s) %i.\n",
                rcutils_get_error_string().str,
                f_name,
                rc);
    }
}


void spin(Context* context,
          void** v_subs,
          size_t n_subs,
          void** v_timers,
          size_t n_timers,
          void** v_service_servers,
          size_t n_service_servers,
          bool run_forever,
          uint64_t duration){

    rcl_ret_t return_code = RCL_RET_OK;

    rcutils_time_point_value_t start_time;
    return_code = rcutils_system_time_now(&start_time);

    check_return_code(return_code,"rcutils_system_time_now");

    // GHC wants to pass void** but we need Subscription** and Timer**
    Subscription ** subs = (Subscription **) v_subs;
    Timer** timers = (Timer **) v_timers;
    ServiceServer** service_servers = (ServiceServer **) v_service_servers;


    HsOwnedPtr* timers_accs = malloc(sizeof(void*) * n_timers);

    for (int i = 0; i < n_timers; i++){
        timers_accs[i] = timers[i]->inital_acc;
    }

    HsOwnedPtr* subs_accs = malloc(sizeof(void*) * n_subs);

    for (int i = 0; i < n_subs; i++){
        subs_accs[i] = subs[i]->inital_acc;
    }

    rcl_allocator_t allocator = rcl_get_default_allocator();

    rcl_wait_set_t wait_set = rcl_get_zero_initialized_wait_set();

    return_code = rcl_wait_set_init(&wait_set,n_subs,0,n_timers,
                                    0,n_service_servers,0,
                                    &context->context,allocator);
    
    check_return_code(return_code,"wait_set_init");

    fprintf(stderr, "[C] Began Spinning!\n");

    while (rcl_context_is_valid(&context->context)){

        if (!run_forever) {
            rcutils_time_point_value_t now;
            return_code = rcutils_system_time_now(&now);
            check_return_code(return_code, "rcutils_system_time_now");

            if ((now - start_time) >= duration) {
                fprintf(stderr, "[C] spinFor duration reached, exiting.\n");
                break; 
            }
        }

        // each wait resets the wait_set
        return_code = rcl_wait_set_clear(&wait_set);
        check_return_code(return_code,"ws_clear");

        for (size_t i = 0; i < n_subs; i++){
            return_code = rcl_wait_set_add_subscription(&wait_set, &subs[i]->subscription, NULL);
            check_return_code(return_code,"add_sub");
        }
        for (size_t i = 0; i < n_timers; i++){
            return_code = rcl_wait_set_add_timer(&wait_set, &timers[i]->timer, NULL);
            check_return_code(return_code,"add_timer");
        }

        for (size_t i = 0; i < n_service_servers; i++){
            return_code = rcl_wait_set_add_service(&wait_set, &service_servers[i]->service, NULL);
            check_return_code(return_code,"add_service_servers");
        }


        // Block until something happens or timeout (10- ms,i.e. 0.01 second)
        return_code = rcl_wait(&wait_set,RCL_MS_TO_NS(10));
        check_return_code(return_code,"wait");

        // Execute any ready timers
        for (size_t i = 0; i < n_timers; i++) {
            if (wait_set.timers[i] != NULL) {
                fprintf(stderr,"[C] Triggering timer %zu.\n",i);
                // Inital acc is freed when the Timer goes out of scope
                // This allows for multiple spins on the same timer 
                // (each with the same initial value)
                bool is_not_inital_acc = timers_accs[i] != timers[i]->inital_acc;
                timers_accs[i] = timers[i]->callback(timers_accs[i],is_not_inital_acc);
                return_code = rcl_timer_call(&timers[i]->timer);
                check_return_code(return_code,"timer_call");
            }
        }

        for (size_t i = 0; i < n_subs; i++) {
            if (wait_set.subscriptions[i] != NULL){
                fprintf(stderr, "[C] Subscription %zu triggered.\n",i);
                HsOwnedPtr msg = subs[i]->create_msg();

                rmw_message_info_t msg_info;

                return_code = rcl_take(wait_set.subscriptions[i],msg,&msg_info,NULL);
                check_return_code(return_code,"rcl_take");

                fprintf(stderr,"[C] Successfully receieved from topic \"%s\".\n",
                rcl_subscription_get_topic_name(wait_set.subscriptions[i]));

                bool is_not_inital_acc = subs_accs[i] != subs[i]->inital_acc;
                subs_accs[i] = subs[i]->callback(subs_accs[i],msg,is_not_inital_acc);

                subs[i]->destroy_msg(msg);

            }
        }

        for (size_t i = 0; i < n_service_servers; i++) {
            if (wait_set.services[i] != NULL) {
                fprintf(stderr, "[C] Service server %zu receieved message.\n",i);

                rmw_request_id_t req_id;
                HsOwnedPtr req_msg = service_servers[i]->create_req();

                return_code = rcl_take_request(wait_set.services[i], &req_id, req_msg);
                if (return_code == RCL_RET_OK) {
                    HsOwnedPtr res_msg = NULL; 

                    res_msg = service_servers[i]->callback(req_msg);

                    if (res_msg != NULL) {
                        return_code = rcl_send_response(wait_set.services[i], &req_id, res_msg);
                        check_return_code(return_code, "rcl_send_response");

                        service_servers[i]->destroy_res(res_msg);
                    } else {
                        fprintf(stderr, "[C] Service Server callback returned a NULL pointer.\n");
                    }
                }
                service_servers[i]->destroy_req(req_msg);
            }
        }

    }

    // Free the last accumulator states
    for (size_t i = 0; i < n_timers; i++){
        freeHsOwnedPtr(timers_accs[i]);
    }
    for (size_t i = 0; i < n_subs; i++){
        freeHsOwnedPtr(subs_accs[i]);
    }

    free(timers_accs);
    return_code = rcl_wait_set_fini(&wait_set);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to destory wait-set, ERR - %s.\n",
                rcutils_get_error_string().str);
    } else {
        fprintf(stderr,"[C] Successfully destroyed wait-set.\n");
    }
}
