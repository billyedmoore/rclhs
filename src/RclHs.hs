module RclHs
  ( Publisher,
    Subscription,
    Node,
    Context,
    Timer,
    publish,
    withSubscription,
    withPublisher,
    withNode,
    withContext,
    withTimer,
    spin,
    spinFor,
    secondInNanoSecond,
  )
where

import Data.Word (Word64)
import Foreign.StablePtr (StablePtr)
import RclHs.Bindings
  ( Context,
    Node,
    Publisher,
    Subscription,
    Timer,
    freeHsOwnedPtr,
    publish,
    spin,
    spinFor,
    withContext,
    withNode,
    withPublisher,
    withSubscription,
    withTimer,
  )

secondInNanoSecond :: Word64
secondInNanoSecond = 1000000000

foreign export capi freeHsOwnedPtr :: StablePtr a -> IO ()
