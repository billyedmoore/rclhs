module Main (main) where

import Control.Concurrent (threadDelay)
import Foreign (ForeignPtr, newForeignPtr_, nullPtr)
import RclHs (Context, createNode)
import System.Mem (performGC)

mockContext :: IO (ForeignPtr Context)
mockContext = newForeignPtr_ nullPtr

main :: IO ()
main = do
  ctx <- mockContext
  _ <- createNode "hello" "" ctx
  threadDelay 10000
  performGC
