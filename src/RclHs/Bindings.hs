module RclHs.Bindings (createNode, Node, Context) where

import Foreign (ForeignPtr, FunPtr, Ptr, newForeignPtr, withForeignPtr)
import Foreign.C (CString, withCString)

-- Opaque types
data Node

data Context

foreign import capi "wrap.h create_node" c_createNodeRawPtr :: CString -> CString -> Ptr Context -> IO (Ptr Node)

foreign import capi "wrap.h &destroy_node" c_destoryNodeRawPtr :: FunPtr (Ptr Node -> IO ())

createNode :: String -> String -> ForeignPtr Context -> IO (ForeignPtr Node)
createNode name namespace context =
  withCString name $ \c_name ->
    withCString namespace $ \c_namespace ->
      withForeignPtr context $ \c_context -> do
        ptr <- c_createNodeRawPtr c_name c_namespace c_context
        newForeignPtr c_destoryNodeRawPtr ptr
