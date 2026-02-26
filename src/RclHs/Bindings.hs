module RclHs.Bindings (publish, createNode, createContext, createPublisher, Node, Context) where

import Foreign (ForeignPtr, FunPtr, Ptr, newForeignPtr, touchForeignPtr, withForeignPtr)
import Foreign.C (CString, withCString)
import Foreign.Concurrent qualified as FC

-- Opaque types
data Node

data Context

data Publisher

foreign import capi "wrap.h create_node" c_createNodeRawPtr :: CString -> CString -> Ptr Context -> IO (Ptr Node)

foreign import capi "wrap.h destroy_node" c_destoryNodeRawPtr :: Ptr Node -> IO ()

foreign import capi "wrap.h create_publisher" c_createPublisherRawPtr :: Ptr Node -> CString -> IO (Ptr Publisher)

foreign import capi "wrap.h destroy_publisher" c_destoryPublisherRawPtr :: Ptr Node -> Ptr Publisher -> IO ()

foreign import capi "wrap.h publish" c_publish :: Ptr Publisher -> CString -> IO ()

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
          -- context must live at least as long as node
          touchForeignPtr context

-- It will likely be cleaner to move to a withContext pattern
-- at sometime.
createContext :: IO (ForeignPtr Context)
createContext = do
  ptr <- c_createContextRawPtr
  newForeignPtr c_shutdownContextRawPtr ptr

-- topic -> owning node -> new publisher
-- NOTE: can only publish strings for now
createPublisher :: String -> ForeignPtr Node -> IO (ForeignPtr Publisher)
createPublisher topic node =
  withCString topic $ \c_topic ->
    withForeignPtr node $ \c_node -> do
      ptr <- c_createPublisherRawPtr c_node c_topic
      FC.newForeignPtr ptr $ do
        -- this enforces node living longer than its publishers
        withForeignPtr node $ \c_node_fin ->
          c_destoryPublisherRawPtr c_node_fin ptr

publish :: ForeignPtr Publisher -> String -> IO ()
publish publisher message =
  withForeignPtr publisher $ \c_publisher ->
    withCString message $ \c_message ->
      c_publish c_publisher c_message
