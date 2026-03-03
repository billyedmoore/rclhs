module Main (main) where

import RclHs
  ( publish,
    withContext,
    withNode,
    withPublisher,
    withSubscription,
    withTimer,
  )

main :: IO ()
main = do
  withContext $ \ctx -> do
    withNode "hello" "" ctx $ \node -> do
      withPublisher "hello" node $ \pub -> do
        publish pub "Hello World!"
        withTimer ctx (publish pub "Hello World") 10000 (\_ -> pure ())
        withSubscription "hello" node (putStrLn . take 80 . cycle . (++ " ")) (\_ -> pure ())
