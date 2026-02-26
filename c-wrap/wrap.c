#include "wrap.h"
#include "rcl/context.h"
#include "rcl/init.h"
#include "rcl/init_options.h"
#include <stdio.h>
#include <rcutils/error_handling.h>

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
    rcl_node_t rcl_node = rcl_get_zero_initialized_node();
    rcl_node_options_t node_opt = rcl_node_get_default_options();
    return_code = rcl_node_init(&rcl_node,node_name,namespace,&context->context,&node_opt);

    Node *node = malloc(sizeof(Node));
    node->node = rcl_node;

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
        fprintf(stderr,"[C] Failed to destory node, ERR - %s.\n",rcutils_get_error_string().str);
    }
    else {
        printf("[C] Successfully destroyed node.\n");
    }

}

