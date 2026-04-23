module RclHs
  ( Publisher,
    Subscription,
    Node,
    Context,
    Timer,
    SomeSubscription (..),
    SomeServiceServer (..),
    publish,
    withSubscription,
    withPublisher,
    withNode,
    withContext,
    withTimer,
    spin,
    spinFor,
    secondInNanoSecond,
    withServiceServer,
    withServiceClient,
    callService,
  )
where

import Data.Word (Word64)
import Foreign.StablePtr (StablePtr)
import RclHs.Bindings
  ( Context,
    Node,
    Publisher,
    SomeServiceServer (..),
    SomeSubscription (..),
    Subscription,
    Timer,
    callService,
    freeHsOwnedPtr,
    publish,
    spin,
    spinFor,
    withContext,
    withNode,
    withPublisher,
    withServiceClient,
    withServiceServer,
    withSubscription,
    withTimer,
  )

secondInNanoSecond :: Word64
secondInNanoSecond = 1000000000

foreign export capi freeHsOwnedPtr :: StablePtr a -> IO ()
