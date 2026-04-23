module RclHs.Bindings
  ( publish,
    Node,
    Context,
    Publisher,
    Subscription,
    Timer,
    SomeSubscription (..),
    SomeServiceServer (..),
    spin,
    spinFor,
    withContext,
    withNode,
    withPublisher,
    withSubscription,
    withServiceServer,
    withServiceClient,
    callService,
    withTimer,
    freeHsOwnedPtr,
  )
where

import Control.Exception (bracket)
import Control.Monad (when)
import Data.Int (Int64)
import Data.Word (Word64)
import Foreign (FunPtr, Ptr, castFunPtr, castPtr, freeHaskellFunPtr, toBool)
import Foreign.C (CBool (..), CSize (..), CString, withCString)
import Foreign.Marshal.Array (withArrayLen)
import Foreign.StablePtr (StablePtr, deRefStablePtr, freeStablePtr, newStablePtr)
import RclHs.Types
  ( RosMessage (..),
    RosService (..),
    RosidlMessageTypeSupport,
    RosidlServiceTypeSupport,
    createEmptyMessage,
    destroyMessage,
  )

-- Opaque types
data Node

data Timer

data Context

data Publisher msg

data Subscription msg

-- Subscription with the specific msg erased
data UntypedSubscription

data ServiceServer srv

-- Service server with the specific srv erased
data UntypedServiceServer

data ServiceClient srv

data SomeSubscription where
  SomeSubscription :: (RosMessage msg) => Ptr (Subscription msg) -> SomeSubscription

data SomeServiceServer where
  SomeServiceServer :: (RosService srv) => Ptr (ServiceServer srv) -> SomeServiceServer

-- Callback Types
type SubCallback acc msg = acc -> msg -> IO acc

type CSubCallback acc msg = StablePtr acc -> Ptr msg -> CBool -> IO (StablePtr acc)

type TimerCallback acc = acc -> IO acc

type CTimerCallback acc = StablePtr acc -> CBool -> IO (StablePtr acc)

type ServiceServerCallback srv = SrvRequest srv -> IO (SrvResponse srv)

type CServiceServerCallback srv = Ptr (SrvRequest srv) -> IO (Ptr (SrvResponse srv))

type RawCServiceServerCallback srv = Ptr () -> IO (Ptr ())

type ServiceClientCallback srv = SrvResponse srv -> IO ()

type CServiceClientCallback srv = Ptr (SrvResponse srv) -> IO ()

type RawCServiceClientCallback srv = Ptr () -> IO ()

type CreateMessageCallback msg = IO (Ptr msg)

type DestroyMessageCallback msg = Ptr msg -> IO ()

foreign import capi "wrap.h create_node" c_createNodeRawPtr :: CString -> CString -> Ptr Context -> IO (Ptr Node)

foreign import capi "wrap.h destroy_node" c_destoryNodeRawPtr :: Ptr Node -> IO ()

foreign import capi "wrap.h create_publisher"
  c_createPublisherRawPtr ::
    Ptr Node ->
    Ptr (RosidlMessageTypeSupport msg) ->
    CString ->
    IO (Ptr (Publisher msg))

foreign import capi "wrap.h destroy_publisher" c_destoryPublisherRawPtr :: Ptr Node -> Ptr (Publisher msg) -> IO ()

foreign import capi "wrap.h create_subscription"
  c_createSubscriptionRawPtr ::
    Ptr Node ->
    Ptr (RosidlMessageTypeSupport msg) ->
    CString ->
    StablePtr a ->
    FunPtr (CreateMessageCallback msg) ->
    FunPtr (DestroyMessageCallback msg) ->
    FunPtr (CSubCallback a msg) ->
    IO (Ptr (Subscription msg))

foreign import capi "wrap.h destroy_subscription"
  c_destorySubscriptionRawPtr ::
    Ptr Node -> Ptr (Subscription msg) -> IO ()

foreign import capi "wrap.h publish" c_publish :: Ptr (Publisher msg) -> Ptr msg -> IO ()

foreign import capi "wrap.h create_context" c_createContextRawPtr :: IO (Ptr Context)

foreign import capi "wrap.h shutdown_context" c_shutdownContextRawPtr :: Ptr Context -> IO ()

foreign import capi "wrap.h create_service_server"
  c_createServiceServer ::
    Ptr Node ->
    Ptr (RosidlServiceTypeSupport srv) ->
    CString ->
    FunPtr (CreateMessageCallback req) ->
    FunPtr (DestroyMessageCallback req) ->
    FunPtr (DestroyMessageCallback res) ->
    FunPtr (CServiceServerCallback srv) ->
    IO (Ptr (ServiceServer srv))

