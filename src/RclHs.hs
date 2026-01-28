module RclHs (helloWorld) where

import RclHs.Bindings (hello)

helloWorld :: IO ()
helloWorld = hello
