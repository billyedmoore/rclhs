module Main where

import Data.Int (Int64)
import RclHs
  ( callService,
    secondInNanoSecond,
    withContext,
    withNode,
    withServiceClient,
  )
import RclHs.ExampleTypes.Srv.AddTwoInts
  ( AddTwoInts,
    AddTwoInts_Request (AddTwoInts_Request),
    AddTwoInts_Response (AddTwoInts_Response),
  )
import RclHs.Types (RosService (..))

clientCallback :: SrvRequest AddTwoInts -> SrvResponse AddTwoInts -> IO ()
clientCallback (AddTwoInts_Request a b) (AddTwoInts_Response tot) =
  putStrLn $ "Result -> " ++ show a ++ " + " ++ show b ++ " = " ++ show tot

main :: IO ()
main = do
  withContext $ \ctx -> do
    withNode "node_name" "" ctx $ \node -> do
      withServiceClient @AddTwoInts "add_two_ints" node $ \client -> do
        let a = 10
            b = 10
            request = AddTwoInts_Request a b
            timeoutTime = fromIntegral secondInNanoSecond * 10 :: Int64
        callService @AddTwoInts node ctx client request (clientCallback request) timeoutTime
