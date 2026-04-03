module RclHs.Types where

import Foreign.Ptr

-- Opaque Ptr
data RosidlMessageTypeSupport a

class RosMessage msg where
  getTypeSupport :: IO (Ptr (RosidlMessageTypeSupport msg))
