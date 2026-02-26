module Main (main) where

import Control.Concurrent (threadDelay)
import RclHs (createContext, createNode, createPublisher, publish)
import System.Mem (performGC)

main :: IO ()
main = do
  ctx <- createContext
  node <- createNode "hello" "" ctx
  pub <- createPublisher "hello" node
  publish pub "Hello World!"
  threadDelay 10000
  performGC
