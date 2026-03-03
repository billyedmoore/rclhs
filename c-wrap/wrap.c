#include "wrap.h"
#include "rcl/allocator.h"
#include "rcl/context.h"
#include "rcl/init.h"
#include "rcl/init_options.h"
#include "rcl/node.h"
#include "rcl/publisher.h"
#include "rcl/subscription.h"
#include "rcl/timer.h"
#include <stdio.h>
#include <rcutils/error_handling.h>
#include <rosidl_runtime_c/message_type_support_struct.h>
#include <rosidl_runtime_c/string_functions.h>
#include <std_msgs/msg/string.h>

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
    
    printf("[C] Successfully created node.\n");

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
        printf("[C] Successfully destroyed node.\n");
    }

}

Publisher* create_publisher(
                Node* node,
                const char* topic){
    rcl_ret_t return_code = RCL_RET_OK;
    Publisher *pub  = malloc(sizeof(Publisher));
    pub->publisher = rcl_get_zero_initialized_publisher();

    // All data can be encoded as Strings don't you know!
    const rosidl_message_type_support_t * string_ts = ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, String);

    rcl_publisher_options_t pub_options = rcl_publisher_get_default_options();
    return_code = rcl_publisher_init(&pub->publisher, &node->node, string_ts, topic, &pub_options);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to init publisher, ERR - %s.\n",rcutils_get_error_string().str);
        destroy_publisher(node, pub);
        return NULL;
    }


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
        printf("[C] Successfully destroyed publisher.\n");
    }
}

Subscription* create_subscription(
                Node* node,
                const char* topic,
                string_callback_t callback){
    rcl_ret_t return_code = RCL_RET_OK;
    Subscription *sub  = malloc(sizeof(Subscription));
    sub->subscription = rcl_get_zero_initialized_subscription();

    // (some say) strings are all you need (they are wrong)
    const rosidl_message_type_support_t * string_ts = ROSIDL_GET_MSG_TYPE_SUPPORT(std_msgs, msg, String);
    
    rcl_subscription_options_t sub_options = rcl_subscription_get_default_options();

    return_code = rcl_subscription_init(&sub->subscription, &node->node, string_ts, topic, &sub_options);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to init subscription, ERR - %s.\n",rcutils_get_error_string().str);
        destroy_subscription(node, sub);
        return NULL;
    }

    sub->callback = callback;
    
    // NOTE: Testing purposes only, to be called from spin()
    callback("Some recieved message!");

    return sub;
}

void destroy_subscription(Node* node, Subscription* sub){
    // NOTE: Subscription is not responsible for the callback,
    //       it is allocated and freed from Haskell world.
    rcl_ret_t return_code = RCL_RET_OK;

    // Does NOT fini the node just the sub
    return_code = rcl_subscription_fini(&sub->subscription, &node->node);

    free(sub);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to destroy subscription, ERR - %s.\n",rcutils_get_error_string().str);
    }
    else {
        printf("[C] Successfully destroyed subscription.\n");
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
                    uint64_t period){
    rcl_ret_t return_code = RCL_RET_OK;

    rcl_clock_t clock;
    rcl_allocator_t allocator = rcl_get_default_allocator();
    rcl_ret_t rc = rcl_clock_init(RCL_STEADY_TIME, &clock, &allocator);

    Timer *timer = malloc(sizeof(Timer));
    timer->timer =  rcl_get_zero_initialized_timer();
    timer->callback = callback;
    rcl_node_options_t node_opt = rcl_node_get_default_options();
    return_code = rcl_timer_init2(&timer->timer,
                    &clock,
                    &context->context,
                    period,
                    nop_timer_callback,
                    allocator,
                    false);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to init timer ERR - %s.\n",
                rcutils_get_error_string().str);
        destroy_timer(timer);
        return NULL;
    }
    
    printf("[C] Successfully created timer.\n");

    // NOTE: Testing purposes only, to be called from spin()
    callback();

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
        printf("[C] Successfully destroyed timer.\n");
    }
    
}


// Publish a message (fire and forget)
// msg_content will be null_terminated since it is a CString.
void publish(Publisher* pub, const char* msg_content){
    rcl_ret_t return_code = RCL_RET_OK;

    std_msgs__msg__String msg;

    std_msgs__msg__String__init(&msg);

    bool success = rosidl_runtime_c__String__assign(&msg.data, msg_content);

    if (!success){
        fprintf(stderr,"[C] Failed to create message \"%s\".",
                msg_content);
        return;
    }

    return_code = rcl_publish(&pub->publisher,&msg,NULL);
    
    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to publish \"%s\" to \"%s\", ERR - %s.\n",
                msg_content,
                rcl_publisher_get_topic_name(&pub->publisher),
                rcutils_get_error_string().str);
    } else {
        fprintf(stderr,"[C] Successfully published \"%s\" to \"%s\", ERR - %s.\n",
                msg_content,
                rcl_publisher_get_topic_name(&pub->publisher),
                rcutils_get_error_string().str);
    }

    std_msgs__msg__String__fini(&msg);
}
