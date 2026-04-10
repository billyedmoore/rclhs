module RclHs.Bindings
  ( publish,
    Node,
    Context,
    Publisher,
    Subscription,
    Timer,
    spin,
    spinFor,
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
import Foreign.C (CBool (..), CSize (..), CString, withCString)
import Foreign.Marshal.Array (withArrayLen)
import Foreign.StablePtr (StablePtr, deRefStablePtr, freeStablePtr, newStablePtr)
import RclHs.Types (RosMessage (..), RosidlMessageTypeSupport, createMessage, destroyMessage)

-- Opaque types
data Node

data Timer

data Context

data Publisher

data Subscription

-- Callback Types
type SubCallback acc msg = acc -> msg -> IO acc

type CSubCallback acc msg = StablePtr acc -> Ptr msg -> CBool -> IO (StablePtr acc)

type TimerCallback acc = acc -> IO acc

type CTimerCallback acc = StablePtr acc -> CBool -> IO (StablePtr acc)

foreign import capi "wrap.h create_node" c_createNodeRawPtr :: CString -> CString -> Ptr Context -> IO (Ptr Node)

foreign import capi "wrap.h destroy_node" c_destoryNodeRawPtr :: Ptr Node -> IO ()

foreign import capi "wrap.h create_publisher"
  c_createPublisherRawPtr ::
    Ptr Node ->
    Ptr (RosidlMessageTypeSupport msg) ->
    CString ->
    IO (Ptr Publisher)

foreign import capi "wrap.h destroy_publisher" c_destoryPublisherRawPtr :: Ptr Node -> Ptr Publisher -> IO ()

foreign import capi "wrap.h create_subscription"
  c_createSubscriptionRawPtr ::
    Ptr Node ->
    Ptr (RosidlMessageTypeSupport msg) ->
    CString ->
    StablePtr a ->
    FunPtr (IO (Ptr msg)) ->
    FunPtr (Ptr msg -> IO ()) ->
    FunPtr (CSubCallback a msg) ->
    IO (Ptr Subscription)

foreign import capi "wrap.h destroy_subscription" c_destorySubscriptionRawPtr :: Ptr Node -> Ptr Subscription -> IO ()

foreign import capi "wrap.h publish" c_publish :: Ptr Publisher -> Ptr msg -> IO ()

foreign import capi "wrap.h create_context" c_createContextRawPtr :: IO (Ptr Context)

foreign import capi "wrap.h shutdown_context" c_shutdownContextRawPtr :: Ptr Context -> IO ()

foreign import capi "wrap.h create_timer"
  c_createTimer :: Ptr Context -> FunPtr (CTimerCallback a) -> Word64 -> StablePtr a -> IO (Ptr Timer)

foreign import capi "wrap.h destroy_timer" c_destoryTimer :: Ptr Timer -> IO ()

foreign import capi "wrap.h spin"
  c_spin ::
    Ptr Context ->
    Ptr (Ptr Subscription) ->
    CSize ->
    Ptr (Ptr Timer) ->
    CSize ->
    CBool ->
    Word64 ->
    IO ()

-- "wrapper" is a special function to get a FunPtr from a Haskell function
foreign import ccall "wrapper"
  c_getSubFunctionPtr :: CSubCallback a msg -> IO (FunPtr (CSubCallback a msg))

foreign import ccall "wrapper"
  c_getTimerFunctionPtr :: CTimerCallback a -> IO (FunPtr (CTimerCallback a))

foreign import ccall "wrapper"
  c_getCreateMessageFunctionPtr :: IO (Ptr msg) -> IO (FunPtr (IO (Ptr msg)))

foreign import ccall "wrapper"
  c_getDestroyMessageFunctionPtr :: (Ptr msg -> IO ()) -> IO (FunPtr (Ptr msg -> IO ()))

-- Allows a HsOwnedPtr to be freed from C land
-- Should be used sparingly
freeHsOwnedPtr :: StablePtr a -> IO ()
freeHsOwnedPtr = freeStablePtr

publish :: forall msg. (RosMessage msg) => Ptr Publisher -> msg -> IO ()
publish publisher message =
  withCStruct message $ \messagePtr -> do
    c_publish publisher messagePtr

spin :: Ptr Context -> [Ptr Subscription] -> [Ptr Timer] -> IO ()
spin context subs timers =
  withArrayLen subs $ \n_subs c_subs ->
    withArrayLen timers $ \n_timers c_timers ->
      c_spin context c_subs (fromIntegral n_subs) c_timers (fromIntegral n_timers) (CBool 1) 0

-- spinFor `duration` nano seconds
spinFor :: Ptr Context -> [Ptr Subscription] -> [Ptr Timer] -> Word64 -> IO ()
spinFor context subs timers duration =
  withArrayLen subs $ \n_subs c_subs ->
    withArrayLen timers $ \n_timers c_timers ->
      c_spin context c_subs (fromIntegral n_subs) c_timers (fromIntegral n_timers) (CBool 0) duration

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

-- Require users to explicity state the type of the publisher
withPublisher :: forall msg a. (RosMessage msg) => String -> Ptr Node -> (Ptr Publisher -> IO a) -> IO a
withPublisher topic node action = do
  ts <- getTypeSupport @msg
  withCString topic $ \c_topic ->
    bracket (c_createPublisherRawPtr node ts c_topic) (c_destoryPublisherRawPtr node) $ \publisher ->
      action publisher

-- Require users to explicity state the type of the publisher
withSubscription ::
  forall msg acc b.
  (RosMessage msg) =>
  String ->
  Ptr Node ->
  acc ->
  SubCallback acc msg ->
  (Ptr Subscription -> IO b) ->
  IO b
withSubscription topic node initalAcc callback action = do
  ts <- getTypeSupport @msg

  withCString topic $ \c_topic ->
    bracket (wrapSubCallback callback) freeHaskellFunPtr $
      \c_callback ->
        bracket
          (newStablePtr initalAcc)
          freeStablePtr
          $ \c_initalAcc ->
            bracket
              ( do
                  createPtrCallback <- c_getCreateMessageFunctionPtr (createMessage @msg)
                  destroyPtrCallback <- c_getDestroyMessageFunctionPtr (destroyMessage @msg)
                  c_createSubscriptionRawPtr
                    node
                    ts
                    c_topic
                    c_initalAcc
                    createPtrCallback
                    destroyPtrCallback
                    c_callback
              )
              (c_destorySubscriptionRawPtr node)
              $ \sub -> action sub

withTimer :: Ptr Context -> acc -> TimerCallback acc -> Word64 -> (Ptr Timer -> IO b) -> IO b
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

-- Convert Haskell Callbacks to somthing that can be called from C

wrapTimerCallback :: TimerCallback acc -> IO (FunPtr (CTimerCallback acc))
wrapTimerCallback callback =
  c_getTimerFunctionPtr wrapped
  where
    wrapped input free = do
      val <- deRefStablePtr input
      when (toBool free) (freeStablePtr input)
      result <- callback val
      newStablePtr result

wrapSubCallback :: (RosMessage msg) => SubCallback acc msg -> IO (FunPtr (CSubCallback acc msg))
wrapSubCallback callback =
  c_getSubFunctionPtr wrapped
  where
    wrapped input c_msg free = do
      acc <- deRefStablePtr input
      when (toBool free) (freeStablePtr input)
      msg <- peekCStruct c_msg
      result <- callback acc msg
      newStablePtr result
