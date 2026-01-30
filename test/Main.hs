module Main where

import RclHs (initNode)
import Control.Concurrent (threadDelay)
import System.Mem (performGC)

main :: IO ()
main = do
    putStrLn "Creating Node"
    maybeNode <- initNode "haskell_test_node" ""

    case maybeNode of
        Nothing -> putStrLn "Node creation failed"
        Just _node -> do
            putStrLn "Pretending to work"
            threadDelay 1000000
            
            putStrLn "Node out of scope"

    putStrLn "Forcing Garbage Collection (performGC)"
    performGC
    
    threadDelay 500000
