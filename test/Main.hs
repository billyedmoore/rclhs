module Main (main) where

import Control.Concurrent (threadDelay)
import RclHs (createContext, createNode)
import System.Mem (performGC)

main :: IO ()
main = do
  ctx <- createContext
  _ <- createNode "hello" "" ctx
  threadDelay 10000
  performGC
