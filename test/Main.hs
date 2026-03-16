module Main (main) where

import Control.Exception (SomeException, try)
import PubSubExample qualified
import Test.Tasty
import Test.Tasty.HUnit

main :: IO ()
main = defaultMain integrationTests

integrationTests :: TestTree
integrationTests =
  testGroup
    "Integration Tests Based On Ros2 Examples"
    [ -- Visual inspection of the test output is required to
      -- check all is working correctly :(.
      testCase "Run PubSub without crashing for 10 seconds" $ do
        result <- try PubSubExample.main :: IO (Either SomeException ())
        case result of
          Left err -> assertFailure $ "PubSubExample Crashed: " ++ show err
          Right _ -> return ()
    ]
