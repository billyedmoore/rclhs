module Main (main) where

import Control.Concurrent (threadDelay)
import RclHs (createContext, createNode, createPublisher, createSubscription, publish)
import System.Mem (performGC)

main :: IO ()
main = do
  ctx <- createContext
  node <- createNode "hello" "" ctx
  pub <- createPublisher "hello" node
  _ <- createSubscription "hello" node (putStrLn . take 80 . cycle . (++ " "))
  publish pub "Hello World!"
  threadDelay 10000
  performGC
