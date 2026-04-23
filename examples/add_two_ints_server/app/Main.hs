module Main where

import RclHs
  ( SomeServiceServer (SomeServiceServer),
    spin,
    withContext,
    withNode,
    withServiceServer,
  )
import RclHs.ExampleTypes.Srv.AddTwoInts
  ( AddTwoInts,
    AddTwoInts_Request (AddTwoInts_Request),
    AddTwoInts_Response (AddTwoInts_Response),
  )
import RclHs.Types (RosService (..))

serverCallback :: SrvRequest AddTwoInts -> IO (SrvResponse AddTwoInts)
serverCallback (AddTwoInts_Request a b) = do
  return $ AddTwoInts_Response (a + b)

main :: IO ()
main = do
  withContext $ \ctx -> do
    withNode "node_name" "" ctx $ \node -> do
      withServiceServer @AddTwoInts "add_two_ints" node serverCallback $ \service -> do
        spin ctx [] [] [SomeServiceServer service]
