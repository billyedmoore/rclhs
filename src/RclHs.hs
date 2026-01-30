module RclHs (Node, initNode) where

import Foreign (ForeignPtr, free, newForeignPtr, nullPtr)
import Foreign.C.String (newCString)
import RclHs.Bindings (RclHsNodeStruct, c_create_node, c_destroy_node)

newtype Node = Node (ForeignPtr RclHsNodeStruct)

initNode :: String -> String -> IO (Maybe Node)
initNode name namespace = do
  cName <- newCString name
  cNs <- newCString namespace

  rawPtr <- c_create_node cName cNs

  free cName
  free cNs

  if rawPtr == nullPtr
    then return Nothing
    else do
      managedPtr <- newForeignPtr c_destroy_node rawPtr
      return $ Just (Node managedPtr)
