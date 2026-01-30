#ifndef RCLHS_WRAP_H
#define RCLHS_WRAP_H


// Opaque struct definition (contents hidden from Haskell)
typedef struct RclHsNode RclHsNode;

/**
 * Allocates memory, initializes ROS context, and initializes a Node.
 * Returns NULL if any step fails.
 */
RclHsNode* rclhs_create_node(const char* node_name, const char* ns);

/**
 * Tears down the node, the context, and frees the memory.
 * This signature is void (*)(ptr) so it matches Haskell's Finalizer interface.
 */
void rclhs_destroy_node(RclHsNode* node);

#endif
