#include "wrap.h"
#include <rcl/rcl.h>
#include <rcl/node_options.h>
#include <stdlib.h>
#include <stdio.h>

struct RclHsNode {
    // Typically Node's shouldn't have their own context
    // it should be shared, this is a short-cut.
    rcl_context_t context;
    rcl_node_t node;
    rcl_allocator_t allocator;
};

void log_failure(rcl_ret_t result, const char* err_msg){
    if (result != RCL_RET_OK) {
        fprintf(stderr, "[C] Error: %s: %d\n", err_msg, result);
    }
}

RclHsNode* rclhs_create_node(const char* node_name, const char* topic) {
    RclHsNode* ptr = (RclHsNode*)malloc(sizeof(RclHsNode));
    if (!ptr) return NULL;

    ptr->allocator = rcl_get_default_allocator();

    ptr->context = rcl_get_zero_initialized_context();
    rcl_init_options_t init_ops = rcl_get_zero_initialized_init_options();
    rcl_ret_t init_opts_res = rcl_init_options_init(&init_ops, ptr->allocator);
    log_failure(init_opts_res, "failed to init rcl_init_options");

    // For now argc == 0
    rcl_ret_t node_creation_res = rcl_init(0, NULL, &init_ops, &ptr->context);
    
    rcl_ret_t free_init_options_res = rcl_init_options_fini(&init_ops);
    log_failure(free_init_options_res, "failed to free rcl_init_options");

    if (node_creation_res != RCL_RET_OK) {
        log_failure(node_creation_res, "rcl_init failed");
        free(ptr);
        return NULL;
    }

    ptr->node = rcl_get_zero_initialized_node();
    rcl_node_options_t node_ops = rcl_node_get_default_options();

    node_creation_res = rcl_node_init(&ptr->node, node_name, topic, &ptr->context, &node_ops);

    // Failed to create Node
    if (node_creation_res != RCL_RET_OK) {
        log_failure(node_creation_res, "rcl_node_init failed");
        rcl_ret_t shutdown_res = rcl_shutdown(&ptr->context);
        log_failure(shutdown_res, "failed to shutdown rcl");
        rcl_ret_t ctx_free_res = rcl_context_fini(&ptr->context);
        log_failure(ctx_free_res, "failed to free context");
        free(ptr);
        return NULL;
    }

    return ptr;
}

void rclhs_destroy_node(RclHsNode* ptr) {
    // Nothing to destory
    if (!ptr) return;

    printf("[C] Tearing down node...\n");

    // Tear down in reverse order of creation
    rcl_ret_t node_free_res =rcl_node_fini(&ptr->node);
    log_failure(node_free_res, "failed to free node");
    rcl_ret_t shutdown_res = rcl_shutdown(&ptr->context);
    log_failure(shutdown_res, "failed to shutdown rcl");
    rcl_ret_t ctx_free_res = rcl_context_fini(&ptr->context);
    log_failure(ctx_free_res, "failed to free context");


    free(ptr);
    printf("[C] Memory freed.\n");
}
