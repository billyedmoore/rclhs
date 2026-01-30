{-# LANGUAGE ForeignFunctionInterface #-}

module RclHs.Bindings (RclHsNodeStruct, c_create_node, c_destroy_node) where

import Foreign (FunPtr, Ptr)
import Foreign.C.String (CString)

data RclHsNodeStruct

foreign import ccall safe "rclhs_create_node"
  c_create_node :: CString -> CString -> IO (Ptr RclHsNodeStruct)

foreign import ccall "&rclhs_destroy_node"
  c_destroy_node :: FunPtr (Ptr RclHsNodeStruct -> IO ())
