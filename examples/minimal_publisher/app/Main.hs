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
  publish pub (StringMessage ("Hello World " ++ show (i + 1)))
  return (i + 1)

main :: IO ()
main = do
  let topic = "topic"
  withContext $ \ctx -> do
    withNode "node_name" "" ctx $ \node -> do
      withPublisher @StringMessage topic node $ \pub -> do
        withTimer ctx (-1) (pubCallback pub) (5 * secondInNanoSecond) $ \timer ->
          spin ctx [] [timer]