foreign import capi "wrap.h destroy_service_server" c_destroyServiceServer :: Ptr Node -> Ptr (ServiceServer srv) -> IO ()

foreign import capi "wrap.h create_service_client"
  c_createServiceClient ::
    Ptr Node ->
    Ptr (RosidlServiceTypeSupport srv) ->
    CString ->
    FunPtr (CreateMessageCallback res) ->
    FunPtr (DestroyMessageCallback res) ->
    IO (Ptr (ServiceClient msg))

foreign import capi "wrap.h destroy_service_client" c_destroyServiceClient :: Ptr Node -> Ptr (ServiceClient msg) -> IO ()

foreign import capi "wrap.h call_service_server" c_callService :: Ptr Node -> Ptr Context -> Ptr (ServiceClient msg) -> Ptr req -> FunPtr (CServiceClientCallback srv) -> Int64 -> IO CBool

foreign import capi "wrap.h create_timer"
  c_createTimer :: Ptr Context -> FunPtr (CTimerCallback a) -> Word64 -> StablePtr a -> IO (Ptr Timer)

foreign import capi "wrap.h destroy_timer" c_destoryTimer :: Ptr Timer -> IO ()

foreign import capi "wrap.h spin"
  c_spin ::
    Ptr Context ->
    Ptr (Ptr UntypedSubscription) ->
    CSize ->
    Ptr (Ptr Timer) ->
    CSize ->
    Ptr (Ptr UntypedServiceServer) ->
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
  c_getServiceClientFunctionPtr :: RawCServiceClientCallback srv -> IO (FunPtr (RawCServiceClientCallback srv))

foreign import ccall "wrapper"
  c_getServiceServerFunctionPtr :: RawCServiceServerCallback srv -> IO (FunPtr (RawCServiceServerCallback srv))

foreign import ccall "wrapper"
  c_getCreateMessageFunctionPtr :: IO (Ptr msg) -> IO (FunPtr (IO (Ptr msg)))

foreign import ccall "wrapper"
  c_getDestroyMessageFunctionPtr :: (Ptr msg -> IO ()) -> IO (FunPtr (Ptr msg -> IO ()))

-- Allows a HsOwnedPtr to be freed from C land
-- Should be used sparingly
freeHsOwnedPtr :: StablePtr a -> IO ()
freeHsOwnedPtr = freeStablePtr

publish :: forall msg. (RosMessage msg) => Ptr (Publisher msg) -> msg -> IO ()
publish publisher message =
  withCStruct message $ \messagePtr -> do
    c_publish publisher messagePtr

spin :: Ptr Context -> [SomeSubscription] -> [Ptr Timer] -> [SomeServiceServer] -> IO ()
spin context wrappedSubs timers wrappedService =
  let subs = map (\(SomeSubscription p) -> castPtr p :: Ptr UntypedSubscription) wrappedSubs
      services = map (\(SomeServiceServer p) -> castPtr p :: Ptr UntypedServiceServer) wrappedService
   in withArrayLen subs $ \n_subs c_subs ->
        withArrayLen timers $ \n_timers c_timers ->
          withArrayLen services $ \n_services c_services ->
            c_spin
              context
              c_subs
              (fromIntegral n_subs)
              c_timers
              (fromIntegral n_timers)
              c_services
              (fromIntegral n_services)
              (CBool 1)
              0

-- spinFor `duration` nano seconds
spinFor :: Ptr Context -> [SomeSubscription] -> [Ptr Timer] -> [SomeServiceServer] -> Word64 -> IO ()
spinFor context wrappedSubs timers wrappedService duration =
  let subs = map (\(SomeSubscription p) -> castPtr p :: Ptr UntypedSubscription) wrappedSubs
      services = map (\(SomeServiceServer p) -> castPtr p :: Ptr UntypedServiceServer) wrappedService
   in withArrayLen subs $ \n_subs c_subs ->
        withArrayLen timers $ \n_timers c_timers ->
          withArrayLen services $ \n_services c_services ->
            c_spin
              context
              c_subs
              (fromIntegral n_subs)
              c_timers
              (fromIntegral n_timers)
              c_services
              (fromIntegral n_services)
              (CBool 0)
              duration

callService ::
  forall srv.
  (RosService srv, RosMessage (SrvRequest srv), RosMessage (SrvResponse srv)) =>
  Ptr Node ->
  Ptr Context ->
  Ptr (ServiceClient srv) ->
  SrvRequest srv ->
  (SrvResponse srv -> IO ()) ->
  Int64 ->
  IO ()
