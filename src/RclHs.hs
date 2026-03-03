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
    secondInNanoSecond,
  )
where

import Data.Word (Word64)
import RclHs.Bindings
  ( Context,
    Node,
    Publisher,
    Subscription,
    Timer,
    publish,
    spin,
    withContext,
    withNode,
    withPublisher,
    withSubscription,
    withTimer,
  )

secondInNanoSecond :: Word64
secondInNanoSecond = 1000000000
