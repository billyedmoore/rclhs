module RclHs.Bindings (createNode, createContext, Node, Context) where

import Foreign (ForeignPtr, FunPtr, Ptr, newForeignPtr, touchForeignPtr, withForeignPtr)
import Foreign.C (CString, withCString)
import Foreign.Concurrent qualified as FC

-- Opaque types
data Node

data Context

foreign import capi "wrap.h create_node" c_createNodeRawPtr :: CString -> CString -> Ptr Context -> IO (Ptr Node)

foreign import capi "wrap.h destroy_node" c_destoryNodeRawPtr :: Ptr Node -> IO ()

foreign import capi "wrap.h create_context" c_createContextRawPtr :: IO (Ptr Context)

foreign import capi "wrap.h &shutdown_context" c_shutdownContextRawPtr :: FunPtr (Ptr Context -> IO ())

createNode :: String -> String -> ForeignPtr Context -> IO (ForeignPtr Node)
createNode name namespace context =
  withCString name $ \c_name ->
    withCString namespace $ \c_namespace ->
      withForeignPtr context $ \c_context -> do
        ptr <- c_createNodeRawPtr c_name c_namespace c_context
        FC.newForeignPtr ptr $ do
          c_destoryNodeRawPtr ptr
          touchForeignPtr context

-- It will likely be cleaner to move to a withContext pattern
-- at sometime.
createContext :: IO (ForeignPtr Context)
createContext = do
  ptr <- c_createContextRawPtr
  newForeignPtr c_shutdownContextRawPtr ptr