callService node context serviceClient req callback timeout =
  bracket
    (wrapServiceClientCallback @srv callback)
    freeHaskellFunPtr
    $ \c_callback ->
      withCStruct @(SrvRequest srv) req $ \reqPtr -> do
        _ <- c_callService node context serviceClient reqPtr (castFunPtr c_callback) timeout
        return ()

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

withServiceServer ::
  forall srv a.
  ( RosService srv,
    RosMessage (SrvRequest srv),
    RosMessage (SrvResponse srv)
  ) =>
  String ->
  Ptr Node ->
  (SrvRequest srv -> IO (SrvResponse srv)) ->
  (Ptr (ServiceServer srv) -> IO a) ->
  IO a
withServiceServer service_name node callback action = do
  ts <- getServiceTypeSupport @srv
  withCString service_name $ \c_serviceName ->
    bracket
      (wrapServiceServerCallback @srv callback)
      freeHaskellFunPtr
      $ \c_callback ->
        bracket (c_getCreateMessageFunctionPtr (createEmptyMessage @(SrvRequest srv))) freeHaskellFunPtr $
          \c_createReqCallback ->
            bracket (c_getDestroyMessageFunctionPtr (destroyMessage @(SrvRequest srv))) freeHaskellFunPtr $
              \c_destroyReqCallback ->
                bracket (c_getDestroyMessageFunctionPtr (destroyMessage @(SrvResponse srv))) freeHaskellFunPtr $
                  \c_destroyResCallback ->
                    bracket
                      ( c_createServiceServer
                          node
                          ts
                          c_serviceName
                          (castFunPtr c_createReqCallback)
                          (castFunPtr c_destroyReqCallback)
                          (castFunPtr c_destroyResCallback)
                          (castFunPtr c_callback)
                      )
                      (c_destroyServiceServer node)
                      action

withServiceClient ::
  forall srv a.
  ( RosService srv,
    RosMessage (SrvRequest srv),
    RosMessage (SrvResponse srv)
  ) =>
  String ->
  Ptr Node ->
  (Ptr (ServiceClient srv) -> IO a) ->
  IO a
withServiceClient service_name node action = do
  ts <- getServiceTypeSupport @srv
  withCString service_name $ \c_serviceName ->
    bracket (c_getCreateMessageFunctionPtr (createEmptyMessage @(SrvResponse srv))) freeHaskellFunPtr $
      \c_createReqCallback ->
        bracket (c_getDestroyMessageFunctionPtr (destroyMessage @(SrvResponse srv))) freeHaskellFunPtr $
          \c_destroyReqCallback ->
            bracket
              ( c_createServiceClient
                  node
                  ts
                  c_serviceName
                  (castFunPtr c_createReqCallback)
                  (castFunPtr c_destroyReqCallback)
              )
              (c_destroyServiceClient node)
              action

-- Require users to explicity state the type of the publisher with @ syntax
withPublisher :: forall msg a. (RosMessage msg) => String -> Ptr Node -> (Ptr (Publisher msg) -> IO a) -> IO a
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
  (Ptr (Subscription msg) -> IO b) ->
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
              -- WARNING: These function ptrs are not freed?
              ( do
                  createPtrCallback <- c_getCreateMessageFunctionPtr (createEmptyMessage @msg)
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

wrapServiceServerCallback ::
  forall srv.
  ( RosService srv,
    RosMessage (SrvRequest srv),
    RosMessage (SrvResponse srv)
  ) =>
  ServiceServerCallback srv ->
  IO (FunPtr (CServiceServerCallback srv))
wrapServiceServerCallback callback = do
  rawFunPtr <- c_getServiceServerFunctionPtr wrapped
  return (castFunPtr rawFunPtr)
  where
    wrapped :: Ptr () -> IO (Ptr ())
    wrapped reqVoidPtr = do
      let reqPtr = castPtr reqVoidPtr :: Ptr (SrvRequest srv)
      haskellReq <- peekCStruct @(SrvRequest srv) reqPtr
      haskellRes <- callback haskellReq
      resPtr <- newCStruct @(SrvResponse srv) haskellRes
      return (castPtr resPtr)

wrapServiceClientCallback ::
  forall srv.
  ( RosService srv,
    RosMessage (SrvResponse srv)
  ) =>
  ServiceClientCallback srv ->
  IO
    (FunPtr (CServiceClientCallback srv))
wrapServiceClientCallback callback = do
  rawFunPtr <- c_getServiceClientFunctionPtr wrapped
  return (castFunPtr rawFunPtr)
  where
    wrapped :: Ptr () -> IO ()
    wrapped resVoidPtr = do
      let resPtr = castPtr resVoidPtr :: Ptr (SrvResponse srv)
      haskellRes <- peekCStruct @(SrvResponse srv) resPtr
      callback haskellRes
