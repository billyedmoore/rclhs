module Main where

import Control.Monad (replicateM)
import Data.Vector.Storable.Sized qualified as SizedVector
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
import RclHs.ExampleTypes.Msg.IntSequence
import System.Random (randomIO, randomRIO)

generateRandomIntSequence :: IO IntSequence
generateRandomIntSequence = do
  listLength <- randomRIO (1, 512)
  randomList <- replicateM listLength randomIO
  randomArray <- SizedVector.replicateM randomIO
  return $ IntSequence randomList randomArray

pubCallback :: Ptr (Publisher IntSequence) -> () -> IO ()
pubCallback pub _ = do
  intSeq <- generateRandomIntSequence
  publish pub intSeq
  return ()

main :: IO ()
main = do
  let topic = "topic"
  withContext $ \ctx -> do
    withNode "node_name" "" ctx $ \node -> do
      withPublisher @IntSequence topic node $ \pub -> do
        withTimer ctx () (pubCallback pub) (secondInNanoSecond `div` 2) $ \timer ->
          spin ctx [] [timer] []
