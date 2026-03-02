module RclHs.Bindings
  ( publish,
    createNode,
    createContext,
    createPublisher,
    createSubscription,
    Node,
    Context,
  )
where

import Foreign (ForeignPtr, FunPtr, Ptr, freeHaskellFunPtr, newForeignPtr, touchForeignPtr, withForeignPtr)
import Foreign.C (CString, peekCString, withCString)
import Foreign.Concurrent qualified as FC

-- Opaque types
data Node

data Context

data Publisher

data Subscription

foreign import capi "wrap.h create_node" c_createNodeRawPtr :: CString -> CString -> Ptr Context -> IO (Ptr Node)

foreign import capi "wrap.h destroy_node" c_destoryNodeRawPtr :: Ptr Node -> IO ()

foreign import capi "wrap.h create_publisher" c_createPublisherRawPtr :: Ptr Node -> CString -> IO (Ptr Publisher)

foreign import capi "wrap.h destroy_publisher" c_destoryPublisherRawPtr :: Ptr Node -> Ptr Publisher -> IO ()

foreign import capi "wrap.h create_subscription"
  c_createSubscriptionRawPtr ::
    Ptr Node ->
    CString ->
    FunPtr (CString -> IO ()) ->
    IO (Ptr Subscription)

foreign import capi "wrap.h destroy_subscription" c_destorySubscriptionRawPtr :: Ptr Node -> Ptr Subscription -> IO ()

foreign import capi "wrap.h publish" c_publish :: Ptr Publisher -> CString -> IO ()

foreign import capi "wrap.h create_context" c_createContextRawPtr :: IO (Ptr Context)

foreign import capi "wrap.h &shutdown_context" c_shutdownContextRawPtr :: FunPtr (Ptr Context -> IO ())

foreign import ccall "wrapper" c_getFunctionPtr :: (CString -> IO ()) -> IO (FunPtr (CString -> IO ()))

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

toCFunc :: (String -> IO ()) -> (CString -> IO ())
toCFunc f c_str = do
  str <- peekCString c_str
  f str

createSubscription :: String -> ForeignPtr Node -> (String -> IO ()) -> IO (ForeignPtr Subscription)
createSubscription topic node callback =
  withCString topic $ \c_topic ->
    withForeignPtr node $ \c_node -> do
      callbackFP <- (c_getFunctionPtr . toCFunc) callback
      ptr <- c_createSubscriptionRawPtr c_node c_topic callbackFP
      FC.newForeignPtr ptr $ do
        -- this enforces node living longer than its subscribers
        withForeignPtr node $ \c_node_fin -> do
          c_destorySubscriptionRawPtr c_node_fin ptr
          freeHaskellFunPtr callbackFP
