module Main where

import Foreign (Ptr)
import RclHs
  ( Publisher,
    publish,
    secondInNanoSecond,
    spin,
    withContext,
    withNode,
    withPublisher,
    withTimer,
  )
import RclHs.ExampleTypes.Msg.StringMessage

pubCallback :: Ptr Publisher -> Int -> IO Int
pubCallback pub i = do
  publish pub (StringMessage ("Hello, world! " ++ show i))
  return (i + 1)

main :: IO ()
main = do
  let topic = "topic"
  withContext $ \ctx -> do
    withNode "node_name" "" ctx $ \node -> do
      withPublisher @StringMessage topic node $ \pub -> do
        withTimer ctx 0 (pubCallback pub) (secondInNanoSecond `div` 2) $ \timer ->
          spin ctx [] [timer]
