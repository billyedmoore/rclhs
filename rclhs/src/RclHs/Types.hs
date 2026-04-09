module RclHs.Types where

import Foreign (Ptr, Storable (..), callocBytes, free)
import Foreign.C.Types (CBool)

-- Opaque Ptr
data RosidlMessageTypeSupport a

-- Allocate and init message
createMessage :: forall msg. (RosMessage msg) => IO (Ptr msg)
createMessage = do
  ptr <- callocBytes (sizeOf (undefined :: msg))
  success <- initMessage ptr
  if success == 1
    then return ptr
    else do
      free ptr
      error "Failed to create message!"

destroyMessage :: forall msg. (RosMessage msg) => Ptr msg -> IO ()
destroyMessage ptr = do
  finiMessage ptr
  free ptr

class (Storable msg) => RosMessage msg where
  getTypeSupport :: IO (Ptr (RosidlMessageTypeSupport msg))
  initMessage :: Ptr msg -> IO CBool
  finiMessage :: Ptr msg -> IO ()
