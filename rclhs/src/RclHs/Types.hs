module RclHs.Types
  ( createEmptyMessage,
    destroyMessage,
    peekRosString,
    peekRosSequence,
    withRosSequence,
    initRosString,
    destroyRosString,
    copyCArrayToSized,
    RosSequence,
    RosString,
    RosMessage (..),
    RosidlMessageTypeSupport,
    RosidlServiceTypeSupport,
    RosService (..),
  )
where

import Data.Kind (Type)
import Data.Proxy (Proxy (..))
import Foreign (Ptr, callocBytes, free)
import Foreign.C.Types (CBool (..))
import RclHs.Types.Dynamic
  ( RosSequence,
    RosString,
    copyCArrayToSized,
    destroyRosString,
    initRosString,
    peekRosSequence,
    peekRosString,
    withRosSequence,
  )

-- Opaque Ptrs for type supports
data RosidlMessageTypeSupport a

data RosidlServiceTypeSupport a

-- Allocate and init message
createEmptyMessage :: forall msg. (RosMessage msg) => IO (Ptr msg)
createEmptyMessage = do
  ptr <- callocBytes (outerSize (Proxy @msg))
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

class RosMessage a where
  outerSize :: Proxy a -> Int

  initMessage :: Ptr a -> IO CBool
  finiMessage :: Ptr a -> IO ()

  getTypeSupport :: IO (Ptr (RosidlMessageTypeSupport a))

  newCStruct :: a -> IO (Ptr a)
  withCStruct :: a -> (Ptr a -> IO b) -> IO b
  peekCStruct :: Ptr a -> IO a

class (RosMessage (SrvRequest srv), RosMessage (SrvResponse srv)) => RosService srv where
  type SrvRequest srv :: Type
  type SrvResponse srv :: Type

  getServiceTypeSupport :: IO (Ptr (RosidlServiceTypeSupport srv))
