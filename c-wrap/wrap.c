#include "wrap.h"
#include <stdio.h>
#include <rcutils/error_handling.h>

Node* create_node(const char *node_name,
                  const char *namespace,
                  rcl_context_t *context){
    rcl_ret_t return_code = RCL_RET_OK;
    rcl_node_t rcl_node = rcl_get_zero_initialized_node();
    rcl_node_options_t node_opt = rcl_node_get_default_options();
    return_code = rcl_node_init(&rcl_node,node_name,namespace,context,&node_opt);

    Node *node = malloc(sizeof(Node));
    node->node = &rcl_node;

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to init node (name - \"%s\", namespace - \"%s\") ERR - %s.\n",
                node_name,namespace,rcutils_get_error_string().str);
        destroy_node(node);
        return 0;
    }
    
    // TODO: remove once working
    printf("[C] Successfully created node.\n");

    return node;
}

void destroy_node(Node* node){
    rcl_ret_t return_code = RCL_RET_OK;
    return_code = rcl_node_fini(node->node);

    if (return_code != RCL_RET_OK){
        fprintf(stderr,"[C] Failed to destory node, ERR - %s.\n",rcutils_get_error_string().str);
    }
    else {
        // TODO: remove once working
        printf("[C] Successfully destoryed node.\n");
    }
}

