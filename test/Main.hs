module Main (main) where

import Control.Concurrent (threadDelay)
import RclHs
  ( createContext,
    createNode,
    createPublisher,
    createSubscription,
    createTimer,
    publish,
  )
import System.Mem (performGC)

main :: IO ()
main = do
  ctx <- createContext
  node <- createNode "hello" "" ctx
  pub <- createPublisher "hello" node
  _ <- createSubscription "hello" node (putStrLn . take 80 . cycle . (++ " "))
  _ <- createTimer ctx (publish pub "Hello World") 10000

  publish pub "Hello World!"
  threadDelay 10000
  performGC
