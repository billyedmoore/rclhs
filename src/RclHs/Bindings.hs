module RclHs.Bindings
  ( publish,
    Node,
    Context,
    Publisher,
    Subscription,
    Timer,
    spin,
    withContext,
    withNode,
    withPublisher,
    withSubscription,
    withTimer,
    freeHsOwnedPtr,
  )
where

import Control.Exception (bracket)
import Control.Monad (when)
import Data.Word (Word64)
import Foreign (FunPtr, Ptr, freeHaskellFunPtr, toBool)
import Foreign.C (CBool (..), CSize (..), CString, peekCString, withCString)
import Foreign.Marshal.Array (withArrayLen)
import Foreign.StablePtr (StablePtr, deRefStablePtr, freeStablePtr, newStablePtr)

-- Opaque types
data Node

data Timer

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

foreign import capi "wrap.h shutdown_context" c_shutdownContextRawPtr :: Ptr Context -> IO ()

foreign import capi "wrap.h create_timer" c_createTimer :: Ptr Context -> FunPtr (StablePtr a -> CBool -> IO (StablePtr a)) -> Word64 -> StablePtr a -> IO (Ptr Timer)

foreign import capi "wrap.h destroy_timer" c_destoryTimer :: Ptr Timer -> IO ()

foreign import capi "wrap.h spin" c_spin :: Ptr Context -> Ptr (Ptr Subscription) -> CSize -> Ptr (Ptr Timer) -> CSize -> IO ()

-- "wrapper" is a special function to get a FunPtr from a Haskell function
foreign import ccall "wrapper" c_getStringFunctionPtr :: (CString -> IO ()) -> IO (FunPtr (CString -> IO ()))

foreign import ccall "wrapper" c_getTimerFunctionPtr :: (StablePtr a -> CBool -> IO (StablePtr a)) -> IO (FunPtr (StablePtr a -> CBool -> IO (StablePtr a)))

-- Allows a HsOwnedPtr to be freed from C land
-- Should be used sparingly
freeHsOwnedPtr :: StablePtr a -> IO ()
freeHsOwnedPtr = freeStablePtr

publish :: Ptr Publisher -> String -> IO ()
publish publisher message =
  withCString message $ \c_message ->
    c_publish publisher c_message

spin :: Ptr Context -> [Ptr Subscription] -> [Ptr Timer] -> IO ()
spin context subs timers =
  withArrayLen subs $ \n_subs c_subs ->
    withArrayLen timers $ \n_timers c_timers ->
      c_spin context c_subs (fromIntegral n_subs) c_timers (fromIntegral n_timers)

toCFunc :: (String -> IO ()) -> (CString -> IO ())
toCFunc f c_str = do
  str <- peekCString c_str
  f str

withNode :: String -> String -> Ptr Context -> (Ptr Node -> IO a) -> IO a
withNode name namespace context action =
  withCString name $ \c_name ->
    withCString namespace $ \c_ns -> do
      bracket (c_createNodeRawPtr c_name c_ns context) c_destoryNodeRawPtr $ \node ->
        action node

withContext :: (Ptr Context -> IO a) -> IO a
withContext action =
  bracket c_createContextRawPtr c_shutdownContextRawPtr $ \context ->
    action context

withPublisher :: String -> Ptr Node -> (Ptr Publisher -> IO a) -> IO a
withPublisher topic node action =
  withCString topic $ \c_topic ->
    bracket (c_createPublisherRawPtr node c_topic) (c_destoryPublisherRawPtr node) $ \publisher ->
      action publisher

withSubscription :: String -> Ptr Node -> (String -> IO ()) -> (Ptr Subscription -> IO a) -> IO a
withSubscription topic node callback action =
  withCString topic $ \c_topic ->
    bracket ((c_getStringFunctionPtr . toCFunc) callback) freeHaskellFunPtr $
      \c_callback ->
        bracket
          (c_createSubscriptionRawPtr node c_topic c_callback)
          (c_destorySubscriptionRawPtr node)
          $ \sub ->
            action sub

withTimer :: Ptr Context -> a -> (a -> IO a) -> Word64 -> (Ptr Timer -> IO b) -> IO b
withTimer context accumInitalValue callback period action =
  bracket
    (newStablePtr accumInitalValue)
    freeStablePtr
    $ \c_initalAccum ->
      bracket
        (wrapTimerCallback callback)
        freeHaskellFunPtr
        $ \c_callback ->
          bracket (c_createTimer context c_callback period c_initalAccum) c_destoryTimer $ \timer ->
            action timer

wrapTimerCallback :: (a -> IO a) -> IO (FunPtr (StablePtr a -> CBool -> IO (StablePtr a)))
wrapTimerCallback callback = c_getTimerFunctionPtr wrapped
  where
    -- wrapped :: StablePtr a -> CBool -> IO (StablePtr a)
    wrapped input free = do
      val <- deRefStablePtr input
      when (toBool free) (freeStablePtr input)
      result <- callback val
      newStablePtr result
