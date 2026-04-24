module Main where

import Data.Vector.Storable.Sized qualified as SizedVector
import RclHs
  ( SomeSubscription (SomeSubscription),
    spin,
    withContext,
    withNode,
    withSubscription,
  )
import RclHs.ExampleTypes.Msg.IntSequence

subCallback :: () -> IntSequence -> IO ()
subCallback _ (IntSequence {int_seq = lst, int_array = vec}) =
  putStrLn $ "list " ++ show lst ++ "\n vec" ++ show vec

main :: IO ()
main = do
  let topic = "topic"
  withContext $ \ctx -> do
    withNode "node_name" "" ctx $ \node -> do
      withSubscription @IntSequence topic node () subCallback $ \sub -> do
        spin ctx [SomeSubscription sub] [] []
