module Main where

import RclHs
  ( spin,
    withContext,
    withNode,
    withSubscription,
  )
import RclHs.ExampleTypes.Msg.StringMessage

subCallback :: () -> StringMessage -> IO ()
subCallback _ msg = putStrLn ("I heard: '" ++ str msg ++ "'")

main :: IO ()
main = do
  let topic = "topic"
  withContext $ \ctx -> do
    withNode "minimal_subscriber" "" ctx $ \node -> do
      withSubscription @StringMessage topic node () subCallback $ \sub -> do
        spin ctx [sub] []
